import 'dart:async';

import 'package:flutter/material.dart';
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
}
