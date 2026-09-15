import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:table_pagination/src/cubit/generic_table_state.dart';
import 'package:table_pagination/src/models/table_column_config.dart';
import 'package:table_pagination/src/widgets/sortable_header.dart';

typedef CellTextFormatter = String Function(Object? value);

/// Hàm tiện ích: tạo nhanh 1 [GridColumn] có header bấm-để-sort, thay vì
/// phải tự viết SortableHeader mỗi lần. Dùng trong `columnsBuilder`:
///
/// ```dart
/// columnsBuilder: (state, onSort) => [
///   buildSortableColumn(field: 'name', label: 'Tên', state: state, onSort: onSort),
///   buildSortableColumn(field: 'email', label: 'Email', state: state, onSort: onSort, sortable: false),
/// ],
/// ```
GridColumn buildSortableColumn<T>({
  required String field,
  required String label,
  required GenericTableState<T> state,
  required void Function(String field) onSort,
  double width = double.nan,
  double minimumWidth = double.nan,
  double maximumWidth = double.nan,
  ColumnWidthMode columnWidthMode = ColumnWidthMode.none,
  bool sortable = true,
  Alignment headerAlignment = Alignment.centerLeft,
  EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(horizontal: 8),
}) {
  return GridColumn(
    columnName: field,
    width: width,
    minimumWidth: minimumWidth,
    maximumWidth: maximumWidth,
    columnWidthMode: columnWidthMode,
    allowSorting: false,
    label: Container(
      padding: headerPadding,
      alignment: headerAlignment,
      child: SortableHeader(
        label: label,
        field: field,
        currentSortField: state.sortBy,
        ascending: state.ascending,
        sortable: sortable,
        onTap: () => onSort(field),
      ),
    ),
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

DataGridCell<Object?> dataCell({
  required String columnName,
  required Object? value,
}) {
  return DataGridCell<Object?>(columnName: columnName, value: value);
}

EdgeInsetsGeometry columnPadding({double horizontal = 8, double vertical = 0}) {
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
