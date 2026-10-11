/// Services tab: weather link → Medical & Healthcare → MyHealth services →
/// Health Tools → Support → Policies. Reads the same [PatientCatalog] as Home;
/// Home Quick Access stays the place for the patient's own features.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/patient_catalog.dart';
import 'catalog_widgets.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final palette = PatientPalette.of(context);
    String group(ServiceGroup g) => switch (g) {
      ServiceGroup.medical => t.paMedicalHealthcare,
      ServiceGroup.tools => t.paHealthTools,
      ServiceGroup.support => t.paSupportServices,
      ServiceGroup.policies => t.paPolicies,
    };
    final services = PatientCatalog.services;
    return PatientPageScaffold(
      header: PatientPageTitle(t.paServices),
      children: [
        const SizedBox(height: Space.md),
        SurfaceCard(
          onTap: () => context.go(AppRoutes.patientWeather),
          semanticLabel: t.paWeather,
          child: Row(
            children: [
              const IconTile(
                icon: Icons.wb_sunny_outlined,
                accent: PatientAccent.amber,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: ReadableLabel(
                  t.paWeatherLink,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.text),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
        SectionHeading(group(ServiceGroup.medical)),
        CatalogGrid(items: services[ServiceGroup.medical]!),
        SectionHeading(t.paMyHealthServices),
        ServiceCarousel(items: PatientCatalog.promotions),
        SectionHeading(group(ServiceGroup.tools)),
        CatalogGrid(items: services[ServiceGroup.tools]!),
        SectionHeading(group(ServiceGroup.support)),
        CatalogGrid(items: services[ServiceGroup.support]!),
        SectionHeading(group(ServiceGroup.policies)),
        CatalogGrid(items: services[ServiceGroup.policies]!),
      ],
    );
  }
}
