import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/budget.dart' as model;
import 'package:rocket_pocket/data/model/enums.dart';

import '../helpers/test_data_builders.dart';

void main() {
  group('Budget', () {
    test('copyWith updates selected fields and keeps others', () {
      final original = buildBudgetModel();
      final updated = original.copyWith(name: 'Transport', amount: 300);

      expect(updated.id, original.id);
      expect(updated.name, 'Transport');
      expect(updated.amount, 300);
      expect(updated.period, original.period);
      expect(updated.startDate, original.startDate);
    });

    test('fromDb maps row fields to model', () {
      final row = buildBudgetRow(
        id: 9,
        name: 'Bills',
        amount: 750,
        period: BudgetPeriod.weekly,
      );

      final budget = model.Budget.fromDb(row);

      expect(budget.id, 9);
      expect(budget.name, 'Bills');
      expect(budget.amount, 750);
      expect(budget.period, BudgetPeriod.weekly);
      expect(budget.startDate, row.startDate);
      expect(budget.createdAt, row.createdAt);
    });
  });
}
