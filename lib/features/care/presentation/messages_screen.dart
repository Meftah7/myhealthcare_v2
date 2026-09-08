/// "Ask your doctor" — the patient's message threads with the doctors they
/// have seen (P10-07).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/care_providers.dart';
import 'message_thread_screen.dart';
import 'thread_list.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(patientThreadsProvider);
    final doctors =
        ref.watch(messageableDoctorsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask your doctor'),
        actions: const [PatientTopActions()],
      ),
      floatingActionButton: doctors.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startThread(context, doctors),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New message'),
            ),
      body: threads.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your messages.',
          onRetry: () => ref.invalidate(patientThreadsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              message: doctors.isEmpty
                  ? 'Once you have seen a doctor you can message them here.'
                  : 'No conversations yet.\nTap "New message" to ask a '
                        'non-urgent question.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) {
                  final t = list[i];
                  return ThreadTile(
                    thread: t,
                    viewerIsStaff: false,
                    onTap: () => _open(context, t.staffId, t.counterpartName),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startThread(
    BuildContext context,
    List<({String id, String name})> doctors,
  ) async {
    final chosen = await showModalBottomSheet<({String id, String name})>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final d in doctors)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(d.name),
                onTap: () => Navigator.of(context).pop(d),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    _open(context, chosen.id, chosen.name);
  }

  void _open(BuildContext context, String staffId, String name) {
    final q = Uri.encodeComponent(name);
    unawaited(context.push('${AppRoutes.patientMessages}/$staffId?name=$q'));
  }
}

/// Router entry for a patient thread — the patient id comes from the session.
class PatientMessageThreadPage extends ConsumerWidget {
  const PatientMessageThreadPage({required this.staffId, this.title, super.key});

  final String staffId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final doctors =
        ref.watch(messageableDoctorsProvider).valueOrNull ?? const [];
    final name =
        title ??
        doctors.where((d) => d.id == staffId).map((d) => d.name).firstOrNull ??
        'Your doctor';

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MessageThreadScreen(
      patientId: user.id,
      staffId: staffId,
      title: name,
      viewerIsStaff: false,
    );
  }
}
