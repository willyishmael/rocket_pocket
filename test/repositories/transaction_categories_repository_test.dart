import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late TransactionCategoriesRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionCategoriesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionCategoriesRepository', () {
    test('filters by type and gets category by id', () async {
      final id = await repository.insertTransactionCategory(
        TransactionCategoriesCompanion.insert(
          name: 'Bonus',
          type: Value(TransactionType.income),
          updatedAt: fixedDate(1),
        ),
      );

      final incomeCategories = await repository
          .getAllTransactionCategoriesByType(TransactionType.income);
      final category = await repository.getTransactionCategoryById(id);

      expect(incomeCategories.any((item) => item.id == id), isTrue);
      expect(category!.name, 'Bonus');
    });

    test('update name and delete persist changes', () async {
      final id = await repository.insertTransactionCategory(
        TransactionCategoriesCompanion.insert(
          name: 'Temp',
          type: Value(TransactionType.expense),
          updatedAt: fixedDate(1),
        ),
      );

      await repository.updateTransactionCategoryName(id, 'Updated');
      expect(
        (await repository.getTransactionCategoryById(id))!.name,
        'Updated',
      );

      await repository.deleteTransactionCategory(id);
      expect(await repository.getTransactionCategoryById(id), isNull);
    });

    test('throws DatabaseError when table is unavailable', () async {
      await db.customStatement('DROP TABLE transaction_categories;');

      expect(
        repository.getAllTransactionCategories,
        throwsA(isA<DatabaseError>()),
      );
    });
  });
}
