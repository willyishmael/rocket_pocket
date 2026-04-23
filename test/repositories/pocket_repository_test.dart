import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late PocketRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = PocketRepository(db, ColorGradientRepository(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('PocketRepository', () {
    test('insert/get/update/delete works for pockets', () async {
      final id = await repository.insertPocket(
        buildPocketModel(
          id: null,
          name: 'Travel',
          colorGradient: buildGradientModel(id: 1),
        ),
      );

      final inserted = await repository.getPocketById(id);
      expect(inserted, isNotNull);
      expect(inserted!.name, 'Travel');

      await repository.updatePocket(
        inserted.copyWith(name: 'Travel Fund', balance: 250),
      );
      final updated = await repository.getPocketById(id);
      expect(updated!.name, 'Travel Fund');
      expect(updated.balance, 250);

      await repository.deletePocket(id);
      expect(await repository.getPocketById(id), isNull);
    });

    test('throws DatabaseError when table is unavailable', () async {
      await db.customStatement('DROP TABLE pockets;');

      expect(repository.getAllPockets, throwsA(isA<DatabaseError>()));
    });
  });
}
