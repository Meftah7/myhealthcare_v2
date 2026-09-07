/// "Send feedback / report a problem" — a small composer any signed-in user
/// can open (ported from the FirstSemMyHealth `feedback_reports` flow). The
/// report lands in the admin dashboard's Feedback inbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';

Future<void> showFeedbackSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FeedbackSheet(),
  );
}

String feedbackCategoryLabel(FeedbackCategory c) => switch (c) {
  FeedbackCategory.bug => 'Something is broken',
  FeedbackCategory.featureRequest => 'Feature request',
  FeedbackCategory.generalFeedback => 'General feedback',
  FeedbackCategory.complaint => 'Complaint',
};

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet();

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  FeedbackCategory _category = FeedbackCategory.generalFeedback;
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref
        .read(feedbackRepositoryProvider)
        .submit(
          category: _category,
          message: _message.text,
          reporterId: ref.read(currentUserProvider)?.id,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => 'Thanks — your feedback was sent to the team.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Send feedback', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              'Tell the team what is working, what is not, or what you wish the '
              'app did.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<FeedbackCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'About'),
              items: [
                for (final c in FeedbackCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Text(feedbackCategoryLabel(c)),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Your message',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || _message.text.trim().length < 5)
                  ? null
                  : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
