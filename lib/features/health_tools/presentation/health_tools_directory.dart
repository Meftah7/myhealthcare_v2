import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/lab_conversion.dart';
import 'tool_widgets.dart';

AppBar toolsAppBar(BuildContext context, String title) => AppBar(
  title: Text(title),
  leading: BackButton(
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(AppRoutes.patientHome),
  ),
);

class HealthCalculatorsScreen extends StatelessWidget {
  const HealthCalculatorsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    Widget unavailable(
      String id,
      String title,
      String description,
      IconData icon,
    ) => ToolEntryRow(
      key: ValueKey(id),
      title: title,
      description: description,
      icon: icon,
      onTap: () => explainFutureTool(context, title, description),
    );
    Widget nutrition(String id, String title, IconData icon) => ToolEntryRow(
      key: ValueKey(id),
      title: title,
      description: t.htNutritionReuse,
      icon: icon,
      onTap: () => context.push(AppRoutes.patientNutrition),
    );
    return PatientPageScaffold(
      appBar: toolsAppBar(context, t.paHealthCalculators),
      children: [
        ReadableLabel(
          t.paHealthCalculators,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: Space.sm),
        Text(t.htScope),
        const SizedBox(height: Space.lg),
        ExpansionTile(
          key: const PageStorageKey('women-calculators'),
          title: Text(t.htWomensHealth),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          children: [
            ToolEntryRow(
              key: const ValueKey('ovulation'),
              title: t.htOvulation,
              description: t.htOvulationDesc,
              icon: Icons.calendar_month_outlined,
              onTap: () => context.push(AppRoutes.patientOvulation),
            ),
            ToolEntryRow(
              key: const ValueKey('due-date'),
              title: t.htDueDate,
              description: t.htDueDateDesc,
              icon: Icons.child_care_outlined,
              onTap: () => context.push(AppRoutes.patientDueDate),
            ),
          ],
        ),
        ExpansionTile(
          key: const PageStorageKey('general-calculators'),
          title: Text(t.htGeneralHealth),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          children: [
            ToolEntryRow(
              key: const ValueKey('bmi'),
              title: t.htBmi,
              description: t.htBmiDescription,
              icon: Icons.monitor_weight_outlined,
              onTap: () => context.push(AppRoutes.patientBodyMeasurements),
            ),
            nutrition('calories', t.htCalories, Icons.restaurant_outlined),
            nutrition('bmr', t.htBmr, Icons.battery_charging_full_outlined),
            ToolEntryRow(
              key: const ValueKey('ideal-weight'),
              title: t.htIdealWeight,
              description: t.htIdealWeightDesc,
              icon: Icons.accessibility_new_outlined,
              onTap: () => context.push(AppRoutes.patientIdealWeight),
            ),
            ToolEntryRow(
              key: const ValueKey('body-fat'),
              title: t.htBodyFat,
              description: t.htBodyFatDesc,
              icon: Icons.water_drop_outlined,
              onTap: () => context.push(AppRoutes.patientBodyFat),
            ),
            nutrition('macros', t.htMacros, Icons.pie_chart_outline),
          ],
        ),
      ],
    );
  }
}

class HealthConvertersScreen extends StatelessWidget {
  const HealthConvertersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final names = {
      LabAnalyte.glucose: t.htBloodSugar,
      LabAnalyte.cholesterol: t.htCholesterol,
      LabAnalyte.triglycerides: t.htTriglycerides,
    };
    return PatientPageScaffold(
      appBar: toolsAppBar(context, t.paHealthConverters),
      children: [
        ReadableLabel(
          t.paHealthConverters,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: Space.sm),
        Text(t.htScope),
        const SizedBox(height: Space.lg),
        for (final analyte in LabAnalyte.values)
          ToolEntryRow(
            key: ValueKey('converter-${analyte.name}'),
            title: names[analyte]!,
            description: t.htConverterDescription,
            icon: Icons.science_outlined,
            onTap: () =>
                context.push('${AppRoutes.patientConverters}/${analyte.name}'),
          ),
        ToolEntryRow(
          title: t.htOtherConverters,
          description: t.htConverterDescription,
          icon: Icons.swap_horiz,
          onTap: () => context.push(AppRoutes.patientGeneralConverters),
        ),
      ],
    );
  }
}
