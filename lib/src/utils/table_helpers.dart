import 'package:flutter/material.dart';
import 'package:table_pagination/src/models/table_column_config.dart';

typedef CellTextFormatter = String Function(Object? value);

TableColumnConfig<T> buildSortableColumn<T>({
  required String field,
  required String label,
  required TableCellValueGetter<T> valueGetter,
  String? sortField,
  double width = double.nan,
  double minimumWidth = double.nan,
  double maximumWidth = double.nan,
  bool sortable = true,
  AlignmentGeometry headerAlignment = Alignment.centerLeft,
  AlignmentGeometry cellAlignment = Alignment.centerLeft,
  EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(horizontal: 8),
  EdgeInsetsGeometry cellPadding = const EdgeInsets.symmetric(horizontal: 8),
}) {
  return textColumn<T>(
    name: field,
    label: label,
    valueGetter: valueGetter,
    sortField: sortField,
    sortable: sortable,
    width: width,
    minimumWidth: minimumWidth,
    maximumWidth: maximumWidth,
    headerAlignment: headerAlignment,
    cellAlignment: cellAlignment,
    headerPadding: headerPadding,
    cellPadding: cellPadding,
  );
}

TableColumnConfig<T> textColumn<T>({
  required String name,
  required String label,
  required TableCellValueGetter<T> valueGetter,
  String? sortField,
  bool sortable = false,
  double width = double.nan,
  double minimumWidth = double.nan,
  double maximumWidth = double.nan,
  AlignmentGeometry headerAlignment = Alignment.centerLeft,
  AlignmentGeometry cellAlignment = Alignment.centerLeft,
  EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(horizontal: 8),
  EdgeInsetsGeometry cellPadding = const EdgeInsets.symmetric(horizontal: 8),
  TextStyle? style,
  TextOverflow overflow = TextOverflow.ellipsis,
  int? maxLines = 1,
  CellTextFormatter? formatter,
}) {
  return TableColumnConfig<T>(
    name: name,
    label: label,
    valueGetter: valueGetter,
    sortField: sortField,
    sortable: sortable,
    width: width,
    minimumWidth: minimumWidth,
    maximumWidth: maximumWidth,
    headerAlignment: headerAlignment,
    cellAlignment: cellAlignment,
    headerPadding: headerPadding,
    cellPadding: cellPadding,
    cellBuilder: (item, _) {
      final value = valueGetter(item);
      return Text(
        formatter?.call(value) ?? value?.toString() ?? '',
        overflow: overflow,
        maxLines: maxLines,
        style: style,
      );
    },
  );
}

TableColumnConfig<T> widgetColumn<T>({
  required String name,
  required String label,
  required TableCellBuilder<T> cellBuilder,
  String? sortField,
  bool sortable = false,
  double width = double.nan,
  double minimumWidth = double.nan,
  double maximumWidth = double.nan,
  AlignmentGeometry headerAlignment = Alignment.centerLeft,
  AlignmentGeometry cellAlignment = Alignment.centerLeft,
  EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(horizontal: 8),
  EdgeInsetsGeometry cellPadding = const EdgeInsets.symmetric(horizontal: 8),
  TableColumnHeaderBuilder<T>? headerBuilder,
}) {
  return TableColumnConfig<T>(
    name: name,
    label: label,
    cellBuilder: cellBuilder,
    sortField: sortField,
    sortable: sortable,
    width: width,
    minimumWidth: minimumWidth,
    maximumWidth: maximumWidth,
    headerAlignment: headerAlignment,
    cellAlignment: cellAlignment,
    headerPadding: headerPadding,
    cellPadding: cellPadding,
    headerBuilder: headerBuilder,
  );
}

EdgeInsetsGeometry columnPadding({double horizontal = 8, double vertical = 0}) {
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
