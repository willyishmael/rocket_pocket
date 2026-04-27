import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as localDb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/transaction_detail_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockPocketRepository extends Mock implements PocketRepository {}

/// Creates an isolated container with repository overrides.
/// Pass [database] to also override [appDatabaseProvider] (e.g. with an
/// in-memory instance) when the viewmodel calls [database.transaction()].
ProviderContainer _makeContainer({
  required MockTransactionRepository txRepo,
  required MockPocketRepository pocketRepo,
  localDb.AppDatabase? database,
}) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(txRepo),
      pocketRepositoryProvider.overrideWithValue(pocketRepo),
      if (database != null)
        localDb.appDatabaseProvider.overrideWithValue(database),
    ],
  );
}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockPocketRepository mockPocketRepo;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockPocketRepo = MockPocketRepository();
  });

  setUpAll(() {
    registerFallbackValue(buildPocketModel());
  });

  void stubLoad({int txId = 1, List<Pocket>? pockets}) {
    when(() => mockTxRepo.getTransactionById(txId)).thenAnswer(
      (_) async => buildTransactionModel(id: txId, senderPocketId: 1),
    );
    when(
      () => mockPocketRepo.getAllPockets(),
    ).thenAnswer((_) async => pockets ?? [buildPocketModel(id: 1)]);
  }

  group('build()', () {
    test('loads transaction and pocket map', () async {
      stubLoad(txId: 5, pockets: [buildPocketModel(id: 1)]);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
      );
      addTearDown(container.dispose);

      final state = await container.read(
        transactionDetailViewModelProvider(5).future,
      );

      expect(state.transaction.id, 5);
      expect(state.pockets, contains(1));
      expect(state.isSaving, isFalse);
    });

    test('calls repository for each id independently', () async {
      final pocket1 = buildPocketModel(id: 1);
      when(() => mockTxRepo.getTransactionById(5)).thenAnswer(
        (_) async => buildTransactionModel(id: 5, senderPocketId: 1),
      );
      when(() => mockTxRepo.getTransactionById(6)).thenAnswer(
        (_) async => buildTransactionModel(id: 6, senderPocketId: 1),
      );
      when(
        () => mockPocketRepo.getAllPockets(),
      ).thenAnswer((_) async => [pocket1]);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
      );
      addTearDown(container.dispose);

      final state5 = await container.read(
        transactionDetailViewModelProvider(5).future,
      );
      final state6 = await container.read(
        transactionDetailViewModelProvider(6).future,
      );

      expect(state5.transaction.id, 5);
      expect(state6.transaction.id, 6);
      // Each load is independent — the provider is keyed by ID.
      verify(() => mockTxRepo.getTransactionById(5)).called(1);
      verify(() => mockTxRepo.getTransactionById(6)).called(1);
    });
  });

  group('refreshTransaction()', () {
    test('re-fetches data and updates state', () async {
      stubLoad(txId: 1);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
      );
      addTearDown(container.dispose);

      await container.read(transactionDetailViewModelProvider(1).future);

      // Update stub to return a modified transaction.
      when(() => mockTxRepo.getTransactionById(1)).thenAnswer(
        (_) async => buildTransactionModel(
          id: 1,
          senderPocketId: 1,
          description: 'Updated description',
        ),
      );

      await container
          .read(transactionDetailViewModelProvider(1).notifier)
          .refreshTransaction();

      final state =
          container.read(transactionDetailViewModelProvider(1)).requireValue;
      expect(state.transaction.description, 'Updated description');
    });
  });

  group('deleteTransaction()', () {
    test('sets isSaving during delete and calls repository', () async {
      stubLoad(txId: 1, pockets: [buildPocketModel(id: 1, balance: 100.0)]);

      when(
        () => mockPocketRepo.getPocketById(1),
      ).thenAnswer((_) async => buildPocketModel(id: 1, balance: 100.0));
      when(
        () => mockPocketRepo.updatePocket(any()),
      ).thenAnswer((_) async => true);
      when(() => mockTxRepo.deleteTransaction(1)).thenAnswer((_) async {});

      // Use an in-memory AppDatabase so database.transaction() can wrap the
      // mocked repository calls in a real Drift SQL transaction.
      final inMemoryDb = localDb.AppDatabase(NativeDatabase.memory());
      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
        database: inMemoryDb,
      );
      addTearDown(container.dispose);
      addTearDown(inMemoryDb.close);

      await container.read(transactionDetailViewModelProvider(1).future);

      // Capture isSaving transitions emitted during deleteTransaction().
      final savingTransitions = <bool>[];
      container.listen(transactionDetailViewModelProvider(1), (_, next) {
        final v = next.asData?.value;
        if (v != null) savingTransitions.add(v.isSaving);
      }, fireImmediately: false);

      await container
          .read(transactionDetailViewModelProvider(1).notifier)
          .deleteTransaction();

      // isSaving should have gone true → false.
      expect(savingTransitions, equals([true, false]));

      // All three repository methods that the delete flow touches.
      verify(() => mockPocketRepo.getPocketById(1)).called(1);
      verify(() => mockPocketRepo.updatePocket(any())).called(1);
      verify(() => mockTxRepo.deleteTransaction(1)).called(1);
    });

    test('no-op when state is not loaded', () async {
      // Keep the provider in AsyncLoading by returning a Completer future
      // that never resolves — state.value is null, so deleteTransaction returns
      // early without touching the repository.
      when(
        () => mockTxRepo.getTransactionById(any()),
      ).thenAnswer((_) => Completer<Transaction?>().future);
      when(() => mockPocketRepo.getAllPockets()).thenAnswer((_) async => []);

      final container = _makeContainer(
        txRepo: mockTxRepo,
        pocketRepo: mockPocketRepo,
      );
      addTearDown(container.dispose);

      // Instantiate the provider (it stays in AsyncLoading).
      container.read(transactionDetailViewModelProvider(99));

      // deleteTransaction with AsyncLoading state → no-op.
      await container
          .read(transactionDetailViewModelProvider(99).notifier)
          .deleteTransaction();

      verifyNever(() => mockTxRepo.deleteTransaction(any()));
    });
  });

  group('TransactionDetailState', () {
    test('copyWith updates isSaving while preserving other fields', () {
      final original = buildTransactionModel(id: 1);
      final state = TransactionDetailState(
        transaction: original,
        pockets: {1: buildPocketModel(id: 1, name: 'A')},
      );

      final updated = state.copyWith(isSaving: true);
      expect(updated.isSaving, isTrue);
      expect(updated.transaction, same(original));
    });

    test('state with income type has senderPocketId set', () {
      final tx = buildTransactionModel(
        id: 2,
        type: TransactionType.income,
        senderPocketId: 3,
      );
      expect(tx.senderPocketId, 3);
      expect(tx.type, TransactionType.income);
    });
  });
}
