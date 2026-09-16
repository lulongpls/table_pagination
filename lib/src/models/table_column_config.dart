import 'dart:math' as math;

import 'package:flutter/material.dart';
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

typedef TableRowBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      int rowIndex,
      Widget row,
      bool isHovered,
    );

typedef TableRowDecorationBuilder<T> =
    BoxDecoration? Function(
      BuildContext context,
      T item,
      int rowIndex,
      bool isHovered,
    );

typedef TableRowTap<T> = void Function(T item, int rowIndex);

/// Declarative config for one table column.
///
/// Use [valueGetter] for plain value cells, or [cellBuilder] when the column
/// needs a fully custom widget such as an avatar row, chip, switch, or action
/// buttons. [cellPadding] and [headerPadding] are per-column, so a screen can
/// tune the spacing of only the first two columns without affecting the rest.
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
    this.headerAlignment = Alignment.centerLeft,
    this.cellAlignment = Alignment.centerLeft,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 8),
  });

  /// Column identifier used by row cells and sort/filter code.
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
  final AlignmentGeometry headerAlignment;
  final AlignmentGeometry cellAlignment;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry cellPadding;

  String get effectiveSortField => sortField ?? name;

  Widget buildHeader({
    required BuildContext context,
    required GenericTableState<T> state,
    required ValueChanged<String> onSort,
    required double defaultWidth,
    double height = double.nan,
  }) {
    return SizedBox(
      width: resolveWidth(defaultWidth),
      height: height.isNaN ? null : height,
      child: Container(
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

  Widget buildCell({
    required T item,
    required int rowIndex,
    required double defaultWidth,
    double height = double.nan,
  }) {
    final value = cellBuilder?.call(item, rowIndex) ?? valueGetter?.call(item);
    final content = value is Widget
        ? value
        : Text(value?.toString() ?? '', overflow: TextOverflow.ellipsis);

    return SizedBox(
      width: resolveWidth(defaultWidth),
      height: height.isNaN ? null : height,
      child: Container(
        alignment: cellAlignment,
        padding: cellPadding,
        child: content,
      ),
    );
  }

  double resolveWidth(double defaultWidth) {
    var resolved = width.isNaN ? defaultWidth : width;

    if (!minimumWidth.isNaN) {
      resolved = math.max(minimumWidth, resolved);
    }

    if (!maximumWidth.isNaN) {
      resolved = math.min(maximumWidth, resolved);
    }

    return resolved;
  }
}
