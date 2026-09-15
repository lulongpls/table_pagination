import 'package:flutter/material.dart';

/// Header 1 cột có thể bấm để sort, tự hiển thị icon mũi tên lên/xuống theo
/// trạng thái sort hiện tại của cubit. Dùng bên trong hàm columnsBuilder mà
/// bạn truyền cho [GenericDataTable].
class SortableHeader extends StatelessWidget {
  const SortableHeader({
    super.key,
    required this.label,
    required this.field,
    required this.currentSortField,
    required this.ascending,
    required this.onTap,
    this.sortable = true,
  });

  final String label;
  final String field;
  final String? currentSortField;
  final bool ascending;
  final VoidCallback onTap;

  /// Đặt false nếu cột này không cho sort (vẫn hiển thị label bình thường).
  final bool sortable;

  @override
  Widget build(BuildContext context) {
    final bool isActive = sortable && currentSortField == field;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (sortable) ...[
          const SizedBox(width: 4),
          Icon(
            !isActive
                ? Icons.unfold_more
                : (ascending ? Icons.arrow_upward : Icons.arrow_downward),
            size: 14,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        ],
      ],
    );

    if (!sortable) return content;

    return InkWell(onTap: onTap, child: content);
  }
}
