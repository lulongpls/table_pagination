import 'package:equatable/equatable.dart';
import 'package:table_pagination/src/core/table_sort.dart';

/// Tham số truy vấn được cubit gửi tới hàm fetch (do người dùng lib cung cấp)
/// mỗi khi cần lấy dữ liệu: lần đầu, load more, đổi trang, đổi sort, đổi filter.
class TableQuery extends Equatable {
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool ascending;
  final List<TableSort> sorts;
  final Map<String, dynamic> filters;

  const TableQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.ascending = true,
    this.sorts = const [],
    this.filters = const {},
  });

  TableSort? get sort {
    final effectiveSorts = this.effectiveSorts;
    if (effectiveSorts.isEmpty) return null;

    return effectiveSorts.first;
  }

  List<TableSort> get effectiveSorts {
    if (sorts.isNotEmpty) return sorts;

    final field = sortBy;
    if (field == null || field.isEmpty) return const [];

    return [TableSort.fromAscending(field: field, ascending: ascending)];
  }

  TableQuery copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? ascending,
    List<TableSort>? sorts,
    Map<String, dynamic>? filters,
    bool clearSort = false,
  }) {
    return TableQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      ascending: ascending ?? this.ascending,
      sorts: clearSort ? const [] : (sorts ?? this.sorts),
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [
    page,
    pageSize,
    sortBy,
    ascending,
    sorts,
    filters,
  ];
}
