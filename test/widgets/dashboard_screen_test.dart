import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/screens/dashboard/dashboard_screen.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets(
    'keeps pockets slider on dashboard and does not render statistics section',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pocketViewModelProvider.overrideWith(
            () => _FakePocketViewModel([
              buildPocketModel(
                id: 10,
                name: 'Wallet',
                currency: 'USD',
                icon: '\$',
              ),
              buildPocketModel(
                id: 11,
                name: 'Savings',
                currency: 'USD',
                icon: '\$',
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
                amount: 150,
                date: DateTime(2026, 4, 5),
              ),
              buildTransactionModel(
                id: 2,
                senderPocketId: 11,
                type: TransactionType.income,
                categoryId: 2,
                amount: 400,
                date: DateTime(2026, 3, 8),
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pockets'), findsOneWidget);
      expect(find.text('Statistics'), findsNothing);

      await tester.drag(find.byType(Swiper), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Pockets'), findsOneWidget);
      expect(find.text('Statistics'), findsNothing);
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
