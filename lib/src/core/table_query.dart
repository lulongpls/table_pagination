import 'package:equatable/equatable.dart';
import 'package:table_pagination/src/core/table_sort.dart';

/// Tham số truy vấn được cubit gửi tới hàm fetch (do người dùng lib cung cấp)
/// mỗi khi cần lấy dữ liệu: lần đầu, load more, đổi trang, đổi sort, đổi filter.
class TableQuery extends Equatable {
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool ascending;
  final Map<String, dynamic> filters;

  const TableQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.ascending = true,
    this.filters = const {},
  });

  TableSort? get sort {
    final field = sortBy;
    if (field == null || field.isEmpty) return null;

    return TableSort.fromAscending(field: field, ascending: ascending);
  }

  TableQuery copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? ascending,
    Map<String, dynamic>? filters,
    bool clearSort = false,
  }) {
    return TableQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      ascending: ascending ?? this.ascending,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, sortBy, ascending, filters];
}
