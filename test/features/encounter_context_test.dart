// The open encounter's stage is explicit (draft / awaiting signature / save
// failed / signed) and its context never survives a change of account.
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/consultation/application/consultation_providers.dart';
import 'package:myhealthcare/features/consultation/presentation/encounter_context.dart';

import '../support/sessions.dart';

void main() {
  test('stages', () {
    EncounterStage s(AppointmentStatus a, DraftSaveState d, bool sign) =>
        encounterStage(status: a, save: d, canSign: sign);
    expect(
      s(AppointmentStatus.completed, DraftSaveState.idle, true),
      EncounterStage.signed,
    );
    expect(
      s(AppointmentStatus.booked, DraftSaveState.idle, true),
      EncounterStage.notStarted,
    );
    expect(
      s(AppointmentStatus.inProgress, DraftSaveState.saved, true),
      EncounterStage.draft,
    );
    // A nurse's saved draft waits for a doctor's signature.
    expect(
      s(AppointmentStatus.inProgress, DraftSaveState.saved, false),
      EncounterStage.awaitingSignature,
    );
    for (final failed in [DraftSaveState.failed, DraftSaveState.conflict]) {
      expect(
        s(AppointmentStatus.inProgress, failed, false),
        EncounterStage.saveFailed,
      );
    }
  });

  test('the open encounter is cleared when the account changes', () async {
    final (c, _) = await seededContainer();
    await signInAs(c, 'staff1@myhealth.demo');
    c.read(activeEncounterProvider.notifier).state = 'appt-1';
    expect(c.read(activeEncounterProvider), 'appt-1');
    await signInAs(c, 'staff2@myhealth.demo');
    expect(c.read(activeEncounterProvider), isNull);
  });
}
