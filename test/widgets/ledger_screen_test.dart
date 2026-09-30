import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/screens/ledger/ledger_screen.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets('Ledger keeps its greeting and pocket carousel with previews', (
    tester,
  ) async {
    final today = DateTime.now();
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
        budgetViewModelProvider.overrideWith(
          () => _FakeBudgetViewModel([
            BudgetWithSpent(
              budget: buildBudgetModel(id: 1, name: 'High risk budget'),
              spent: 1500,
            ),
            BudgetWithSpent(
              budget: buildBudgetModel(id: 2, name: 'Near limit budget'),
              spent: 900,
            ),
            BudgetWithSpent(
              budget: buildBudgetModel(id: 3, name: 'Normal budget'),
              spent: 600,
            ),
          ]),
        ),
        ledgerLoanPreviewsProvider.overrideWith(
          (ref) async => [
            LoanPreview(
              loan: buildLoanModel(
                id: 1,
                counterpartyName: 'Overdue loan',
                dueDate: today.subtract(const Duration(days: 1)),
              ),
              nextDueDate: today.subtract(const Duration(days: 1)),
            ),
            LoanPreview(
              loan: buildLoanModel(
                id: 2,
                counterpartyName: 'Upcoming loan',
                dueDate: today.add(const Duration(days: 2)),
              ),
              nextDueDate: today.add(const Duration(days: 2)),
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LedgerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi William!'), findsOneWidget);
    expect(find.text('Pockets'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('High risk budget'), findsOneWidget);
    expect(find.textContaining('Spent'), findsNothing);
    expect(find.textContaining('Budget limit:'), findsWidgets);
    expect(find.byType(Swiper), findsOneWidget);

    await tester.drag(find.byType(Swiper), const Offset(-350, 0));
    await tester.pumpAndSettle();

    expect(find.text('Hi William!'), findsOneWidget);
    expect(find.byType(Swiper), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Overdue loan'), findsOneWidget);
  });
}

class _FakePocketViewModel extends PocketViewModel {
  final List<Pocket> _pockets;

  _FakePocketViewModel(this._pockets);

  @override
  Future<List<Pocket>> build() async => _pockets;
}

class _FakeBudgetViewModel extends BudgetViewModel {
  final List<BudgetWithSpent> _budgets;

  _FakeBudgetViewModel(this._budgets);

  @override
  Future<List<BudgetWithSpent>> build() async => _budgets;
}
