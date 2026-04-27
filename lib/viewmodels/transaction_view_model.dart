import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/screens/0_widgets/transaction_filter_sheet.dart';
import 'package:rocket_pocket/viewmodels/viewmodel_utils.dart';

// ── Filter / sort state ──────────────────────────────────────────────────────

class TransactionFilterState {
  /// Empty set means "show all types"; non-empty set filters to those types.
  final Set<TransactionType> activeTypeFilters;

  /// `null` means "auto-select the most recent month that has transactions".
  final DateTime? selectedMonth;

  final TransactionSortOrder sortOrder;

  const TransactionFilterState({
    this.activeTypeFilters = const {},
    this.selectedMonth,
    this.sortOrder = TransactionSortOrder.newest,
  });

  TransactionFilterState copyWith({
    Set<TransactionType>? activeTypeFilters,
    Object? selectedMonth = absent,
    TransactionSortOrder? sortOrder,
  }) {
    return TransactionFilterState(
      activeTypeFilters: activeTypeFilters ?? this.activeTypeFilters,
      selectedMonth:
          selectedMonth == absent
              ? this.selectedMonth
              : selectedMonth as DateTime?,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TransactionFilterViewModel extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() => const TransactionFilterState();

  void setTypeFilters(Set<TransactionType> filters) {
    state = state.copyWith(activeTypeFilters: Set.unmodifiable(filters));
  }

  void setSelectedMonth(DateTime? month) {
    state = state.copyWith(selectedMonth: month);
  }

  void setSortOrder(TransactionSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterViewModel, TransactionFilterState>(
      TransactionFilterViewModel.new,
    );

// ── Transaction list ─────────────────────────────────────────────────────────

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
