import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';

class AddTransactionState {
  final List<Pocket> pockets;
  final List<db.TransactionCategory> categories;
  final TransactionType selectedType;
  final Pocket? senderPocket;
  final Pocket? receiverPocket;
  final db.TransactionCategory? selectedCategory;
  final String description;
  final double amount;

  AddTransactionState({
    required this.pockets,
    required this.categories,
    this.selectedType = TransactionType.expense,
    this.senderPocket,
    this.receiverPocket,
    this.selectedCategory,
    this.description = '',
    this.amount = 0,
  });

  AddTransactionState copyWith({
    List<Pocket>? pockets,
    List<db.TransactionCategory>? categories,
    TransactionType? selectedType,
    Pocket? senderPocket,
    Pocket? receiverPocket,
    db.TransactionCategory? selectedCategory,
    String? description,
    double? amount,
    bool clearSenderPocket = false,
    bool clearReceiverPocket = false,
    bool clearCategory = false,
  }) {
    return AddTransactionState(
      pockets: pockets ?? this.pockets,
      categories: categories ?? this.categories,
      selectedType: selectedType ?? this.selectedType,
      senderPocket:
          clearSenderPocket ? null : senderPocket ?? this.senderPocket,
      receiverPocket:
          clearReceiverPocket ? null : receiverPocket ?? this.receiverPocket,
      selectedCategory:
          clearCategory ? null : selectedCategory ?? this.selectedCategory,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }

  bool get isValid {
    if (description.trim().isEmpty) return false;
    if (amount <= 0) return false;
    if (selectedType == TransactionType.transfer) {
      return senderPocket != null &&
          receiverPocket != null &&
          senderPocket != receiverPocket;
    }
    return senderPocket != null;
  }
}

final addTransactionViewModelProvider =
    AsyncNotifierProvider<AddTransactionViewModel, AddTransactionState>(
      AddTransactionViewModel.new,
    );

class AddTransactionViewModel extends AsyncNotifier<AddTransactionState> {
  late PocketRepository _pocketRepository;
  late TransactionRepository _transactionRepository;

  @override
  FutureOr<AddTransactionState> build() async {
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    _transactionRepository = ref.watch(transactionRepositoryProvider);

    final pockets = await _pocketRepository.getAllPockets();
    final categories = await _transactionRepository.getAllCategories();

    return AddTransactionState(
      pockets: pockets,
      categories: categories,
      senderPocket: pockets.isNotEmpty ? pockets.first : null,
      selectedCategory: categories.isNotEmpty ? categories.first : null,
    );
  }

  void setType(TransactionType type) {
    final current = state.valueOrNull;
    if (current == null) return;
    // Clear receiver pocket when switching away from transfer
    state = AsyncData(
      current.copyWith(
        selectedType: type,
        clearReceiverPocket: type != TransactionType.transfer,
      ),
    );
  }

  void setSenderPocket(Pocket pocket) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(senderPocket: pocket));
  }

  void setReceiverPocket(Pocket pocket) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(receiverPocket: pocket));
  }

  void setCategory(db.TransactionCategory category) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCategory: category));
  }

  void setDescription(String description) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(description: description));
  }

  void setAmount(double amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(amount: amount));
  }

  Future<void> submit() async {
    final current = state.valueOrNull;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      final transaction = Transaction(
        type: current.selectedType,
        senderPocketId: current.senderPocket?.id,
        receiverPocketId: current.receiverPocket?.id,
        categoryId: current.selectedCategory?.id,
        description: current.description.trim(),
        amount: current.amount,
      );
      await _transactionRepository.insertTransaction(
        transaction.toInsertCompanion(),
      );
      // Reset form after successful submit
      state = AsyncData(current.copyWith(description: '', amount: 0));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
