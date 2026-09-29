/// A shared "pick a valid, open slot" bottom sheet — used wherever a caller
/// used to accept a free-form date/time (patient reschedule, admin's
/// book-for-patient), which could produce an off-grid time the repository
/// now rejects. Only ever returns a slot the repository has already
/// confirmed sits on the clinician's real schedule grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Shows the sheet and returns the chosen slot, or null if the person backed
/// out without picking one.
Future<OpenSlot?> pickOpenSlot(
  BuildContext context, {
  required String staffId,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<OpenSlot>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SlotPickerSheet(staffId: staffId, initialDate: initialDate),
    ),
  );
}

class _SlotPickerSheet extends ConsumerStatefulWidget {
  const _SlotPickerSheet({required this.staffId, this.initialDate});

  final String staffId;
  final DateTime? initialDate;

  @override
  ConsumerState<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends ConsumerState<_SlotPickerSheet> {
  late DateTime _date;
  Future<List<OpenSlot>>? _future;

  @override
  void initState() {
    super.initState();
    final schedule = ref.read(clinicScheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = widget.initialDate ?? today;
    _date = isClinicDay(base, schedule) && !base.isBefore(today)
        ? base
        : nextClinicDay(today, schedule);
    _load();
  }

  void _load() {
    _future = ref
        .read(appointmentRepositoryProvider)
        .openSlots(widget.staffId, _date)
        // A failed read is an error, never "no open slots that day".
        .then(
          (r) => switch (r) {
            Ok(:final value) => value,
            Err(:final failure) => throw failure,
          },
        );
  }

  Future<void> _pickDate() async {
    final t = AppLocalizations.of(context)!;
    final schedule = ref.read(clinicScheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: (d) => isClinicDay(d, schedule),
      helpText: t.clinicDaysHelp,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final df = MaterialLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.chooseATimeTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(df.formatMediumDate(_date)),
            ),
            const SizedBox(height: Space.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: FutureBuilder<List<OpenSlot>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return ErrorStateView(
                        message: snap.error is Failure
                            ? (snap.error! as Failure).message
                            : UnexpectedFailure.from(snap.error!).message,
                        onRetry: () => setState(_load),
                      );
                    }
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: Space.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final slots = snap.data!;
                    if (slots.isEmpty) {
                      return EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: t.noOpenSlotsThatDay,
                      );
                    }
                    return Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        for (final slot in slots)
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, slot),
                            child: Text(fmtTime(slot.start)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
