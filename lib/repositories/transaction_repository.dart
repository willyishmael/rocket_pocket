import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

class TransactionRepository {
  final AppDatabase db;
  TransactionRepository(this.db);

  Future<List<Transaction>> getAllTransactions() async {
    try {
      return await db.select(db.transactions).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all transactions', stack).throwError();
    }
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    try {
      return await db.into(db.transactions).insert(transaction);
    } catch (e, stack) {
      DatabaseError('Failed to insert transaction', stack).throwError();
    }
  }

  Future updateTransaction(TransactionsCompanion transaction) async {
    try {
      return await db.update(db.transactions).replace(transaction);
    } catch (e, stack) {
      DatabaseError('Failed to update transaction', stack).throwError();
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    try {
      return await (db.select(db.transactions)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError('Failed to fetch transaction by ID', stack).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByType(String type) async {
    try {
      return await (db.select(db.transactions)
        ..where((tbl) => tbl.type.equals(type))).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch transactions by type', stack).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByCategoryId(int categoryId) async {
    try {
      return await (db.select(db.transactions)
        ..where((tbl) => tbl.categoryId.equals(categoryId))).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by category ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByLoanId(int loanId) async {
    try {
      return await (db.select(db.transactions)
        ..where((tbl) => tbl.loanId.equals(loanId))).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by loan ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsBySenderAccountId(
    int senderAccountId,
  ) async {
    try {
      return await (db.select(db.transactions)
        ..where((tbl) => tbl.senderAccountId.equals(senderAccountId))).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by sender account ID',
        stack,
      ).throwError();
    }
  }

  Future<List<Transaction>> getTransactionsByReceiverAccountId(
    int receiverAccountId,
  ) async {
    try {
      return await (db.select(
        db.transactions,
      )..where((tbl) => tbl.receiverAccountId.equals(receiverAccountId))).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transactions by receiver account ID',
        stack,
      ).throwError();
    }
  }

  Future deleteTransaction(int id) async {
    try {
      return await (db.delete(db.transactions)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete transaction', stack).throwError();
    }
  }
}
