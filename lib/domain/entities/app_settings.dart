/// Runtime app settings (single row in the DB) (P1-10/P1-11).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    required bool aiEnabled,
    required bool mockMode,
    required String modelId,
    required double aiTaskWeight,
    required int seedVersion,
    required DateTime updatedAt,
  }) = _AppSettings;

  const AppSettings._();

  /// True when the real API should be called (AI on, not forced to mock).
  bool get usesRealAi => aiEnabled && !mockMode;
}
