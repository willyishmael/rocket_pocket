import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/statistics/statistics_breakdown_screen.dart';
import 'package:rocket_pocket/screens/statistics/statistics_category_transactions_screen.dart';
import 'package:rocket_pocket/screens/statistics/statistics_screen.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets(
    'show more and category drilldown navigate to transactions list',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pocketViewModelProvider.overrideWith(
            () => _FakePocketViewModel([
              buildPocketModel(
                id: 10,
                name: 'Wallet',
                currency: 'USD',
                balance: 1000,
              ),
            ]),
          ),
          transactionViewModelProvider.overrideWith(
            () => _FakeTransactionViewModel([
              buildTransactionModel(
                id: 1,
                senderPocketId: 10,
                type: TransactionType.expense,
                categoryId: 1,
                amount: 120,
                description: 'Lunch',
                date: DateTime(2026, 4, 5),
              ),
              buildTransactionModel(
                id: 2,
                senderPocketId: 10,
                type: TransactionType.expense,
                categoryId: 1,
                amount: 80,
                description: 'Dinner',
                date: DateTime(2026, 4, 8),
              ),
              buildTransactionModel(
                id: 3,
                senderPocketId: 10,
                type: TransactionType.income,
                categoryId: 2,
                amount: 500,
                description: 'Salary',
                date: DateTime(2026, 4, 2),
              ),
            ]),
          ),
          budgetViewModelProvider.overrideWith(
            () => _FakeBudgetViewModel(const []),
          ),
          loanViewModelProvider.overrideWith(
            () => _FakeLoanViewModel(const []),
          ),
          categoryNamesProvider.overrideWith(
            (ref) => Future.value({1: 'Food', 2: 'Salary'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      final router = GoRouter(
        initialLocation: Paths.statistics,
        routes: [
          GoRoute(
            path: Paths.statistics,
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: Paths.statisticsShowMore,
            builder: (context, state) {
              final extra = state.extra;
              return StatisticsBreakdownScreen(
                initialChartType: extra is StatisticsChartType ? extra : null,
              );
            },
          ),
          GoRoute(
            path: Paths.statisticsCategoryTransactions,
            builder: (context, state) {
              final drilldown = state.extra! as StatisticsCategoryDrilldown;
              return StatisticsCategoryTransactionsScreen(drilldown: drilldown);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expenses by Category'));
      await tester.pumpAndSettle();

      expect(find.text('Full Category Breakdown'), findsOneWidget);

      await tester.tap(find.text('Food').first);
      await tester.pumpAndSettle();

      expect(find.text('Food Transactions'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    },
  );
}

class _FakePocketViewModel extends PocketViewModel {
  final List<Pocket> _pockets;

  _FakePocketViewModel(this._pockets);

  @override
  Future<List<Pocket>> build() async => _pockets;
}

class _FakeTransactionViewModel extends TransactionViewModel {
  final List<Transaction> _transactions;

  _FakeTransactionViewModel(this._transactions);

  @override
  Future<List<Transaction>> build() async => _transactions;
}

class _FakeBudgetViewModel extends BudgetViewModel {
  final List<BudgetWithSpent> _budgets;

  _FakeBudgetViewModel(this._budgets);

  @override
  Future<List<BudgetWithSpent>> build() async => _budgets;
}

class _FakeLoanViewModel extends LoanViewModel {
  final List<Loan> _loans;

  _FakeLoanViewModel(this._loans);

  @override
  Future<List<Loan>> build() async => _loans;
}
