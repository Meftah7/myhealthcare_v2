/// Building blocks for every staff role's Home tab, in the patient Home's
/// visual language: the same page frame and inset, one compact greeting
/// header, one primary work card, compact figures and a tools list.
///
/// Purely presentational except for the header (who is signed in) and the
/// tools list (where each tool lives); role screens pass data and callbacks.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import 'staff_navigation.dart';
import 'staff_top_actions.dart';

/// The staff Home page frame — the patient Home's [PatientPageScaffold]
/// (inset, width cap, bottom clearance above the bar) with the compact staff
/// header. Re-tapping Home scrolls back to the top.
class StaffHomeScaffold extends StatefulWidget {
  const StaffHomeScaffold({required this.children, this.onRefresh, super.key});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  State<StaffHomeScaffold> createState() => _StaffHomeScaffoldState();
}

class _StaffHomeScaffoldState extends State<StaffHomeScaffold> {
  final _scroll = ScrollController();
  ValueNotifier<int>? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = ScrollToTopSignal.maybeOf(context);
    if (identical(signal, _signal)) return;
    _signal?.removeListener(_toTop);
    _signal = signal?..addListener(_toTop);
  }

  @override
  void dispose() {
    _signal?.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (!_scroll.hasClients) return;
    if (Motion.reduced(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: Motion.slow, curve: Motion.standard);
    }
  }

  @override
  Widget build(BuildContext context) => PatientPageScaffold(
    controller: _scroll,
    onRefresh: widget.onRefresh,
    header: const StaffHomeHeader(),
    children: widget.children,
  );
}

/// One greeting, then "Role · Department" underneath — two lines in all,
/// beside the account avatar (opens Settings) and the existing notification
/// and theme controls.
class StaffHomeHeader extends ConsumerWidget {
  const StaffHomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final user = ref.watch(currentUserProvider);
    final line = ref.watch(staffRoleLineProvider);
    final name = user?.fullName ?? '';
    final roleLine = line == null
        ? null
        : [
            staffRoleLabel(context, line.role),
            line.department ??
                workText(context, 'Department not assigned', 'القسم غير مسند'),
          ].where((s) => s.isNotEmpty).join(' · ');
    final avatar = Semantics(
      button: true,
      label: workText(context, 'Settings', 'الإعدادات'),
      child: InkWell(
        key: const ValueKey('staff-home-avatar'),
        customBorder: const CircleBorder(),
        onTap: () => context.go(AppRoutes.staffProfile),
        child: SizedBox.square(
          dimension: 48,
          child: CircleAvatar(
            backgroundColor: palette.softAccent,
            foregroundColor: palette.onSoftAccent,
            child: Text(
              initialsOf(name),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadableLabel(
          greeting(name.split(' ').first),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
        if (roleLine != null)
          ReadableLabel(
            roleLine,
            key: const ValueKey('staff-home-role-line'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: LayoutBuilder(
        builder: (context, box) {
          // Large text on a narrow phone: controls on one row, the greeting
          // and role line full width beneath, so no word is squeezed apart.
          final stacked =
              box.maxWidth < MediaQuery.textScalerOf(context).scale(340);
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [avatar, const Spacer(), const StaffTopActions()],
                ),
                const SizedBox(height: Space.xs),
                identity,
              ],
            );
          }
          return Row(
            children: [
              avatar,
              const SizedBox(width: Space.sm),
              Expanded(child: identity),
              const StaffTopActions(),
            ],
          );
        },
      ),
    );
  }
}

/// A status shown as words plus a colour family — never colour alone.
class StaffStatus {
  const StaffStatus(this.label, {this.accent = PatientAccent.blue, this.icon});

  final String label;
  final PatientAccent accent;
  final IconData? icon;

  Widget badge() => StatusBadge(label, accent: accent, icon: icon);
}

/// The one primary work card at the top of Home: what this person does next,
/// and the button that does it.
class StaffWorkCard extends StatelessWidget {
  const StaffWorkCard({
    required this.overline,
    required this.icon,
    this.title,
    this.lines = const [],
    this.status,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
    this.emptyMessage,
    this.highlight = false,
    super.key,
  });

  final String overline;
  final IconData icon;

  /// The patient / item name; null shows [emptyMessage] instead.
  final String? title;
  final List<String> lines;
  final StaffStatus? status;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;
  final String? emptyMessage;

  /// Tints the card for something happening now (an ongoing visit).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: SurfaceCard(
        color: highlight ? palette.softAccent : null,
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(icon: icon, size: 40),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: ReadableLabel(
                    overline,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.link,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (status != null && title != null) ...[
                  const SizedBox(width: Space.xs),
                  Flexible(child: status!.badge()),
                ],
              ],
            ),
            const SizedBox(height: Space.sm),
            if (title == null)
              ReadableLabel(
                emptyMessage ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textMuted,
                ),
              )
            else ...[
              ReadableLabel(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xxs),
                  child: ReadableLabel(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
            ],
            if (primaryLabel != null && title != null) ...[
              const SizedBox(height: Space.md),
              PrimaryActionButton(
                label: primaryLabel!,
                busy: busy,
                onPressed: busy ? null : onPrimary,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Center(
                  child: TextButton(
                    onPressed: onSecondary,
                    child: ReadableLabel(secondaryLabel!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One compact figure: what it counts, the number, and where it leads.
class StaffFigure {
  const StaffFigure({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.onTap,
    this.accent = PatientAccent.blue,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final VoidCallback? onTap;
  final PatientAccent accent;
}

/// Four compact figures: one row on wide windows, two by two on phones, one
/// per row when large text needs the width. Cards grow vertically.
class StaffFigureGrid extends StatelessWidget {
  const StaffFigureGrid(this.items, {super.key});

  final List<StaffFigure> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = (box.maxWidth / (150 * scale)).floor().clamp(
          1,
          items.length,
        );
        final width = (box.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final f in items)
              SizedBox(
                width: width,
                child: SurfaceCard(
                  onTap: f.onTap,
                  semanticLabel: '${f.label}: ${f.value}',
                  padding: const EdgeInsets.all(Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            f.icon,
                            size: 20,
                            color: f.accent.colors(palette).$1,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              f.value,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xxs),
                      ReadableLabel(
                        f.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.text,
                        ),
                      ),
                      if (f.caption != null)
                        ReadableLabel(
                          f.caption!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Two soft actions side by side, stacked when large text needs the width.
class StaffActionPair extends StatelessWidget {
  const StaffActionPair({required this.actions, super.key});

  final List<({String label, IconData icon, VoidCallback onPressed, Key? key})>
  actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.sm),
    child: LayoutBuilder(
      builder: (context, box) {
        final side =
            box.maxWidth / actions.length >=
            MediaQuery.textScalerOf(context).scale(160);
        final buttons = [
          for (final a in actions)
            SoftActionButton(
              key: a.key,
              label: a.label,
              icon: a.icon,
              onPressed: a.onPressed,
            ),
        ];
        if (!side) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, b) in buttons.indexed) ...[
                if (i > 0) const SizedBox(height: Space.xs),
                b,
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final (i, b) in buttons.indexed) ...[
              if (i > 0) const SizedBox(width: Space.xs),
              Expanded(child: b),
            ],
          ],
        );
      },
    ),
  );
}

/// One tool on Home: icon, title, hint, and what opening it does.
class StaffTool {
  const StaffTool(this.icon, this.title, this.hint, this.onTap, {this.key});

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final Key? key;
}

/// The role tools that used to sit behind "My work" and Quick Access, kept
/// one tap from Home. Schedule, Chat and Settings are tabs, so not repeated.
List<StaffTool> staffTools(
  BuildContext context,
  StaffRole? role, {
  List<StaffTool> leading = const [],
}) {
  String t(String en, String ar) => workText(context, en, ar);
  return [
    ...leading,
    StaffTool(
      Icons.assignment_outlined,
      t('My work', 'عملي'),
      t('Tasks assigned to you', 'المهام المسندة إليك'),
      () => unawaited(context.push(AppRoutes.staffTasks)),
      key: const ValueKey('tool-tasks'),
    ),
    StaffTool(
      Icons.swap_horiz,
      t('Shift handover', 'تسليم المناوبة'),
      t('Offer and accept cover', 'عرض التغطية وقبولها'),
      () => unawaited(context.push('${AppRoutes.staffTasks}/handover')),
      key: const ValueKey('tool-handover'),
    ),
    StaffTool(
      Icons.description_outlined,
      t('Documents and records', 'الوثائق والسجلات'),
      t('Document work your role allows', 'أعمال الوثائق المسموحة لدورك'),
      () => unawaited(context.push('/staff/documents')),
      key: const ValueKey('tool-documents'),
    ),
    StaffTool(
      Icons.work_history_outlined,
      t('Cover and time off', 'التغطية والإجازة'),
      t('Availability changes and conflicts', 'تغييرات التوفر والتعارضات'),
      () => unawaited(context.push('${AppRoutes.staffSchedule}/work')),
      key: const ValueKey('tool-cover'),
    ),
    if (role != StaffRole.receptionist)
      StaffTool(
        Icons.calculate_outlined,
        t('Care tools', 'أدوات الرعاية'),
        t('Calculators and lab converters', 'الحاسبات ومحولات المختبر'),
        () => unawaited(context.push('/staff/care-tools')),
        key: const ValueKey('tool-care-tools'),
      ),
    StaffTool(
      Icons.groups_outlined,
      t('Team directory', 'دليل الفريق'),
      t('Find colleagues and message them', 'ابحث عن الزملاء وراسلهم'),
      () => unawaited(context.push(AppRoutes.staffTeamDirectory)),
      key: const ValueKey('tool-team'),
    ),
    StaffTool(
      Icons.help_outline,
      t('Help', 'المساعدة'),
      t('How staff features work', 'كيف تعمل ميزات الموظفين'),
      () => unawaited(context.push('/staff/help')),
      key: const ValueKey('tool-help'),
    ),
  ];
}

/// The tools as one rounded card of patient discovery rows.
class StaffToolsCard extends StatelessWidget {
  const StaffToolsCard(this.tools, {super.key});

  final List<StaffTool> tools;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(workText(context, 'Tools', 'الأدوات')),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, tool) in tools.indexed) ...[
                if (i > 0) Divider(height: 1, color: palette.divider),
                DiscoveryOptionRow(
                  key: tool.key,
                  icon: tool.icon,
                  title: tool.title,
                  hint: tool.hint,
                  onTap: tool.onTap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A list of rows in one rounded card, with an empty message.
class StaffListCard extends StatelessWidget {
  const StaffListCard({
    required this.children,
    this.emptyMessage,
    this.emptyIcon = Icons.check_circle_outline,
    super.key,
  });

  final List<Widget> children;
  final String? emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    if (children.isEmpty) {
      return SurfaceCard(
        child: Row(
          children: [
            Icon(emptyIcon, color: palette.textMuted),
            const SizedBox(width: Space.sm),
            Expanded(
              child: ReadableLabel(
                emptyMessage ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
            ),
          ],
        ),
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, color: palette.divider),
            child,
          ],
        ],
      ),
    );
  }
}

/// One row in a [StaffListCard]: a time / tag box, a name, detail text, an
/// optional status and an optional trailing action. Grows with large text.
class StaffRow extends StatelessWidget {
  const StaffRow({
    required this.title,
    this.leadingText,
    this.leadingIcon,
    this.subtitle,
    this.status,
    this.trailing,
    this.onTap,
    this.muted = false,
    this.emphasis = false,
    super.key,
  });

  final String title;
  final String? leadingText;
  final IconData? leadingIcon;
  final String? subtitle;
  final StaffStatus? status;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Quieter text for finished work (completed visits).
  final bool muted;

  /// A tinted time box for work happening now.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final narrow =
        MediaQuery.sizeOf(context).width <
        MediaQuery.textScalerOf(context).scale(360);
    final lead = leadingText == null && leadingIcon == null
        ? null
        : Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xs,
              vertical: Space.xs,
            ),
            decoration: BoxDecoration(
              color: emphasis ? palette.action : palette.softAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: leadingText != null
                ? Text(
                    leadingText!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: emphasis ? palette.onAction : palette.onSoftAccent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabularFigures,
                    ),
                  )
                : Icon(
                    leadingIcon,
                    color: emphasis ? palette.onAction : palette.onSoftAccent,
                  ),
          );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadableLabel(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: muted ? palette.textMuted : palette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null)
          ReadableLabel(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        if (status != null) ...[
          const SizedBox(height: Space.xxs),
          status!.badge(),
        ],
      ],
    );
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: narrow && trailing != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lead != null) ...[
                      lead,
                      const SizedBox(width: Space.sm),
                    ],
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
              ],
            )
          : Row(
              children: [
                if (lead != null) ...[lead, const SizedBox(width: Space.sm)],
                Expanded(child: text),
                if (trailing != null) ...[
                  const SizedBox(width: Space.xs),
                  trailing!,
                ] else if (onTap != null)
                  Icon(Icons.chevron_right, color: palette.textMuted),
              ],
            ),
    );
    return onTap == null ? body : InkWell(onTap: onTap, child: body);
  }
}

/// Appointment status as words + colour family.
StaffStatus appointmentStatus(BuildContext context, AppointmentStatus s) {
  String t(String en, String ar) => workText(context, en, ar);
  return switch (s) {
    AppointmentStatus.booked => StaffStatus(
      t('Booked', 'محجوز'),
      icon: Icons.event_outlined,
    ),
    AppointmentStatus.confirmed => StaffStatus(
      t('Confirmed', 'مؤكد'),
      icon: Icons.event_available_outlined,
    ),
    AppointmentStatus.checkedIn => StaffStatus(
      t('Arrived', 'وصل'),
      accent: PatientAccent.green,
      icon: Icons.how_to_reg_outlined,
    ),
    AppointmentStatus.inProgress => StaffStatus(
      t('In progress', 'قيد التنفيذ'),
      accent: PatientAccent.amber,
      icon: Icons.play_circle_outline,
    ),
    AppointmentStatus.completed => StaffStatus(
      t('Completed', 'مكتمل'),
      accent: PatientAccent.neutral,
      icon: Icons.check,
    ),
    AppointmentStatus.cancelled => StaffStatus(
      t('Cancelled', 'ملغى'),
      accent: PatientAccent.red,
      icon: Icons.block,
    ),
    AppointmentStatus.noShow => StaffStatus(
      t('No-show', 'لم يحضر'),
      accent: PatientAccent.red,
      icon: Icons.person_off_outlined,
    ),
  };
}
