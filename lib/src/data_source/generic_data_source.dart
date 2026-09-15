import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:table_pagination/src/models/table_column_config.dart';

typedef TableRowBuilder<T> = DataGridRow Function(T item, int rowIndex);

/// DataGridSource tổng quát: nhận danh sách item T và 1 hàm [rowBuilder] do
/// người dùng lib tự viết để quy định từng cell hiển thị widget gì.
///
/// Vì [DataGridCell.value] có thể chứa trực tiếp 1 Widget, bạn có thể custom
/// cell tuỳ ý: Text, Chip, Icon, Row nhiều nút bấm... mà không cần đụng vào
/// code của package này.
class GenericDataSource<T> extends DataGridSource {
  GenericDataSource({
    required List<T> items,
    required this.columns,
    this.rowBuilder,
    this.defaultCellPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.defaultCellAlignment = Alignment.centerLeft,
  }) {
    updateData(items, notify: false);
  }

  List<TableColumnConfig<T>> columns;
  final TableRowBuilder<T>? rowBuilder;
  final EdgeInsetsGeometry defaultCellPadding;
  final AlignmentGeometry defaultCellAlignment;

  List<T> _items = [];
  List<DataGridRow> _rows = [];

  Map<String, TableColumnConfig<T>> get _columnsByName {
    return {for (final column in columns) column.name: column};
  }

  /// Gọi khi danh sách cột đổi từ widget cha.
  void updateColumns(List<TableColumnConfig<T>> columns) {
    this.columns = columns;
    updateData(_items);
  }

  /// Gọi khi cubit emit danh sách item mới (load more nối thêm, đổi trang,
  /// đổi sort/filter...). Không tự sort/filter lại ở đây — dữ liệu luôn coi
  /// server là nguồn sự thật về thứ tự và nội dung.
  void updateData(List<T> items, {bool notify = true}) {
    _items = items;
    _rows = [
      for (var index = 0; index < _items.length; index++)
        _buildRow(_items[index], index),
    ];

    if (notify) {
      notifyListeners();
    }
  }

  DataGridRow _buildRow(T item, int rowIndex) {
    final customRowBuilder = rowBuilder;
    if (customRowBuilder != null) {
      return customRowBuilder(item, rowIndex);
    }

    return DataGridRow(
      cells: columns.map((column) {
        final customCellBuilder = column.cellBuilder;
        final value = customCellBuilder != null
            ? customCellBuilder(item, rowIndex)
            : column.valueGetter?.call(item);

        return DataGridCell<Object?>(columnName: column.name, value: value);
      }).toList(),
    );
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final columnsByName = _columnsByName;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final column = columnsByName[cell.columnName];
        final value = cell.value;
        final content = value is Widget
            ? value
            : Text(value?.toString() ?? '', overflow: TextOverflow.ellipsis);

        return Container(
          alignment: column?.cellAlignment ?? defaultCellAlignment,
          padding: column?.cellPadding ?? defaultCellPadding,
          child: content,
        );
      }).toList(),
    );
  }
}
