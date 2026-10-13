/// Admin dashboard (Phase 6) — built around ownership and correction, not
/// totals: date overline + greeting, one hero that says how much is waiting
/// on the administrator (or that the queues could not be checked), the
/// "Needs attention" list of exception queues, Quick actions, and recent
/// activity. System totals and appointment analytics live one tap away
/// (Analytics) instead of competing for the first screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/data_state_view.dart';
import '../../../core/presentation/profile_navigation.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/ui/patient/workspace_home.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../application/admin_providers.dart';
import '../application/attention_providers.dart';
import 'admin_quick_actions.dart';
import 'admin_top_actions.dart';
import 'admin_workspace_screens.dart';
import 'attention_list.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? t.greetingFallbackName)
        .split(' ')
        .first;

    return AppScaffold(
      stagger: true,
      hero: true,
      heroOverline: fmtDate(DateTime.now()),
      title: greeting(firstName),
      actions: const [AdminTopActions()],
      onRefresh: () async {
        refreshAdminAttention(ref);
        ref.invalidate(adminWorkProvider);
        ref.invalidate(auditLogProvider);
      },
      // Same structure as patient Home: feature card, shortcuts,
      // workspace cards, Quick Access directly below, then the attention
      // and activity panels.
      children: [
        const AdminWorkspaceOverview(),
        const SizedBox(height: Space.md),
        // Shortcuts lead to places not already in the navigation bar.
        ShortcutGrid(
          items: [
            ShortcutItem(
              icon: Icons.inbox_outlined,
              label: t.workQueueTitle,
              onTap: () => context.push(AppRoutes.adminWorkQueue),
            ),
            ShortcutItem(
              icon: Icons.call_split_outlined,
              label: t.referralRequestsTitle,
              onTap: () => context.push(AppRoutes.adminReferralRequests),
            ),
            ShortcutItem(
              icon: Icons.home_work_outlined,
              label: t.homeVisitsTitle,
              onTap: () => context.push(AppRoutes.adminHomeVisits),
            ),
            ShortcutItem(
              icon: Icons.reviews_outlined,
              label: t.feedbackTitle,
              onTap: () => context.push(AppRoutes.adminFeedback),
            ),
          ],
        ),
        SectionHeader(
          adminText(context, 'Workspace', 'مساحة العمل'),
          overline: true,
        ),
        WorkspaceCardGrid(
          items: [
            WorkspaceItem(
              icon: Icons.badge_outlined,
              title: adminText(
                context,
                'People & access',
                'الأشخاص والصلاحيات',
              ),
              description: adminText(
                context,
                'Accounts, five staff roles, credentials and status.',
                'الحسابات والأدوار الخمسة والاعتمادات والحالة.',
              ),
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            WorkspaceItem(
              icon: Icons.local_hospital_outlined,
              title: adminText(context, 'Clinic', 'العيادة'),
              description: adminText(
                context,
                'Departments, clinic hours and schedules.',
                'الأقسام وساعات العيادة والجداول.',
              ),
              onTap: () => context.go(AppRoutes.adminDepartments),
            ),
            WorkspaceItem(
              icon: Icons.description_outlined,
              title: adminText(context, 'Documents', 'المستندات'),
              description: adminText(
                context,
                'Templates, policies and the verification registry.',
                'القوالب والسياسات وسجل التحقق.',
              ),
              onTap: () => context.push(AppRoutes.adminDocumentPolicies),
            ),
            WorkspaceItem(
              icon: Icons.account_balance_wallet_outlined,
              title: adminText(context, 'Finance', 'المالية'),
              description: adminText(
                context,
                'Invoices, desk payments, refunds and reconciliation.',
                'الفواتير ومدفوعات الاستقبال والاسترداد والمطابقة.',
              ),
              onTap: () => context.go(AppRoutes.adminBilling),
            ),
            WorkspaceItem(
              icon: Icons.call_split_outlined,
              title: adminText(
                context,
                'Referrals & home visits',
                'الإحالات والزيارات المنزلية',
              ),
              description: adminText(
                context,
                'Decide requests. External transport is not connected.',
                'البت في الطلبات. النقل الخارجي غير متصل.',
              ),
              onTap: () => context.push(AppRoutes.adminReferralRequests),
            ),
            WorkspaceItem(
              icon: Icons.insights_outlined,
              title: adminText(context, 'Reports', 'التقارير'),
              description: adminText(
                context,
                'Historical activity, demand and audit.',
                'النشاط السابق والطلب وسجل التدقيق.',
              ),
              onTap: () => context.push(AppRoutes.adminProfileAnalytics),
            ),
          ],
        ),
        SectionHeader(t.quickActionsHeader, overline: true),
        const AdminQuickActions(),
        SectionColumns(
          primary: [
            SectionHeader(
              t.needsAttentionHeader,
              overline: true,
              action: t.workQueueTitle,
              onAction: () => context.push(AppRoutes.adminWorkQueue),
            ),
            const AdminAttentionList(),
          ],
          secondary: [
            SectionHeader(
              t.recentActivityHeader,
              overline: true,
              action: t.auditLogTitle,
              onAction: () => context.push(AppRoutes.adminProfileAudit),
            ),
            const _ActivityCard(),
            const SizedBox(height: Space.sm),
            ProfileNavigationGroup(
              items: [
                ProfileNavigationItem(
                  icon: Icons.query_stats_outlined,
                  label: t.capacityForecastTitle,
                  onTap: () => context.push(AppRoutes.adminProfileForecast),
                ),
                ProfileNavigationItem(
                  icon: Icons.history_toggle_off_outlined,
                  label: t.aiActivityTitle,
                  onTap: () => context.push(AppRoutes.adminProfileAiLog),
                ),
                ProfileNavigationItem(
                  icon: Icons.fact_check_outlined,
                  label: t.auditLogTitle,
                  onTap: () => context.push(AppRoutes.adminProfileAudit),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AsyncDataView(
      value: ref.watch(auditLogProvider),
      onRetry: () => ref.invalidate(auditLogProvider),
      loading: const LoadingSkeleton(height: 90),
      isEmpty: (list) => list.isEmpty,
      empty: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Text(t.noAuditEntriesYet),
      ),
      builder: (context, list) {
        final rows = list.take(6).toList();
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: Space.md),
                ListTile(
                  dense: true,
                  title: ReadableLabel(
                    readableAuditAction(context, rows[i].action),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReadableLabel(
                        [rows[i].entityType, ?rows[i].entityId].join(' · '),
                      ),
                      ReadableLabel(
                        fmtDateTime(rows[i].at),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
