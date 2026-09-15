import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:table_pagination/src/cubit/generic_table_state.dart';
import 'package:table_pagination/src/widgets/sortable_header.dart';

typedef TableCellValueGetter<T> = Object? Function(T item);
typedef TableCellBuilder<T> = Widget Function(T item, int rowIndex);
typedef TableColumnHeaderBuilder<T> =
    Widget Function(
      BuildContext context,
      GenericTableState<T> state,
      ValueChanged<String> onSort,
    );

/// Declarative config for one [SfDataGrid] column.
///
/// Use [valueGetter] for plain text/value cells, or [cellBuilder] when the
/// column needs a fully custom widget such as a chip, badge, avatar, or action
/// buttons. [cellPadding] and [headerPadding] are per-column, so you can add
/// different padding to two specific columns without changing the whole table.
class TableColumnConfig<T> {
  const TableColumnConfig({
    required this.name,
    required this.label,
    this.valueGetter,
    this.cellBuilder,
    this.headerBuilder,
    this.sortField,
    this.sortable = false,
    this.width = double.nan,
    this.minimumWidth = double.nan,
    this.maximumWidth = double.nan,
    this.columnWidthMode = ColumnWidthMode.none,
    this.autoFitPadding = const EdgeInsets.all(16),
    this.headerAlignment = Alignment.centerLeft,
    this.cellAlignment = Alignment.centerLeft,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 8),
  });

  /// Column identifier used by Syncfusion and by row cells.
  final String name;

  /// Default visible header text.
  final String label;

  /// Field sent to the fetcher when this column is sorted.
  ///
  /// Defaults to [name].
  final String? sortField;

  /// Whether tapping the header should request server-side sorting.
  final bool sortable;

  /// Plain value builder for the cell.
  final TableCellValueGetter<T>? valueGetter;

  /// Full custom widget builder for the cell.
  final TableCellBuilder<T>? cellBuilder;

  /// Full custom header builder. When omitted, [SortableHeader] is used.
  final TableColumnHeaderBuilder<T>? headerBuilder;

  final double width;
  final double minimumWidth;
  final double maximumWidth;
  final ColumnWidthMode columnWidthMode;
  final EdgeInsets autoFitPadding;
  final AlignmentGeometry headerAlignment;
  final AlignmentGeometry cellAlignment;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry cellPadding;

  String get effectiveSortField => sortField ?? name;

  GridColumn toGridColumn({
    required BuildContext context,
    required GenericTableState<T> state,
    required ValueChanged<String> onSort,
  }) {
    return GridColumn(
      columnName: name,
      width: width,
      minimumWidth: minimumWidth,
      maximumWidth: maximumWidth,
      columnWidthMode: columnWidthMode,
      autoFitPadding: autoFitPadding,
      allowSorting: false,
      label: Container(
        alignment: headerAlignment,
        padding: headerPadding,
        child:
            headerBuilder?.call(context, state, onSort) ??
            SortableHeader(
              label: label,
              field: effectiveSortField,
              currentSortField: state.sortBy,
              ascending: state.ascending,
              sortable: sortable,
              onTap: () => onSort(effectiveSortField),
            ),
      ),
    );
  }
}
