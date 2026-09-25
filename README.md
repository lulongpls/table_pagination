# table_pagination

Reusable Flutter data grid built on `flutter_advanced_table` and Cubit state.

## Features

- Server-side pagination or scroll-based load more.
- Server-side sorting through custom sortable headers.
- Filter, refresh, reload, page-size, and page navigation methods on the cubit.
- Custom columns, custom cell widgets, and per-column header/cell padding.
- Declarative row actions with inline, grouped, and secondary-click context menus.
- Frozen leading columns for horizontally scrollable tables.
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
  stickyFooter: true,
  fetcher: (query) {
    // Send query.page, query.pageSize, query.sortBy, query.ascending,
    // query.sorts, and query.filters to your API/repository.
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

Set `stickyFooter: true` when the footer should appear directly after a short
list, but remain pinned below the table when the rows need to scroll. The
default is `false`, which keeps the footer at the bottom of the available
table area.

Define row actions once instead of creating a dedicated actions column. In
`defaultMode`, one or two actions are shown inline and more than two actions
are grouped behind the three-dots menu. Use `full` or `group` to force a mode.
Rows also open the same named actions with a Windows secondary click or a
macOS two-finger click.
On web, the native browser context menu is disabled only while an actions-enabled
table is mounted, then restored when the table is removed. Set
`enableContextMenu: false` to keep the browser menu.

```dart
GenericTable<User>(
  fetcher: userRepository.fetchUsers,
  columns: userColumns,
  actions: [
    TableAction<User>(
      name: 'Delete',
      icon: const Icon(Icons.delete_outline),
      onTap: (user, index) => deleteUser(user),
    ),
    TableAction<User>(
      name: 'Reset password',
      icon: const Icon(Icons.lock_reset),
      onTap: (user, index) => resetPassword(user),
    ),
  ],
  actionMode: TableActionMode.defaultMode,
  actionsColumnWidth: 140,
  actionsColumnTitle: 'Actions',
  enableActions: true,
  enableContextMenu: true,
  actionsMenuIcon: const Icon(Icons.more_vert),
)
```

Freeze the first columns from left to right with `frozenColumnCount`. Explicit
column widths make the horizontal overflow predictable:

```dart
GenericTable<User>(
  frozenColumnCount: 1,
  columns: [
    textColumn<User>(
      name: 'name',
      label: 'Name',
      width: 220,
      valueGetter: (user) => user.name,
    ),
    // Other columns can scroll horizontally.
  ],
  fetcher: userRepository.fetchUsers,
)
```

Use local sort when the loaded rows should be sorted immediately without a new
API call:

```dart
GenericTable<User>(
  sortMode: TableSortMode.local,
  fetcher: userRepository.fetchUsers,
  columns: [
    textColumn<User>(
      name: 'name',
      label: 'Name',
      sortable: true,
      valueGetter: (user) => user.name,
    ),
    widgetColumn<User>(
      name: 'status',
      label: 'Status',
      sortable: true,
      localSortValueGetter: (user) => user.active ? 1 : 0,
      cellBuilder: (user, _) => Chip(
        label: Text(user.active ? 'Active' : 'Inactive'),
      ),
    ),
  ],
)
```

In `TableMode.loadMore`, sort is always online so the API keeps the whole
dataset in one consistent order.

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

Override only the default pagination footer styling with `footerBuilder` and
`PaginationFooterStyle`:

```dart
GenericTable<User>.withCubit(
  cubit: cubit,
  columns: userColumns,
  footerBuilder: (context, state, cubit) {
    return PaginationFooter(
      page: state.page,
      totalPages: state.totalPages,
      totalCount: state.totalCount,
      pageSize: state.pageSize,
      isLoading: state.isLoading,
      onPageChanged: cubit.goToPage,
      labelBuilder: (page, totalPages, totalCount) {
        return 'Trang $page/$totalPages · $totalCount tài khoản';
      },
      style: const PaginationFooterStyle(
        backgroundColor: Color(0xFFF8FAF9),
        selectedPageBackgroundColor: Color(0xFFE93D69),
        selectedPageForegroundColor: Colors.white,
        pageForegroundColor: Color(0xFF394542),
        iconForegroundColor: Color(0xFFE93D69),
      ),
    );
  },
)
```
