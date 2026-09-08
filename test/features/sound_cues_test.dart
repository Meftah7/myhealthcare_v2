// The bundled cue sounds: every enum entry points at a file that is actually
// on disk under assets/, and each staff working status has its own cue.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/audio/app_sounds.dart';
import 'package:myhealthcare/domain/enums.dart';

void main() {
  test('every cue points at a bundled file', () {
    for (final sound in AppSound.values) {
      expect(
        File('assets/${sound.asset}').existsSync(),
        isTrue,
        reason: 'missing asset for ${sound.name}: assets/${sound.asset}',
      );
    }
  });

  test('assets/sounds/ is declared in pubspec', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/sounds/'),
    );
  });

  test('each working status maps to its own cue', () {
    final cues = {
      for (final s in PresenceStatus.values) s: AppSound.forPresence(s),
    };
    expect(cues[PresenceStatus.onDuty], AppSound.presenceOnDuty);
    expect(cues[PresenceStatus.inConsultation], AppSound.presenceInConsultation);
    expect(cues[PresenceStatus.onBreak], AppSound.presenceOnBreak);
    expect(cues[PresenceStatus.offShift], AppSound.presenceOffShift);
    // No two statuses share a sound.
    expect(cues.values.toSet(), hasLength(PresenceStatus.values.length));
  });
}
