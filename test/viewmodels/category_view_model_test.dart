import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/category_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockCategoryRepository extends Mock
    implements TransactionCategoriesRepository {}

void main() {
  late MockCategoryRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      TransactionCategoriesCompanion.insert(
        name: 'Fallback',
        type: const Value(TransactionType.expense),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockCategoryRepository();
  });

  test('build loads categories and addCategory refreshes them', () async {
    final categories = [
      buildCategoryRow(id: 99, name: 'Bonus', type: TransactionType.income),
    ];
    when(
      () => mockRepository.getAllTransactionCategories(),
    ).thenAnswer((_) async => categories);
    when(
      () => mockRepository.insertTransactionCategory(any()),
    ).thenAnswer((_) async => 99);

    final container = ProviderContainer(
      overrides: [
        transactionCategoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(categoryViewModelProvider.future), categories);
    await container
        .read(categoryViewModelProvider.notifier)
        .addCategory('Bonus', TransactionType.income);

    verify(() => mockRepository.insertTransactionCategory(any())).called(1);
    expect(container.read(categoryViewModelProvider).requireValue, categories);
  });

  test('renameCategory stores AsyncError on failure', () async {
    when(
      () => mockRepository.getAllTransactionCategories(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.updateTransactionCategoryName(1, 'Renamed'),
    ).thenThrow(
      DatabaseError(
        'Failed to update transaction category name',
        StackTrace.empty,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        transactionCategoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(categoryViewModelProvider.future);
    await container
        .read(categoryViewModelProvider.notifier)
        .renameCategory(1, 'Renamed');

    expect(container.read(categoryViewModelProvider).hasError, isTrue);
  });
}
