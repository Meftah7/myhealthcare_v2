/// Semantic colour tokens for the patient experience (approved blue rebuild).
///
/// The patient app uses a brighter action blue than the staff/admin
/// workspaces, so its tokens live in a [ThemeExtension] rather than replacing
/// the shared [AppColors] palette. Read them with `PatientPalette.of(context)`.
///
/// Red is semantic only (emergencies, errors) — never brand decoration.
library;

import 'package:flutter/material.dart';

@immutable
class PatientPalette extends ThemeExtension<PatientPalette> {
  const PatientPalette({
    required this.action,
    required this.onAction,
    required this.softAccent,
    required this.onSoftAccent,
    required this.canvas,
    required this.card,
    required this.text,
    required this.textMuted,
    required this.divider,
    required this.link,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.danger,
    required this.dangerContainer,
  });

  /// Filled primary actions (CTAs, selected segments, the appointment tile).
  /// The same #246BFD in both modes — white labels stay readable on it.
  final Color action;
  final Color onAction;

  /// Pale-blue surface for secondary actions, selected chips and icon tiles.
  final Color softAccent;
  final Color onSoftAccent;

  final Color canvas;
  final Color card;
  final Color text;
  final Color textMuted;
  final Color divider;

  /// Small links and icons on the card/canvas. In dark mode this is a lighter
  /// blue, because #246BFD on navy does not meet text contrast.
  final Color link;

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color danger;
  final Color dangerContainer;

  static const light = PatientPalette(
    action: Color(0xFF246BFD),
    onAction: Color(0xFFFFFFFF),
    softAccent: Color(0xFFE9F0FF),
    onSoftAccent: Color(0xFF1F5FE0),
    canvas: Color(0xFFF7F7F8),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF2D333C),
    // #727A83 from the preview, nudged darker to reach 4.5:1 on white.
    textMuted: Color(0xFF5F6770),
    divider: Color(0xFFEBEDF0),
    // #246BFD is 4.27:1 on the canvas; small text links use a deeper blue.
    link: Color(0xFF1F5FE0),
    success: Color(0xFF0E8F65),
    successContainer: Color(0xFFE6F7F0),
    warning: Color(0xFFB26A00),
    warningContainer: Color(0xFFFFF3DD),
    info: Color(0xFF1F5FE0),
    infoContainer: Color(0xFFE9F0FF),
    danger: Color(0xFFD12E3B),
    dangerContainer: Color(0xFFFDE8EA),
  );

  static const dark = PatientPalette(
    action: Color(0xFF246BFD),
    onAction: Color(0xFFFFFFFF),
    softAccent: Color(0xFF213858),
    onSoftAccent: Color(0xFFBFD3FF),
    canvas: Color(0xFF111B28),
    card: Color(0xFF1C2839),
    text: Color(0xFFEEF3F9),
    textMuted: Color(0xFFA4B1C2),
    divider: Color(0xFF2C394A),
    link: Color(0xFF9ABEFF),
    success: Color(0xFF4FD1A5),
    successContainer: Color(0xFF163C36),
    warning: Color(0xFFF5C26B),
    warningContainer: Color(0xFF3F3220),
    info: Color(0xFF9ABEFF),
    infoContainer: Color(0xFF213858),
    danger: Color(0xFFFF8A8F),
    dangerContainer: Color(0xFF4A1C22),
  );

  /// The brand fill for shared widgets (hero cards, the logo tile, the ticket
  /// card): the patient action blue under a patient theme, else [fallback].
  static Color brandOf(BuildContext context, Color fallback) =>
      Theme.of(context).extension<PatientPalette>()?.action ?? fallback;

  /// The tokens for the ambient theme, falling back by brightness so a patient
  /// widget never crashes when rendered under another role's theme.
  static PatientPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PatientPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  PatientPalette copyWith({
    Color? action,
    Color? onAction,
    Color? softAccent,
    Color? onSoftAccent,
    Color? canvas,
    Color? card,
    Color? text,
    Color? textMuted,
    Color? divider,
    Color? link,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? danger,
    Color? dangerContainer,
  }) => PatientPalette(
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    softAccent: softAccent ?? this.softAccent,
    onSoftAccent: onSoftAccent ?? this.onSoftAccent,
    canvas: canvas ?? this.canvas,
    card: card ?? this.card,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    divider: divider ?? this.divider,
    link: link ?? this.link,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    danger: danger ?? this.danger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
  );

  @override
  PatientPalette lerp(ThemeExtension<PatientPalette>? other, double t) {
    if (other is! PatientPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PatientPalette(
      action: l(action, other.action),
      onAction: l(onAction, other.onAction),
      softAccent: l(softAccent, other.softAccent),
      onSoftAccent: l(onSoftAccent, other.onSoftAccent),
      canvas: l(canvas, other.canvas),
      card: l(card, other.card),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      divider: l(divider, other.divider),
      link: l(link, other.link),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
    );
  }
}
