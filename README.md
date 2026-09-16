# table_pagination

Reusable Flutter data grid built on `flutter_advanced_table` and Cubit state.

## Features

- Server-side pagination or scroll-based load more.
- Server-side sorting through custom sortable headers.
- Filter, refresh, reload, page-size, and page navigation methods on the cubit.
- Custom columns, custom cell widgets, and per-column header/cell padding.
- Custom row wrappers and row decorations for card-like rows.
- Loading, empty, error, load-more, and pagination footer states.

## Usage

```dart
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
  });

  final int id;
  final String name;
  final String email;
  final bool active;
}

GenericTable<User>(
  pageSize: 20,
  mode: TableMode.pagination,
  fetcher: (query) {
    // Send query.page, query.pageSize, query.sortBy, query.ascending,
    // and query.filters to your API/repository.
    return userRepository.fetchUsers(query);
  },
  columns: [
    textColumn<User>(
      name: 'name',
      label: 'Name',
      sortable: true,
      valueGetter: (user) => user.name,
      cellPadding: const EdgeInsets.only(left: 16, right: 8),
    ),
    textColumn<User>(
      name: 'email',
      label: 'Email',
      sortable: true,
      valueGetter: (user) => user.email,
      cellPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    widgetColumn<User>(
      name: 'status',
      label: 'Status',
      cellBuilder: (user, _) => Chip(
        label: Text(user.active ? 'Active' : 'Inactive'),
      ),
    ),
  ],
  rowDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE1E6E3)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  ),
  elementsPadding: const EdgeInsets.symmetric(vertical: 6),
)
```

Use `GenericTable.withCubit` when the screen needs to control filters or sort
state from outside the table:

```dart
final cubit = GenericTableCubit<User>(
  fetcher: userRepository.fetchUsers,
  mode: TableMode.loadMore,
);

await cubit.applyFilters({'status': 'active'});
await cubit.sort('name');
await cubit.refresh();

GenericTable<User>.withCubit(
  cubit: cubit,
  columns: userColumns,
)
```
