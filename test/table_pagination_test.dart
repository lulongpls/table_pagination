import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:table_pagination/table_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenericTableCubit', () {
    test('fetchFirstPage loads the first page', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        pageSize: 2,
        fetcher: (query) async {
          queries.add(query);
          return const PagedResult(items: [1, 2], totalCount: 5);
        },
      );

      await cubit.fetchFirstPage();

      expect(queries, [const TableQuery(page: 1, pageSize: 2)]);
      expect(cubit.state.status, TableStatus.success);
      expect(cubit.state.items, [1, 2]);
      expect(cubit.state.totalPages, 3);

      await cubit.close();
    });

    test('loadMore appends rows and stops at max', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        mode: TableMode.loadMore,
        pageSize: 2,
        fetcher: (query) async {
          queries.add(query);
          return switch (query.page) {
            1 => const PagedResult(items: [1, 2], totalCount: 3),
            2 => const PagedResult(items: [3], totalCount: 3),
            _ => const PagedResult(items: <int>[], totalCount: 3),
          };
        },
      );

      await cubit.fetchFirstPage();
      await cubit.loadMore();
      await cubit.loadMore();

      expect(queries.map((query) => query.page), [1, 2]);
      expect(cubit.state.items, [1, 2, 3]);
      expect(cubit.state.hasReachedMax, isTrue);

      await cubit.close();
    });

    test('goToPage fetches the selected page in pagination mode', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        pageSize: 2,
        fetcher: (query) async {
          queries.add(query);
          return PagedResult(items: [query.page], totalCount: 6);
        },
      );

      await cubit.fetchFirstPage();
      await cubit.goToPage(3);

      expect(queries.map((query) => query.page), [1, 3]);
      expect(cubit.state.page, 3);
      expect(cubit.state.items, [3]);

      await cubit.close();
    });

    test('sort toggles direction and reloads from page one', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        pageSize: 10,
        fetcher: (query) async {
          queries.add(query);
          return const PagedResult(items: [1], totalCount: 1);
        },
      );

      await cubit.sort('name');
      await cubit.sort('name');

      expect(queries.length, 2);
      expect(queries.first.sortBy, 'name');
      expect(queries.first.ascending, isTrue);
      expect(queries.last.sortBy, 'name');
      expect(queries.last.ascending, isFalse);
      expect(queries.last.sorts, [
        const TableSort(
          field: 'name',
          direction: TableSortDirection.descending,
        ),
      ]);
      expect(cubit.state.page, 1);

      await cubit.close();
    });

    test('sort supports multiple online sort fields', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (query) async {
          queries.add(query);
          return const PagedResult(items: [1], totalCount: 1);
        },
      );

      await cubit.sort('name');
      await cubit.sort('email');

      expect(queries.last.sorts, const [
        TableSort(field: 'name'),
        TableSort(field: 'email'),
      ]);
      expect(cubit.state.sortPriority('name'), 1);
      expect(cubit.state.sortPriority('email'), 2);

      await cubit.close();
    });

    test(
      'local sort updates items immediately without fetching again',
      () async {
        var fetchCount = 0;
        final cubit = GenericTableCubit<int>(
          autoFetchOnCreate: false,
          sortMode: TableSortMode.local,
          fetcher: (_) async {
            fetchCount++;
            return const PagedResult(items: [3, 1, 2], totalCount: 3);
          },
        );

        await cubit.fetchFirstPage();
        await cubit.sort(
          'value',
          localComparatorBuilder: (sorts) {
            return (left, right) => left.compareTo(right);
          },
        );

        expect(fetchCount, 1);
        expect(cubit.state.items, [1, 2, 3]);
        expect(cubit.state.sorts, const [TableSort(field: 'value')]);

        await cubit.close();
      },
    );

    test('loadMore always sorts online even when sortMode is local', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        mode: TableMode.loadMore,
        sortMode: TableSortMode.local,
        fetcher: (query) async {
          queries.add(query);
          return const PagedResult(items: [1], totalCount: 3);
        },
      );

      await cubit.fetchFirstPage();
      await cubit.sort(
        'value',
        localComparatorBuilder: (_) {
          return (left, right) => right.compareTo(left);
        },
      );

      expect(queries.length, 2);
      expect(queries.last.sorts, const [TableSort(field: 'value')]);
      expect(cubit.state.page, 1);

      await cubit.close();
    });

    test('online sort keeps existing rows while loading', () async {
      final completers = <Completer<PagedResult<int>>>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) {
          final completer = Completer<PagedResult<int>>();
          completers.add(completer);
          return completer.future;
        },
      );

      final firstLoad = cubit.fetchFirstPage();
      completers.single.complete(
        const PagedResult(items: [2, 1], totalCount: 2),
      );
      await firstLoad;

      final sortFuture = cubit.sort('value');

      expect(cubit.state.status, TableStatus.loading);
      expect(cubit.state.items, [2, 1]);
      expect(cubit.state.isFirstLoad, isFalse);

      completers.last.complete(const PagedResult(items: [1, 2], totalCount: 2));
      await sortFuture;

      expect(cubit.state.items, [1, 2]);

      await cubit.close();
    });

    test('applyFilters replaces filters and reloads', () async {
      final queries = <TableQuery>[];
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (query) async {
          queries.add(query);
          return const PagedResult(items: [1], totalCount: 1);
        },
      );

      await cubit.applyFilters({'status': 'active'});

      expect(queries.single.filters, {'status': 'active'});
      expect(cubit.state.filters, {'status': 'active'});

      await cubit.close();
    });

    test('addItem inserts a local item and increases total count', () async {
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) async {
          return const PagedResult(items: [1, 3], totalCount: 2);
        },
      );

      await cubit.fetchFirstPage();
      cubit.addItem(2, index: 1);

      expect(cubit.state.items, [1, 2, 3]);
      expect(cubit.state.totalCount, 3);
      expect(cubit.state.status, TableStatus.success);

      await cubit.close();
    });

    test('updateItem updates the matching local item', () async {
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) async {
          return const PagedResult(items: [1, 2, 3], totalCount: 3);
        },
      );

      await cubit.fetchFirstPage();
      cubit.updateItem((item) => item == 2, (_) => 20);

      expect(cubit.state.items, [1, 20, 3]);
      expect(cubit.state.totalCount, 3);
      expect(cubit.state.status, TableStatus.success);

      await cubit.close();
    });

    test(
      'removeItem removes the matching local item and decreases total count',
      () async {
        final cubit = GenericTableCubit<int>(
          autoFetchOnCreate: false,
          fetcher: (_) async {
            return const PagedResult(items: [1, 2, 3], totalCount: 3);
          },
        );

        await cubit.fetchFirstPage();
        cubit.removeItem((item) => item == 2);

        expect(cubit.state.items, [1, 3]);
        expect(cubit.state.totalCount, 2);
        expect(cubit.state.status, TableStatus.success);

        await cubit.close();
      },
    );
  });

  group('PaginationFooter', () {
    testWidgets('supports project label and selected page colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationFooter(
              page: 2,
              totalPages: 4,
              totalCount: 40,
              pageSize: 10,
              onPageChanged: (_) {},
              labelBuilder: (page, totalPages, totalCount) {
                return 'Trang $page/$totalPages · $totalCount tài khoản';
              },
              style: const PaginationFooterStyle(
                backgroundColor: Color(0xFFF8FAF9),
                selectedPageBackgroundColor: Color(0xFFE93D69),
                selectedPageForegroundColor: Colors.white,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trang 2/4 · 40 tài khoản'), findsOneWidget);

      final material = tester.widget<Material>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.color == const Color(0xFFF8FAF9),
        ),
      );
      expect(material.color, const Color(0xFFF8FAF9));

      final selectedButton = tester.widget<TextButton>(
        find.ancestor(of: find.text('2'), matching: find.byType(TextButton)),
      );
      expect(
        selectedButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFFE93D69),
      );
      expect(
        selectedButton.style?.foregroundColor?.resolve({WidgetState.disabled}),
        Colors.white,
      );
    });
  });

  group('GenericTable sticky footer', () {
    testWidgets('uses a loose table body when stickyFooter is enabled', (
      tester,
    ) async {
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) async => const PagedResult(items: [1], totalCount: 1),
      );

      await cubit.fetchFirstPage();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: GenericTable<int>.withCubit(
                cubit: cubit,
                stickyFooter: true,
                columns: [
                  textColumn<int>(
                    name: 'value',
                    label: 'Value',
                    valueGetter: (item) => item,
                  ),
                ],
                footerBuilder: (context, state, cubit) =>
                    const SizedBox(height: 40, child: Text('Footer')),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('generic-table-sticky-footer-body')),
        findsOneWidget,
      );
      expect(find.text('Footer'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('keeps footer outside horizontal table scroll', (tester) async {
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) async => const PagedResult(items: [1], totalCount: 1),
      );
      await cubit.fetchFirstPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 400,
              child: GenericTable<int>.withCubit(
                cubit: cubit,
                columns: [
                  textColumn<int>(
                    name: 'first',
                    label: 'First',
                    width: 180,
                    valueGetter: (item) => item,
                  ),
                  textColumn<int>(
                    name: 'second',
                    label: 'Second',
                    width: 180,
                    valueGetter: (item) => item + 1,
                  ),
                  textColumn<int>(
                    name: 'third',
                    label: 'Third',
                    width: 180,
                    valueGetter: (item) => item + 2,
                  ),
                ],
                footerBuilder: (context, state, cubit) =>
                    const SizedBox(height: 40, child: Text('Footer')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Footer'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Footer'),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );

      final footerBefore = tester.getCenter(find.text('Footer')).dx;
      final headerScrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      expect(
        headerScrollView.controller!.position.maxScrollExtent,
        greaterThan(0),
      );

      headerScrollView.controller!.jumpTo(100);
      await tester.pump();

      expect(
        tester.getCenter(find.text('Footer')).dx,
        closeTo(footerBefore, 0.1),
      );

      await cubit.close();
    });
  });

  group('GenericTable row actions', () {
    Future<GenericTableCubit<int>> createCubit() async {
      final cubit = GenericTableCubit<int>(
        autoFetchOnCreate: false,
        fetcher: (_) async => const PagedResult(items: [42], totalCount: 1),
      );
      await cubit.fetchFirstPage();
      return cubit;
    }

    List<TableColumnConfig<int>> columns() {
      return [
        textColumn<int>(
          name: 'value',
          label: 'Value',
          valueGetter: (item) => item,
        ),
      ];
    }

    testWidgets('default mode groups more than two actions', (tester) async {
      final cubit = await createCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericTable<int>.withCubit(
              cubit: cubit,
              columns: columns(),
              actions: [
                TableAction<int>(
                  name: 'Edit',
                  icon: const Icon(Icons.edit),
                  onTap: (_, _) {},
                ),
                TableAction<int>(
                  name: 'Delete',
                  icon: const Icon(Icons.delete),
                  onTap: (_, _) {},
                ),
                TableAction<int>(
                  name: 'Reset',
                  icon: const Icon(Icons.refresh),
                  onTap: (_, _) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsNothing);

      await cubit.close();
    });

    testWidgets('full mode passes the row item and index to the callback', (
      tester,
    ) async {
      final cubit = await createCubit();
      int? receivedItem;
      int? receivedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericTable<int>.withCubit(
              cubit: cubit,
              columns: columns(),
              actionMode: TableActionMode.full,
              actions: [
                TableAction<int>(
                  name: 'Edit',
                  icon: const Icon(Icons.edit),
                  onTap: (item, index) {
                    receivedItem = item;
                    receivedIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      expect(receivedItem, 42);
      expect(receivedIndex, 0);

      await cubit.close();
    });

    testWidgets('supports an actions column title and width override', (
      tester,
    ) async {
      final cubit = await createCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericTable<int>.withCubit(
              cubit: cubit,
              columns: columns(),
              actionsColumnTitle: 'Actions',
              actionsColumnWidth: 140,
              actions: [
                TableAction<int>(
                  name: 'Edit',
                  icon: const Icon(Icons.edit),
                  onTap: (_, _) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);
      final actionHeader = tester.widget<SizedBox>(
        find
            .ancestor(of: find.text('Actions'), matching: find.byType(SizedBox))
            .first,
      );
      expect(actionHeader.width, 140);

      await cubit.close();
    });

    testWidgets('secondary click opens the row actions menu', (tester) async {
      final cubit = await createCubit();
      int? receivedItem;
      int? receivedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericTable<int>.withCubit(
              cubit: cubit,
              columns: columns(),
              actions: [
                TableAction<int>(
                  name: 'Delete',
                  icon: const Icon(Icons.delete),
                  onTap: (item, index) {
                    receivedItem = item;
                    receivedIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('42'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      expect(receivedItem, 42);
      expect(receivedIndex, 0);

      await cubit.close();
    });

    testWidgets('frozen columns render without changing row callbacks', (
      tester,
    ) async {
      final cubit = await createCubit();
      int? tappedItem;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 400,
              child: GenericTable<int>.withCubit(
                cubit: cubit,
                frozenColumnCount: 2,
                columns: [
                  textColumn<int>(
                    name: 'first',
                    label: 'First',
                    width: 120,
                    valueGetter: (item) => item,
                  ),
                  textColumn<int>(
                    name: 'second',
                    label: 'Second',
                    width: 120,
                    valueGetter: (item) => item + 1,
                  ),
                  textColumn<int>(
                    name: 'third',
                    label: 'Third',
                    width: 180,
                    valueGetter: (item) => item + 2,
                  ),
                  textColumn<int>(
                    name: 'fourth',
                    label: 'Fourth',
                    width: 180,
                    valueGetter: (item) => item + 3,
                  ),
                ],
                onRowTap: (item, index) {
                  tappedItem = item;
                  tappedIndex = index;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Fourth'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final headerScrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      final headerController = headerScrollView.controller!;
      expect(headerController.position.maxScrollExtent, greaterThan(0));

      final firstBefore = tester.getCenter(find.text('First')).dx;
      final secondBefore = tester.getCenter(find.text('Second')).dx;
      final thirdBefore = tester.getCenter(find.text('Third')).dx;

      headerController.jumpTo(100);
      await tester.pump();

      expect(
        tester.getCenter(find.text('First')).dx,
        closeTo(firstBefore, 0.1),
      );
      expect(
        tester.getCenter(find.text('Second')).dx,
        closeTo(secondBefore, 0.1),
      );
      expect(tester.getCenter(find.text('Third')).dx, lessThan(thirdBefore));

      await tester.tap(find.text('42').last);
      expect(tappedItem, 42);
      expect(tappedIndex, 0);

      await cubit.close();
    });

    testWidgets('uses headerTextStyle in frozen and non-frozen modes', (
      tester,
    ) async {
      const headerStyle = TextStyle(color: Colors.purple, fontSize: 22);

      Future<TextStyle> renderHeaderStyle(int frozenColumnCount) async {
        final cubit = await createCubit();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 400,
                child: GenericTable<int>.withCubit(
                  cubit: cubit,
                  frozenColumnCount: frozenColumnCount,
                  headerTextStyle: headerStyle,
                  columns: [
                    textColumn<int>(
                      name: 'value',
                      label: 'Value',
                      width: 180,
                      valueGetter: (item) => item,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Value'),
        );
        final renderedStyle = paragraph.text.style!;
        await cubit.close();
        return renderedStyle;
      }

      final nonFrozenStyle = await renderHeaderStyle(0);
      final frozenStyle = await renderHeaderStyle(1);

      expect(nonFrozenStyle.color, headerStyle.color);
      expect(nonFrozenStyle.fontSize, headerStyle.fontSize);
      expect(frozenStyle.color, headerStyle.color);
      expect(frozenStyle.fontSize, headerStyle.fontSize);
    });
  });
}
