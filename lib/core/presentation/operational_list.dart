/// Shared searchable and filterable work list (Phase 6).
///
/// Search, filters and selection live in this stateful widget, so refreshing
/// or paging the backing data does not make the operator lose their place.
/// Wide windows use a table; compact windows use accessible cards.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'paging_widgets.dart';

@immutable
class OperationalFilter<T> {
  const OperationalFilter({
    required this.label,
    required this.options,
    required this.matches,
  });

  final String label;
  final Map<String, String> options;
  final bool Function(T item, String value) matches;
}

@immutable
class OperationalColumn<T> {
  const OperationalColumn({required this.label, required this.value});

  final String label;
  final String Function(T item) value;
}

class OperationalList<T> extends StatefulWidget {
  const OperationalList({
    required this.items,
    required this.itemId,
    required this.searchText,
    required this.columns,
    required this.searchHint,
    required this.allLabel,
    required this.empty,
    this.filters = const [],
    this.selectedId,
    this.onSelected,
    this.trailing,
    this.fetchedAt,
    this.onRefresh,
    this.hasMore = false,
    this.onLoadMore,
    super.key,
  });

  final List<T> items;
  final String Function(T item) itemId;
  final String Function(T item) searchText;
  final List<OperationalColumn<T>> columns;
  final List<OperationalFilter<T>> filters;
  final String searchHint;
  final String allLabel;
  final Widget empty;
  final String? selectedId;
  final ValueChanged<T>? onSelected;
  final Widget Function(BuildContext context, T item)? trailing;
  final DateTime? fetchedAt;
  final VoidCallback? onRefresh;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  @override
  State<OperationalList<T>> createState() => _OperationalListState<T>();
}

class _OperationalListState<T> extends State<OperationalList<T>> {
  String _query = '';
  late List<String?> _filterValues;
  late DateTime _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    _filterValues = List<String?>.filled(widget.filters.length, null);
    _lastLoadedAt = DateTime.now();
  }

  @override
  void didUpdateWidget(OperationalList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.length != widget.filters.length) {
      _filterValues = List<String?>.filled(widget.filters.length, null);
    }
    if (!identical(oldWidget.items, widget.items)) {
      _lastLoadedAt = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible = widget.items
        .where((item) {
          if (query.isNotEmpty &&
              !widget.searchText(item).toLowerCase().contains(query)) {
            return false;
          }
          for (var i = 0; i < widget.filters.length; i++) {
            final value = _filterValues[i];
            if (value != null && !widget.filters[i].matches(item, value)) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            SizedBox(
              width: 320,
              child: SearchBar(
                hintText: widget.searchHint,
                leading: const Icon(Icons.search),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            for (var i = 0; i < widget.filters.length; i++)
              _FilterMenu(
                filter: widget.filters[i],
                value: _filterValues[i],
                allLabel: widget.allLabel,
                onChanged: (value) => setState(() => _filterValues[i] = value),
              ),
          ],
        ),
        if (widget.onRefresh != null) ...[
          const SizedBox(height: Space.xxs),
          FreshnessBar(
            fetchedAt: widget.fetchedAt ?? _lastLoadedAt,
            onRefresh: widget.onRefresh!,
          ),
        ],
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.lg),
            child: widget.empty,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 720
                ? _WideList<T>(widget: widget, items: visible)
                : _CompactList<T>(widget: widget, items: visible),
          ),
        if (widget.hasMore && widget.onLoadMore != null)
          LoadMoreFooter(onLoadMore: widget.onLoadMore!),
      ],
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.filter,
    required this.value,
    required this.allLabel,
    required this.onChanged,
  });

  final OperationalFilter<T> filter;
  final String? value;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownMenu<String>(
    label: Text(filter.label),
    initialSelection: value ?? '',
    onSelected: (selected) =>
        onChanged(selected == null || selected.isEmpty ? null : selected),
    dropdownMenuEntries: [
      DropdownMenuEntry(value: '', label: allLabel),
      for (final option in filter.options.entries)
        DropdownMenuEntry(value: option.key, label: option.value),
    ],
  );
}

class _WideList<T> extends StatelessWidget {
  const _WideList({required this.widget, required this.items});
  final OperationalList<T> widget;
  final List<T> items;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      showCheckboxColumn: false,
      columns: [
        for (final column in widget.columns)
          DataColumn(label: Text(column.label)),
        if (widget.trailing != null) const DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final item in items)
          DataRow(
            selected: widget.itemId(item) == widget.selectedId,
            onSelectChanged: widget.onSelected == null
                ? null
                : (_) => widget.onSelected!(item),
            cells: [
              for (final column in widget.columns)
                DataCell(Text(column.value(item))),
              if (widget.trailing != null)
                DataCell(widget.trailing!(context, item)),
            ],
          ),
      ],
    ),
  );
}

class _CompactList<T> extends StatelessWidget {
  const _CompactList({required this.widget, required this.items});
  final OperationalList<T> widget;
  final List<T> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        Card(
          color: widget.itemId(item) == widget.selectedId
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          child: InkWell(
            onTap: widget.onSelected == null
                ? null
                : () => widget.onSelected!(item),
            child: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < widget.columns.length; i++) ...[
                          if (i > 0) const SizedBox(height: Space.xxs),
                          Text(
                            widget.columns[i].value(item),
                            style: i == 0
                                ? Theme.of(context).textTheme.titleSmall
                                : Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!(context, item),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
