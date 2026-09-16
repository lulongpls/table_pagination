import 'package:flutter/material.dart';
import 'package:table_pagination/src/core/table_sort.dart';

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
    this.sort,
    this.sortPriority = 0,
    this.sortable = true,
  });

  final String label;
  final String field;
  final String? currentSortField;
  final bool ascending;
  final TableSort? sort;
  final int sortPriority;
  final VoidCallback onTap;

  /// Đặt false nếu cột này không cho sort (vẫn hiển thị label bình thường).
  final bool sortable;

  @override
  Widget build(BuildContext context) {
    final activeSort = sort;
    final bool isActive =
        sortable && (activeSort != null || currentSortField == field);
    final isAscending = activeSort?.ascending ?? ascending;

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
                : (isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            size: 14,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          if (isActive && sortPriority > 1) ...[
            const SizedBox(width: 2),
            _SortPriorityBadge(value: sortPriority),
          ],
        ],
      ],
    );

    if (!sortable) return content;

    return InkWell(onTap: onTap, child: content);
  }
}

class _SortPriorityBadge extends StatelessWidget {
  const _SortPriorityBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
