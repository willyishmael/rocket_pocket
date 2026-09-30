import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/router/navigation_helper.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/budget/budget_screen.dart';
import 'package:rocket_pocket/screens/loan/loan_screen.dart';
import 'package:rocket_pocket/screens/pocket/edit_pocket_screen.dart';
import 'package:rocket_pocket/screens/pocket/pocket_detail_screen.dart';
import 'package:rocket_pocket/screens/pocket/pocket_list_screen.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/edit_pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets('navigation orders four destinations and starts on Ledger', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        pocketViewModelProvider.overrideWith(
          () => _FakePocketViewModel([
            buildPocketModel(
              id: 1,
              name: 'Main',
              currency: 'USD',
              balance: 100,
              icon: '\$',
            ),
          ]),
        ),
        budgetViewModelProvider.overrideWith(() => _FakeBudgetViewModel()),
        loanViewModelProvider.overrideWith(() => _FakeLoanViewModel()),
        transactionViewModelProvider.overrideWith(
          () => _FakeTransactionViewModel(),
        ),
        categoryNamesProvider.overrideWith((ref) async => {}),
        ledgerLoanPreviewsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    NavigationHelper();
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: NavigationHelper.router),
      ),
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels =
        navBar.destinations
            .map((d) => (d as NavigationDestination).label)
            .toList();

    expect(labels, ['Ledger', 'Transaction', 'Statistics', 'Settings']);
    expect(navBar.selectedIndex, 0);
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.ledger,
    );

    NavigationHelper.router.go(Paths.dashboard);
    await tester.pumpAndSettle();
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.ledger,
    );

    NavigationHelper.router.go(Paths.pockets);
    await tester.pumpAndSettle();
    expect(find.byType(PocketListScreen), findsOneWidget);

    NavigationHelper.router.go(Paths.budget);
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);

    NavigationHelper.router.go(Paths.loan);
    await tester.pumpAndSettle();
    expect(find.byType(LoanScreen), findsOneWidget);

    NavigationHelper.router.go(Paths.ledger);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transaction'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.transaction,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ledger'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.ledger,
    );
  });

  testWidgets('current and legacy pocket routes reach canonical destinations', (
    tester,
  ) async {
    final pocket = buildPocketModel(
      id: 1,
      name: 'Main',
      currency: 'USD',
      balance: 100,
      icon: '\$',
    );
    final container = ProviderContainer(
      overrides: [
        pocketViewModelProvider.overrideWith(() => _FakePocketViewModel([])),
        editPocketViewModelProvider(
          pocket,
        ).overrideWith(() => _FakeEditPocketViewModel(pocket)),
        budgetViewModelProvider.overrideWith(() => _FakeBudgetViewModel()),
        loanViewModelProvider.overrideWith(() => _FakeLoanViewModel()),
        ledgerLoanPreviewsProvider.overrideWith((ref) async => const []),
        transactionViewModelProvider.overrideWith(
          () => _FakeTransactionViewModel(),
        ),
        categoryNamesProvider.overrideWith((ref) async => {}),
      ],
    );
    addTearDown(container.dispose);

    NavigationHelper();
    NavigationHelper.router.go(Paths.pocketDetailsRoute(1));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: NavigationHelper.router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PocketDetailScreen), findsOneWidget);

    for (final route in ['/dashboard/pocket/1', Paths.pocketDetailsRoute(1)]) {
      NavigationHelper.router.go(route);
      await tester.pumpAndSettle();
      expect(
        NavigationHelper.router.routeInformationProvider.value.uri.path,
        Paths.pocketDetailsRoute(1),
      );
      expect(find.byType(PocketDetailScreen), findsOneWidget);
    }

    NavigationHelper.router.go(Paths.editPocketRoute(1), extra: pocket);
    await tester.pumpAndSettle();
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.editPocketRoute(1),
    );
    expect(find.byType(EditPocketScreen), findsOneWidget);
    expect(find.text('Main'), findsNWidgets(2));

    NavigationHelper.router.go('/dashboard/pocket/1/edit', extra: pocket);
    await tester.pumpAndSettle();
    expect(
      NavigationHelper.router.routeInformationProvider.value.uri.path,
      Paths.editPocketRoute(1),
    );
    expect(find.byType(PocketEditRouteScreen), findsOneWidget);

    for (final route in [
      '/dashboard/pocket/1/pocket-transactions',
      Paths.pocketTransactionsRoute(1),
    ]) {
      NavigationHelper.router.go(route);
      await tester.pumpAndSettle();
      expect(
        NavigationHelper.router.routeInformationProvider.value.uri.path,
        Paths.pocketDetailsRoute(1),
      );
      expect(find.byType(PocketDetailScreen), findsOneWidget);
    }
  });

  testWidgets('edit route loads its pocket when navigation extra is missing', (
    tester,
  ) async {
    final pocket = buildPocketModel(
      id: 1,
      name: 'Main',
      currency: 'USD',
      balance: 100,
      icon: '\$',
    );
    final container = ProviderContainer(
      overrides: [
        pocketViewModelProvider.overrideWith(
          () => _FakePocketViewModel([pocket]),
        ),
        editPocketViewModelProvider(
          pocket,
        ).overrideWith(() => _FakeEditPocketViewModel(pocket)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PocketEditRouteScreen(pocketId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EditPocketScreen), findsOneWidget);
    expect(find.text('Main'), findsNWidgets(2));
  });
}

class _FakeBudgetViewModel extends BudgetViewModel {
  @override
  Future<List<BudgetWithSpent>> build() async => const [];
}

class _FakeLoanViewModel extends LoanViewModel {
  @override
  Future<List<Loan>> build() async => const [];
}

class _FakePocketViewModel extends PocketViewModel {
  final List<Pocket> _pockets;

  _FakePocketViewModel(this._pockets);

  @override
  Future<List<Pocket>> build() async => _pockets;
}

class _FakeEditPocketViewModel extends EditPocketViewModel {
  _FakeEditPocketViewModel(this._pocket) : super(_pocket);

  final Pocket _pocket;

  @override
  Future<EditPocketState> build() async =>
      EditPocketState(pocket: _pocket, gradients: const []);
}

class _FakeTransactionViewModel extends TransactionViewModel {
  @override
  Future<List<Transaction>> build() async => [];
}
