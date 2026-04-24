import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  group('BudgetWithSpent', () {
    test('computes remaining and progress', () {
      final budget = buildBudgetModel(amount: 1000);
      final value = BudgetWithSpent(budget: budget, spent: 250);

      expect(value.remaining, 750);
      expect(value.progress, 0.25);
      expect(value.isOverBudget, isFalse);
      expect(value.status, BudgetStatus.onTrack);
    });

    test('status transitions at threshold boundaries', () {
      final budget = buildBudgetModel(amount: 1000);

      final nearLimit = BudgetWithSpent(budget: budget, spent: 800);
      final over = BudgetWithSpent(budget: budget, spent: 1000);

      expect(nearLimit.status, BudgetStatus.nearLimit);
      expect(over.status, BudgetStatus.overBudget);
    });

    test('progress is clamped between 0 and 1', () {
      final budget = buildBudgetModel(amount: 1000);
      final over = BudgetWithSpent(budget: budget, spent: 5000);

      expect(over.progress, 1);
    });
  });
}
