/// Admin → Clinic hours: which days the clinic is open, and the daily
/// open/close hour. Shared by the booking wizard, the reschedule flow, and
/// admin scheduling (`core/utils/clinic_hours.dart`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../l10n/app_localizations.dart';

class ClinicHoursScreen extends ConsumerWidget {
  const ClinicHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final schedule = ref.watch(clinicScheduleProvider);
    final controller = ref.read(clinicScheduleProvider.notifier);

    Future<void> save(ClinicSchedule next) async {
      await controller.set(next);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.clinicHoursSaved)));
      }
    }

    Future<void> pickHour({required bool isOpen}) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: isOpen ? schedule.openHour : schedule.closeHour,
          minute: 0,
        ),
      );
      if (picked == null) return;
      unawaited(
        save(
          isOpen
              ? schedule.copyWith(openHour: picked.hour)
              : schedule.copyWith(closeHour: picked.hour),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.clinicHoursTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(t.openDaysLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(_weekdayLabel(context, weekday)),
                  selected: schedule.openDays.contains(weekday),
                  onSelected: (selected) => unawaited(
                    save(
                      schedule.copyWith(
                        openDays: {...schedule.openDays}
                          ..toggle(weekday, selected),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(t.openTimeLabel),
            trailing: Text(
              TimeOfDay(hour: schedule.openHour, minute: 0).format(context),
            ),
            onTap: () => unawaited(pickHour(isOpen: true)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.nights_stay_outlined),
            title: Text(t.closeTimeLabel),
            trailing: Text(
              TimeOfDay(hour: schedule.closeHour, minute: 0).format(context),
            ),
            onTap: () => unawaited(pickHour(isOpen: false)),
          ),
        ],
      ),
    );
  }

  /// Short, locale-aware weekday name (Sun, Mon, ...) for [weekday]
  /// (1=Mon..7=Sun, [DateTime.weekday]'s convention) via a fixed reference
  /// week rather than a hardcoded label list, so Arabic gets a real
  /// translation for free.
  String _weekdayLabel(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toString();
    // 2024-01-01 was a Monday.
    final reference = DateTime(2024, 1, 1 + (weekday - 1));
    return DateFormat('EEE', locale).format(reference);
  }
}

extension on Set<int> {
  void toggle(int value, bool include) {
    if (include) {
      add(value);
    } else {
      remove(value);
    }
  }
}
