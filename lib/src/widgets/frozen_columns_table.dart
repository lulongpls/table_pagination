import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
    required this.actionColumnWidth,
    required this.actionColumnTitle,
    required this.addSpacerToActions,
    required this.onRowTap,
    required this.rowDecorationBuilder,
    required this.rowDecoration,
    required this.headerDecoration,
    required this.headerTextStyle,
    required this.innerHeaderPadding,
    required this.innerRowElementsPadding,
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
  final double actionColumnWidth;
  final String? actionColumnTitle;
  final bool addSpacerToActions;
  final TableRowTap<T>? onRowTap;
  final TableRowDecorationBuilder<T>? rowDecorationBuilder;
  final BoxDecoration? rowDecoration;
  final BoxDecoration? headerDecoration;
  final TextStyle? headerTextStyle;
  final EdgeInsets? innerHeaderPadding;
  final EdgeInsets? innerRowElementsPadding;
  final EdgeInsets? elementsPadding;
  final EdgeInsets? outterHeaderPadding;
  final EdgeInsets? outterRowsPadding;

  @override
  State<FrozenColumnsTable<T>> createState() => _FrozenColumnsTableState<T>();
}

class _FrozenColumnsTableState<T> extends State<FrozenColumnsTable<T>> {
  static const _pointerSignalAxisLockDuration = Duration(milliseconds: 120);
  static const _verticalIntentThreshold = 12.0;

  late final ValueNotifier<double> _horizontalOffset;
  Timer? _pointerSignalAxisLockTimer;
  bool _isHorizontalPointerSignalLocked = false;

  @override
  void initState() {
    super.initState();
    _horizontalOffset = ValueNotifier(0);
    _horizontalOffset.addListener(_lockPointerSignalToHorizontalAxis);
  }

  @override
  void dispose() {
    _pointerSignalAxisLockTimer?.cancel();
    _horizontalOffset.removeListener(_lockPointerSignalToHorizontalAxis);
    _horizontalOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final actionCount = _visibleActionCount;
        final defaultActionWidth = widget.defaultColumnWidth * .5;
        final columnsWidth = widget.columnWidths.fold<double>(
          0,
          (sum, width) => sum + width,
        );
        final defaultActionsWidth = _actionsWidth(
          defaultActionWidth,
          actionCount,
        );
        final actionsWidth = widget.actionColumnWidth.isNaN
            ? defaultActionsWidth
            : widget.actionColumnWidth;
        final actionWidth = actionCount == 0
            ? 0.0
            : widget.actionColumnWidth.isNaN
            ? defaultActionWidth
            : widget.actionColumnWidth / actionCount;
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
          columnsWidth: columnsWidth,
          actionsWidth: actionsWidth,
          actionCount: actionCount,
        );

        return _withFrozenShadow(
          frozenWidth: frozenWidth,
          child: Column(
            children: [
              header,
              Expanded(
                child: widget.items.isEmpty
                    ? widget.emptyBuilder
                    : ListView.builder(
                        physics: _PointerSignalAxisScrollPhysics(
                          isEnabled: () => !_isHorizontalPointerSignalLocked,
                        ),
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
                              onPointerSignalIntent: _handlePointerSignalIntent,
                              rowHeight: widget.rowHeight,
                              actions: widget.actions,
                              actionMode: widget.actionMode,
                              actionIcon: widget.actionIcon,
                              actionWidth: actionWidth,
                              addSpacerToActions: widget.addSpacerToActions,
                              onRowTap: widget.onRowTap,
                              rowDecorationBuilder: widget.rowDecorationBuilder,
                              rowDecoration: widget.rowDecoration,
                              innerRowElementsPadding:
                                  widget.innerRowElementsPadding,
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

  Widget _withFrozenShadow({
    required double frozenWidth,
    required Widget child,
  }) {
    if (frozenWidth <= 0) return child;

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned(
            left: frozenWidth - 1,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _horizontalOffset,
                builder: (context, offset, child) {
                  return DecoratedBox(
                    key: const ValueKey('frozen-columns-shadow'),
                    decoration: BoxDecoration(
                      boxShadow: offset > .5
                          ? [
                              const BoxShadow(
                                color: Color(0x14000000), // ~8%
                                blurRadius: 12,
                                spreadRadius:
                                    -2, // âm để bóng không lem lên/xuống
                                offset: Offset(4, 0),
                              ),
                              const BoxShadow(
                                color: Color(0x1F000000), // ~12%
                                blurRadius: 3,
                                spreadRadius: -1,
                                offset: Offset(1, 0),
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  );
                },
                child: const SizedBox(width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _lockPointerSignalToHorizontalAxis() {
    _isHorizontalPointerSignalLocked = true;
    _pointerSignalAxisLockTimer?.cancel();
    _pointerSignalAxisLockTimer = Timer(
      _pointerSignalAxisLockDuration,
      () => _isHorizontalPointerSignalLocked = false,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!_isHorizontalPointerSignalLocked || event is! PointerScrollEvent) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  void _handlePointerSignalIntent(PointerScrollEvent event) {
    final delta = event.scrollDelta;
    if (delta.dx.abs() > delta.dy.abs()) {
      _lockPointerSignalToHorizontalAxis();
      return;
    }

    if (_isHorizontalPointerSignalLocked &&
        delta.dy.abs() >= _verticalIntentThreshold) {
      _pointerSignalAxisLockTimer?.cancel();
      _isHorizontalPointerSignalLocked = false;
    }
  }

  Widget _buildHeader(
    BuildContext context, {
    required double viewportWidth,
    required double contentWidth,
    required double frozenWidth,
    required int frozenCount,
    required double columnsWidth,
    required double actionsWidth,
    required int actionCount,
  }) {
    final headerStyle =
        widget.headerTextStyle ?? Theme.of(context).textTheme.labelMedium!;
    final headerCells = [
      for (var index = 0; index < widget.columnCount; index++)
        widget.headerBuilder(context, index),
    ];

    final headerAction = actionCount == 0
        ? const SizedBox.shrink()
        : SizedBox(
            width: actionsWidth,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: widget.actionColumnTitle == null
                  ? null
                  : Text(
                      widget.actionColumnTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          );
    final headerSpacerWidth = widget.addSpacerToActions
        ? math.max(0, contentWidth - columnsWidth - actionsWidth).toDouble()
        : 0.0;
    // Render frozen headers only in the fixed overlay. Keeping them out of
    // the scrolling child avoids duplicate titles/semantics and prevents the
    // scrolling copy from showing through while the table is offset.
    final scrollingCells = DefaultTextStyle(
      style: headerStyle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...headerCells.skip(frozenCount),
          if (headerSpacerWidth > 0) SizedBox(width: headerSpacerWidth),
          headerAction,
        ],
      ),
    );
    final frozenCells = DefaultTextStyle(
      style: headerStyle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: headerCells.take(frozenCount).toList(),
      ),
    );

    return _FrozenHorizontalViewport(
      viewportWidth: viewportWidth,
      contentWidth: contentWidth,
      frozenWidth: frozenWidth,
      offset: _horizontalOffset,
      onPointerSignalIntent: _handlePointerSignalIntent,
      fixedChild: frozenCells,
      wrapper: (child) => DefaultTextStyle(
        style: headerStyle,
        child: Container(
          decoration: widget.headerDecoration,
          padding: widget.innerHeaderPadding,
          child: child,
        ),
      ),
      child: scrollingCells,
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
    required this.onPointerSignalIntent,
    required this.rowHeight,
    required this.actions,
    required this.actionMode,
    required this.actionIcon,
    required this.actionWidth,
    required this.addSpacerToActions,
    required this.onRowTap,
    required this.rowDecorationBuilder,
    required this.rowDecoration,
    required this.innerRowElementsPadding,
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
  final ValueChanged<PointerScrollEvent> onPointerSignalIntent;
  final double rowHeight;
  final List<TableAction<T>> actions;
  final TableActionMode actionMode;
  final Widget? actionIcon;
  final double actionWidth;
  final bool addSpacerToActions;
  final TableRowTap<T>? onRowTap;
  final TableRowDecorationBuilder<T>? rowDecorationBuilder;
  final BoxDecoration? rowDecoration;
  final EdgeInsets? innerRowElementsPadding;

  @override
  State<_FrozenDataRow<T>> createState() => _FrozenDataRowState<T>();
}

class _FrozenDataRowState<T> extends State<_FrozenDataRow<T>> {
  late final ScrollController _scrollController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.horizontalOffset.value,
      keepScrollOffset: false,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cells = widget.rowCellsBuilder(context, widget.rowIndex);
    final frozenCells = cells.take(widget.frozenCount).toList();
    final frozen = Row(mainAxisSize: MainAxisSize.min, children: frozenCells);
    final scrolling = Row(
      mainAxisSize: MainAxisSize.min,
      children: [...cells.skip(widget.frozenCount), ..._buildActions(context)],
    );

    final rowDecoration =
        widget.rowDecorationBuilder?.call(
          context,
          widget.item,
          widget.rowIndex,
          _isHovered,
        ) ??
        widget.rowDecoration;

    final baseRow = _FrozenHorizontalViewport(
      viewportWidth: widget.viewportWidth,
      contentWidth: widget.contentWidth,
      frozenWidth: widget.frozenWidth,
      offset: widget.horizontalOffset,
      onPointerSignalIntent: widget.onPointerSignalIntent,
      controller: _scrollController,
      fixedChild: frozen,
      wrapper: (child) => widget.rowHeight.isNaN
          ? child
          : SizedBox(height: widget.rowHeight, child: child),
      child: scrolling,
    );

    final decoratedRow = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: rowDecoration,
      padding: widget.innerRowElementsPadding,
      child: widget.onRowTap == null
          ? baseRow
          : InkWell(
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
    final actionsAreaWidth = mode == TableActionMode.group
        ? widget.actionWidth
        : widget.actionWidth * widget.actions.length;
    final actionWidgets = mode == TableActionMode.group
        ? <Widget>[_buildActionGroup(context)]
        : <Widget>[_buildFullActions(context, actionsAreaWidth)];

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
                actionsAreaWidth,
          ),
        ),
      ...actionWidgets,
    ];
  }

  Widget _buildFullActions(BuildContext context, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.actions.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              _buildInlineActionContent(context, widget.actions[index]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineActionContent(
    BuildContext context,
    TableAction<T> action,
  ) {
    return Tooltip(
      message: action.name,
      child: InkWell(
        onTap: action.isEnabled(widget.item, widget.rowIndex)
            ? () => unawaited(
                Future<void>.sync(
                  () => action.onTap(widget.item, widget.rowIndex),
                ),
              )
            : null,
        child: action.icon,
      ),
    );
  }

  Widget _buildActionGroup(BuildContext context) {
    return SizedBox(
      width: widget.actionWidth,
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        icon: widget.actionIcon ?? const Icon(Icons.more_horiz),
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
        onSelected: (index) {
          final action = widget.actions[index];
          if (!action.isEnabled(widget.item, widget.rowIndex)) return;
          unawaited(
            Future<void>.sync(() => action.onTap(widget.item, widget.rowIndex)),
          );
        },
        itemBuilder: (context) => [
          for (var index = 0; index < widget.actions.length; index++)
            PopupMenuItem<int>(
              value: index,
              enabled: widget.actions[index].isEnabled(
                widget.item,
                widget.rowIndex,
              ),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
    required this.onPointerSignalIntent,
    required this.child,
    required this.fixedChild,
    this.controller,
    this.wrapper,
  });

  final double viewportWidth;
  final double contentWidth;
  final double frozenWidth;
  final ValueNotifier<double> offset;
  final ValueChanged<PointerScrollEvent> onPointerSignalIntent;
  final Widget child;
  final Widget fixedChild;
  final ScrollController? controller;
  final Widget Function(Widget child)? wrapper;

  @override
  State<_FrozenHorizontalViewport> createState() =>
      _FrozenHorizontalViewportState();
}

class _FrozenHorizontalViewportState extends State<_FrozenHorizontalViewport> {
  late final ScrollController _internalController;
  bool _isSyncingOffset = false;
  bool _acceptHorizontalPointerSignal = true;

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
      (oldWidget.controller ?? _internalController).removeListener(
        _publishOffset,
      );
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
    if (_isSyncingOffset || !_controller.hasClients) return;
    final current = widget.offset.value;
    final next = _controller.offset;
    if ((current - next).abs() > .5) widget.offset.value = next;
  }

  void _syncOffset() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final next = widget.offset.value.clamp(0.0, max).toDouble();
    if ((_controller.offset - next).abs() <= .5) return;

    _isSyncingOffset = true;
    try {
      _controller.jumpTo(next);
    } finally {
      _isSyncingOffset = false;
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final delta = event.scrollDelta;
    final isHorizontal = delta.dx.abs() > delta.dy.abs();
    if (!isHorizontal) {
      _acceptHorizontalPointerSignal = false;
      scheduleMicrotask(() => _acceptHorizontalPointerSignal = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        SizedBox(
          width: widget.viewportWidth,
          child: Padding(
            padding: EdgeInsets.only(left: widget.frozenWidth),
            child: SingleChildScrollView(
              controller: _controller,
              physics: _PointerSignalAxisScrollPhysics(
                isEnabled: () => _acceptHorizontalPointerSignal,
              ),
              scrollDirection: Axis.horizontal,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: _handlePointerSignal,
                child: SizedBox(
                  width: math.max(0, widget.contentWidth - widget.frozenWidth),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
        if (widget.frozenWidth > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.frozenWidth,
            child: ClipRect(child: widget.fixedChild),
          ),
      ],
    );
    final pointerAwareViewport = Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          widget.onPointerSignalIntent(event);
        }
      },
      child: viewport,
    );

    return widget.wrapper?.call(pointerAwareViewport) ?? pointerAwareViewport;
  }
}

class _PointerSignalAxisScrollPhysics extends ScrollPhysics {
  const _PointerSignalAxisScrollPhysics({
    required this.isEnabled,
    super.parent,
  });

  final bool Function() isEnabled;

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return isEnabled() && super.shouldAcceptUserOffset(position);
  }

  @override
  _PointerSignalAxisScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _PointerSignalAxisScrollPhysics(
      isEnabled: isEnabled,
      parent: buildParent(ancestor),
    );
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
        SizedBox(width: 18, height: 18, child: FittedBox(child: action.icon)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            action.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
