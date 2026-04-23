import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
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
    final expense = buildTransactionRow(id: 1, type: TransactionType.expense);
    final income = buildTransactionRow(id: 2, type: TransactionType.income);

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
    final row = buildTransactionRow(id: 1, type: TransactionType.expense);
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
}
