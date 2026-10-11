/// Terms and Conditions / Privacy Policy. Public (readable before signing
/// in). A draft shows a banner and the owner's open items; approved text
/// shows its version and date.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/policy_content.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({required this.kind, super.key});

  final PolicyKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final async = ref.watch(policyProvider((kind, lang)));
    final fallbackTitle = kind == PolicyKind.terms ? t.paTerms : t.paPrivacy;
    return PatientPageScaffold(
      appBar: AppBar(
        title: Text(fallbackTitle),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      children: async.when(
        loading: () => const [PatientStateView(kind: PatientStateKind.loading)],
        error: (_, _) => [
          PatientStateView(
            kind: PatientStateKind.error,
            title: t.paPolicyLoadError,
            actionLabel: t.tryAgain,
            onAction: () => ref.invalidate(policyProvider((kind, lang))),
          ),
        ],
        data: (doc) => [
          if (!doc.approved) _DraftBanner(doc: doc),
          const SizedBox(height: Space.md),
          PatientPageTitle(
            doc.title.isEmpty ? fallbackTitle : doc.title,
            subtitle: t.paPolicyVersion(doc.version, doc.lastUpdated),
          ),
          const SizedBox(height: Space.sm),
          for (final block in doc.blocks) _Block(block: block),
          if (!doc.approved && doc.unresolved.isNotEmpty) ...[
            SectionHeading(t.paPolicyOpenItems),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in doc.unresolved) _Bullet(text: item),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.doc});
  final PolicyDocument doc;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final palette = PatientPalette.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: SurfaceCard(
        key: const ValueKey('policy-draft-banner'),
        color: palette.warningContainer,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.edit_note, color: palette.warning),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReadableLabel(
                    t.paPolicyDraftTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.paPolicyDraftBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});
  final PolicyBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return switch (block.type) {
      PolicyBlockType.heading => Padding(
        padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
        child: Semantics(
          header: true,
          child: ReadableLabel(
            block.text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ),
      ),
      PolicyBlockType.bullet => _Bullet(text: block.text),
      PolicyBlockType.paragraph => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Text(
          block.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: palette.text,
            height: 1.5,
          ),
        ),
      ),
    };
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: palette.link,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.text,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
