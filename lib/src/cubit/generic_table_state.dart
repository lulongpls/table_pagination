import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:table_pagination/src/core/table_sort.dart';

enum TableStatus {
  /// Chưa fetch lần nào.
  initial,

  /// Đang tải lần đầu / đang tải lại do đổi sort, filter, hoặc đổi trang.
  loading,

  /// Đang tải thêm (chỉ dùng ở mode loadMore, không che mất list hiện có).
  loadingMore,

  /// Tải thành công.
  success,

  /// Tải lỗi.
  failure,
}

class GenericTableState<T> extends Equatable {
  final TableStatus status;
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool ascending;
  final List<TableSort> sorts;
  final Map<String, dynamic> filters;
  final bool hasReachedMax;
  final bool hasLoadedOnce;
  final String? errorMessage;

  const GenericTableState({
    required this.status,
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.sortBy,
    required this.ascending,
    required this.sorts,
    required this.filters,
    required this.hasReachedMax,
    required this.hasLoadedOnce,
    this.errorMessage,
  });

  factory GenericTableState.initial({required int pageSize}) {
    return GenericTableState<T>(
      status: TableStatus.initial,
      items: const [],
      totalCount: 0,
      page: 1,
      pageSize: pageSize,
      sortBy: null,
      ascending: true,
      sorts: const [],
      filters: const {},
      hasReachedMax: false,
      hasLoadedOnce: false,
      errorMessage: null,
    );
  }

  /// Tổng số trang, tối thiểu 1 (dùng cho mode pagination).
  int get totalPages {
    if (totalCount == 0) return 1;
    return math.max(1, (totalCount / pageSize).ceil());
  }

  bool get isFirstLoad => status == TableStatus.loading && !hasLoadedOnce;
  bool get isEmpty => status == TableStatus.success && items.isEmpty;
  bool get isLoading => status == TableStatus.loading;
  bool get isLoadingMore => status == TableStatus.loadingMore;
  bool get isFailure => status == TableStatus.failure;
  bool get canShowRows => items.isNotEmpty;
  bool get canLoadMore => !hasReachedMax && !isLoading && !isLoadingMore;
  TableSort? sortFor(String field) {
    for (final sort in sorts) {
      if (sort.field == field) return sort;
    }

    if (sortBy == field) {
      return TableSort.fromAscending(field: field, ascending: ascending);
    }

    return null;
  }

  int sortPriority(String field) {
    final index = sorts.indexWhere((sort) => sort.field == field);
    return index == -1 ? 0 : index + 1;
  }

  GenericTableState<T> copyWith({
    TableStatus? status,
    List<T>? items,
    int? totalCount,
    int? page,
    int? pageSize,
    String? sortBy,
    bool? ascending,
    List<TableSort>? sorts,
    Map<String, dynamic>? filters,
    bool? hasReachedMax,
    bool? hasLoadedOnce,
    String? errorMessage,
    bool clearSortBy = false,
  }) {
    return GenericTableState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      ascending: ascending ?? this.ascending,
      sorts: clearSortBy ? const [] : (sorts ?? this.sorts),
      filters: filters ?? this.filters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    totalCount,
    page,
    pageSize,
    sortBy,
    ascending,
    sorts,
    filters,
    hasReachedMax,
    hasLoadedOnce,
    errorMessage,
  ];
}
