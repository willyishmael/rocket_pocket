import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db_provider;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

/// Provider for the PocketRepository
final pocketRepositoryProvider = Provider<PocketRepository>((ref) {
  final db = ref.watch(db_provider.appDatabaseProvider);
  final colorGradientRepository = ref.watch(colorGradientRepositoryProvider);
  return PocketRepository(db, colorGradientRepository);
});

/// Repository for managing pockets in the database
class PocketRepository {
  final db_provider.AppDatabase db;
  final ColorGradientRepository colorGradientRepository;

  PocketRepository(this.db, this.colorGradientRepository);

  /// Fetches all pockets from the database
  /// Returns a list of [Pocket] objects
  /// Throws [DatabaseError] if the operation fails
  Future<List<Pocket>> getAllPockets() async {
    try {
      final rows = await db.select(db.pockets).get();
      return Future.wait(
        rows.map(
          (row) async => await Pocket.fromDb(row, (id) async {
            final gradient = await colorGradientRepository.getGradientById(id);
            return gradient;
          }),
        ),
      );
    } catch (e, stack) {
      DatabaseError('Failed to fetch all pockets', stack).throwError();
    }
  }

  /// Inserts a new pocket into the database
  /// Returns the ID of the inserted pocket
  /// Throws [DatabaseError] if the operation fails
  Future<int> insertPocket(Pocket pocket) async {
    try {
      return await db.into(db.pockets).insert(pocket.toInsertCompanion());
    } catch (e, stack) {
      DatabaseError('Failed to insert pocket', stack).throwError();
    }
  }

  /// Fetches a pocket by its ID
  /// Returns a [Pocket] object if found
  /// Throws [DatabaseError] if the operation fails or if the pocket is not found
  Future<Pocket?> getPocketById(int id) async {
    try {
      final row =
          await (db.select(db.pockets)
            ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (row == null) return null;
      return await Pocket.fromDb(
        row,
        (id) => colorGradientRepository.getGradientById(id),
      );
    } catch (e, stack) {
      DatabaseError('Failed to fetch pocket by ID', stack).throwError();
    }
  }

  /// Updates an existing pocket in the database
  /// Throws [DatabaseError] if the operation fails
  Future updatePocket(Pocket pocket) async {
    try {
      return await db.update(db.pockets).replace(pocket.toDb());
    } catch (e, stack) {
      DatabaseError('Failed to update pocket', stack).throwError();
    }
  }

  /// Deletes a pocket by its ID
  /// Throws [DatabaseError] if the operation fails
  Future deletePocket(int id) async {
    try {
      return await (db.delete(db.pockets)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete pocket', stack).throwError();
    }
  }
}
