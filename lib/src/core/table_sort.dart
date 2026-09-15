import 'package:equatable/equatable.dart';

/// Sort direction sent to the server through [TableQuery].
enum TableSortDirection {
  ascending,
  descending;

  bool get isAscending => this == TableSortDirection.ascending;

  TableSortDirection get reversed => isAscending
      ? TableSortDirection.descending
      : TableSortDirection.ascending;
}

/// Server-side sort descriptor for a single table column.
class TableSort extends Equatable {
  const TableSort({
    required this.field,
    this.direction = TableSortDirection.ascending,
  });

  factory TableSort.fromAscending({
    required String field,
    required bool ascending,
  }) {
    return TableSort(
      field: field,
      direction: ascending
          ? TableSortDirection.ascending
          : TableSortDirection.descending,
    );
  }

  final String field;
  final TableSortDirection direction;

  bool get ascending => direction.isAscending;

  TableSort toggled() {
    return copyWith(direction: direction.reversed);
  }

  TableSort copyWith({String? field, TableSortDirection? direction}) {
    return TableSort(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  @override
  List<Object?> get props => [field, direction];
}
