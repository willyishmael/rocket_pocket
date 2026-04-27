import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/utils/pocket_balance_utils.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class TransactionDetailState {
  final Transaction transaction;
  final Map<int, Pocket> pockets;
  final bool isSaving;

  const TransactionDetailState({
    required this.transaction,
    this.pockets = const {},
    this.isSaving = false,
  });

  TransactionDetailState copyWith({
    Transaction? transaction,
    Map<int, Pocket>? pockets,
    bool? isSaving,
  }) {
    return TransactionDetailState(
      transaction: transaction ?? this.transaction,
      pockets: pockets ?? this.pockets,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class TransactionDetailViewModel
    extends AsyncNotifier<TransactionDetailState> {
  TransactionDetailViewModel(this._transactionId);

  final int _transactionId;
  late PocketRepository _pocketRepository;
  late TransactionRepository _transactionRepository;

  @override
  Future<TransactionDetailState> build() async {
    _pocketRepository = ref.read(pocketRepositoryProvider);
    _transactionRepository = ref.read(transactionRepositoryProvider);
    return _load(_transactionId);
  }

  Future<TransactionDetailState> _load(int transactionId) async {
    final transaction = await _transactionRepository.getTransactionById(
      transactionId,
    );
    if (transaction == null) throw Exception('Transaction not found');

    final pocketList = await _pocketRepository.getAllPockets();
    final pockets = {
      for (final p in pocketList)
        if (p.id != null) p.id!: p,
    };
    return TransactionDetailState(transaction: transaction, pockets: pockets);
  }

  /// Re-fetches the current transaction and pocket map from the repository.
  /// Call this after returning from the edit screen.
  Future<void> refreshTransaction() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_transactionId));
  }

  /// Reverts the transaction's pocket-balance impact and deletes the record.
  Future<void> deleteTransaction() async {
    final current = state.value;
    if (current == null || current.isSaving) return;

    state = AsyncData(current.copyWith(isSaving: true));
    try {
      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
        await applyPocketImpact(
          current.transaction,
          revert: true,
          pocketRepository: _pocketRepository,
        );
        await _transactionRepository.deleteTransaction(
          current.transaction.id!,
        );
      });

      ref.invalidate(transactionViewModelProvider);
      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(budgetViewModelProvider);

      state = AsyncData(current.copyWith(isSaving: false));
    } catch (e) {
      state = AsyncData(current.copyWith(isSaving: false));
      rethrow;
    }
  }
}

/// Provider for the transaction detail viewmodel, keyed by transaction ID.
///
/// Loads the transaction and its related pockets in [build], so no separate
/// load provider or manual initialisation call is needed.
final transactionDetailViewModelProvider = AsyncNotifierProvider.family<
  TransactionDetailViewModel,
  TransactionDetailState,
  int
>(TransactionDetailViewModel.new);
