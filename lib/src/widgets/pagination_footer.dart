import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef PaginationLabelBuilder =
    String Function(int page, int totalPages, int totalCount);

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
    this.isLoading = false,
    this.maxVisiblePages = 5,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.labelBuilder,
    this.showFirstLastButtons = true,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final bool isLoading;
  final int maxVisiblePages;
  final EdgeInsetsGeometry padding;
  final PaginationLabelBuilder? labelBuilder;
  final bool showFirstLastButtons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTotalPages = math.max(1, totalPages);
    final effectivePage = page.clamp(1, effectiveTotalPages).toInt();
    final pages = _visiblePages(effectivePage, effectiveTotalPages);

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Text(
                labelBuilder?.call(
                      effectivePage,
                      effectiveTotalPages,
                      totalCount,
                    ) ??
                    'Page $effectivePage of $effectiveTotalPages · $totalCount rows',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            if (showFirstLastButtons)
              _PagerIconButton(
                icon: Icons.first_page,
                tooltip: 'First page',
                enabled: !isLoading && effectivePage > 1,
                onPressed: () => onPageChanged(1),
              ),
            _PagerIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Previous page',
              enabled: !isLoading && effectivePage > 1,
              onPressed: () => onPageChanged(effectivePage - 1),
            ),
            for (final item in pages)
              _PagerNumberButton(
                page: item,
                selected: item == effectivePage,
                enabled: !isLoading,
                onPressed: () => onPageChanged(item),
              ),
            _PagerIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Next page',
              enabled: !isLoading && effectivePage < effectiveTotalPages,
              onPressed: () => onPageChanged(effectivePage + 1),
            ),
            if (showFirstLastButtons)
              _PagerIconButton(
                icon: Icons.last_page,
                tooltip: 'Last page',
                enabled: !isLoading && effectivePage < effectiveTotalPages,
                onPressed: () => onPageChanged(effectiveTotalPages),
              ),
          ],
        ),
      ),
    );
  }

  List<int> _visiblePages(int currentPage, int totalPages) {
    final count = math.max(1, math.min(maxVisiblePages, totalPages));
    final half = count ~/ 2;
    var start = currentPage - half;
    var end = start + count - 1;

    if (start < 1) {
      start = 1;
      end = count;
    }

    if (end > totalPages) {
      end = totalPages;
      start = math.max(1, end - count + 1);
    }

    return [for (var page = start; page <= end; page++) page];
  }
}

class _PagerIconButton extends StatelessWidget {
  const _PagerIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

class _PagerNumberButton extends StatelessWidget {
  const _PagerNumberButton({
    required this.page,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 36,
        height: 36,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: selected
                ? colors.onPrimary
                : colors.onSurfaceVariant,
            backgroundColor: selected ? colors.primary : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: enabled && !selected ? onPressed : null,
          child: Text('$page'),
        ),
      ),
    );
  }
}
