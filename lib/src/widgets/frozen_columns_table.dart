import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_pagination/src/models/table_action.dart';
import 'package:table_pagination/src/models/table_column_config.dart';

typedef TableHeaderCellBuilder =
    Widget Function(BuildContext context, int index);
typedef TableRowCellsBuilder<T> =
    List<Widget> Function(BuildContext context, int rowIndex);
typedef TableBuiltRowBuilder =
    Widget Function(
      BuildContext context,
      int rowIndex,
      Widget row,
      bool isHovered,
    );

/// The table renderer used when the first [frozenColumnCount] columns must
/// remain visible while the rest of the row scrolls horizontally.
class FrozenColumnsTable<T> extends StatefulWidget {
  const FrozenColumnsTable({
    super.key,
    required this.items,
    required this.columnCount,
    required this.headerBuilder,
    required this.rowCellsBuilder,
    required this.rowBuilder,
    required this.emptyBuilder,
    required this.defaultColumnWidth,
    required this.columnWidths,
    required this.frozenColumnCount,
    required this.rowHeight,
    required this.headerRowHeight,
    required this.actions,
    required this.actionMode,
    required this.actionIcon,
    required this.addSpacerToActions,
    required this.onRowTap,
    required this.rowDecorationBuilder,
    required this.rowDecoration,
    required this.headerDecoration,
    required this.headerTextStyle,
    required this.innerHeaderPadding,
    required this.elementsPadding,
    required this.outterHeaderPadding,
    required this.outterRowsPadding,
  });

  final List<T> items;
  final int columnCount;
  final TableHeaderCellBuilder headerBuilder;
  final TableRowCellsBuilder<T> rowCellsBuilder;
  final TableBuiltRowBuilder rowBuilder;
  final Widget emptyBuilder;
  final double defaultColumnWidth;
  final List<double> columnWidths;
  final int frozenColumnCount;
  final double rowHeight;
  final double headerRowHeight;
  final List<TableAction<T>> actions;
  final TableActionMode actionMode;
  final Widget? actionIcon;
  final bool addSpacerToActions;
  final TableRowTap<T>? onRowTap;
  final TableRowDecorationBuilder<T>? rowDecorationBuilder;
  final BoxDecoration? rowDecoration;
  final BoxDecoration? headerDecoration;
  final TextStyle? headerTextStyle;
  final EdgeInsets? innerHeaderPadding;
  final EdgeInsets? elementsPadding;
  final EdgeInsets? outterHeaderPadding;
  final EdgeInsets? outterRowsPadding;

  @override
  State<FrozenColumnsTable<T>> createState() => _FrozenColumnsTableState<T>();
}

class _FrozenColumnsTableState<T> extends State<FrozenColumnsTable<T>> {
  late final ValueNotifier<double> _horizontalOffset;

  @override
  void initState() {
    super.initState();
    _horizontalOffset = ValueNotifier(0);
  }

  @override
  void dispose() {
    _horizontalOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final actionCount = _visibleActionCount;
        final actionWidth = widget.defaultColumnWidth * .5;
        final columnsWidth = widget.columnWidths.fold<double>(
          0,
          (sum, width) => sum + width,
        );
        final actionsWidth = _actionsWidth(actionWidth, actionCount);
        final contentWidth = math.max(
          viewportWidth,
          columnsWidth + actionsWidth,
        );
        final frozenCount = widget.frozenColumnCount.clamp(
          0,
          widget.columnCount,
        );
        final frozenWidth = widget.columnWidths
            .take(frozenCount)
            .fold<double>(0, (sum, width) => sum + width);

        final header = _buildHeader(
          context,
          viewportWidth: viewportWidth,
          contentWidth: contentWidth,
          frozenWidth: frozenWidth,
          frozenCount: frozenCount,
        );

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              header,
              Expanded(
                child: widget.items.isEmpty
                    ? widget.emptyBuilder
                    : ListView.builder(
                        padding: widget.outterRowsPadding,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                widget.elementsPadding ??
                                const EdgeInsets.symmetric(vertical: 5),
                            child: _FrozenDataRow<T>(
                              item: widget.items[index],
                              rowIndex: index,
                              viewportWidth: viewportWidth,
                              contentWidth: contentWidth,
                              frozenWidth: frozenWidth,
                              frozenCount: frozenCount,
                              columnCount: widget.columnCount,
                              columnWidths: widget.columnWidths,
                              rowCellsBuilder: widget.rowCellsBuilder,
                              rowBuilder: widget.rowBuilder,
                              horizontalOffset: _horizontalOffset,
                              rowHeight: widget.rowHeight,
                              actions: widget.actions,
                              actionMode: widget.actionMode,
                              actionIcon: widget.actionIcon,
                              actionWidth: actionWidth,
                              addSpacerToActions: widget.addSpacerToActions,
                              onRowTap: widget.onRowTap,
                              rowDecorationBuilder: widget.rowDecorationBuilder,
                              rowDecoration: widget.rowDecoration,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double viewportWidth,
    required double contentWidth,
    required double frozenWidth,
    required int frozenCount,
  }) {
    Widget buildCells(int count) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < count; index++)
            widget.headerBuilder(context, index),
        ],
      );
    }

    final allCells = buildCells(widget.columnCount);
    final frozenCells = buildCells(frozenCount);

    return _FrozenHorizontalViewport(
      viewportWidth: viewportWidth,
      contentWidth: contentWidth,
      frozenWidth: frozenWidth,
      offset: _horizontalOffset,
      fixedBackgroundColor:
          widget.headerDecoration?.color ??
          Theme.of(context).colorScheme.surface,
      fixedChild: frozenCells,
      wrapper: (child) => DefaultTextStyle(
        style:
            widget.headerTextStyle ?? Theme.of(context).textTheme.labelMedium!,
        child: Padding(
          padding:
              (widget.elementsPadding ??
                      const EdgeInsets.symmetric(vertical: 5))
                  .add(
                    widget.outterHeaderPadding ??
                        const EdgeInsets.only(bottom: 10),
                  ),
          child: Container(
            decoration: widget.headerDecoration,
            padding: widget.innerHeaderPadding,
            child: child,
          ),
        ),
      ),
      child: allCells,
    );
  }

  int get _visibleActionCount {
    if (widget.actions.isEmpty) return 0;
    return _effectiveMode == TableActionMode.group ? 1 : widget.actions.length;
  }

  TableActionMode get _effectiveMode {
    if (widget.actionMode == TableActionMode.defaultMode) {
      return widget.actions.length > 2
          ? TableActionMode.group
          : TableActionMode.full;
    }
    return widget.actionMode;
  }

  double _actionsWidth(double actionWidth, int actionCount) {
    final width = actionWidth * actionCount;
    if (!widget.addSpacerToActions || actionCount == 0) return width;
    return width;
  }
}

class _FrozenDataRow<T> extends StatefulWidget {
  const _FrozenDataRow({
    required this.item,
    required this.rowIndex,
    required this.viewportWidth,
    required this.contentWidth,
    required this.frozenWidth,
    required this.frozenCount,
    required this.columnCount,
    required this.columnWidths,
    required this.rowCellsBuilder,
    required this.rowBuilder,
    required this.horizontalOffset,
    required this.rowHeight,
    required this.actions,
    required this.actionMode,
    required this.actionIcon,
    required this.actionWidth,
    required this.addSpacerToActions,
    required this.onRowTap,
    required this.rowDecorationBuilder,
    required this.rowDecoration,
  });

  final T item;
  final int rowIndex;
  final double viewportWidth;
  final double contentWidth;
  final double frozenWidth;
  final int frozenCount;
  final int columnCount;
  final List<double> columnWidths;
  final TableRowCellsBuilder<T> rowCellsBuilder;
  final TableBuiltRowBuilder rowBuilder;
  final ValueNotifier<double> horizontalOffset;
  final double rowHeight;
  final List<TableAction<T>> actions;
  final TableActionMode actionMode;
  final Widget? actionIcon;
  final double actionWidth;
  final bool addSpacerToActions;
  final TableRowTap<T>? onRowTap;
  final TableRowDecorationBuilder<T>? rowDecorationBuilder;
  final BoxDecoration? rowDecoration;

  @override
  State<_FrozenDataRow<T>> createState() => _FrozenDataRowState<T>();
}

class _FrozenDataRowState<T> extends State<_FrozenDataRow<T>> {
  late final ScrollController _scrollController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_publishOffset);
    widget.horizontalOffset.addListener(_syncOffset);
  }

  @override
  void didUpdateWidget(covariant _FrozenDataRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalOffset != widget.horizontalOffset) {
      oldWidget.horizontalOffset.removeListener(_syncOffset);
      widget.horizontalOffset.addListener(_syncOffset);
    }
  }

  @override
  void dispose() {
    widget.horizontalOffset.removeListener(_syncOffset);
    _scrollController
      ..removeListener(_publishOffset)
      ..dispose();
    super.dispose();
  }

  void _publishOffset() {
    if (!mounted || !_scrollController.hasClients) return;
    final current = widget.horizontalOffset.value;
    final next = _scrollController.offset;
    if ((current - next).abs() > .5) {
      widget.horizontalOffset.value = next;
    }
  }

  void _syncOffset() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final next = widget.horizontalOffset.value.clamp(0.0, max).toDouble();
    if ((_scrollController.offset - next).abs() > .5) {
      _scrollController.jumpTo(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cells = widget.rowCellsBuilder(context, widget.rowIndex);
    final frozenCells = cells.take(widget.frozenCount).toList();
    final allChildren = [...cells, ..._buildActions(context)];
    final frozen = Row(mainAxisSize: MainAxisSize.min, children: frozenCells);
    final all = Row(mainAxisSize: MainAxisSize.min, children: allChildren);

    final baseRow = _FrozenHorizontalViewport(
      viewportWidth: widget.viewportWidth,
      contentWidth: widget.contentWidth,
      frozenWidth: widget.frozenWidth,
      offset: widget.horizontalOffset,
      fixedBackgroundColor: Theme.of(context).colorScheme.surface,
      controller: _scrollController,
      fixedChild: frozen,
      wrapper: (child) => widget.rowHeight.isNaN
          ? child
          : SizedBox(height: widget.rowHeight, child: child),
      child: all,
    );

    final decoratedRow = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration:
          widget.rowDecorationBuilder?.call(
            context,
            widget.item,
            widget.rowIndex,
            _isHovered,
          ) ??
          widget.rowDecoration,
      child: widget.onRowTap == null
          ? baseRow
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onRowTap!(widget.item, widget.rowIndex),
              child: baseRow,
            ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.rowBuilder(
        context,
        widget.rowIndex,
        decoratedRow,
        _isHovered,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (widget.actions.isEmpty) return const [];
    final mode = widget.actionMode == TableActionMode.defaultMode
        ? (widget.actions.length > 2
              ? TableActionMode.group
              : TableActionMode.full)
        : widget.actionMode;
    final actionWidgets = mode == TableActionMode.group
        ? <Widget>[_buildActionGroup(context)]
        : [
            for (final action in widget.actions)
              _buildInlineAction(context, action),
          ];

    return [
      if (widget.addSpacerToActions)
        SizedBox(
          width: math.max(
            0,
            widget.contentWidth -
                widget.columnWidths.fold<double>(
                  0,
                  (sum, width) => sum + width,
                ) -
                widget.actionWidth * actionWidgets.length,
          ),
        ),
      ...actionWidgets,
    ];
  }

  Widget _buildInlineAction(BuildContext context, TableAction<T> action) {
    return SizedBox(
      width: widget.actionWidth,
      child: Center(
        child: Tooltip(
          message: action.name,
          child: InkWell(
            onTap: action.enabled
                ? () => unawaited(
                    Future<void>.sync(
                      () => action.onTap(widget.item, widget.rowIndex),
                    ),
                  )
                : null,
            child: action.icon,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGroup(BuildContext context) {
    return SizedBox(
      width: widget.actionWidth,
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        icon: widget.actionIcon ?? const Icon(Icons.more_horiz),
        onSelected: (index) {
          final action = widget.actions[index];
          if (!action.enabled) return;
          unawaited(
            Future<void>.sync(() => action.onTap(widget.item, widget.rowIndex)),
          );
        },
        itemBuilder: (context) => [
          for (var index = 0; index < widget.actions.length; index++)
            PopupMenuItem<int>(
              value: index,
              enabled: widget.actions[index].enabled,
              child: _ActionMenuItem(action: widget.actions[index]),
            ),
        ],
      ),
    );
  }
}

class _FrozenHorizontalViewport extends StatefulWidget {
  const _FrozenHorizontalViewport({
    required this.viewportWidth,
    required this.contentWidth,
    required this.frozenWidth,
    required this.offset,
    required this.child,
    required this.fixedChild,
    required this.fixedBackgroundColor,
    this.controller,
    this.wrapper,
  });

  final double viewportWidth;
  final double contentWidth;
  final double frozenWidth;
  final ValueNotifier<double> offset;
  final Widget child;
  final Widget fixedChild;
  final Color fixedBackgroundColor;
  final ScrollController? controller;
  final Widget Function(Widget child)? wrapper;

  @override
  State<_FrozenHorizontalViewport> createState() =>
      _FrozenHorizontalViewportState();
}

class _FrozenHorizontalViewportState extends State<_FrozenHorizontalViewport> {
  late final ScrollController _internalController;

  bool get _ownsController => widget.controller == null;

  ScrollController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
    _controller.addListener(_publishOffset);
    widget.offset.addListener(_syncOffset);
  }

  @override
  void didUpdateWidget(covariant _FrozenHorizontalViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_publishOffset);
      _controller.addListener(_publishOffset);
    }
    if (oldWidget.offset != widget.offset) {
      oldWidget.offset.removeListener(_syncOffset);
      widget.offset.addListener(_syncOffset);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_publishOffset);
    if (_ownsController) _internalController.dispose();
    widget.offset.removeListener(_syncOffset);
    super.dispose();
  }

  void _publishOffset() {
    if (!_controller.hasClients) return;
    final current = widget.offset.value;
    final next = _controller.offset;
    if ((current - next).abs() > .5) widget.offset.value = next;
  }

  void _syncOffset() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final next = widget.offset.value.clamp(0.0, max).toDouble();
    if ((_controller.offset - next).abs() > .5) _controller.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final viewport = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        SizedBox(
          width: widget.viewportWidth,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: widget.contentWidth, child: widget.child),
          ),
        ),
        if (widget.frozenWidth > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.frozenWidth,
            child: ColoredBox(
              color: widget.fixedBackgroundColor,
              child: ClipRect(child: widget.fixedChild),
            ),
          ),
      ],
    );

    return widget.wrapper?.call(viewport) ?? viewport;
  }
}

class _ActionMenuItem<T> extends StatelessWidget {
  const _ActionMenuItem({required this.action});

  final TableAction<T> action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        action.icon,
        const SizedBox(width: 10),
        Flexible(child: Text(action.name)),
      ],
    );
  }
}
