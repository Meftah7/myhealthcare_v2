/// Short cue sounds, bundled in `assets/sounds/` and declared in pubspec.
///
/// Audio is decoration: every failure path is swallowed, so a device with no
/// output, a platform the plugin isn't registered on (widget tests), or a codec
/// the OS dislikes can never interrupt the action that triggered the cue.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings/ui_prefs.dart';
import '../../domain/enums.dart';

enum AppSound {
  /// A message arrived for the signed-in user.
  notification('sounds/notification.wav'),

  // The four staff working statuses.
  presenceOnDuty('sounds/presence_on_duty.wav'),
  presenceInConsultation('sounds/presence_in_consultation.wav'),
  presenceOnBreak('sounds/presence_on_break.wav'),
  presenceOffShift('sounds/presence_off_shift.wav');

  const AppSound(this.asset);

  /// Path *under* `assets/` — audioplayers' [AssetSource] adds that prefix.
  final String asset;

  /// The cue for a staff member's working status.
  static AppSound forPresence(PresenceStatus status) => switch (status) {
    PresenceStatus.onDuty => presenceOnDuty,
    PresenceStatus.inConsultation => presenceInConsultation,
    PresenceStatus.onBreak => presenceOnBreak,
    PresenceStatus.offShift => presenceOffShift,
  };

  /// The cue for an admin's working status — reuses the four status sounds.
  static AppSound forAdminStatus(AdminStatus status) => switch (status) {
    AdminStatus.available => presenceOnDuty,
    AdminStatus.meeting => presenceInConsultation,
    AdminStatus.away => presenceOnBreak,
    AdminStatus.off => presenceOffShift,
  };
}

/// Plays one short cue at a time. The underlying player is built lazily on the
/// first cue and reused, so an app that never makes a sound never touches the
/// audio plugin at all.
class SoundPlayer {
  SoundPlayer(this._ref);

  final Ref _ref;
  AudioPlayer? _player;

  Future<void> play(AppSound sound) async {
    if (!_ref.read(soundsEnabledProvider)) return;
    try {
      final player = _player ??= AudioPlayer(playerId: 'myhealth-cues');
      await player.setReleaseMode(ReleaseMode.stop);
      // Cues are short and never overlap — a new one replaces the last.
      await player.stop();
      await player.play(AssetSource(sound.asset));
    } catch (_) {
      // Deliberately silent: see the library doc above.
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {
      // Nothing to do — the player is going away regardless.
    }
    _player = null;
  }
}

final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = SoundPlayer(ref);
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});
