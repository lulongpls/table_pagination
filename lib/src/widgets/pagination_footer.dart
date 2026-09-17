import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef PaginationLabelBuilder =
    String Function(int page, int totalPages, int totalCount);

class PaginationFooterStyle {
  const PaginationFooterStyle({
    this.backgroundColor,
    this.labelStyle,
    this.loadingIndicatorColor,
    this.iconForegroundColor,
    this.disabledIconForegroundColor,
    this.pageForegroundColor,
    this.disabledPageForegroundColor,
    this.pageBackgroundColor,
    this.selectedPageForegroundColor,
    this.selectedPageBackgroundColor,
    this.pageButtonBorder,
    this.selectedPageButtonBorder,
    this.pageButtonBorderRadius,
    this.pageButtonSize = 36,
    this.pageButtonSpacing = 2,
  });

  final Color? backgroundColor;
  final TextStyle? labelStyle;
  final Color? loadingIndicatorColor;
  final Color? iconForegroundColor;
  final Color? disabledIconForegroundColor;
  final Color? pageForegroundColor;
  final Color? disabledPageForegroundColor;
  final Color? pageBackgroundColor;
  final Color? selectedPageForegroundColor;
  final Color? selectedPageBackgroundColor;
  final BorderSide? pageButtonBorder;
  final BorderSide? selectedPageButtonBorder;
  final BorderRadiusGeometry? pageButtonBorderRadius;
  final double pageButtonSize;
  final double pageButtonSpacing;
}

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
    this.firstPageTooltip = 'First page',
    this.previousPageTooltip = 'Previous page',
    this.nextPageTooltip = 'Next page',
    this.lastPageTooltip = 'Last page',
    this.style = const PaginationFooterStyle(),
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
  final String firstPageTooltip;
  final String previousPageTooltip;
  final String nextPageTooltip;
  final String lastPageTooltip;
  final PaginationFooterStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTotalPages = math.max(1, totalPages);
    final effectivePage = page.clamp(1, effectiveTotalPages).toInt();
    final pages = _visiblePages(effectivePage, effectiveTotalPages);

    return Material(
      color: style.backgroundColor ?? theme.colorScheme.surface,
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
                style: style.labelStyle ?? theme.textTheme.bodySmall,
              ),
            ),
            if (isLoading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: style.loadingIndicatorColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showFirstLastButtons)
              _PagerIconButton(
                icon: Icons.first_page,
                tooltip: firstPageTooltip,
                enabled: !isLoading && effectivePage > 1,
                foregroundColor: style.iconForegroundColor,
                disabledForegroundColor: style.disabledIconForegroundColor,
                onPressed: () => onPageChanged(1),
              ),
            _PagerIconButton(
              icon: Icons.chevron_left,
              tooltip: previousPageTooltip,
              enabled: !isLoading && effectivePage > 1,
              foregroundColor: style.iconForegroundColor,
              disabledForegroundColor: style.disabledIconForegroundColor,
              onPressed: () => onPageChanged(effectivePage - 1),
            ),
            for (final item in pages)
              _PagerNumberButton(
                page: item,
                selected: item == effectivePage,
                enabled: !isLoading,
                style: style,
                onPressed: () => onPageChanged(item),
              ),
            _PagerIconButton(
              icon: Icons.chevron_right,
              tooltip: nextPageTooltip,
              enabled: !isLoading && effectivePage < effectiveTotalPages,
              foregroundColor: style.iconForegroundColor,
              disabledForegroundColor: style.disabledIconForegroundColor,
              onPressed: () => onPageChanged(effectivePage + 1),
            ),
            if (showFirstLastButtons)
              _PagerIconButton(
                icon: Icons.last_page,
                tooltip: lastPageTooltip,
                enabled: !isLoading && effectivePage < effectiveTotalPages,
                foregroundColor: style.iconForegroundColor,
                disabledForegroundColor: style.disabledIconForegroundColor,
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
    required this.foregroundColor,
    required this.disabledForegroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Color? foregroundColor;
  final Color? disabledForegroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: 20,
          color: enabled
              ? foregroundColor
              : (disabledForegroundColor ?? theme.disabledColor),
        ),
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
    required this.style,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final bool enabled;
  final PaginationFooterStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderRadius =
        style.pageButtonBorderRadius ?? BorderRadius.circular(6);
    final border = selected
        ? style.selectedPageButtonBorder
        : style.pageButtonBorder;
    final foregroundColor = selected
        ? (style.selectedPageForegroundColor ?? colors.onPrimary)
        : (style.pageForegroundColor ?? colors.onSurfaceVariant);
    final disabledForegroundColor =
        style.disabledPageForegroundColor ?? theme.disabledColor;
    final backgroundColor = selected
        ? (style.selectedPageBackgroundColor ?? colors.primary)
        : (style.pageBackgroundColor ?? Colors.transparent);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: style.pageButtonSpacing),
      child: SizedBox(
        width: style.pageButtonSize,
        height: style.pageButtonSize,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: foregroundColor,
            disabledForegroundColor: selected
                ? foregroundColor
                : disabledForegroundColor,
            backgroundColor: backgroundColor,
            disabledBackgroundColor: selected
                ? backgroundColor
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: border ?? BorderSide.none,
            ),
          ),
          onPressed: enabled ? onPressed : null,
          child: Text('$page'),
        ),
      ),
    );
  }
}
