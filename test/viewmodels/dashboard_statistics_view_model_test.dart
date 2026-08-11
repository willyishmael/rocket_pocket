import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  Future<DashboardStatisticsState> readStats(
    ProviderContainer container,
    int pocketId,
  ) async {
    await Future.wait([
      container.read(transactionViewModelProvider.future),
      container.read(budgetViewModelProvider.future),
      container.read(loanViewModelProvider.future),
      container.read(categoryNamesProvider.future),
    ]);

    final statsAsync = container.read(dashboardStatisticsProvider(pocketId));
    expect(statsAsync.hasValue, isTrue);
    return statsAsync.requireValue;
  }

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        transactionViewModelProvider.overrideWith(
          () => _FakeTransactionViewModel([
            buildTransactionModel(
              id: 1,
              senderPocketId: 10,
              type: TransactionType.expense,
              categoryId: 1,
              budgetId: 7,
              amount: 120,
              date: DateTime(2026, 4, 5),
            ),
            buildTransactionModel(
              id: 2,
              senderPocketId: 10,
              type: TransactionType.income,
              categoryId: 2,
              amount: 200,
              date: DateTime(2026, 4, 3),
            ),
            buildTransactionModel(
              id: 3,
              senderPocketId: 10,
              receiverPocketId: 11,
              type: TransactionType.transfer,
              amount: 50,
              date: DateTime(2026, 4, 4),
            ),
            buildTransactionModel(
              id: 4,
              senderPocketId: 10,
              type: TransactionType.adjustment,
              amount: -10,
              date: DateTime(2026, 4, 2),
            ),
            buildTransactionModel(
              id: 5,
              senderPocketId: 10,
              type: TransactionType.loanTaken,
              loanId: 21,
              amount: 300,
              date: DateTime(2026, 4, 6),
            ),
            buildTransactionModel(
              id: 6,
              senderPocketId: 10,
              type: TransactionType.loanRepayment,
              loanId: 21,
              amount: 40,
              date: DateTime(2026, 4, 7),
            ),
            buildTransactionModel(
              id: 7,
              senderPocketId: 10,
              type: TransactionType.expense,
              categoryId: 1,
              amount: 40,
              date: DateTime(2026, 3, 12),
            ),
            buildTransactionModel(
              id: 8,
              senderPocketId: 22,
              type: TransactionType.expense,
              categoryId: 1,
              amount: 999,
              date: DateTime(2026, 4, 8),
            ),
          ]),
        ),
        budgetViewModelProvider.overrideWith(
          () => _FakeBudgetViewModel([
            BudgetWithSpent(
              budget: buildBudgetModel(id: 7, amount: 500),
              spent: 320,
            ),
          ]),
        ),
        loanViewModelProvider.overrideWith(
          () => _FakeLoanViewModel([
            buildLoanModel(
              id: 21,
              amount: 1000,
              repaidAmount: 200,
              status: LoanStatus.ongoing,
            ),
          ]),
        ),
        categoryNamesProvider.overrideWith(
          (ref) => Future.value({1: 'Food', 2: 'Salary'}),
        ),
      ],
    );
  }

  test(
    'derives pocket scoped monthly stats and excludes non-chart activity',
    () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final stats = await readStats(container, 10);

      expect(stats.availableMonths, [DateTime(2026, 4), DateTime(2026, 3)]);
      expect(stats.selectedMonth, DateTime(2026, 4));
      expect(stats.totals.income, 200);
      expect(stats.totals.expense, 120);
      expect(stats.totals.net, 80);
      expect(stats.totals.transactionCount, 2);
      expect(stats.expenseSlices.single.label, 'Food');
      expect(stats.expenseSlices.single.amount, 120);
      expect(stats.incomeSlices.single.label, 'Salary');
      expect(stats.incomeSlices.single.amount, 200);
      expect(stats.budgetHighlight.activeBudgetCount, 1);
      expect(stats.budgetHighlight.spentTotal, 120);
      expect(stats.budgetHighlight.budgetedTotal, 500);
      expect(stats.loanHighlight.relatedLoanCount, 1);
      expect(stats.loanHighlight.inflow, 300);
      expect(stats.loanHighlight.outflow, 40);
      expect(stats.loanHighlight.outstandingTotal, 800);
    },
  );

  test('uses the requested month when it is still available', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    container
        .read(dashboardSelectedMonthProvider(10).notifier)
        .setMonth(DateTime(2026, 3));

    final stats = await readStats(container, 10);

    expect(stats.selectedMonth, DateTime(2026, 3));
    expect(stats.totals.income, 0);
    expect(stats.totals.expense, 40);
    expect(stats.expenseSlices.single.amount, 40);
    expect(stats.loanHighlight.relatedLoanCount, 0);
  });

  test(
    'falls back to latest month when requested month is unavailable',
    () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(dashboardSelectedMonthProvider(10).notifier)
          .setMonth(DateTime(2025, 12));

      final stats = await readStats(container, 10);

      expect(stats.selectedMonth, DateTime(2026, 4));
      expect(stats.totals.income, 200);
      expect(stats.totals.expense, 120);
    },
  );
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
