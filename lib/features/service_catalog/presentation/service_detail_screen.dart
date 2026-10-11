/// One reusable service detail page: back, a small original icon image, the
/// soft-blue category label, heading, short description and a bottom action
/// area that stays visible without covering the scrolling content.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/catalog_dispatcher.dart';
import '../domain/service_details.dart';

/// Readable width on tablets and desktops.
const double _maxWidth = 640;

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({required this.id, super.key});

  final String id;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.patientServices);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final detail = ServiceDetails.byId[id];
    final appBar = AppBar(
      leading: BackButton(onPressed: () => _back(context)),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );

    if (detail == null) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPatientInset),
            child: Text(t.svcNotFound, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final item = detail.item;
    return Scaffold(
      appBar: appBar,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              kPatientInset,
              Space.md,
              kPatientInset,
              Space.xl,
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: palette.softAccent,
                    child: Icon(item.icon, color: palette.action, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm,
                      vertical: Space.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.softAccent,
                      borderRadius: Radii.chip,
                    ),
                    child: Text(
                      item.title(t),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.onSoftAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.isFutureWork) FutureWorkBadge(label: t.paFutureWork),
                ],
              ),
              const SizedBox(height: Space.lg),
              Semantics(
                header: true,
                child: Text(
                  detail.heading(t),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                detail.body(t),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      // A bottom bar, not an overlay: the list above ends where it begins,
      // so on a short phone the action never hides content.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: palette.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kPatientInset,
              Space.md,
              kPatientInset,
              Space.md,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: detail.hasWorkingAction
                    ? FilledButton(
                        key: const ValueKey('service-detail-action'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => context.go(detail.actionRoute!),
                        child: Text(detail.actionLabel!(t)),
                      )
                    : SoftActionButton(
                        key: const ValueKey('service-detail-action'),
                        icon: Icons.info_outline_rounded,
                        label: t.svcLearnFutureWork,
                        onPressed: () =>
                            unawaited(showFutureWorkSheet(context, item)),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
