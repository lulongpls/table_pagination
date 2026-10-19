import 'package:flutter/material.dart';
import 'package:table_pagination/src/models/table_column_layout.dart';

typedef TableColumnSettingsDialogBuilder =
    Widget Function(BuildContext context, Widget panel);

enum TableColumnSettingsButtonType { reset, apply }

typedef TableColumnSettingsButtonBuilder =
    Widget Function(
      BuildContext context,
      TableColumnSettingsButtonType type,
      String label,
      VoidCallback? onPressed,
    );

/// Builds the column search field. The panel filters the list from
/// [controller], so the builder only has to render a field bound to it.
typedef TableColumnSettingsSearchBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController controller,
      String hint,
    );

class TableColumnSettingsTexts {
  const TableColumnSettingsTexts({
    this.tooltip = 'Columns',
    this.title = 'Sort & show/hide columns',
    this.searchHint = 'Search columns...',
    this.reset = 'Reset',
    this.apply = 'Apply',
    this.empty = 'No columns found',
  });

  final String tooltip;

  /// Heading shown at the top of the panel.
  final String title;
  final String searchHint;
  final String reset;
  final String apply;
  final String empty;
}

/// Opt-in "show / hide / reorder columns" panel opened from an icon fixed to
/// the header's right edge. Colours fall back to the current [Theme].
class TableColumnSettings {
  const TableColumnSettings({
    this.storageKey,
    this.texts = const TableColumnSettingsTexts(),
    this.store = const SharedPreferencesColumnLayoutStore(),
    this.icon,
    this.primaryColor,
    this.surfaceColor,
    this.borderColor,
    this.textColor,
    this.mutedColor,
    this.hoverColor,
    this.panelWidth = 240,
    this.triggerWidth = 44,
    this.dialogBuilder,
    this.buttonBuilder,
    this.searchBuilder,
    this.actionsAlignment = MainAxisAlignment.spaceBetween,
    this.panelElevation = 8,
    this.titleStyle,
    this.horizontalPadding,
  });

  /// Optional prefix to tell apart two tables that share the same columns.
  final String? storageKey;
  final TableColumnSettingsTexts texts;
  final TableColumnLayoutStore store;
  final Widget? icon;
  final Color? primaryColor;
  final Color? surfaceColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? mutedColor;
  final Color? hoverColor;
  final double panelWidth;

  /// Width reserved for the settings trigger fixed at the table's right edge.
  final double triggerWidth;

  /// Wraps the settings panel in the project's dialog implementation.
  ///
  /// This can provide an app-specific [Theme] or dialog shell. When omitted,
  /// the package uses a transparent Material [Dialog].
  final TableColumnSettingsDialogBuilder? dialogBuilder;

  /// Builds the reset and apply controls, allowing the host project to use
  /// its shared button component. Inspect [type] to select the proper variant.
  final TableColumnSettingsButtonBuilder? buttonBuilder;

  /// Replaces the built-in search field (e.g. with the project's search box).
  final TableColumnSettingsSearchBuilder? searchBuilder;

  /// Footer alignment of the reset / apply buttons. `end` puts them together
  /// on the right like a regular form dialog.
  final MainAxisAlignment actionsAlignment;

  /// Elevation of the panel surface; use 0 inside a host dialog shell.
  final double panelElevation;

  /// Style of the heading; falls back to a small bold [textColor] text.
  final TextStyle? titleStyle;

  /// Left/right padding of the title, search and footer.
  final double? horizontalPadding;
}
