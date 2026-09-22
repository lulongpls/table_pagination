import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_table/flutter_advanced_table.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_pagination/src/core/table_mode.dart';
import 'package:table_pagination/src/core/table_sort.dart';
import 'package:table_pagination/src/cubit/generic_table_cubit.dart';
import 'package:table_pagination/src/cubit/generic_table_state.dart';
import 'package:table_pagination/src/data_source/generic_data_source.dart';
import 'package:table_pagination/src/models/table_column_config.dart';
import 'package:table_pagination/src/widgets/pagination_footer.dart';

typedef TableStateWidgetBuilder<T> =
    Widget Function(BuildContext context, GenericTableState<T> state);

typedef TableFooterBuilder<T> =
    Widget Function(
      BuildContext context,
      GenericTableState<T> state,
      GenericTableCubit<T> cubit,
    );

class GenericTable<T> extends StatefulWidget {
  const GenericTable({
    super.key,
    required this.fetcher,
    required this.columns,
    this.mode = TableMode.pagination,
    this.sortMode = TableSortMode.online,
    this.pageSize = 20,
    this.initialFilters = const {},
    this.initialSortBy,
    this.initialSorts = const [],
    this.initialAscending = true,
    this.autoFetchOnCreate = true,
    this.rowBuilder,
    this.rowDecorationBuilder,
    this.onRowTap,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.loadMoreIndicatorBuilder,
    this.headerDecoration,
    this.rowDecoration,
    this.elementsPadding,
    this.innerHeaderPadding,
    this.innerRowElementsPadding,
    this.outterHeaderPadding,
    this.outterRowsPadding,
    this.headerTextStyle,
    this.addSpacerToActions = true,
    this.rowHeight = double.nan,
    this.headerRowHeight = double.nan,
    this.defaultColumnWidth = double.nan,
    this.shrinkWrapRows = false,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.loadMoreThreshold = 160,
    this.stickyFooter = false,
  }) : cubit = null;

  const GenericTable.withCubit({
    super.key,
    required this.cubit,
    required this.columns,
    this.rowBuilder,
    this.rowDecorationBuilder,
    this.onRowTap,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.loadMoreIndicatorBuilder,
    this.headerDecoration,
    this.rowDecoration,
    this.elementsPadding,
    this.innerHeaderPadding,
    this.innerRowElementsPadding,
    this.outterHeaderPadding,
    this.outterRowsPadding,
    this.headerTextStyle,
    this.addSpacerToActions = true,
    this.rowHeight = double.nan,
    this.headerRowHeight = double.nan,
    this.defaultColumnWidth = double.nan,
    this.shrinkWrapRows = false,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.loadMoreThreshold = 160,
    this.stickyFooter = false,
  }) : fetcher = null,
       mode = TableMode.pagination,
       sortMode = TableSortMode.online,
       pageSize = 20,
       initialFilters = const {},
       initialSortBy = null,
       initialSorts = const [],
       initialAscending = true,
       autoFetchOnCreate = true;

  final TableFetcher<T>? fetcher;
  final GenericTableCubit<T>? cubit;
  final List<TableColumnConfig<T>> columns;
  final TableMode mode;
  final TableSortMode sortMode;
  final int pageSize;
  final Map<String, dynamic> initialFilters;
  final String? initialSortBy;
  final List<TableSort> initialSorts;
  final bool initialAscending;
  final bool autoFetchOnCreate;
  final TableRowBuilder<T>? rowBuilder;
  final TableRowDecorationBuilder<T>? rowDecorationBuilder;
  final TableRowTap<T>? onRowTap;
  final TableStateWidgetBuilder<T>? loadingBuilder;
  final TableStateWidgetBuilder<T>? emptyBuilder;
  final TableStateWidgetBuilder<T>? errorBuilder;
  final TableFooterBuilder<T>? footerBuilder;
  final TableStateWidgetBuilder<T>? loadMoreIndicatorBuilder;
  final BoxDecoration? headerDecoration;
  final BoxDecoration? rowDecoration;
  final EdgeInsets? elementsPadding;
  final EdgeInsets? innerHeaderPadding;
  final EdgeInsets? innerRowElementsPadding;
  final EdgeInsets? outterHeaderPadding;
  final EdgeInsets? outterRowsPadding;
  final TextStyle? headerTextStyle;
  final bool addSpacerToActions;
  final double rowHeight;
  final double headerRowHeight;
  final double defaultColumnWidth;
  final bool shrinkWrapRows;
  final bool showHorizontalScrollbar;
  final bool showVerticalScrollbar;
  final double loadMoreThreshold;

  /// When enabled, the footer follows short lists but stays pinned below the
  /// scrollable table when the rows exceed the available height.
  final bool stickyFooter;

  @override
  State<GenericTable<T>> createState() => _GenericTableState<T>();
}

class _GenericTableState<T> extends State<GenericTable<T>> {
  late GenericTableCubit<T> _cubit;
  late GenericDataSource<T> _dataSource;
  late bool _ownsCubit;
  late final ValueNotifier<bool> _isLoadingAll;
  late final ValueNotifier<bool> _isLoadingMore;

  @override
  void initState() {
    super.initState();
    _isLoadingAll = ValueNotifier(false);
    _isLoadingMore = ValueNotifier(false);
    _createCubit();
    _dataSource = GenericDataSource<T>(
      items: _cubit.state.items,
      columns: widget.columns,
    );
  }

  @override
  void didUpdateWidget(covariant GenericTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final cubitChanged = oldWidget.cubit != widget.cubit;
    final ownedCubitConfigChanged =
        _ownsCubit &&
        (oldWidget.fetcher != widget.fetcher ||
            oldWidget.mode != widget.mode ||
            oldWidget.sortMode != widget.sortMode ||
            oldWidget.pageSize != widget.pageSize ||
            oldWidget.initialSortBy != widget.initialSortBy ||
            !listEquals(oldWidget.initialSorts, widget.initialSorts) ||
            oldWidget.initialAscending != widget.initialAscending ||
            !mapEquals(oldWidget.initialFilters, widget.initialFilters));

    if (cubitChanged || ownedCubitConfigChanged) {
      if (_ownsCubit) {
        unawaited(_cubit.close());
      }
      _createCubit();
      _dataSource = GenericDataSource<T>(
        items: _cubit.state.items,
        columns: widget.columns,
      );
      _syncLoadingNotifiers(_cubit.state);
      return;
    }

    if (oldWidget.columns != widget.columns) {
      _dataSource.updateColumns(widget.columns);
    }
  }

  @override
  void dispose() {
    _isLoadingAll.dispose();
    _isLoadingMore.dispose();
    if (_ownsCubit) {
      unawaited(_cubit.close());
    }
    super.dispose();
  }

  void _createCubit() {
    final providedCubit = widget.cubit;
    if (providedCubit != null) {
      _cubit = providedCubit;
      _ownsCubit = false;
      return;
    }

    final fetcher = widget.fetcher;
    if (fetcher == null) {
      throw StateError('GenericTable requires either a fetcher or a cubit.');
    }

    _cubit = GenericTableCubit<T>(
      fetcher: fetcher,
      mode: widget.mode,
      sortMode: widget.sortMode,
      pageSize: widget.pageSize,
      initialFilters: widget.initialFilters,
      initialSortBy: widget.initialSortBy,
      initialSorts: widget.initialSorts,
      initialAscending: widget.initialAscending,
      autoFetchOnCreate: widget.autoFetchOnCreate,
    );
    _ownsCubit = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenericTableCubit<T>, GenericTableState<T>>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.items != current.items || previous.status != current.status,
      listener: (context, state) {
        _dataSource.updateData(state.items);
        _syncLoadingNotifiers(state);
      },
      builder: (context, state) {
        _syncLoadingNotifiers(state);

        if (state.isFirstLoad) {
          return widget.loadingBuilder?.call(context, state) ??
              const Center(child: CircularProgressIndicator());
        }

        if (state.isFailure && !state.canShowRows) {
          return widget.errorBuilder?.call(context, state) ??
              _DefaultErrorState(
                message: state.errorMessage,
                onRetry: _cubit.reload,
              );
        }

        final table = NotificationListener<ScrollNotification>(
          onNotification: (notification) => _handleScroll(notification, state),
          child: AdvancedTableWidget(
            items: state.items,
            headerItems: widget.columns,
            isLoadingAll: _isLoadingAll,

            fullLoadingPlaceHolder:
                widget.loadingBuilder?.call(context, state) ??
                const Center(child: CircularProgressIndicator()),
            onEmptyState: _buildEmptyState(context, state),
            headerDecoration: widget.headerDecoration,
            rowDecorationBuilder: _hasCustomRowDecoration
                ? (index, isHovered) =>
                      _buildRowDecoration(context, state, index, isHovered)
                : null,
            elementsPadding: widget.elementsPadding,
            innerHeaderPadding: widget.innerHeaderPadding,
            innerRowElementsPadding: widget.innerRowElementsPadding,
            outterHeaderPadding: widget.outterHeaderPadding,
            outterRowsPadding: widget.outterRowsPadding,
            headerTextStyle: widget.headerTextStyle,
            addSpacerToActions: widget.addSpacerToActions,
            onRowTap: widget.onRowTap == null
                ? null
                : (index) => widget.onRowTap!(state.items[index], index),
            headerBuilder: (context, header) {
              return _dataSource.buildHeader(
                context: context,
                columnIndex: header.index,
                state: state,
                onSort: _sortColumn,
                defaultWidth: _resolveDefaultWidth(header.defualtWidth),
                height: widget.headerRowHeight,
              );
            },
            rowElementsBuilder: (context, rowParams) {
              return _dataSource.buildRowCells(
                rowIndex: rowParams.index,
                defaultWidth: _resolveDefaultWidth(rowParams.defualtWidth),
                height: widget.rowHeight,
              );
            },
            rowBuilder: (context, index, row, isHovered) {
              return _buildRow(context, state, index, row, isHovered);
            },
          ),
        );

        final tableBody = widget.shrinkWrapRows
            ? SizedBox(height: _shrinkWrapHeight(state), child: table)
            : widget.stickyFooter
            ? Flexible(
                key: const ValueKey('generic-table-sticky-footer-body'),
                fit: FlexFit.loose,
                child: SizedBox(height: _shrinkWrapHeight(state), child: table),
              )
            : Expanded(child: table);

        return Column(children: [tableBody, _buildFooter(context, state)]);
      },
    );
  }

  bool get _hasCustomRowDecoration {
    return widget.rowDecorationBuilder != null || widget.rowDecoration != null;
  }

  Widget _buildEmptyState(BuildContext context, GenericTableState<T> state) {
    if (state.isLoading) {
      return widget.loadingBuilder?.call(context, state) ??
          const Center(child: CircularProgressIndicator());
    }

    return widget.emptyBuilder?.call(context, state) ??
        const _DefaultEmptyState();
  }

  void _sortColumn(String field) {
    unawaited(
      _cubit.sort(field, localComparatorBuilder: _buildLocalSortComparator),
    );
  }

  Comparator<T>? _buildLocalSortComparator(List<TableSort> sorts) {
    final sortableColumns = [
      for (final sort in sorts) _columnForSortField(sort.field),
    ];

    if (sortableColumns.every((column) => column == null)) {
      return null;
    }

    return (left, right) {
      for (var i = 0; i < sorts.length; i++) {
        final column = sortableColumns[i];
        if (column == null) continue;

        final result = _compareSortValues(
          column.localSortValue(left),
          column.localSortValue(right),
        );
        if (result != 0) {
          return sorts[i].ascending ? result : -result;
        }
      }

      return 0;
    };
  }

  TableColumnConfig<T>? _columnForSortField(String field) {
    for (final column in widget.columns) {
      if (column.effectiveSortField == field || column.name == field) {
        return column;
      }
    }

    return null;
  }

  int _compareSortValues(Object? left, Object? right) {
    if (identical(left, right)) return 0;
    if (left == null) return -1;
    if (right == null) return 1;

    if (left is Comparable && right is Comparable) {
      try {
        return left.compareTo(right);
      } catch (_) {
        // Fall through to string comparison when Comparable types differ.
      }
    }

    return left.toString().compareTo(right.toString());
  }

  void _syncLoadingNotifiers(GenericTableState<T> state) {
    final isLoadingAll = state.isFirstLoad;
    if (_isLoadingAll.value != isLoadingAll) {
      _isLoadingAll.value = isLoadingAll;
    }

    final isLoadingMore = state.isLoadingMore;
    if (_isLoadingMore.value != isLoadingMore) {
      _isLoadingMore.value = isLoadingMore;
    }
  }

  bool _handleScroll(
    ScrollNotification notification,
    GenericTableState<T> state,
  ) {
    if (_cubit.mode != TableMode.loadMore) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.extentAfter > widget.loadMoreThreshold) {
      return false;
    }

    unawaited(_cubit.loadMore());
    return false;
  }

  Widget _buildRow(
    BuildContext context,
    GenericTableState<T> state,
    int index,
    Widget row,
    bool isHovered,
  ) {
    if (_cubit.mode == TableMode.loadMore &&
        index >= state.items.length - 2 &&
        state.canLoadMore) {
      unawaited(_cubit.loadMore());
    }

    final sizedRow = widget.rowHeight.isNaN
        ? row
        : SizedBox(height: widget.rowHeight, child: row);
    final customBuilder = widget.rowBuilder;
    if (customBuilder == null) return sizedRow;

    return customBuilder(
      context,
      state.items[index],
      index,
      sizedRow,
      isHovered,
    );
  }

  BoxDecoration _buildRowDecoration(
    BuildContext context,
    GenericTableState<T> state,
    int index,
    bool isHovered,
  ) {
    final decoration =
        widget.rowDecorationBuilder?.call(
          context,
          state.items[index],
          index,
          isHovered,
        ) ??
        widget.rowDecoration ??
        const BoxDecoration();

    if (decoration.borderRadius != null) return decoration;

    return decoration.copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    );
  }

  double _resolveDefaultWidth(double packageDefaultWidth) {
    return widget.defaultColumnWidth.isNaN
        ? packageDefaultWidth
        : widget.defaultColumnWidth;
  }

  double _shrinkWrapHeight(GenericTableState<T> state) {
    final headerHeight = widget.headerRowHeight.isNaN
        ? 56.0
        : widget.headerRowHeight;
    final rowHeight = widget.rowHeight.isNaN ? 72.0 : widget.rowHeight;
    return headerHeight + (state.items.length * rowHeight) + 72;
  }

  Widget _buildFooter(BuildContext context, GenericTableState<T> state) {
    final customFooter = widget.footerBuilder;
    if (customFooter != null) {
      return customFooter(context, state, _cubit);
    }

    if (_cubit.mode == TableMode.pagination) {
      return PaginationFooter(
        page: state.page,
        totalPages: state.totalPages,
        totalCount: state.totalCount,
        pageSize: state.pageSize,
        isLoading: state.isLoading,
        onPageChanged: _cubit.goToPage,
      );
    }

    if (state.isLoadingMore) {
      return widget.loadMoreIndicatorBuilder?.call(context, state) ??
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (state.isFailure && state.canShowRows) {
      return _InlineLoadMoreError(
        message: state.errorMessage,
        onRetry: _cubit.loadMore,
      );
    }

    return const SizedBox.shrink();
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No data', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DefaultErrorState extends StatelessWidget {
  const _DefaultErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(message ?? 'Unable to load data', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineLoadMoreError extends StatelessWidget {
  const _InlineLoadMoreError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              message ?? 'Unable to load more rows',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
