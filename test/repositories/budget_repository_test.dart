import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late BudgetRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BudgetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetRepository', () {
    test('insert/get/getSpentAmount returns expected values', () async {
      final startDate = fixedDate(1);
      final budgetId = await repository.insertBudget(
        BudgetsCompanion.insert(
          name: 'Food',
          amount: 1000,
          period: BudgetPeriod.once,
          startDate: startDate,
          updatedAt: fixedDate(2),
        ),
      );

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: TransactionType.expense,
              description: 'Meal',
              amount: 200,
              budgetId: Value(budgetId),
              date: Value(fixedDate(3)),
              updatedAt: fixedDate(3),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: TransactionType.income,
              description: 'Salary',
              amount: 100,
              budgetId: Value(budgetId),
              date: Value(fixedDate(3)),
              updatedAt: fixedDate(3),
            ),
          );

      final budget = await repository.getBudgetById(budgetId);
      final spent = await repository.getSpentAmount(
        budgetId,
        BudgetPeriod.once,
        startDate,
      );

      expect(budget, isNotNull);
      expect(budget!.name, 'Food');
      expect(spent, 200);
    });

    test('deleteBudget clears budgetId on linked transactions', () async {
      final budgetId = await repository.insertBudget(
        BudgetsCompanion.insert(
          name: 'Groceries',
          amount: 400,
          period: BudgetPeriod.once,
          startDate: fixedDate(1),
          updatedAt: fixedDate(2),
        ),
      );

      final txId = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: TransactionType.expense,
              description: 'Bread',
              amount: 20,
              budgetId: Value(budgetId),
              date: Value(fixedDate(2)),
              updatedAt: fixedDate(2),
            ),
          );

      await repository.deleteBudget(budgetId);

      final tx =
          await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId))).getSingle();

      expect(tx.budgetId, isNull);
    });

    test('throws DatabaseError when DB is unavailable', () async {
      await db.customStatement('DROP TABLE budgets;');

      expect(repository.getAllBudgets, throwsA(isA<DatabaseError>()));
    });
  });
}
