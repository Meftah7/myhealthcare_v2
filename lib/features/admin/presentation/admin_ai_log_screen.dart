/// Admin → AI usage log (ported from the FirstSemMyHealth admin "AI Logs"
/// view): every time an AI surface answered, which one, and whether the live
/// model or the offline fallback served it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';

IconData _aiFeatureIcon(AiFeature f) => switch (f) {
  AiFeature.careNavigator => Icons.smart_toy_outlined,
  AiFeature.clinicalScribe => Icons.note_add_outlined,
  AiFeature.patientSummary => Icons.summarize_outlined,
};

class AdminAiLogScreen extends ConsumerStatefulWidget {
  const AdminAiLogScreen({super.key});

  @override
  ConsumerState<AdminAiLogScreen> createState() => _AdminAiLogScreenState();
}

class _AdminAiLogScreenState extends ConsumerState<AdminAiLogScreen> {
  AiFeature? _filter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = ref.watch(aiUsageProvider(_filter));
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.aiActivityTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: FilterChip(
                    label: Text(t.allFilterChip),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final f in AiFeature.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      label: Text(f.label(context)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: entries.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadAiLog,
          onRetry: () => ref.invalidate(aiUsageProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.auto_awesome_outlined,
              message: t.noAiActivityRecordedYet,
            );
          }
          final live = list.where((e) => e.usedLiveModel).length;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.xxl,
                ),
                children: [
                  Text(
                    t.aiCallsSummary(list.length, live, list.length - live),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: Space.md),
                          ListTile(
                            leading: Icon(_aiFeatureIcon(list[i].feature)),
                            title: Text(list[i].feature.label(context)),
                            subtitle: Text(
                              [
                                list[i].usedLiveModel
                                    ? t.liveModelLabel
                                    : t.offlineLabel,
                                if (list[i].summary != null) list[i].summary!,
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              fmtDateTime(list[i].at),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
