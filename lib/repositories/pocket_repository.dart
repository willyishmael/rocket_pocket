import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final pocketRepositoryProvider = Provider<PocketRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PocketRepository(db);
});

class PocketRepository {
  final AppDatabase db;
  PocketRepository(this.db);

  Future<List<Pocket>> getAllPockets() async {
    try {
      return await db.select(db.pockets).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all pockets', stack).throwError();
    }
  }

  Future<int> insertPocket(PocketsCompanion pocket) async {
    try {
      return await db.into(db.pockets).insert(pocket);
    } catch (e, stack) {
      DatabaseError('Failed to insert pocket', stack).throwError();
    }
  }

  Future<Pocket?> getPocketById(int id) async {
    try {
      return await (db.select(db.pockets)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError('Failed to fetch pocket by ID', stack).throwError();
    }
  }

  Future updatePocket(PocketsCompanion pocket) async {
    try {
      return await db.update(db.pockets).replace(pocket);
    } catch (e, stack) {
      DatabaseError('Failed to update pocket', stack).throwError();
    }
  }

  Future deletePocket(int id) async {
    try {
      return await (db.delete(db.pockets)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete pocket', stack).throwError();
    }
  }
}
