/// Kết quả trả về từ hàm fetch dữ liệu (repository/API) cho 1 lần gọi.
///
/// [items] là danh sách dữ liệu của trang/lô hiện tại.
/// [totalCount] là tổng số bản ghi (toàn bộ dataset), dùng để tính
/// tổng số trang (mode pagination) hoặc biết khi nào hết dữ liệu (mode loadMore).
class PagedResult<T> {
  final List<T> items;
  final int totalCount;

  const PagedResult({required this.items, required this.totalCount});

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;
}
