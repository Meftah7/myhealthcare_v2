/// Opens a [CatalogItem] — the one place catalogue actions are dispatched, so
/// widgets never embed routing strings or access logic.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_chat/application/care_navigator.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../../timeline/presentation/import_record_sheet.dart';
import '../domain/patient_catalog.dart';

Future<void> openCatalogItem(
  BuildContext context,
  WidgetRef ref,
  CatalogItem item,
) async {
  switch (item.action) {
    case CatalogActionKind.route:
      context.go(item.route!);
    case CatalogActionKind.explainReport:
      await startReportExplanation(context, ref);
    case CatalogActionKind.feedback:
      await showFeedbackSheet(context, ref);
    case CatalogActionKind.emergency:
      await showEmergencySheet(context);
    case CatalogActionKind.futureWork:
      await showFutureWorkSheet(context, item);
    case CatalogActionKind.unavailable:
      await showUnavailableSheet(context, item);
  }
}

/// Explain a report: the existing PDF import (validation + text extraction)
/// saves the original to the patient's records, then the report-explanation
/// chat opens grounded on that record.
Future<void> startReportExplanation(BuildContext context, WidgetRef ref) async {
  final record = await showImportRecordSheet(context);
  if (record == null) return;
  ref.read(careNavigatorViewProvider.notifier).state = CareNavView.panel;
  unawaited(ref.read(careNavigatorProvider.notifier).explainDocument(record));
}

/// A planned extension: says plainly it is future work and not part of this
/// version — no data, no pretend service.
Future<void> showFutureWorkSheet(BuildContext context, CatalogItem item) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kPatientInset,
          0,
          kPatientInset,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconTile(
                icon: item.icon,
                accent: PatientAccent.amber,
                size: 56,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              item.title(t),
              textAlign: TextAlign.center,
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xs),
            Center(child: FutureWorkBadge(label: t.paFutureWork)),
            const SizedBox(height: Space.sm),
            Text(
              t.paFutureWorkBody,
              textAlign: TextAlign.center,
              style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                color: PatientPalette.of(sheet).textMuted,
              ),
            ),
            const SizedBox(height: Space.lg),
            SoftActionButton(
              label: t.paClose,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showUnavailableSheet(BuildContext context, CatalogItem item) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kPatientInset,
          0,
          kPatientInset,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconTile(
                icon: item.icon,
                accent: PatientAccent.neutral,
                size: 56,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              item.title(t),
              textAlign: TextAlign.center,
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xs),
            Text(
              t.paServiceUnavailableBody,
              textAlign: TextAlign.center,
              style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                color: PatientPalette.of(sheet).textMuted,
              ),
            ),
            const SizedBox(height: Space.lg),
            SoftActionButton(
              label: t.paClose,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Emergency guidance. MyHealth does not dispatch emergency services, so this
/// says so plainly and points to the local emergency number.
Future<void> showEmergencySheet(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final palette = PatientPalette.of(sheet);
      final theme = Theme.of(sheet);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            kPatientInset,
            0,
            kPatientInset,
            Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconTile(
                  icon: Icons.emergency_outlined,
                  accent: PatientAccent.red,
                  size: 56,
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                t.paEmergencyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.sm),
              SurfaceCard(
                color: palette.dangerContainer,
                child: Text(
                  t.paEmergencyBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                t.paEmergencyNotDispatch,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: Space.lg),
              SoftActionButton(
                label: t.paClose,
                onPressed: () => Navigator.of(sheet).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
