import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../data/local/database.dart' as db_provider;
import '../data/model/color_gradient.dart';

/// Provider for the ColorGradientRepository
final colorGradientRepositoryProvider = Provider<ColorGradientRepository>((
  ref,
) {
  final db = ref.watch(db_provider.appDatabaseProvider);
  return ColorGradientRepository(db);
});

/// Repository for managing color gradients in the database
class ColorGradientRepository {
  final db_provider.AppDatabase db;
  ColorGradientRepository(this.db);

  /// Fetches all color gradients from the database
  /// Returns a list of [ColorGradient] objects
  /// Throws [DatabaseError] if the operation fails
  Future<List<ColorGradient>> getAllGradients() async {
    try {
      final rows = await db.select(db.colorGradients).get();
      return rows.map((row) => ColorGradient.fromDb(row)).toList();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all color gradients', stack).throwError();
    }
  }

  /// Inserts a new color gradient into the database
  /// Returns the ID of the inserted gradient
  /// Throws [DatabaseError] if the operation fails
  Future<int> insertGradient(ColorGradient gradient) async {
    try {
      return await db.into(db.colorGradients).insert(gradient.toDb());
    } catch (e, stack) {
      DatabaseError('Failed to insert color gradient', stack).throwError();
    }
  }

  /// Fetches a color gradient by its ID
  /// Returns a [ColorGradient] object if found
  /// Throws [DatabaseError] if the operation fails or if the gradient is not found
  Future<ColorGradient> getGradientById(int id) async {
    try {
      final row =
          await (db.select(db.colorGradients)
            ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      return row != null
          ? ColorGradient.fromDb(row)
          : throw DatabaseError(
            'Color gradient with ID $id not found',
            StackTrace.current,
          );
    } catch (e, stack) {
      DatabaseError('Failed to fetch gradient by ID', stack).throwError();
    }
  }

  /// Updates an existing color gradient in the database
  /// Throws [DatabaseError] if the operation fails
  Future updateGradient(ColorGradient gradient) async {
    try {
      return await db.update(db.colorGradients).replace(gradient.toDb());
    } catch (e, stack) {
      DatabaseError('Failed to update color gradient', stack).throwError();
    }
  }

  /// Deletes a color gradient by its ID
  /// Throws [DatabaseError] if the operation fails
  Future deleteGradient(int id) async {
    try {
      return await (db.delete(db.colorGradients)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete color gradient', stack).throwError();
    }
  }
}
