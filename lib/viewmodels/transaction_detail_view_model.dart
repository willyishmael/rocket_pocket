import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class TransactionDetailState {
  final Transaction? transaction;
  final Map<int, Pocket> pockets;
  final bool isSaving;

  const TransactionDetailState({
    this.transaction,
    this.pockets = const {},
    this.isSaving = false,
  });

  TransactionDetailState copyWith({bool? isSaving}) {
    return TransactionDetailState(
      transaction: transaction,
      pockets: pockets,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class _TransactionDetailNotifier extends Notifier<TransactionDetailState> {
  late PocketRepository _pocketRepository;
  late TransactionRepository _transactionRepository;

  @override
  TransactionDetailState build() {
    _pocketRepository = ref.read(pocketRepositoryProvider);
    _transactionRepository = ref.read(transactionRepositoryProvider);
    return const TransactionDetailState();
  }

  void initializeFrom(Transaction transaction, Map<int, Pocket> pockets) {
    state = TransactionDetailState(transaction: transaction, pockets: pockets);
  }

  /// Re-fetches the current transaction and pocket map from the repository.
  /// Call this after returning from the edit screen.
  Future<void> refreshTransaction() async {
    final tx = state.transaction;
    if (tx?.id == null) return;

    final row = await _transactionRepository.getTransactionById(tx!.id!);
    final pocketList = await _pocketRepository.getAllPockets();
    final pocketMap = {
      for (final p in pocketList)
        if (p.id != null) p.id!: p,
    };

    state = TransactionDetailState(transaction: row, pockets: pocketMap);
  }

  /// Reverts the transaction's pocket-balance impact and deletes the record.
  Future<void> deleteTransaction() async {
    final tx = state.transaction;
    if (tx?.id == null || state.isSaving) return;

    state = state.copyWith(isSaving: true);
    try {
      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
        await _applyPocketImpact(tx!, revert: true);
        await _transactionRepository.deleteTransaction(tx.id!);
      });

      ref.invalidate(transactionViewModelProvider);
      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(budgetViewModelProvider);

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> _applyPocketImpact(
    Transaction tx, {
    required bool revert,
  }) async {
    final multiplier = revert ? -1.0 : 1.0;

    if (tx.type.isPositive) {
      await _updatePocketBalance(tx.senderPocketId, tx.amount * multiplier);
      return;
    }

    if (tx.type == TransactionType.transfer) {
      await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
      await _updatePocketBalance(tx.receiverPocketId, tx.amount * multiplier);
      return;
    }

    await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
  }

  Future<void> _updatePocketBalance(int? pocketId, double delta) async {
    if (pocketId == null || delta == 0) return;
    final pocket = await _pocketRepository.getPocketById(pocketId);
    if (pocket == null) return;
    await _pocketRepository.updatePocket(
      pocket.copyWith(balance: pocket.balance + delta),
    );
  }
}

final transactionDetailViewModelProvider =
    NotifierProvider<_TransactionDetailNotifier, TransactionDetailState>(
      _TransactionDetailNotifier.new,
    );

/// Loads the transaction and pocket map for the detail screen.
/// Separate from the mutable [transactionDetailViewModelProvider] so that
/// loading/error states are handled cleanly before the screen renders.
final transactionDetailLoadProvider =
    FutureProvider.family<(Transaction, Map<int, Pocket>), int>((
      ref,
      transactionId,
    ) async {
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      final pocketRepository = ref.watch(pocketRepositoryProvider);

      final transaction = await transactionRepository.getTransactionById(
        transactionId,
      );
      if (transaction == null) throw Exception('Transaction not found');

      final pocketList = await pocketRepository.getAllPockets();
      final pockets = {
        for (final p in pocketList)
          if (p.id != null) p.id!: p,
      };

      return (transaction, pockets);
    });
