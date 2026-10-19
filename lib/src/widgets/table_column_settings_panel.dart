import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_pagination/src/models/table_column_config.dart';
import 'package:table_pagination/src/models/table_column_layout.dart';
import 'package:table_pagination/src/models/table_column_settings.dart';

/// Header icon that opens the column settings panel below itself.
class TableColumnSettingsButton<T> extends StatelessWidget {
  const TableColumnSettingsButton({
    super.key,
    required this.columns,
    required this.frozenCount,
    required this.layout,
    required this.settings,
    required this.onApply,
  });

  final List<TableColumnConfig<T>> columns;
  final int frozenCount;
  final TableColumnLayout layout;
  final TableColumnSettings settings;
  final ValueChanged<TableColumnLayout> onApply;

  @override
  Widget build(BuildContext context) {
    final primary =
        settings.primaryColor ?? Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: settings.texts.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child:
                settings.icon ??
                Icon(Icons.view_column_outlined, size: 20, color: primary),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final configurable = [
      for (final column in columns)
        if (!isFixedTableColumn(column)) column,
    ];
    final frozen = frozenCount.clamp(0, configurable.length).toInt();

    showDialog<void>(
      context: context,
      barrierLabel: settings.texts.tooltip,
      builder: (dialogContext) {
        final height = MediaQuery.sizeOf(dialogContext).height;
        final panel = _ColumnSettingsPanel<T>(
          frozen: configurable.take(frozen).toList(),
          defaultMovable: configurable.skip(frozen).toList(),
          layout: layout,
          settings: settings,
          maxHeight: (height * 0.8).clamp(240, 640),
          onApply: (value) {
            Navigator.of(dialogContext).pop();
            onApply(value);
          },
        );
        final dialogBuilder = settings.dialogBuilder;
        if (dialogBuilder != null) {
          return dialogBuilder(dialogContext, panel);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: Center(child: panel),
        );
      },
    );
  }
}

class _ColumnSettingsPanel<T> extends StatefulWidget {
  const _ColumnSettingsPanel({
    required this.frozen,
    required this.defaultMovable,
    required this.layout,
    required this.settings,
    required this.maxHeight,
    required this.onApply,
  });

  final List<TableColumnConfig<T>> frozen;
  final List<TableColumnConfig<T>> defaultMovable;
  final TableColumnLayout layout;
  final TableColumnSettings settings;
  final double maxHeight;
  final ValueChanged<TableColumnLayout> onApply;

  @override
  State<_ColumnSettingsPanel<T>> createState() =>
      _ColumnSettingsPanelState<T>();
}

class _ColumnSettingsPanelState<T> extends State<_ColumnSettingsPanel<T>> {
  late List<TableColumnConfig<T>> _movable;
  late Set<String> _hidden;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _movable = widget.layout.orderedMovable<T>(widget.defaultMovable);
    _hidden = {
      for (final column in widget.defaultMovable)
        if (widget.layout.hidden.contains(column.name)) column.name,
    };
    _initialOrder = [for (final column in _movable) column.name].join('|');
    _initialHidden = _hidden.toList()..sort();
    _search.addListener(() => setState(() {}));
  }

  late final String _initialOrder;
  late final List<String> _initialHidden;

  /// Apply is only available once the order or visibility differs from what
  /// the table currently shows.
  bool get _isDirty {
    final order = [for (final column in _movable) column.name].join('|');
    final hidden = _hidden.toList()..sort();
    return order != _initialOrder || !listEquals(hidden, _initialHidden);
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String _label(TableColumnConfig<T> column) =>
      column.label.trim().isEmpty ? column.name : column.label;

  bool _matches(TableColumnConfig<T> column) {
    final query = _search.text.trim().toLowerCase();
    return query.isEmpty || _label(column).toLowerCase().contains(query);
  }

  void _reset() {
    setState(() {
      _movable = [...widget.defaultMovable];
      _hidden = <String>{};
    });
  }

  void _apply() {
    final layout = TableColumnLayout(
      order: [for (final column in _movable) column.name],
      hidden: _hidden,
    );
    final isOriginal =
        _hidden.isEmpty &&
        [for (final c in _movable) c.name].join('|') ==
            [for (final c in widget.defaultMovable) c.name].join('|');
    widget.onApply(isOriginal ? TableColumnLayout.defaults : layout);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      _movable.insert(newIndex, _movable.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.settings;
    final surface = s.surfaceColor ?? theme.colorScheme.surface;
    final border = s.borderColor ?? theme.dividerColor;
    final searching = _search.text.trim().isNotEmpty;
    final frozen = widget.frozen.where(_matches).toList();
    final movable = [
      for (final c in _movable)
        if (_matches(c)) c,
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Material(
        color: surface,
        elevation: s.panelElevation,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
        child: SizedBox(
          width: s.panelWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(context, border),
                _buildSearch(context),
                Flexible(
                  child: frozen.isEmpty && movable.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.texts.empty,
                            style: TextStyle(color: _muted(context)),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            for (final column in frozen)
                              _ColumnRow(
                                label: _label(column),
                                checked: true,
                                locked: true,
                                settings: s,
                                handle: null,
                              ),
                            if (searching)
                              for (final column in movable)
                                _buildRow(column, handle: null)
                            else
                              _buildReorderable(),
                          ],
                        ),
                ),
                _buildFooter(context, border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _muted(BuildContext context) =>
      widget.settings.mutedColor ??
      Theme.of(context).colorScheme.onSurfaceVariant;

  Widget _buildReorderable() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _movable.length,
      onReorderItem: _reorder,
      proxyDecorator: (child, _, _) => Material(
        color: widget.settings.surfaceColor ?? Colors.transparent,
        elevation: 4,
        child: child,
      ),
      itemBuilder: (context, index) {
        final column = _movable[index];
        return KeyedSubtree(
          key: ValueKey(column.name),
          child: _buildRow(
            column,
            handle: ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(Icons.drag_indicator, size: 16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(TableColumnConfig<T> column, {required Widget? handle}) {
    final checked = !_hidden.contains(column.name);
    return _ColumnRow(
      label: _label(column),
      checked: checked,
      locked: false,
      settings: widget.settings,
      handle: handle,
      onChanged: (value) => setState(() {
        value ? _hidden.remove(column.name) : _hidden.add(column.name);
      }),
    );
  }

  Widget _buildTitle(BuildContext context, Color border) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.settings.horizontalPadding ?? 12,
        12,
        4,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.settings.texts.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  widget.settings.titleStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        widget.settings.textColor ??
                        theme.colorScheme.onSurface,
                  ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            color: _muted(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final muted = _muted(context);
    final h = widget.settings.horizontalPadding ?? 8;
    final custom = widget.settings.searchBuilder;
    return Padding(
      padding: EdgeInsets.fromLTRB(h, 8, h, 4),
      child: custom != null
          ? custom(context, _search, widget.settings.texts.searchHint)
          : TextField(
              controller: _search,
              focusNode: _searchFocus,
              autofocus: true,
              style: TextStyle(
                fontSize: 13,
                color:
                    widget.settings.textColor ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.settings.texts.searchHint,
                hintStyle: TextStyle(fontSize: 13, color: muted),
                prefixIcon: Icon(Icons.search, size: 16, color: muted),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        widget.settings.borderColor ??
                        Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFooter(BuildContext context, Color border) {
    final primary =
        widget.settings.primaryColor ?? Theme.of(context).colorScheme.primary;
    final texts = widget.settings.texts;
    final buttonBuilder = widget.settings.buttonBuilder;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.settings.horizontalPadding ?? 8,
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment: widget.settings.actionsAlignment,
          children: [
            Flexible(
              child:
                  buttonBuilder?.call(
                    context,
                    TableColumnSettingsButtonType.reset,
                    texts.reset,
                    _reset,
                  ) ??
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: _muted(context),
                    ),
                    child: Text(
                      texts.reset,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
            ),
            if (widget.settings.actionsAlignment ==
                MainAxisAlignment.spaceBetween)
              const Spacer()
            else
              const SizedBox(width: 10),
            Flexible(
              child:
                  buttonBuilder?.call(
                    context,
                    TableColumnSettingsButtonType.apply,
                    texts.apply,
                    _isDirty ? _apply : null,
                  ) ??
                  FilledButton(
                    onPressed: _isDirty ? _apply : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      texts.apply,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnRow extends StatefulWidget {
  const _ColumnRow({
    required this.label,
    required this.checked,
    required this.locked,
    required this.settings,
    required this.handle,
    this.onChanged,
  });

  final String label;
  final bool checked;
  final bool locked;
  final TableColumnSettings settings;
  final Widget? handle;
  final ValueChanged<bool>? onChanged;

  @override
  State<_ColumnRow> createState() => _ColumnRowState();
}

class _ColumnRowState extends State<_ColumnRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.settings;
    final primary = s.primaryColor ?? theme.colorScheme.primary;
    final muted = s.mutedColor ?? theme.colorScheme.onSurfaceVariant;
    final text = s.textColor ?? theme.colorScheme.onSurface;
    final enabled = !widget.locked;
    final hover = s.hoverColor ?? primary.withValues(alpha: 0.06);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => widget.onChanged?.call(!widget.checked) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            padding: const EdgeInsets.only(left: 4, right: 8),
            decoration: BoxDecoration(
              color: enabled && _hovered ? hover : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: IconTheme(
                    data: IconThemeData(color: muted),
                    child: widget.handle ?? const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: widget.checked,
                    onChanged: enabled
                        ? (v) => widget.onChanged?.call(v ?? false)
                        : null,
                    activeColor: primary,
                    side: BorderSide(color: muted),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.checked ? text : muted,
                    ),
                  ),
                ),
                if (widget.locked)
                  Icon(Icons.lock_outline, size: 13, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
