import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:table_pagination/src/core/table_mode.dart';
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
    this.pageSize = 20,
    this.initialFilters = const {},
    this.initialSortBy,
    this.initialAscending = true,
    this.autoFetchOnCreate = true,
    this.rowBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.loadMoreIndicatorBuilder,
    this.columnWidthMode = ColumnWidthMode.fill,
    this.gridLinesVisibility = GridLinesVisibility.horizontal,
    this.headerGridLinesVisibility = GridLinesVisibility.horizontal,
    this.rowHeight = double.nan,
    this.headerRowHeight = double.nan,
    this.defaultColumnWidth = double.nan,
    this.selectionMode = SelectionMode.none,
    this.controller,
    this.onCellTap,
    this.onCellDoubleTap,
    this.shrinkWrapRows = false,
    this.shrinkWrapColumns = false,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.loadMoreThreshold = 160,
  }) : cubit = null;

  const GenericTable.withCubit({
    super.key,
    required this.cubit,
    required this.columns,
    this.rowBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.loadMoreIndicatorBuilder,
    this.columnWidthMode = ColumnWidthMode.fill,
    this.gridLinesVisibility = GridLinesVisibility.horizontal,
    this.headerGridLinesVisibility = GridLinesVisibility.horizontal,
    this.rowHeight = double.nan,
    this.headerRowHeight = double.nan,
    this.defaultColumnWidth = double.nan,
    this.selectionMode = SelectionMode.none,
    this.controller,
    this.onCellTap,
    this.onCellDoubleTap,
    this.shrinkWrapRows = false,
    this.shrinkWrapColumns = false,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.loadMoreThreshold = 160,
  }) : fetcher = null,
       mode = TableMode.pagination,
       pageSize = 20,
       initialFilters = const {},
       initialSortBy = null,
       initialAscending = true,
       autoFetchOnCreate = true;

  final TableFetcher<T>? fetcher;
  final GenericTableCubit<T>? cubit;
  final List<TableColumnConfig<T>> columns;
  final TableMode mode;
  final int pageSize;
  final Map<String, dynamic> initialFilters;
  final String? initialSortBy;
  final bool initialAscending;
  final bool autoFetchOnCreate;
  final TableRowBuilder<T>? rowBuilder;
  final TableStateWidgetBuilder<T>? loadingBuilder;
  final TableStateWidgetBuilder<T>? emptyBuilder;
  final TableStateWidgetBuilder<T>? errorBuilder;
  final TableFooterBuilder<T>? footerBuilder;
  final TableStateWidgetBuilder<T>? loadMoreIndicatorBuilder;
  final ColumnWidthMode columnWidthMode;
  final GridLinesVisibility gridLinesVisibility;
  final GridLinesVisibility headerGridLinesVisibility;
  final double rowHeight;
  final double headerRowHeight;
  final double defaultColumnWidth;
  final SelectionMode selectionMode;
  final DataGridController? controller;
  final DataGridCellTapCallback? onCellTap;
  final DataGridCellDoubleTapCallback? onCellDoubleTap;
  final bool shrinkWrapRows;
  final bool shrinkWrapColumns;
  final bool showHorizontalScrollbar;
  final bool showVerticalScrollbar;
  final double loadMoreThreshold;

  @override
  State<GenericTable<T>> createState() => _GenericTableState<T>();
}

class _GenericTableState<T> extends State<GenericTable<T>> {
  late GenericTableCubit<T> _cubit;
  late GenericDataSource<T> _dataSource;
  late bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _createCubit();
    _dataSource = GenericDataSource<T>(
      items: _cubit.state.items,
      columns: widget.columns,
      rowBuilder: widget.rowBuilder,
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
            oldWidget.pageSize != widget.pageSize ||
            oldWidget.initialSortBy != widget.initialSortBy ||
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
        rowBuilder: widget.rowBuilder,
      );
      return;
    }

    if (oldWidget.columns != widget.columns) {
      _dataSource.updateColumns(widget.columns);
    } else if (oldWidget.rowBuilder != widget.rowBuilder) {
      _dataSource = GenericDataSource<T>(
        items: _cubit.state.items,
        columns: widget.columns,
        rowBuilder: widget.rowBuilder,
      );
    }
  }

  @override
  void dispose() {
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
      pageSize: widget.pageSize,
      initialFilters: widget.initialFilters,
      initialSortBy: widget.initialSortBy,
      initialAscending: widget.initialAscending,
      autoFetchOnCreate: widget.autoFetchOnCreate,
    );
    _ownsCubit = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenericTableCubit<T>, GenericTableState<T>>(
      bloc: _cubit,
      listenWhen: (previous, current) => previous.items != current.items,
      listener: (context, state) => _dataSource.updateData(state.items),
      builder: (context, state) {
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

        if (state.isEmpty) {
          return widget.emptyBuilder?.call(context, state) ??
              const _DefaultEmptyState();
        }

        final table = NotificationListener<ScrollNotification>(
          onNotification: (notification) => _handleScroll(notification, state),
          child: SfDataGrid(
            source: _dataSource,
            columns: [
              for (final column in widget.columns)
                column.toGridColumn(
                  context: context,
                  state: state,
                  onSort: _cubit.sort,
                ),
            ],
            columnWidthMode: widget.columnWidthMode,
            gridLinesVisibility: widget.gridLinesVisibility,
            headerGridLinesVisibility: widget.headerGridLinesVisibility,
            rowHeight: widget.rowHeight,
            headerRowHeight: widget.headerRowHeight,
            defaultColumnWidth: widget.defaultColumnWidth,
            selectionMode: widget.selectionMode,
            controller: widget.controller,
            onCellTap: widget.onCellTap,
            onCellDoubleTap: widget.onCellDoubleTap,
            shrinkWrapRows: widget.shrinkWrapRows,
            shrinkWrapColumns: widget.shrinkWrapColumns,
            showHorizontalScrollbar: widget.showHorizontalScrollbar,
            showVerticalScrollbar: widget.showVerticalScrollbar,
          ),
        );

        final children = <Widget>[
          if (widget.shrinkWrapRows) table else Expanded(child: table),
          _buildFooter(context, state),
        ];

        return Column(children: children);
      },
    );
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
