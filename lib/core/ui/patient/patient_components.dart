/// Shared building blocks for the rebuilt patient experience (approved blue
/// design): rounded white cards on a soft-grey canvas, pale-blue icon tiles,
/// a full-width blue primary action and honest state views.
///
/// These widgets are purely visual — they never read repositories or
/// providers; feature controllers pass data and callbacks in.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../presentation/readable_label.dart';

/// Patient page inset (≈22 logical px on phones).
const double kPatientInset = 22;

/// Rounded patient card radius.
const BorderRadius kPatientCardRadius = BorderRadius.all(Radius.circular(22));

/// Rounded white surface with a hairline border — the patient "card".
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.md),
    this.onTap,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: color ?? palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: kPatientCardRadius,
          side: BorderSide(color: palette.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// A section title with an optional trailing action ("View All").
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    this.actionLabel,
    this.onAction,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: ReadableLabel(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xxs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ],
    );
    final action = actionLabel != null && onAction != null
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: palette.link),
            child: Text(actionLabel!),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
      child: action == null
          ? heading
          // Side by side when the title fits on its own line; otherwise the
          // action drops below so the title never breaks mid-word.
          : LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                  maxLines: 1,
                )..layout();
                final actionPainter = TextPainter(
                  text: TextSpan(
                    text: actionLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                )..layout();
                final fits =
                    painter.width + actionPainter.width + 28 <=
                    constraints.maxWidth;
                painter.dispose();
                actionPainter.dispose();
                if (fits) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: heading),
                      action,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, action],
                );
              },
            ),
    );
  }
}

/// Full-width filled #246BFD action.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    final child = busy
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: palette.onAction,
            ),
          )
        : ReadableLabel(label, textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: icon == null || busy
          ? FilledButton(onPressed: busy ? null : onPressed, child: child)
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
  }
}

/// Full-width pale-blue secondary action.
class SoftActionButton extends StatelessWidget {
  const SoftActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: palette.softAccent,
      foregroundColor: palette.onSoftAccent,
    );
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
          : FilledButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon),
              label: ReadableLabel(label, textAlign: TextAlign.center),
            ),
    );
  }
}

/// Semantic accent families used for icon tiles and status badges. Each is
/// always paired with an icon or label — colour is never the only signal.
enum PatientAccent { blue, green, amber, red, neutral }

extension PatientAccentColors on PatientAccent {
  (Color fg, Color bg) colors(PatientPalette p) => switch (this) {
    PatientAccent.blue => (p.onSoftAccent, p.softAccent),
    PatientAccent.green => (p.success, p.successContainer),
    PatientAccent.amber => (p.warning, p.warningContainer),
    PatientAccent.red => (p.danger, p.dangerContainer),
    PatientAccent.neutral => (p.textMuted, p.divider),
  };
}

/// A rounded soft-colour square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    this.accent = PatientAccent.blue,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final PatientAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = accent.colors(PatientPalette.of(context));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// A small text badge ("Not available", "Sign in").
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    this.accent = PatientAccent.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final PatientAccent accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = accent.colors(PatientPalette.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            // Wraps rather than truncating: a scope label must stay legible.
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a discovery list: soft icon tile, title, blue hint, chevron.
class DiscoveryOptionRow extends StatelessWidget {
  const DiscoveryOptionRow({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.accent = PatientAccent.blue,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback? onTap;
  final PatientAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          child: Row(
            children: [
              IconTile(icon: icon, accent: accent, size: 46),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReadableLabel(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ReadableLabel(
                      hint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.link,
                      ),
                    ),
                  ],
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
      ),
    );
  }
}

/// The kinds of non-content state a patient page can be in.
enum PatientStateKind { loading, empty, error, unavailable, stale }

/// One honest presentation for loading / empty / error / unavailable / stale
/// states, so optional services never pretend to be operational.
class PatientStateView extends StatelessWidget {
  const PatientStateView({
    required this.kind,
    this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final PatientStateKind kind;
  final String? title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (kind == PatientStateKind.loading) {
      return const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final accent = switch (kind) {
      PatientStateKind.error => PatientAccent.red,
      PatientStateKind.stale => PatientAccent.amber,
      PatientStateKind.unavailable => PatientAccent.neutral,
      _ => PatientAccent.blue,
    };
    final defaultIcon = switch (kind) {
      PatientStateKind.error => Icons.error_outline,
      PatientStateKind.stale => Icons.history_toggle_off,
      PatientStateKind.unavailable => Icons.cloud_off_outlined,
      _ => Icons.inbox_outlined,
    };
    return SurfaceCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          IconTile(icon: icon ?? defaultIcon, accent: accent, size: 56),
          if (title != null) ...[
            const SizedBox(height: Space.md),
            ReadableLabel(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: Space.xs),
            ReadableLabel(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.md),
            SoftActionButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Large patient page title (≈28 logical px).
class PatientPageTitle extends StatelessWidget {
  const PatientPageTitle(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: ReadableLabel(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xxs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// A scrollable patient page with the ≈22px inset, width cap and a bottom
/// spacer that clears the navigation bar / safe area.
class PatientPageScaffold extends StatelessWidget {
  const PatientPageScaffold({
    required this.children,
    this.header,
    this.onRefresh,
    this.appBar,
    this.controller,
    super.key,
  });

  final Widget? header;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final PreferredSizeWidget? appBar;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget list = ListView(
      controller: controller,
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        kPatientInset,
        appBar == null ? Space.xs : Space.md,
        kPatientInset,
        Space.xxl + bottom,
      ),
      children: [?header, ...children],
    );
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        bottom: false,
        top: appBar == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: list,
          ),
        ),
      ),
    );
  }
}

/// Two-option segment (e.g. General / Virtual Care). Side by side when both
/// labels fit; stacked when large text or a narrow screen would split words.
class BookingModeSegment<T> extends StatelessWidget {
  const BookingModeSegment({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// (value, label, icon) per option.
  final List<(T, String, IconData)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    Widget option((T, String, IconData) o) {
      final (value, label, icon) = o;
      final on = value == selected;
      return Semantics(
        selected: on,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: on ? palette.action : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: Space.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: on ? palette.onAction : palette.textMuted,
                    ),
                    const SizedBox(width: Space.xs),
                    Flexible(
                      child: ReadableLabel(
                        label,
                        style: style?.copyWith(
                          color: on ? palette.onAction : palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        var widest = 0.0;
        for (final (_, label, _) in options) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textScaler: scaler,
            textDirection: Directionality.of(context),
          )..layout();
          if (painter.width > widest) widest = painter.width;
          painter.dispose();
        }
        // Icon + gap + horizontal padding per option, plus the frame.
        final perOption = widest + 20 + Space.xs + Space.sm * 2 + 2;
        final fits = perOption * options.length + 8 <= constraints.maxWidth;
        final children = [for (final o in options) option(o)];
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.divider),
          ),
          child: fits
              ? Row(children: [for (final c in children) Expanded(child: c)])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        );
      },
    );
  }
}

/// The visible "Future work" scope label for anything outside the proposal:
/// existing supplementary features (still fully working) and planned
/// extensions alike. Readable text, not just colour or a tooltip.
class FutureWorkBadge extends StatelessWidget {
  const FutureWorkBadge({required this.label, this.compact = false, super.key});

  /// The localized "Future work" text.
  final String label;

  /// Drops the icon for narrow tiles so the words themselves always fit.
  final bool compact;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label,
    accent: PatientAccent.amber,
    icon: compact ? null : Icons.schedule_outlined,
  );
}

/// The visible scope label on a navigation entry (bar, menu, rail).
class NavScopeBadge extends StatelessWidget {
  const NavScopeBadge(this.label, {super.key});

  final String label;

  /// The badge's text style — also used to measure whether the bar fits.
  static TextStyle? styleOf(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall
      ?.copyWith(fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: palette.warningContainer,
        borderRadius: Radii.pill,
        border: Border.all(color: palette.warning.withValues(alpha: .35)),
      ),
      // Wraps (never clips) when the slot is narrow.
      child: Text(
        label,
        maxLines: 2,
        softWrap: true,
        textAlign: TextAlign.center,
        style: styleOf(context)?.copyWith(color: palette.warning),
      ),
    );
  }
}
