import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as drift_db;
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final database = ref.watch(drift_db.appDatabaseProvider);
  return TransactionRepository(database);
});

class TransactionRepository {
  final drift_db.AppDatabase db;
  TransactionRepository(this.db);

  Future<List<Transaction>> getAllTransactions() async {
    try {
      final rows = await db.select(db.transactions).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all transactions', stack).throwError();
    }
  }

  Future<int> insertTransaction(
    drift_db.TransactionsCompanion transaction,
  ) async {
    try {
      return await db.into(db.transactions).insert(transaction);
    } catch (e, stack) {
      DatabaseError('Failed to insert transaction', stack).throwError();
    }
  }

  Future<void> updateTransaction(
    drift_db.TransactionsCompanion transaction,
  ) async {
    try {
      await db.update(db.transactions).replace(transaction);
    } catch (e, stack) {
      DatabaseError('Failed to update transaction', stack).throwError();
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    try {
      final row =
          await (db.select(db.transactions)
            ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      return row == null ? null : Transaction.fromDb(row);
    } catch (e, stack) {
      DatabaseError('Failed to fetch transaction by ID', stack).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    try {
      final rows =
          await (db.select(db.transactions)
            ..where((tbl) => tbl.type.equals(type.name))).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError('Failed to fetch transactions by type', stack).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByCategoryId(int categoryId) async {
    try {
      final rows =
          await (db.select(db.transactions)
            ..where((tbl) => tbl.categoryId.equals(categoryId))).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by category ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByLoanId(int loanId) async {
    try {
      final rows =
          await (db.select(db.transactions)
            ..where((tbl) => tbl.loanId.equals(loanId))).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by loan ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsBySenderPocketId(
    int senderPocketId,
  ) async {
    try {
      final rows =
          await (db.select(db.transactions)
            ..where((tbl) => tbl.senderPocketId.equals(senderPocketId))).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by sender Pocket ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByReceiverPocketId(
    int receiverPocketId,
  ) async {
    try {
      final rows =
          await (db.select(db.transactions)..where(
            (tbl) => tbl.receiverPocketId.equals(receiverPocketId),
          )).get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by receiver Pocket ID',
        stack,
      ).throwError();
    }
  }

  /// Fetches all transactions where the pocket is either sender or receiver,
  /// sorted by createdAt descending (newest first).
  Future<List<Transaction>> getTransactionsByPocketId(int pocketId) async {
    try {
      final rows =
          await (db.select(db.transactions)
                ..where(
                  (tbl) =>
                      tbl.senderPocketId.equals(pocketId) |
                      tbl.receiverPocketId.equals(pocketId),
                )
                ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
              .get();
      return rows.map(Transaction.fromDb).toList();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by pocket ID',
        stack,
      ).throwError();
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await (db.delete(db.transactions)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete transaction', stack).throwError();
    }
  }
}
