import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_pagination/src/models/table_column_config.dart';

/// Columns whose [TableColumnConfig.name] starts with this prefix (action
/// columns, the settings column) are internal: always visible, never listed
/// in the column settings and always kept after the configurable columns.
const String tableInternalColumnPrefix = '__';

bool isInternalTableColumn(String name) =>
    name.startsWith(tableInternalColumnPrefix);

/// Whether [column] is excluded from the column settings and kept at the end.
bool isFixedTableColumn<T>(TableColumnConfig<T> column) =>
    column.fixed ||
    isInternalTableColumn(column.name) ||
    column.label.trim().isEmpty;

/// User customisation of a table: the order of the movable columns and the
/// columns that are hidden.
@immutable
class TableColumnLayout {
  const TableColumnLayout({
    this.order = const <String>[],
    this.hidden = const <String>{},
  });

  /// Names of the movable columns, left to right. Unknown names are ignored
  /// and columns missing from it keep their original relative order at the end.
  final List<String> order;
  final Set<String> hidden;

  static const TableColumnLayout defaults = TableColumnLayout();

  bool get isDefault => order.isEmpty && hidden.isEmpty;

  /// Resolves the columns to render.
  ///
  /// The first [frozenCount] configurable columns (from the columns passed by
  /// the screen) are locked: always visible and always first. Only the other
  /// columns follow [order] / [hidden].
  List<TableColumnConfig<T>> resolve<T>(
    List<TableColumnConfig<T>> columns,
    int frozenCount,
  ) {
    final configurable = <TableColumnConfig<T>>[
      for (final column in columns)
        if (!isFixedTableColumn(column)) column,
    ];
    final internal = <TableColumnConfig<T>>[
      for (final column in columns)
        if (isFixedTableColumn(column)) column,
    ];
    final frozen = frozenCount.clamp(0, configurable.length).toInt();
    final movable = orderedMovable<T>(configurable.skip(frozen).toList());

    return <TableColumnConfig<T>>[
      ...configurable.take(frozen),
      for (final column in movable)
        if (!hidden.contains(column.name)) column,
      ...internal,
    ];
  }

  /// [movable] sorted by [order]; columns missing from it keep their position.
  List<TableColumnConfig<T>> orderedMovable<T>(
    List<TableColumnConfig<T>> movable,
  ) {
    final byName = <String, TableColumnConfig<T>>{
      for (final column in movable) column.name: column,
    };
    final ordered = <TableColumnConfig<T>>[];
    for (final name in order) {
      final column = byName.remove(name);
      if (column != null) ordered.add(column);
    }
    return <TableColumnConfig<T>>[...ordered, ...byName.values];
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'order': order,
    'hidden': hidden.toList(growable: false),
  };

  factory TableColumnLayout.fromJson(Map<String, Object?> json) {
    List<String> strings(Object? value) => value is List
        ? value.whereType<String>().toList(growable: false)
        : const <String>[];
    return TableColumnLayout(
      order: strings(json['order']),
      hidden: strings(json['hidden']).toSet(),
    );
  }
}

/// Persistence for [TableColumnLayout]. Implement it to store the layout
/// somewhere else (e.g. per user, on the server).
abstract class TableColumnLayoutStore {
  Future<TableColumnLayout> load(String key);

  Future<void> save(String key, TableColumnLayout layout);

  Future<void> clear(String key);
}

class SharedPreferencesColumnLayoutStore implements TableColumnLayoutStore {
  const SharedPreferencesColumnLayoutStore();

  @override
  Future<TableColumnLayout> load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return TableColumnLayout.defaults;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return TableColumnLayout.defaults;
      return TableColumnLayout.fromJson(json);
    } catch (e) {
      debugPrint('[TableColumnLayout] Load error: $e');
      return TableColumnLayout.defaults;
    }
  }

  @override
  Future<void> save(String key, TableColumnLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(layout.toJson()));
    } catch (e) {
      debugPrint('[TableColumnLayout] Save error: $e');
    }
  }

  @override
  Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[TableColumnLayout] Clear error: $e');
    }
  }
}

/// Storage key derived from the columns passed to the table, so a different
/// column set never reuses an outdated layout.
String tableColumnLayoutKey<T>(
  List<TableColumnConfig<T>> columns, {
  String? prefix,
}) {
  final names = [
    for (final column in columns)
      if (!isFixedTableColumn(column)) column.name,
  ].join('|');
  var hash = 0x811c9dc5;
  for (final unit in names.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return 'table_columns_${prefix ?? 'default'}_${hash.toRadixString(16)}';
}
