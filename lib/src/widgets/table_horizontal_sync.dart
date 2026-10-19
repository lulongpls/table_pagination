import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontal scroll state of the table, exposed to row builders.
class TableScrollScope extends InheritedWidget {
  const TableScrollScope({
    super.key,
    required this.offset,
    required this.contentWidth,
    required this.viewportWidth,
    required super.child,
  });

  /// Shared horizontal offset; writing it scrolls the whole table.
  final ValueNotifier<double> offset;
  final double contentWidth;
  final double viewportWidth;

  static TableScrollScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TableScrollScope>();

  @override
  bool updateShouldNotify(TableScrollScope old) =>
      old.offset != offset ||
      old.contentWidth != contentWidth ||
      old.viewportWidth != viewportWidth;
}

/// Lays [child] out as wide as the table content and keeps it scrolled with
/// the table rows (e.g. an expanded detail panel under a row), so row + panel
/// behave as one row. Dragging it or using the horizontal wheel / Shift+wheel
/// over it scrolls the table too. Outside a table it just shows [child].
class TableHorizontalSync extends StatefulWidget {
  const TableHorizontalSync({super.key, required this.child});

  final Widget child;

  @override
  State<TableHorizontalSync> createState() => _TableHorizontalSyncState();
}

class _TableHorizontalSyncState extends State<TableHorizontalSync> {
  final ScrollController _controller = ScrollController();
  ValueNotifier<double>? _offset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = TableScrollScope.maybeOf(context)?.offset;
    if (next == _offset) return;
    _offset?.removeListener(_sync);
    next?.addListener(_sync);
    _offset = next;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final offset = _offset;
    if (offset == null || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    _controller.jumpTo(offset.value.clamp(0.0, max).toDouble());
  }

  void _scrollBy(double delta, TableScrollScope scope) {
    final max = (scope.contentWidth - scope.viewportWidth).clamp(
      0.0,
      double.infinity,
    );
    final next = (scope.offset.value + delta).clamp(0.0, max).toDouble();
    if (next != scope.offset.value) scope.offset.value = next;
  }

  void _onPointerSignal(PointerSignalEvent event, TableScrollScope scope) {
    if (event is! PointerScrollEvent) return;
    final shift = HardwareKeyboard.instance.logicalKeysPressed.any(
      (k) =>
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight,
    );
    final delta = event.scrollDelta;
    final horizontal = shift && event.kind == PointerDeviceKind.mouse
        ? delta.dy
        : (delta.dx.abs() > delta.dy.abs() ? delta.dx : 0.0);
    if (horizontal == 0) return; // vertical: let the table list scroll
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _scrollBy(horizontal, scope),
    );
  }

  @override
  void dispose() {
    _offset?.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = TableScrollScope.maybeOf(context);
    if (scope == null) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = scope.contentWidth > constraints.maxWidth
            ? scope.contentWidth
            : constraints.maxWidth;
        return Listener(
          onPointerSignal: (e) => _onPointerSignal(e, scope),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) => _scrollBy(-d.delta.dx, scope),
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(width: width, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
