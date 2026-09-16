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
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';

Future<void> showFeedbackSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FeedbackSheet(),
  );
}

String feedbackCategoryLabel(BuildContext context, FeedbackCategory c) {
  final t = AppLocalizations.of(context)!;
  return switch (c) {
    FeedbackCategory.bug => t.somethingIsBrokenOption,
    FeedbackCategory.featureRequest => t.feedbackCategoryFeatureRequest,
    FeedbackCategory.generalFeedback => t.feedbackCategoryGeneralFeedback,
    FeedbackCategory.complaint => t.feedbackCategoryComplaint,
  };
}

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
    final t = AppLocalizations.of(context)!;
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
          Ok() => t.feedbackThanksMessage,
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.sendFeedbackTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              t.feedbackIntroText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<FeedbackCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: t.aboutLabel),
              items: [
                for (final c in FeedbackCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Text(feedbackCategoryLabel(context, c)),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: t.yourMessageLabel,
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
                  : Text(t.sendButton),
            ),
          ],
        ),
      ),
    );
  }
}
