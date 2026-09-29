/// Shared widgets for paged lists and live queues (Phase 2): a "Load more"
/// footer so long lists never stop silently at a cap, and a freshness line
/// so a queue shows how current it is and can be refreshed on demand.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../utils/format.dart';

class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({required this.onLoadMore, super.key});

  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more),
          label: Text(AppLocalizations.of(context)!.loadMore),
        ),
      ),
    );
  }
}

/// [FreshnessBar] for any async queue: remembers when [value] last finished
/// loading successfully. Refresh reloads the data only — selection, filters
/// and scroll position stay where they are.
class QueueFreshness extends StatefulWidget {
  const QueueFreshness({
    required this.value,
    required this.onRefresh,
    super.key,
  });

  final AsyncValue<Object?> value;
  final VoidCallback onRefresh;

  @override
  State<QueueFreshness> createState() => _QueueFreshnessState();
}

class _QueueFreshnessState extends State<QueueFreshness> {
  DateTime? _fetchedAt;

  void _capture() {
    final v = widget.value;
    if (v.hasValue && !v.isLoading && !v.hasError) _fetchedAt = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _capture();
  }

  @override
  void didUpdateWidget(QueueFreshness old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _capture();
  }

  @override
  Widget build(BuildContext context) =>
      FreshnessBar(fetchedAt: _fetchedAt, onRefresh: widget.onRefresh);
}

/// "Updated 10:42" plus a refresh button. Refreshing keeps whatever the
/// user had selected — only the data reloads.
class FreshnessBar extends StatelessWidget {
  const FreshnessBar({
    required this.fetchedAt,
    required this.onRefresh,
    super.key,
  });

  final DateTime? fetchedAt;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final at = fetchedAt;
    return Row(
      children: [
        Expanded(
          child: Text(
            at == null ? '' : t.updatedAgo(fmtTime(at)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(
            context,
          ).refreshIndicatorSemanticLabel,
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
