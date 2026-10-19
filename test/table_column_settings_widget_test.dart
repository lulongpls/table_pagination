import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_pagination/table_pagination.dart';

class _MemoryColumnLayoutStore implements TableColumnLayoutStore {
  TableColumnLayout layout = TableColumnLayout.defaults;
  int clearCount = 0;

  @override
  Future<TableColumnLayout> load(String key) async => layout;

  @override
  Future<void> save(String key, TableColumnLayout layout) async {
    this.layout = layout;
  }

  @override
  Future<void> clear(String key) async {
    clearCount++;
    layout = TableColumnLayout.defaults;
  }
}

List<TableColumnConfig<int>> _wideColumns() => [
  for (final name in ['A', 'B', 'C', 'D'])
    textColumn<int>(
      name: name.toLowerCase(),
      label: name,
      width: 220,
      valueGetter: (item) => '$name$item',
    ),
];

Widget _table({required TableColumnSettings settings}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320,
        height: 300,
        child: GenericTable<int>(
          fetcher: (_) async => const PagedResult(items: [1], totalCount: 1),
          columns: _wideColumns(),
          columnSettings: settings,
        ),
      ),
    ),
  );
}

void main() {
  group('GenericTable column settings', () {
    testWidgets('uses the host dialog and shared button builders', (
      tester,
    ) async {
      final store = _MemoryColumnLayoutStore();
      final builtButtonTypes = <TableColumnSettingsButtonType>[];
      final projectTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ).copyWith(surface: Colors.deepPurple),
      );

      await tester.pumpWidget(
        _table(
          settings: TableColumnSettings(
            store: store,
            dialogBuilder: (context, panel) => Theme(
              data: projectTheme,
              child: Dialog(
                key: const ValueKey('project-column-dialog'),
                child: panel,
              ),
            ),
            buttonBuilder: (context, type, label, onPressed) {
              builtButtonTypes.add(type);
              return ElevatedButton(
                key: ValueKey('app-button-${type.name}'),
                onPressed: onPressed,
                child: Text(label),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_column_outlined));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('project-column-dialog')), findsOne);
      expect(find.byKey(const ValueKey('app-button-reset')), findsOne);
      expect(find.byKey(const ValueKey('app-button-apply')), findsOne);
      expect(
        builtButtonTypes,
        containsAll(<TableColumnSettingsButtonType>[
          TableColumnSettingsButtonType.reset,
          TableColumnSettingsButtonType.apply,
        ]),
      );
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .any((material) => material.color == Colors.deepPurple),
        isTrue,
      );

      final apply = find.byKey(const ValueKey('app-button-apply'));
      // Nothing changed yet: apply stays disabled.
      expect(tester.widget<ElevatedButton>(apply).onPressed, isNull);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('project-column-dialog')),
          matching: find.text('B'),
        ),
      );
      await tester.pump();
      expect(tester.widget<ElevatedButton>(apply).onPressed, isNotNull);

      await tester.tap(apply);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('project-column-dialog')), findsNothing);
      expect(store.layout.hidden, contains('b'));
    });

    testWidgets('keeps the settings trigger fixed at the table right edge', (
      tester,
    ) async {
      final store = _MemoryColumnLayoutStore();
      const triggerKey = ValueKey('column-settings-trigger');

      await tester.pumpWidget(
        _table(
          settings: TableColumnSettings(
            store: store,
            icon: const Icon(Icons.tune, key: triggerKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final beforeTrigger = tester.getCenter(find.byKey(triggerKey));
      final beforeFirstHeader = tester.getCenter(find.text('A'));
      final horizontalScroll = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .firstWhere((view) => view.scrollDirection == Axis.horizontal);
      expect(
        horizontalScroll.controller!.position.maxScrollExtent,
        greaterThan(0),
      );

      horizontalScroll.controller!.jumpTo(
        horizontalScroll.controller!.position.maxScrollExtent,
      );
      await tester.pump();

      final afterTrigger = tester.getCenter(find.byKey(triggerKey));
      final afterFirstHeader = tester.getCenter(find.text('A'));
      expect(afterTrigger.dx, closeTo(beforeTrigger.dx, 0.1));
      expect(afterFirstHeader.dx, lessThan(beforeFirstHeader.dx));
      expect(afterTrigger.dx, lessThanOrEqualTo(320));
    });
  });
}
