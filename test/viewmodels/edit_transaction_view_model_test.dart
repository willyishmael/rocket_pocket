import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/edit_transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockPocketRepository extends Mock implements PocketRepository {}

class MockCategoryRepository extends Mock
    implements TransactionCategoriesRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

/// Creates a container with all four repositories overridden.
ProviderContainer _makeContainer({
  required MockTransactionRepository txRepo,
  required MockPocketRepository pocketRepo,
  required MockCategoryRepository categoryRepo,
  required MockBudgetRepository budgetRepo,
  required int txId,
}) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(txRepo),
      pocketRepositoryProvider.overrideWithValue(pocketRepo),
      transactionCategoryRepositoryProvider.overrideWithValue(categoryRepo),
      budgetRepositoryProvider.overrideWithValue(budgetRepo),
    ],
  );
}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockPocketRepository mockPocketRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockBudgetRepository mockBudgetRepo;

  setUpAll(() {
    registerFallbackValue(
      TransactionsCompanion(
        id: const Value(1),
        updatedAt: Value(DateTime(2026, 1, 1)),
      ),
    );
    registerFallbackValue(buildPocketModel());
  });

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockPocketRepo = MockPocketRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockBudgetRepo = MockBudgetRepository();
  });

  // Shared stub helpers.
  void stubLoad({
    int txId = 1,
    TransactionType type = TransactionType.expense,
    int? senderPocketId = 1,
    int? categoryId = 1,
  }) {
    when(() => mockTxRepo.getTransactionById(txId)).thenAnswer(
      (_) async => buildTransactionModel(
        id: txId,
        type: type,
        senderPocketId: senderPocketId,
        categoryId: categoryId,
      ),
    );
    when(
      () => mockPocketRepo.getAllPockets(),
    ).thenAnswer((_) async => [buildPocketModel(id: 1)]);
    when(() => mockCategoryRepo.getAllTransactionCategories()).thenAnswer(
      (_) async => [
        buildCategoryRow(
          id: 1,
          type:
              type == TransactionType.income
                  ? TransactionType.income
                  : TransactionType.expense,
        ),
      ],
    );
    when(() => mockBudgetRepo.getAllBudgets()).thenAnswer((_) async => []);
  }

  group('build()', () {
    test('loads transaction and populates initial state', () async {
      stubLoad(txId: 1, type: TransactionType.expense);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      final state = await container.read(
        editTransactionViewModelProvider(1).future,
      );

      expect(state.original?.id, 1);
      expect(state.selectedType, TransactionType.expense);
      expect(state.senderPocket?.id, 1);
      expect(state.description, 'Item');
      expect(state.amount, 10.0);
    });

    test('calls repository for each id independently', () async {
      stubLoad(txId: 1, type: TransactionType.expense);
      stubLoad(txId: 2, type: TransactionType.income);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      final state1 = await container.read(
        editTransactionViewModelProvider(1).future,
      );
      final state2 = await container.read(
        editTransactionViewModelProvider(2).future,
      );

      expect(state1.original?.id, 1);
      expect(state1.selectedType, TransactionType.expense);
      expect(state2.original?.id, 2);
      expect(state2.selectedType, TransactionType.income);
    });
  });

  group('setType()', () {
    test(
      'updates selectedType and clears receiver pocket for non-transfer',
      () async {
        stubLoad(txId: 1, type: TransactionType.expense);

        final container = _makeContainer(
          txRepo: mockTxRepo,
          pocketRepo: mockPocketRepo,
          categoryRepo: mockCategoryRepo,
          budgetRepo: mockBudgetRepo,
          txId: 1,
        );
        addTearDown(container.dispose);

        await container.read(editTransactionViewModelProvider(1).future);
        final notifier = container.read(
          editTransactionViewModelProvider(1).notifier,
        );

        notifier.setType(TransactionType.income);

        final updated =
            container.read(editTransactionViewModelProvider(1)).requireValue;
        expect(updated.selectedType, TransactionType.income);
        expect(updated.receiverPocket, isNull);
      },
    );

    test('clears budget when switching away from expense', () async {
      stubLoad(txId: 1, type: TransactionType.expense);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      await container.read(editTransactionViewModelProvider(1).future);
      final notifier = container.read(
        editTransactionViewModelProvider(1).notifier,
      );

      // Seed a budget then switch to income — budget should clear.
      notifier.setBudget(buildBudgetModel(id: 1));
      notifier.setType(TransactionType.income);

      final updated =
          container.read(editTransactionViewModelProvider(1)).requireValue;
      expect(updated.selectedBudget, isNull);
    });
  });

  group('filteredCategories', () {
    test('returns expense categories for refund type', () async {
      when(() => mockTxRepo.getTransactionById(1)).thenAnswer(
        (_) async => buildTransactionModel(
          id: 1,
          type: TransactionType.refund,
          senderPocketId: 1,
        ),
      );
      when(
        () => mockPocketRepo.getAllPockets(),
      ).thenAnswer((_) async => [buildPocketModel(id: 1)]);
      when(() => mockCategoryRepo.getAllTransactionCategories()).thenAnswer(
        (_) async => [
          buildCategoryRow(id: 1, type: TransactionType.expense),
          buildCategoryRow(id: 2, type: TransactionType.income),
        ],
      );
      when(() => mockBudgetRepo.getAllBudgets()).thenAnswer((_) async => []);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      final state = await container.read(
        editTransactionViewModelProvider(1).future,
      );
      expect(state.selectedType, TransactionType.refund);
      expect(state.filteredCategories, hasLength(1));
      expect(state.filteredCategories.first.type, TransactionType.expense);
    });

    test('returns empty list for transfer type', () async {
      when(() => mockTxRepo.getTransactionById(1)).thenAnswer(
        (_) async => buildTransactionModel(
          id: 1,
          type: TransactionType.transfer,
          senderPocketId: 1,
          receiverPocketId: 2,
        ),
      );
      when(() => mockPocketRepo.getAllPockets()).thenAnswer(
        (_) async => [
          buildPocketModel(id: 1),
          buildPocketModel(id: 2, name: 'B'),
        ],
      );
      when(
        () => mockCategoryRepo.getAllTransactionCategories(),
      ).thenAnswer((_) async => []);
      when(() => mockBudgetRepo.getAllBudgets()).thenAnswer((_) async => []);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      final state = await container.read(
        editTransactionViewModelProvider(1).future,
      );
      expect(state.filteredCategories, isEmpty);
    });
  });

  group('isValid', () {
    test('returns false when description is empty', () async {
      stubLoad(txId: 1, type: TransactionType.expense);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      await container.read(editTransactionViewModelProvider(1).future);
      final notifier = container.read(
        editTransactionViewModelProvider(1).notifier,
      );
      notifier.setDescription('');

      final state =
          container.read(editTransactionViewModelProvider(1)).requireValue;
      expect(state.isValid, isFalse);
    });

    test('returns true for valid expense with category', () async {
      stubLoad(txId: 1, type: TransactionType.expense);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      final state = await container.read(
        editTransactionViewModelProvider(1).future,
      );
      // Default state after load should be valid (description='Item', amount=10,
      // senderPocket set, category set).
      expect(state.isValid, isTrue);
    });
  });

  group('field setters', () {
    test('setDescription, setAmount, setDate update state', () async {
      stubLoad(txId: 1, type: TransactionType.expense);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      await container.read(editTransactionViewModelProvider(1).future);
      final notifier = container.read(
        editTransactionViewModelProvider(1).notifier,
      );

      final newDate = DateTime(2026, 6, 1);
      notifier.setDescription('Updated');
      notifier.setAmount(999.0);
      notifier.setDate(newDate);

      final state =
          container.read(editTransactionViewModelProvider(1)).requireValue;
      expect(state.description, 'Updated');
      expect(state.amount, 999.0);
      expect(state.date, newDate);
    });

    test('setSenderPocket and setReceiverPocket update pockets', () async {
      when(() => mockTxRepo.getTransactionById(1)).thenAnswer(
        (_) async => buildTransactionModel(
          id: 1,
          type: TransactionType.transfer,
          senderPocketId: 1,
        ),
      );
      final pocket1 = buildPocketModel(id: 1, name: 'A');
      final pocket2 = buildPocketModel(id: 2, name: 'B');
      when(
        () => mockPocketRepo.getAllPockets(),
      ).thenAnswer((_) async => [pocket1, pocket2]);
      when(
        () => mockCategoryRepo.getAllTransactionCategories(),
      ).thenAnswer((_) async => []);
      when(() => mockBudgetRepo.getAllBudgets()).thenAnswer((_) async => []);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        categoryRepo: mockCategoryRepo,
        budgetRepo: mockBudgetRepo,
        txId: 1,
      );
      addTearDown(container.dispose);

      await container.read(editTransactionViewModelProvider(1).future);
      final notifier = container.read(
        editTransactionViewModelProvider(1).notifier,
      );

      notifier.setSenderPocket(pocket2);
      notifier.setReceiverPocket(pocket1);

      final state =
          container.read(editTransactionViewModelProvider(1)).requireValue;
      expect(state.senderPocket?.id, 2);
      expect(state.receiverPocket?.id, 1);
    });
  });
}
