import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart' as model;
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late ColorGradientRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ColorGradientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ColorGradientRepository', () {
    test('insert/get/update/delete works for gradients', () async {
      final id = await repository.insertGradient(
        model.ColorGradient(
          name: 'Sunset',
          colors: const [Color(0xFFFF6600), Color(0xFFFFCC00)],
          createdAt: fixedDate(1),
        ),
      );

      final inserted = await repository.getGradientById(id);
      expect(inserted.name, 'Sunset');

      await repository.updateGradient(
        model.ColorGradient(
          id: id,
          name: 'Sunrise',
          colors: const [Color(0xFFFF6600), Color(0xFFFFFF00)],
          createdAt: inserted.createdAt,
        ),
      );

      final updated = await repository.getGradientById(id);
      expect(updated.name, 'Sunrise');

      await repository.deleteGradient(id);
      await expectLater(
        repository.getGradientById(id),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('throws DatabaseError when table is unavailable', () async {
      await db.customStatement('DROP TABLE color_gradients;');

      expect(repository.getAllGradients, throwsA(isA<DatabaseError>()));
    });
  });
}
