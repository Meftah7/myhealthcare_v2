/// Services tab: core clinical services → MyHealth service promotions →
/// Health Tools → clearly grouped Future work extensions → Policies. Reads
/// the same [PatientCatalog] as Home; account actions live in the drawer.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/patient_catalog.dart';
import 'catalog_widgets.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final services = PatientCatalog.services;
    return PatientPageScaffold(
      header: Row(
        children: [
          const ShellMenuButton(),
          const SizedBox(width: Space.xxs),
          Expanded(child: PatientPageTitle(t.paServices)),
        ],
      ),
      children: [
        SectionHeading(t.paCoreServices),
        CatalogGrid(items: services[ServiceGroup.core]!),
        SectionHeading(t.paMyHealthServices),
        ServiceCarousel(items: PatientCatalog.promotions),
        SectionHeading(t.paHealthTools),
        CatalogGrid(items: services[ServiceGroup.tools]!),
        SectionHeading(
          t.paFutureExtensions,
          subtitle: t.paFutureExtensionsSubtitle,
        ),
        CatalogGrid(items: services[ServiceGroup.futureExtensions]!),
        SectionHeading(t.paPolicies),
        CatalogGrid(items: services[ServiceGroup.policies]!),
      ],
    );
  }
}
