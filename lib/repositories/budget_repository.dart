import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetRepository(db);
});

class BudgetRepository {
  final AppDatabase db;
  BudgetRepository(this.db);

  Future<List<Budget>> getAllBudgets() async {
    try {
      return await db.select(db.budgets).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all budgets', stack).throwError();
    }
  }

  Future<int> insertBudget(BudgetsCompanion budget) async {
    try {
      return await db.into(db.budgets).insert(budget);
    } catch (e, stack) {
      DatabaseError('Failed to insert budget', stack).throwError();
    }
  }

  Future<Budget?> getBudgetById(int id) async {
    try {
      return await (db.select(db.budgets)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError('Failed to fetch budget by ID', stack).throwError();
    }
  }

  Future<int> updateBudget(BudgetsCompanion budget) async {
    try {
      return await (db.update(db.budgets)
        ..where((tbl) => tbl.id.equals(budget.id.value))).write(budget);
    } catch (e, stack) {
      DatabaseError('Failed to update budget', stack).throwError();
    }
  }

  Future<int> deleteBudget(int id) async {
    try {
      // Clear budgetId on linked transactions before deleting
      await (db.update(db.transactions)..where(
        (tbl) => tbl.budgetId.equals(id),
      )).write(const TransactionsCompanion(budgetId: Value(null)));
      return await (db.delete(db.budgets)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete budget', stack).throwError();
    }
  }

  /// Returns the total spent amount for a budget within the current period.
  Future<double> getSpentAmount(
    int budgetId,
    BudgetPeriod period,
    DateTime startDate,
  ) async {
    try {
      final periodRange = _periodRange(period, startDate);
      final query =
          db.selectOnly(db.transactions)
            ..addColumns([db.transactions.amount.sum()])
            ..where(db.transactions.budgetId.equals(budgetId))
            ..where(db.transactions.type.equalsValue(TransactionType.expense))
            ..where(
              db.transactions.date.isBiggerOrEqualValue(periodRange.$1) &
                  db.transactions.date.isSmallerThanValue(periodRange.$2),
            );
      final result = await query.getSingle();
      return result.read(db.transactions.amount.sum()) ?? 0.0;
    } catch (e, stack) {
      DatabaseError('Failed to get spent amount', stack).throwError();
    }
  }

  /// Returns all transactions linked to a specific budget within the current period.
  Future<List<Transaction>> getTransactionsForBudget(
    int budgetId,
    BudgetPeriod period,
    DateTime startDate,
  ) async {
    try {
      final periodRange = _periodRange(period, startDate);
      return await (db.select(db.transactions)
            ..where((tbl) => tbl.budgetId.equals(budgetId))
            ..where(
              (tbl) =>
                  tbl.date.isBiggerOrEqualValue(periodRange.$1) &
                  tbl.date.isSmallerThanValue(periodRange.$2),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
    } catch (e, stack) {
      DatabaseError('Failed to get budget transactions', stack).throwError();
    }
  }

  /// Computes the start/end of the current period window.
  (DateTime, DateTime) _periodRange(BudgetPeriod period, DateTime startDate) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        // Find the most recent occurrence of the start weekday
        final daysSinceStart = (now.weekday - startDate.weekday + 7) % 7;
        final periodStart = DateTime(
          now.year,
          now.month,
          now.day - daysSinceStart,
        );
        return (periodStart, periodStart.add(const Duration(days: 7)));
      case BudgetPeriod.monthly:
        final periodStart = DateTime(now.year, now.month, startDate.day);
        final adjustedStart =
            periodStart.isAfter(now)
                ? DateTime(now.year, now.month - 1, startDate.day)
                : periodStart;
        return (
          adjustedStart,
          DateTime(adjustedStart.year, adjustedStart.month + 1, startDate.day),
        );
      case BudgetPeriod.yearly:
        final periodStart = DateTime(now.year, startDate.month, startDate.day);
        final adjustedStart =
            periodStart.isAfter(now)
                ? DateTime(now.year - 1, startDate.month, startDate.day)
                : periodStart;
        return (
          adjustedStart,
          DateTime(adjustedStart.year + 1, startDate.month, startDate.day),
        );
      case BudgetPeriod.once:
        // One-time budget: the entire window from startDate to far future
        return (startDate, DateTime(9999));
    }
  }
}
