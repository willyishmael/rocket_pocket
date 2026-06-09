import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

final pocketViewModelProvider =
    AsyncNotifierProvider<PocketViewModel, List<Pocket>>(PocketViewModel.new);

class PocketViewModel extends AsyncNotifier<List<Pocket>> {
  late PocketRepository _pocketRepository;

  @override
  FutureOr<List<Pocket>> build() async {
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    return await _fetchPockets();
  }

  Future<List<Pocket>> _fetchPockets() async {
    try {
      return _pocketRepository.getAllPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> refreshPockets() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPockets());
  }

  Future<void> addPocket(Pocket pocket) async {
    try {
      await _pocketRepository.insertPocket(pocket);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Pocket?> getPocketById(int id) async {
    try {
      return await _pocketRepository.getPocketById(id);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updatePocket(Pocket pocket) async {
    try {
      await _pocketRepository.updatePocket(pocket);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deletePocket(int id) async {
    try {
      await _pocketRepository.deletePocket(id);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> adjustBalance({
    required Pocket pocket,
    required double newBalance,
    required bool recordAsTransaction,
  }) async {
    final delta = newBalance - pocket.balance;

    try {
      await _pocketRepository.updatePocket(
        pocket.copyWith(balance: newBalance, updatedAt: DateTime.now()),
      );
      await refreshPockets();

      if (recordAsTransaction && delta != 0 && pocket.id != null) {
        final categoryRepo = ref.read(transactionCategoryRepositoryProvider);
        final transactionRepo = ref.read(transactionRepositoryProvider);

        final category = await categoryRepo.getOrCreateSystemCategory(
          name: 'Adjustment',
          type: TransactionType.adjustment,
        );

        final transaction = Transaction(
          senderPocketId: pocket.id,
          type: TransactionType.adjustment,
          categoryId: category.id,
          description: 'Balance Adjustment',
          amount: delta,
          date: DateTime.now(),
        );

        await transactionRepo.insertTransaction(
          transaction.toInsertCompanion(),
        );
        await ref
            .read(transactionViewModelProvider.notifier)
            .refreshTransactions();
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
