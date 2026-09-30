import 'dart:async';

import 'package:flutter/material.dart';

/// Determines how row actions are rendered beside the table rows.
enum TableActionMode {
  /// Render all actions when there are two or fewer, otherwise use a menu.
  defaultMode,

  /// Render every action as an inline icon.
  full,

  /// Always render the actions menu.
  group,
}

/// Backwards-friendly alias for consumers that prefer the plural name.
typedef TableActionsMode = TableActionMode;

typedef TableActionCallback<T> = FutureOr<void> Function(T item, int index);
typedef TableActionEnabledBuilder<T> = bool Function(T item, int index);

/// One action that can be rendered inline or inside a row context menu.
class TableAction<T> {
  const TableAction({
    required this.name,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.enabledBuilder,
  });

  /// Text shown in the actions menu.
  final String name;

  /// Icon shown inline and in the actions menu.
  final Widget icon;

  /// Called with the row item and its current index.
  final TableActionCallback<T> onTap;

  /// Whether this action can currently be selected.
  final bool enabled;

  /// Resolves whether this action can be selected for a specific row.
  ///
  /// The static [enabled] flag is still respected and this builder adds a
  /// row-specific condition using the item and its current index.
  final TableActionEnabledBuilder<T>? enabledBuilder;

  bool isEnabled(T item, int index) {
    return enabled && (enabledBuilder?.call(item, index) ?? true);
  }

  String get label => name;
}
