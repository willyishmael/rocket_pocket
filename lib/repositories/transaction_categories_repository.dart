import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final transactionCategoryRepositoryProvider =
    Provider<TransactionCategoriesRepository>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return TransactionCategoriesRepository(db);
    });

/// A convenience provider that returns a map from category ID to category name
/// for use in UI widgets that need to resolve category names by ID.
final categoryNamesProvider = FutureProvider<Map<int, String>>((ref) async {
  final repo = ref.watch(transactionCategoryRepositoryProvider);
  final categories = await repo.getAllTransactionCategories();
  return {for (final c in categories) c.id: c.name};
});

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

  Future<List<TransactionCategory>> getAllTransactionCategoriesByType(
    TransactionType type,
  ) async {
    try {
      final query = db.select(db.transactionCategories)
        ..where((tbl) => tbl.type.equalsValue(type));
      return await query.get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch transaction categories by type',
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

  Future<bool> updateTransactionCategory(
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

  Future<int> deleteTransactionCategory(int id) async {
    try {
      final category = await getTransactionCategoryById(id);
      if (category != null && category.isSystem) {
        throw const SystemCategoryError('System categories cannot be deleted.');
      }
      return await (db.delete(db.transactionCategories)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      if (e is SystemCategoryError) rethrow;
      DatabaseError(
        'Failed to delete transaction category',
        stack,
      ).throwError();
    }
  }

  Future<int> updateTransactionCategoryName(int id, String name) async {
    try {
      final category = await getTransactionCategoryById(id);
      if (category != null && category.isSystem) {
        throw const SystemCategoryError('System categories cannot be renamed.');
      }
      return await (db.update(db.transactionCategories)
        ..where((tbl) => tbl.id.equals(id))).write(
        TransactionCategoriesCompanion(
          name: Value(name),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e, stack) {
      if (e is SystemCategoryError) rethrow;
      DatabaseError(
        'Failed to update transaction category name',
        stack,
      ).throwError();
    }
  }

  Future<TransactionCategory> getOrCreateSystemCategory({
    required String name,
    required TransactionType type,
  }) async {
    try {
      final existing =
          await (db.select(db.transactionCategories)..where(
            (tbl) => tbl.name.equals(name) & tbl.type.equalsValue(type),
          )).getSingleOrNull();

      if (existing != null) {
        if (!existing.isSystem) {
          await (db.update(db.transactionCategories)
            ..where((tbl) => tbl.id.equals(existing.id))).write(
            TransactionCategoriesCompanion(
              isSystem: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          final updated = await getTransactionCategoryById(existing.id);
          if (updated != null) return updated;
        }
        return existing;
      }

      final id = await insertTransactionCategory(
        TransactionCategoriesCompanion.insert(
          name: name,
          type: Value(type),
          isSystem: const Value(true),
          updatedAt: DateTime.now(),
        ),
      );

      final created = await getTransactionCategoryById(id);
      if (created == null) {
        throw StateError('Failed to create system category "$name".');
      }
      return created;
    } catch (e, stack) {
      DatabaseError(
        'Failed to get or create system category',
        stack,
      ).throwError();
    }
  }
}
