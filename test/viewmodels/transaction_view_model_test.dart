import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      TransactionsCompanion.insert(
        type: TransactionType.expense,
        description: 'Fallback',
        amount: 1,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    registerFallbackValue(
      TransactionsCompanion(
        id: const Value(1),
        updatedAt: Value(DateTime(2026, 1, 1)),
      ),
    );
  });

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  test('build loads rows and filterByType filters in-memory list', () async {
    final expense = buildTransactionModel(id: 1, type: TransactionType.expense);
    final income = buildTransactionModel(id: 2, type: TransactionType.income);

    when(
      () => mockRepository.getAllTransactions(),
    ).thenAnswer((_) async => [expense, income]);

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionViewModelProvider.future);
    final notifier = container.read(transactionViewModelProvider.notifier);

    expect(notifier.filterByType(TransactionType.expense), hasLength(1));
    expect(notifier.filterByType(null), hasLength(2));
  });

  test('addTransaction refreshes state on success', () async {
    final row = buildTransactionModel(id: 1, type: TransactionType.expense);
    final model = buildTransactionModel(type: TransactionType.expense);

    when(
      () => mockRepository.getAllTransactions(),
    ).thenAnswer((_) async => [row]);
    when(
      () => mockRepository.insertTransaction(any()),
    ).thenAnswer((_) async => 1);

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionViewModelProvider.future);
    await container
        .read(transactionViewModelProvider.notifier)
        .addTransaction(model);

    verify(() => mockRepository.insertTransaction(any())).called(1);
    expect(
      container.read(transactionViewModelProvider).requireValue,
      hasLength(1),
    );
  });

  test('deleteTransaction stores AsyncError and rethrows on failure', () async {
    when(() => mockRepository.getAllTransactions()).thenAnswer((_) async => []);
    when(() => mockRepository.deleteTransaction(1)).thenThrow(
      DatabaseError('Failed to delete transaction', StackTrace.empty),
    );

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionViewModelProvider.future);

    await expectLater(
      () => container
          .read(transactionViewModelProvider.notifier)
          .deleteTransaction(1),
      throwsA(isA<DatabaseError>()),
    );

    expect(container.read(transactionViewModelProvider).hasError, isTrue);
  });

  test('updateTransaction calls repository and refreshes state', () async {
    final initial = buildTransactionModel(
      id: 1,
      type: TransactionType.expense,
      description: 'Original',
    );
    final updated = buildTransactionModel(
      id: 1,
      type: TransactionType.expense,
      description: 'Updated',
    );

    when(
      () => mockRepository.getAllTransactions(),
    ).thenAnswer((_) async => [initial]);
    when(
      () => mockRepository.updateTransaction(any()),
    ).thenAnswer((_) async {});

    // Second call (after update) returns the updated model.
    var callCount = 0;
    when(() => mockRepository.getAllTransactions()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? [initial] : [updated];
    });

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionViewModelProvider.future);
    await container
        .read(transactionViewModelProvider.notifier)
        .updateTransaction(updated);

    verify(() => mockRepository.updateTransaction(any())).called(1);
    final state = container.read(transactionViewModelProvider).requireValue;
    expect(state.first.description, 'Updated');
  });

  test('refreshTransactions transitions through loading', () async {
    final tx = buildTransactionModel(id: 1);
    when(
      () => mockRepository.getAllTransactions(),
    ).thenAnswer((_) async => [tx]);

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionViewModelProvider.future);
    await container
        .read(transactionViewModelProvider.notifier)
        .refreshTransactions();

    expect(
      container.read(transactionViewModelProvider).requireValue,
      hasLength(1),
    );
    verify(() => mockRepository.getAllTransactions()).called(greaterThan(1));
  });

  group('TransactionFilterViewModel', () {
    test('initial state has empty filters and newest sort', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(transactionFilterProvider);
      expect(state.activeTypeFilters, isEmpty);
      expect(state.sortOrder, TransactionSortOrder.newest);
      expect(state.selectedMonth, isNull);
    });

    test('setTypeFilters updates active filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(transactionFilterProvider.notifier).setTypeFilters({
        TransactionType.expense,
        TransactionType.income,
      });

      final state = container.read(transactionFilterProvider);
      expect(state.activeTypeFilters, hasLength(2));
      expect(state.activeTypeFilters, contains(TransactionType.expense));
    });

    test('setSortOrder updates sort order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(transactionFilterProvider.notifier)
          .setSortOrder(TransactionSortOrder.oldest);

      expect(
        container.read(transactionFilterProvider).sortOrder,
        TransactionSortOrder.oldest,
      );
    });

    test('setSelectedMonth can be set and cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final month = DateTime(2026, 3);
      container
          .read(transactionFilterProvider.notifier)
          .setSelectedMonth(month);
      expect(container.read(transactionFilterProvider).selectedMonth, month);

      container.read(transactionFilterProvider.notifier).setSelectedMonth(null);
      expect(container.read(transactionFilterProvider).selectedMonth, isNull);
    });
  });
}
