import 'package:flutter_test/flutter_test.dart';
import 'package:table_pagination/table_pagination.dart';

List<TableColumnConfig<int>> _columns() => [
  for (final name in ['a', 'b', 'c', 'd', '__actions'])
    TableColumnConfig<int>(name: name, label: name),
];

List<String> _names(List<TableColumnConfig<int>> columns) => [
  for (final column in columns) column.name,
];

void main() {
  group('TableColumnLayout.resolve', () {
    test('defaults keep every column', () {
      final result = TableColumnLayout.defaults.resolve<int>(_columns(), 1);
      expect(_names(result), ['a', 'b', 'c', 'd', '__actions']);
    });

    test('frozen columns cannot be hidden or moved', () {
      const layout = TableColumnLayout(
        order: ['d', 'a', 'c'],
        hidden: {'a', 'c'},
      );
      final result = layout.resolve<int>(_columns(), 1);
      expect(_names(result), ['a', 'd', 'b', '__actions']);
    });

    test('unknown names are ignored and new columns keep their order', () {
      const layout = TableColumnLayout(order: ['x', 'd'], hidden: {'zzz'});
      final result = layout.resolve<int>(_columns(), 1);
      expect(_names(result), ['a', 'd', 'b', 'c', '__actions']);
    });

    test(
      'fixed and blank-label columns stay last and are not configurable',
      () {
        final columns = [
          TableColumnConfig<int>(name: 'a', label: 'a'),
          TableColumnConfig<int>(name: 'edit', label: ''),
          TableColumnConfig<int>(name: 'b', label: 'b'),
          TableColumnConfig<int>(
            name: 'actions',
            label: 'Actions',
            fixed: true,
          ),
        ];
        const layout = TableColumnLayout(order: ['b'], hidden: {'edit'});
        final result = layout.resolve<int>(columns, 0);
        expect(_names(result), ['b', 'a', 'edit', 'actions']);
        expect(isFixedTableColumn(columns[1]), isTrue);
      },
    );

    test('json round trip', () {
      const layout = TableColumnLayout(order: ['c', 'b'], hidden: {'d'});
      final copy = TableColumnLayout.fromJson(layout.toJson());
      expect(copy.order, ['c', 'b']);
      expect(copy.hidden, {'d'});
    });

    test('storage key depends on the passed columns', () {
      final a = tableColumnLayoutKey<int>(_columns());
      final b = tableColumnLayoutKey<int>(_columns().take(3).toList());
      expect(a, isNot(b));
      expect(a, tableColumnLayoutKey<int>(_columns()));
    });
  });
}
