import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_pagination/src/core/page_result.dart';
import 'package:table_pagination/src/core/table_mode.dart';
import 'package:table_pagination/src/core/table_query.dart';
import 'package:table_pagination/src/core/table_sort.dart';
import 'package:table_pagination/src/cubit/generic_table_state.dart';

/// Hàm do người dùng lib cung cấp để lấy dữ liệu thật (gọi API, query DB...).
/// Cubit sẽ gọi hàm này mỗi khi cần: load lần đầu, load more, đổi trang,
/// đổi cột sort, đổi filter.
typedef TableFetcher<T> = Future<PagedResult<T>> Function(TableQuery query);
typedef TableLocalSortComparatorBuilder<T> =
    Comparator<T>? Function(List<TableSort> sorts);

class GenericTableCubit<T> extends Cubit<GenericTableState<T>> {
  GenericTableCubit({
    required this.fetcher,
    this.mode = TableMode.pagination,
    this.sortMode = TableSortMode.online,
    int pageSize = 20,
    Map<String, dynamic> initialFilters = const {},
    String? initialSortBy,
    List<TableSort> initialSorts = const [],
    bool initialAscending = true,
    bool autoFetchOnCreate = true,
  }) : super(
         GenericTableState<T>.initial(pageSize: pageSize).copyWith(
           filters: initialFilters,
           sortBy: initialSortBy,
           ascending: initialAscending,
           sorts: initialSorts.isNotEmpty
               ? initialSorts
               : _initialSortsFromLegacy(initialSortBy, initialAscending),
         ),
       ) {
    if (autoFetchOnCreate) {
      unawaited(fetchFirstPage());
    }
  }

  final TableFetcher<T> fetcher;
  final TableMode mode;
  final TableSortMode sortMode;
  int _requestId = 0;

  static List<TableSort> _initialSortsFromLegacy(
    String? sortBy,
    bool ascending,
  ) {
    if (sortBy == null || sortBy.isEmpty) return const [];

    return [TableSort.fromAscending(field: sortBy, ascending: ascending)];
  }

  /// Gọi khi mở màn hình lần đầu, hoặc muốn tải lại từ đầu (pull-to-refresh...).
  Future<void> fetchFirstPage() => reload();

  /// Alias dễ hiểu cho pull-to-refresh / nút "Làm mới".
  Future<void> refresh() => reload();

  /// Tải lại trang đầu tiên theo sort/filter hiện tại.
  Future<void> reload({bool keepItems = false}) async {
    final requestId = ++_requestId;

    emit(
      state.copyWith(
        status: TableStatus.loading,
        items: keepItems ? state.items : const [],
        page: 1,
        hasReachedMax: false,
        errorMessage: null,
      ),
    );

    try {
      final result = await fetcher(_buildQuery(page: 1));
      if (!_isLatestRequest(requestId)) return;

      emit(
        state.copyWith(
          status: TableStatus.success,
          items: result.items,
          page: 1,
          totalCount: result.totalCount,
          hasReachedMax: _hasReachedMax(result.items.length, result.totalCount),
          hasLoadedOnce: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (!_isLatestRequest(requestId)) return;

      emit(
        state.copyWith(status: TableStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Chỉ dùng cho mode [TableMode.loadMore]: tải thêm trang kế tiếp và
  /// nối vào danh sách hiện có.
  Future<void> loadMore() async {
    if (mode != TableMode.loadMore) return;
    if (!state.canLoadMore) return;

    final requestId = ++_requestId;
    emit(state.copyWith(status: TableStatus.loadingMore, errorMessage: null));

    final nextPage = state.page + 1;
    try {
      final result = await fetcher(_buildQuery(page: nextPage));
      if (!_isLatestRequest(requestId)) return;

      final merged = [...state.items, ...result.items];
      emit(
        state.copyWith(
          status: TableStatus.success,
          items: merged,
          page: nextPage,
          totalCount: result.totalCount,
          hasReachedMax:
              _hasReachedMax(merged.length, result.totalCount) ||
              result.items.isEmpty,
          hasLoadedOnce: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      // Giữ nguyên danh sách cũ, chỉ báo lỗi cho phần load-more.
      if (!_isLatestRequest(requestId)) return;

      emit(
        state.copyWith(status: TableStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Chỉ dùng cho mode [TableMode.pagination]: nhảy tới trang [page] (1-based).
  Future<void> goToPage(int page) async {
    if (mode != TableMode.pagination) return;
    final targetPage = _normalizePage(page);
    if (targetPage == state.page && state.status == TableStatus.success) return;

    final requestId = ++_requestId;
    emit(state.copyWith(status: TableStatus.loading, errorMessage: null));

    try {
      final result = await fetcher(_buildQuery(page: targetPage));
      if (!_isLatestRequest(requestId)) return;

      emit(
        state.copyWith(
          status: TableStatus.success,
          items: result.items,
          page: targetPage,
          totalCount: result.totalCount,
          hasReachedMax: false,
          hasLoadedOnce: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (!_isLatestRequest(requestId)) return;

      emit(
        state.copyWith(status: TableStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Bấm vào header cột [field] để sort nhiều cột.
  ///
  /// Cột mới sẽ được thêm vào cuối danh sách sort. Bấm lại cùng cột sẽ đảo
  /// chiều sort của cột đó. Nếu [sortMode] là [TableSortMode.local], cubit sort
  /// ngay danh sách hiện tại bằng [localComparatorBuilder]. Riêng
  /// [TableMode.loadMore] luôn sort online để server/API giữ đúng thứ tự toàn bộ
  /// dataset.
  Future<void> sort(
    String field, {
    TableSortMode? mode,
    TableLocalSortComparatorBuilder<T>? localComparatorBuilder,
  }) async {
    final nextSorts = toggleTableSort(state.sorts, field);
    final primarySort = nextSorts.isEmpty ? null : nextSorts.first;
    final effectiveMode = _effectiveSortMode(mode);

    if (effectiveMode == TableSortMode.local) {
      final comparator = localComparatorBuilder?.call(nextSorts);
      final sortedItems = [...state.items];
      if (comparator != null) {
        sortedItems.sort(comparator);
      }

      _requestId++;
      emit(
        state.copyWith(
          status: TableStatus.success,
          items: sortedItems,
          sortBy: primarySort?.field,
          ascending: primarySort?.ascending ?? true,
          sorts: nextSorts,
          hasLoadedOnce: true,
          errorMessage: null,
          clearSortBy: primarySort == null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        sortBy: primarySort?.field,
        ascending: primarySort?.ascending ?? true,
        sorts: nextSorts,
        errorMessage: null,
        clearSortBy: primarySort == null,
      ),
    );
    await reload(keepItems: true);
  }

  Future<void> clearSort({TableSortMode? mode}) async {
    final effectiveMode = _effectiveSortMode(mode);
    emit(
      state.copyWith(
        clearSortBy: true,
        ascending: true,
        sorts: const [],
        errorMessage: null,
      ),
    );
    if (effectiveMode == TableSortMode.online) {
      await reload(keepItems: true);
    }
  }

  /// Áp dụng bộ lọc mới (thay thế toàn bộ filter cũ) và tải lại từ trang 1.
  /// [filters] tùy bạn định nghĩa key/value gì cũng được, miễn khớp với
  /// logic xử lý trong hàm [fetcher] (repository/API) của bạn.
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    emit(
      state.copyWith(
        filters: Map<String, dynamic>.unmodifiable(filters),
        errorMessage: null,
      ),
    );
    await reload();
  }

  Future<void> clearFilters() => applyFilters(const {});

  Future<void> updateFilter(String key, dynamic value) {
    return applyFilters({...state.filters, key: value});
  }

  Future<void> removeFilter(String key) {
    final filters = Map<String, dynamic>.of(state.filters)..remove(key);
    return applyFilters(filters);
  }

  Future<void> setPageSize(int pageSize) async {
    if (pageSize < 1 || pageSize == state.pageSize) return;

    emit(state.copyWith(pageSize: pageSize, errorMessage: null));
    await reload();
  }

  Future<void> nextPage() => goToPage(state.page + 1);

  Future<void> previousPage() => goToPage(state.page - 1);

  /// Thêm item vào danh sách hiện tại mà không gọi lại API.
  ///
  /// Dùng tốt cho optimistic update hoặc sau khi API tạo mới trả về item.
  /// [index] null thì thêm vào cuối list; nếu truyền index, cubit sẽ tự clamp
  /// vào phạm vi hợp lệ.
  void addItem(T item, {int? index, bool increaseTotalCount = true}) {
    if (isClosed) return;
    _requestId++;

    final items = [...state.items];
    final insertIndex = index == null
        ? items.length
        : index.clamp(0, items.length).toInt();
    items.insert(insertIndex, item);

    final totalCount = increaseTotalCount
        ? state.totalCount + 1
        : state.totalCount;

    emit(
      state.copyWith(
        status: TableStatus.success,
        items: items,
        totalCount: totalCount,
        hasReachedMax: _hasReachedMax(items.length, totalCount),
        hasLoadedOnce: true,
        errorMessage: null,
      ),
    );
  }

  /// Cập nhật item đầu tiên khớp [where] mà không gọi lại API.
  ///
  /// Ví dụ:
  /// ```dart
  /// cubit.updateItem(
  ///   (user) => user.id == updated.id,
  ///   (_) => updated,
  /// );
  /// ```
  ///
  /// Đặt [updateAll] = true nếu muốn cập nhật toàn bộ item khớp điều kiện.
  void updateItem(
    bool Function(T item) where,
    T Function(T item) update, {
    bool updateAll = false,
  }) {
    if (isClosed) return;

    var changed = false;
    final items = state.items.map((item) {
      if ((!changed || updateAll) && where(item)) {
        changed = true;
        return update(item);
      }

      return item;
    }).toList();

    if (!changed) return;
    _requestId++;

    emit(
      state.copyWith(
        status: TableStatus.success,
        items: items,
        hasLoadedOnce: true,
        errorMessage: null,
      ),
    );
  }

  /// Xóa item đầu tiên khớp [where] mà không gọi lại API.
  ///
  /// Đặt [removeAll] = true nếu muốn xóa toàn bộ item khớp điều kiện.
  void removeItem(
    bool Function(T item) where, {
    bool removeAll = false,
    bool decreaseTotalCount = true,
  }) {
    if (isClosed) return;

    var removedCount = 0;
    final items = <T>[];
    for (final item in state.items) {
      final shouldRemove = (removeAll || removedCount == 0) && where(item);
      if (shouldRemove) {
        removedCount++;
      } else {
        items.add(item);
      }
    }

    if (removedCount == 0) return;
    _requestId++;

    final totalCount = decreaseTotalCount
        ? (state.totalCount - removedCount).clamp(0, state.totalCount).toInt()
        : state.totalCount;

    emit(
      state.copyWith(
        status: TableStatus.success,
        items: items,
        totalCount: totalCount,
        hasReachedMax: _hasReachedMax(items.length, totalCount),
        hasLoadedOnce: true,
        errorMessage: null,
      ),
    );
  }

  TableQuery _buildQuery({required int page}) {
    return TableQuery(
      page: page,
      pageSize: state.pageSize,
      sortBy: state.sortBy,
      ascending: state.ascending,
      sorts: state.sorts,
      filters: state.filters,
    );
  }

  TableSortMode _effectiveSortMode(TableSortMode? mode) {
    if (this.mode == TableMode.loadMore) return TableSortMode.online;
    return mode ?? sortMode;
  }

  int _normalizePage(int page) {
    if (page < 1) return 1;
    if (state.totalCount == 0) return page;
    return page.clamp(1, state.totalPages).toInt();
  }

  bool _hasReachedMax(int loadedCount, int totalCount) {
    if (mode != TableMode.loadMore) return false;
    return loadedCount >= totalCount;
  }

  bool _isLatestRequest(int requestId) {
    return !isClosed && requestId == _requestId;
  }
}
