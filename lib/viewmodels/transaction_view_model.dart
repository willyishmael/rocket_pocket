import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';

final transactionViewModelProvider =
    AsyncNotifierProvider<TransactionViewModel, List<Transaction>>(
      TransactionViewModel.new,
    );

class TransactionViewModel extends AsyncNotifier<List<Transaction>> {
  late TransactionRepository _transactionRepository;

  @override
  FutureOr<List<Transaction>> build() async {
    _transactionRepository = ref.watch(transactionRepositoryProvider);
    return await _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    try {
      return await _transactionRepository.getAllTransactions();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> refreshTransactions() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _transactionRepository.insertTransaction(
        transaction.toInsertCompanion(),
      );
      await refreshTransactions();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    try {
      return await _transactionRepository.getTransactionById(id);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _transactionRepository.updateTransaction(
        transaction.toUpdateCompanion(),
      );
      await refreshTransactions();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
      await refreshTransactions();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Returns the currently loaded transactions filtered by type.
  /// Does not trigger a DB fetch — filters the in-memory list.
  /// Returns all transactions if [type] is null.
  List<Transaction> filterByType(TransactionType? type) {
    final current = state.value;
    if (current == null) return [];
    if (type == null) return current;
    return current.where((t) => t.type == type).toList();
  }
}
