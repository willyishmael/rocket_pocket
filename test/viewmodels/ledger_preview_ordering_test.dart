import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  group('prioritizeBudgetPreviews', () {
    test('orders status groups and utilization, then limits the result', () {
      final previews = prioritizeBudgetPreviews([
        BudgetWithSpent(budget: buildBudgetModel(id: 1), spent: 900),
        BudgetWithSpent(budget: buildBudgetModel(id: 2), spent: 1500),
        BudgetWithSpent(budget: buildBudgetModel(id: 3), spent: 1200),
        BudgetWithSpent(budget: buildBudgetModel(id: 4), spent: 700),
      ]);

      expect(previews.map((item) => item.budget.id), [2, 3, 1]);
    });
  });

  group('prioritizeLoanPreviews', () {
    test('prioritizes overdue, then seven-day loans and active fill-ins', () {
      final asOf = DateTime(2026, 4, 15);
      final previews = prioritizeLoanPreviews([
        LoanPreview(
          loan: buildLoanModel(id: 1, dueDate: DateTime(2026, 4, 30)),
          nextDueDate: DateTime(2026, 4, 30),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 2, dueDate: DateTime(2026, 4, 14)),
          nextDueDate: DateTime(2026, 4, 14),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 3, dueDate: DateTime(2026, 4, 22)),
          nextDueDate: DateTime(2026, 4, 22),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 6, dueDate: DateTime(2026, 4, 21)),
          nextDueDate: DateTime(2026, 4, 21),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 7, status: LoanStatus.overdue),
          nextDueDate: DateTime(2026, 4, 20),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 8, dueDate: DateTime(2026, 5, 1)),
          nextDueDate: DateTime(2026, 5, 1),
        ),
        LoanPreview(
          loan: buildLoanModel(
            id: 4,
            dueDate: DateTime(2026, 4, 20),
            status: LoanStatus.completed,
          ),
          nextDueDate: DateTime(2026, 4, 20),
        ),
        LoanPreview(
          loan: buildLoanModel(
            id: 5,
            dueDate: DateTime(2026, 4, 20),
            status: LoanStatus.cancelled,
          ),
          nextDueDate: DateTime(2026, 4, 20),
        ),
      ], asOf: asOf);

      expect(previews, hasLength(3));
      expect(previews.map((item) => item.loan.id), [2, 7, 6]);
    });

    test('keeps explicit overdue status ahead of a future due date', () {
      final previews = prioritizeLoanPreviews([
        LoanPreview(
          loan: buildLoanModel(id: 1),
          nextDueDate: DateTime(2026, 4, 18),
        ),
        LoanPreview(
          loan: buildLoanModel(id: 2, status: LoanStatus.overdue),
          nextDueDate: DateTime(2026, 4, 20),
        ),
      ], asOf: DateTime(2026, 4, 15));

      expect(previews.map((item) => item.loan.id), [2, 1]);
    });
  });
}
