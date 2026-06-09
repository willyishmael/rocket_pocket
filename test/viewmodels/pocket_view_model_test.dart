import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockPocketRepository extends Mock implements PocketRepository {}

class MockTransactionCategoriesRepository extends Mock
    implements TransactionCategoriesRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockPocketRepository mockRepository;
  late MockTransactionCategoriesRepository mockCategoryRepository;
  late MockTransactionRepository mockTransactionRepository;

  setUpAll(() {
    registerFallbackValue(buildPocketModel());
    registerFallbackValue(
      TransactionsCompanion.insert(
        type: TransactionType.adjustment,
        description: 'Fallback',
        amount: 1,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockPocketRepository();
    mockCategoryRepository = MockTransactionCategoriesRepository();
    mockTransactionRepository = MockTransactionRepository();
  });

  test('build loads pockets and addPocket refreshes them', () async {
    final pockets = [buildPocketModel(id: 1, name: 'Wallet')];
    when(() => mockRepository.getAllPockets()).thenAnswer((_) async => pockets);
    when(() => mockRepository.insertPocket(any())).thenAnswer((_) async => 1);

    final container = ProviderContainer(
      overrides: [pocketRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(pocketViewModelProvider.future), pockets);
    await container
        .read(pocketViewModelProvider.notifier)
        .addPocket(buildPocketModel(id: null, name: 'Wallet'));

    verify(() => mockRepository.insertPocket(any())).called(1);
    expect(container.read(pocketViewModelProvider).requireValue, pockets);
  });

  test('deletePocket stores AsyncError and rethrows on failure', () async {
    when(() => mockRepository.getAllPockets()).thenAnswer((_) async => []);
    when(
      () => mockRepository.deletePocket(1),
    ).thenThrow(DatabaseError('Failed to delete pocket', StackTrace.empty));

    final container = ProviderContainer(
      overrides: [pocketRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await container.read(pocketViewModelProvider.future);

    await expectLater(
      () => container.read(pocketViewModelProvider.notifier).deletePocket(1),
      throwsA(isA<DatabaseError>()),
    );

    expect(container.read(pocketViewModelProvider).hasError, isTrue);
  });

  test(
    'adjustBalance updates pocket without creating transaction when unchecked',
    () async {
      final pocket = buildPocketModel(id: 1, balance: 100);
      final refreshed = [buildPocketModel(id: 1, balance: 150)];

      when(
        () => mockRepository.getAllPockets(),
      ).thenAnswer((_) async => refreshed);
      when(
        () => mockRepository.updatePocket(any()),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          pocketRepositoryProvider.overrideWithValue(mockRepository),
          transactionCategoryRepositoryProvider.overrideWithValue(
            mockCategoryRepository,
          ),
          transactionRepositoryProvider.overrideWithValue(
            mockTransactionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pocketViewModelProvider.future);
      await container
          .read(pocketViewModelProvider.notifier)
          .adjustBalance(
            pocket: pocket,
            newBalance: 150,
            recordAsTransaction: false,
          );

      verify(() => mockRepository.updatePocket(any())).called(1);
      verifyNever(
        () => mockCategoryRepository.getOrCreateSystemCategory(
          name: 'Adjustment',
          type: TransactionType.adjustment,
        ),
      );
      verifyNever(() => mockTransactionRepository.insertTransaction(any()));
      verifyNever(() => mockTransactionRepository.getAllTransactions());
    },
  );

  test(
    'adjustBalance records adjustment transaction and refreshes list',
    () async {
      final pocket = buildPocketModel(id: 1, balance: 100);
      final refreshedPockets = [buildPocketModel(id: 1, balance: 80)];
      final adjustmentCategory = buildCategoryRow(
        id: 99,
        name: 'Adjustment',
        type: TransactionType.adjustment,
        isSystem: true,
      );

      when(
        () => mockRepository.getAllPockets(),
      ).thenAnswer((_) async => refreshedPockets);
      when(
        () => mockRepository.updatePocket(any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockCategoryRepository.getOrCreateSystemCategory(
          name: 'Adjustment',
          type: TransactionType.adjustment,
        ),
      ).thenAnswer((_) async => adjustmentCategory);
      when(
        () => mockTransactionRepository.insertTransaction(any()),
      ).thenAnswer((_) async => 1);
      when(
        () => mockTransactionRepository.getAllTransactions(),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          pocketRepositoryProvider.overrideWithValue(mockRepository),
          transactionCategoryRepositoryProvider.overrideWithValue(
            mockCategoryRepository,
          ),
          transactionRepositoryProvider.overrideWithValue(
            mockTransactionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pocketViewModelProvider.future);
      await container
          .read(pocketViewModelProvider.notifier)
          .adjustBalance(
            pocket: pocket,
            newBalance: 80,
            recordAsTransaction: true,
          );

      verify(() => mockRepository.updatePocket(any())).called(1);
      verify(
        () => mockCategoryRepository.getOrCreateSystemCategory(
          name: 'Adjustment',
          type: TransactionType.adjustment,
        ),
      ).called(1);
      verify(
        () => mockTransactionRepository.insertTransaction(any()),
      ).called(1);
      verify(
        () => mockTransactionRepository.getAllTransactions(),
      ).called(greaterThanOrEqualTo(1));
    },
  );
}
