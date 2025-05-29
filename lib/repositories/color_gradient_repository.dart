import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../data/local/database.dart' as db_provider;
import '../data/model/color_gradient.dart';

final colorGradientRepositoryProvider = Provider<ColorGradientRepository>((
  ref,
) {
  final db = ref.watch(db_provider.appDatabaseProvider);
  return ColorGradientRepository(db);
});

class ColorGradientRepository {
  final db_provider.AppDatabase db;
  ColorGradientRepository(this.db);

  Future<List<ColorGradient>> getAllGradients() async {
    try {
      final rows = await db.select(db.colorGradients).get();
      return rows.map((row) => ColorGradient.fromDb(row)).toList();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all color gradients', stack).throwError();
    }
  }

  Future<int> insertGradient(ColorGradient gradient) async {
    try {
      return await db.into(db.colorGradients).insert(gradient.toDb());
    } catch (e, stack) {
      DatabaseError('Failed to insert color gradient', stack).throwError();
    }
  }

  Future<ColorGradient?> getGradientById(int id) async {
    try {
      final row = await (db.select(db.colorGradients)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      return row != null ? ColorGradient.fromDb(row) : null;
    } catch (e, stack) {
      DatabaseError('Failed to fetch gradient by ID', stack).throwError();
    }
  }

  Future updateGradient(ColorGradient gradient) async {
    try {
      return await db.update(db.colorGradients).replace(gradient.toDb());
    } catch (e, stack) {
      DatabaseError('Failed to update color gradient', stack).throwError();
    }
  }

  Future deleteGradient(int id) async {
    try {
      return await (db.delete(db.colorGradients)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete color gradient', stack).throwError();
    }
  }
}
