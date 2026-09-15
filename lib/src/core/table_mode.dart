/// Chế độ hiển thị/tải dữ liệu của bảng.
enum TableMode {
  /// Phân trang theo số trang (có thanh điều hướng: trang trước / sau / nhảy trang).
  pagination,

  /// Tải thêm khi cuộn tới cuối danh sách (infinite scroll).
  loadMore,
}
