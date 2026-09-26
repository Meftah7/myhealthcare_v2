/// Admin → AI Settings (P5-16, key entry part of P3-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/ai/ai_models.dart';
import '../../../services/ai/gemini_ai_service.dart';
import '../application/settings_providers.dart';
import 'admin_profile_pages.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final hasKey = ref.watch(aiKeyPresentProvider);

    return AdminSectionScaffold(
      title: t.aiSettingsTitle,
      child: settings.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadSettings,
          onRetry: () => ref.invalidate(appSettingsProvider),
        ),
        data: (s) {
          final controller = ref.read(settingsControllerProvider);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(t.aiFeaturesEnabledTitle),
                      subtitle: Text(t.aiFeaturesEnabledSubtitle),
                      value: s.aiEnabled,
                      onChanged: (v) =>
                          controller.update(s.copyWith(aiEnabled: v)),
                    ),
                    const Divider(height: 1, indent: Space.md),
                    SwitchListTile(
                      title: Text(t.forceMockModeTitle),
                      subtitle: Text(t.forceMockModeSubtitle),
                      value: s.mockMode,
                      onChanged: s.aiEnabled
                          ? (v) => controller.update(s.copyWith(mockMode: v))
                          : null,
                    ),
                  ],
                ),
              ),

              SectionHeader(t.llmProviderHeader),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModelField(
                      initial: s.modelId,
                      onSubmit: (m) =>
                          controller.update(s.copyWith(modelId: m)),
                    ),
                    const SizedBox(height: Space.sm),
                    hasKey.when(
                      loading: () => const LoadingSkeleton(height: 40),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (present) => _ApiKeyField(present: present),
                    ),
                    const SizedBox(height: Space.sm),
                    _TestConnectionButton(model: s.modelId),
                  ],
                ),
              ),

              SectionHeader(t.demoDataHeader),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: Text(t.reseedDemoDataTitle),
                  subtitle: Text(t.reseedDemoDataSubtitle),
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: t.reseedConfirmTitle,
                      message: t.reseedConfirmBody,
                      confirmLabel: t.reseedAction,
                      destructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    final r = await ref.read(seederProvider).reset();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t.reseededSnackbar(r.patients, r.appointments),
                          ),
                        ),
                      );
                    }
                  },
                ),
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
    final t = AppLocalizations.of(context)!;
    return TextField(
      controller: _c,
      decoration: InputDecoration(
        labelText: t.modelFieldLabel,
        helperText: t.modelFieldHelper,
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
    final t = AppLocalizations.of(context)!;
    if (widget.present && !_editing) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.key),
        title: Text(t.apiKeySetTitle),
        subtitle: Text(t.apiKeyStoredNote),
        trailing: Wrap(
          spacing: Space.xs,
          children: [
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: Text(t.replaceAction),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await ref.read(settingsControllerProvider).setApiKey('');
                      if (mounted) setState(() {});
                    },
              child: Text(t.removeButton),
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
            decoration: InputDecoration(
              labelText: t.apiKeyFieldLabel,
              helperText: t.apiKeyHelper,
            ),
          ),
        ),
        const SizedBox(width: Space.xs),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(t.saveButton),
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
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final key = await ref.read(aiKeyStoreProvider).read();
    String message;
    if (key == null) {
      message = t.noApiKeySet;
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
          ? t.connectionOkMessage
          : t.connectionFailedMessage('${r.failureOrNull?.message}');
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
    final t = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _test,
      icon: _busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_tethering),
      label: Text(t.testConnectionAction),
    );
  }
}
