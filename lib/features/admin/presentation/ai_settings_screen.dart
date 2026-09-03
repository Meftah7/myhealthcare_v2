/// Admin → AI Settings (P5-16, key entry part of P3-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../services/ai/ai_models.dart';
import '../../../services/ai/gemini_ai_service.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/settings_providers.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final hasKey = ref.watch(aiKeyPresentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI settings'),
        actions: const [SignOutAction()],
      ),
      body: settings.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load settings.',
          onRetry: () => ref.invalidate(appSettingsProvider),
        ),
        data: (s) {
          final controller = ref.read(settingsControllerProvider);
          return ListView(
            padding: const EdgeInsets.all(Space.lg),
            children: [
              SwitchListTile(
                title: const Text('AI features enabled'),
                subtitle: const Text(
                  'Turn off to hide all AI surfaces entirely.',
                ),
                value: s.aiEnabled,
                onChanged: (v) => controller.update(s.copyWith(aiEnabled: v)),
              ),
              SwitchListTile(
                title: const Text('Force mock mode'),
                subtitle: const Text(
                  'Use the offline deterministic assistant even when a key '
                  'is set. Recommended for demos.',
                ),
                value: s.mockMode,
                onChanged: s.aiEnabled
                    ? (v) => controller.update(s.copyWith(mockMode: v))
                    : null,
              ),
              const Divider(height: Space.xl),

              const SectionHeader('LLM provider (Google Gemini, free tier)'),
              _ModelField(
                initial: s.modelId,
                onSubmit: (m) => controller.update(s.copyWith(modelId: m)),
              ),
              const SizedBox(height: Space.sm),
              hasKey.when(
                loading: () => const LoadingSkeleton(height: 40),
                error: (_, _) => const SizedBox.shrink(),
                data: (present) => _ApiKeyField(present: present),
              ),
              const SizedBox(height: Space.sm),
              _TestConnectionButton(model: s.modelId),

              const Divider(height: Space.xl),
              const SectionHeader('Demo data'),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Re-seed demo data'),
                subtitle: const Text(
                  'Wipe and regenerate the synthetic dataset.',
                ),
                onTap: () async {
                  final ok = await confirm(
                    context,
                    title: 'Re-seed?',
                    message:
                        'This deletes all current data and regenerates the '
                        'demo dataset.',
                    confirmLabel: 'Re-seed',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  final r = await ref.read(seederProvider).reset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Re-seeded: ${r.patients} patients, '
                          '${r.appointments} appointments.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModelField extends StatefulWidget {
  const _ModelField({required this.initial, required this.onSubmit});
  final String initial;
  final ValueChanged<String> onSubmit;

  @override
  State<_ModelField> createState() => _ModelFieldState();
}

class _ModelFieldState extends State<_ModelField> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      decoration: const InputDecoration(
        labelText: 'Model',
        helperText: 'e.g. gemini-2.0-flash, gemini-2.5-flash',
      ),
      onSubmitted: widget.onSubmit,
    );
  }
}

class _ApiKeyField extends ConsumerStatefulWidget {
  const _ApiKeyField({required this.present});
  final bool present;

  @override
  ConsumerState<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends ConsumerState<_ApiKeyField> {
  final _c = TextEditingController();
  bool _editing = false;
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    await ref.read(settingsControllerProvider).setApiKey(_c.text);
    _c.clear();
    if (mounted) {
      setState(() {
        _busy = false;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.present && !_editing) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.key),
        title: const Text('API key set'),
        subtitle: const Text('Stored in the OS secure store.'),
        trailing: Wrap(
          spacing: Space.xs,
          children: [
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Replace'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await ref.read(settingsControllerProvider).setApiKey('');
                      if (mounted) setState(() {});
                    },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API key',
              helperText:
                  'aistudio.google.com/apikey — never logged or committed',
            ),
          ),
        ),
        const SizedBox(width: Space.xs),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TestConnectionButton extends ConsumerStatefulWidget {
  const _TestConnectionButton({required this.model});
  final String model;

  @override
  ConsumerState<_TestConnectionButton> createState() =>
      _TestConnectionButtonState();
}

class _TestConnectionButtonState extends ConsumerState<_TestConnectionButton> {
  bool _busy = false;

  Future<void> _test() async {
    setState(() => _busy = true);
    final key = await ref.read(aiKeyStoreProvider).read();
    String message;
    if (key == null) {
      message = 'No API key set.';
    } else {
      final svc = GeminiAiService(apiKey: key, model: widget.model);
      final r = await svc.summarizeRecords(
        const PatientContext(
          patientId: 'test',
          contextText:
              '# Patient\n- Age: 40\n# Record history\n## 2026-01-10 — '
              'visitNote: Routine check\nUnremarkable.',
          hash: 'test',
          approxTokens: 20,
        ),
      );
      message = r.isOk
          ? 'Connection OK — the model responded.'
          : 'Failed: ${r.failureOrNull?.message}';
    }
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _test,
      icon: _busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_tethering),
      label: const Text('Test connection'),
    );
  }
}
