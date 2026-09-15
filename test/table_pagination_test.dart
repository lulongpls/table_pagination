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
      expect(cubit.state.page, 1);

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
}
