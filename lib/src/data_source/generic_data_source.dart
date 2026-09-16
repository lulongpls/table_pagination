import 'package:flutter/material.dart';
import 'package:table_pagination/src/cubit/generic_table_state.dart';
import 'package:table_pagination/src/models/table_column_config.dart';

/// Lightweight adapter that turns [items] and [columns] into header/cell widgets
/// for the current table renderer.
class GenericDataSource<T> {
  GenericDataSource({required this.items, required this.columns});

  List<TableColumnConfig<T>> columns;

  List<T> items;

  void updateColumns(List<TableColumnConfig<T>> columns) {
    this.columns = columns;
  }

  void updateData(List<T> items) {
    this.items = items;
  }

  Widget buildHeader({
    required BuildContext context,
    required int columnIndex,
    required GenericTableState<T> state,
    required ValueChanged<String> onSort,
    required double defaultWidth,
    double height = double.nan,
  }) {
    return columns[columnIndex].buildHeader(
      context: context,
      state: state,
      onSort: onSort,
      defaultWidth: defaultWidth,
      height: height,
    );
  }

  List<Widget> buildRowCells({
    required int rowIndex,
    required double defaultWidth,
    double height = double.nan,
  }) {
    final item = items[rowIndex];

    return [
      for (final column in columns)
        column.buildCell(
          item: item,
          rowIndex: rowIndex,
          defaultWidth: defaultWidth,
          height: height,
        ),
    ];
  }
}
