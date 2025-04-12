import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

class TransactionCategoriesRepository {
  final AppDatabase db;
  TransactionCategoriesRepository(this.db);

  Future<List<TransactionCategory>> getAllTransactionCategories() async {
    try {
      return await db.select(db.transactionCategories).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch all transaction categories',
        stack,
      ).throwError();
    }
  }

  Future<int> insertTransactionCategory(
    TransactionCategoriesCompanion transactionCategory,
  ) async {
    try {
      return await db
          .into(db.transactionCategories)
          .insert(transactionCategory);
    } catch (e, stack) {
      DatabaseError(
        'Failed to insert transaction category',
        stack,
      ).throwError();
    }
  }

  Future<TransactionCategory?> getTransactionCategoryById(int id) async {
    try {
      return await (db.select(db.transactionCategories)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transaction category by ID',
        stack,
      ).throwError();
    }
  }

  Future updateTransactionCategory(
    TransactionCategoriesCompanion transactionCategory,
  ) async {
    try {
      return await db
          .update(db.transactionCategories)
          .replace(transactionCategory);
    } catch (e, stack) {
      DatabaseError(
        'Failed to update transaction category',
        stack,
      ).throwError();
    }
  }

  Future deleteTransactionCategory(int id) async {
    try {
      return await (db.delete(db.transactionCategories)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError(
        'Failed to delete transaction category',
        stack,
      ).throwError();
    }
  }
}
