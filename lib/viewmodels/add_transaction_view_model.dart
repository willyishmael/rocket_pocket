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
  final List<db.TransactionCategory> allCategories;
  final List<Transaction> allTransactions;
  final TransactionType selectedType;
  final Pocket? senderPocket;
  final Pocket? receiverPocket;
  final db.TransactionCategory? selectedCategory;
  final String description;
  final double amount;
  final int? originalTransactionId;

  AddTransactionState({
    required this.pockets,
    required this.allCategories,
    required this.allTransactions,
    this.selectedType = TransactionType.expense,
    this.senderPocket,
    this.receiverPocket,
    this.selectedCategory,
    this.description = '',
    this.amount = 0,
    this.originalTransactionId,
  });

  /// Categories filtered to match the selected type.
  /// Refund shares expense categories; Transfer has no categories.
  List<db.TransactionCategory> get filteredCategories {
    final typeToFilter =
        selectedType == TransactionType.refund
            ? TransactionType.expense
            : selectedType;
    if (typeToFilter == TransactionType.transfer) return [];
    return allCategories.where((c) => c.type == typeToFilter).toList();
  }

  /// Expense transactions available to link as originals for a refund.
  List<Transaction> get refundableTransactions =>
      allTransactions.where((t) => t.type == TransactionType.expense).toList();

  AddTransactionState copyWith({
    List<Pocket>? pockets,
    List<db.TransactionCategory>? allCategories,
    List<Transaction>? allTransactions,
    TransactionType? selectedType,
    Pocket? senderPocket,
    Pocket? receiverPocket,
    db.TransactionCategory? selectedCategory,
    String? description,
    double? amount,
    int? originalTransactionId,
    bool clearSenderPocket = false,
    bool clearReceiverPocket = false,
    bool clearCategory = false,
    bool clearOriginalTransactionId = false,
  }) {
    return AddTransactionState(
      pockets: pockets ?? this.pockets,
      allCategories: allCategories ?? this.allCategories,
      allTransactions: allTransactions ?? this.allTransactions,
      selectedType: selectedType ?? this.selectedType,
      senderPocket:
          clearSenderPocket ? null : senderPocket ?? this.senderPocket,
      receiverPocket:
          clearReceiverPocket ? null : receiverPocket ?? this.receiverPocket,
      selectedCategory:
          clearCategory ? null : selectedCategory ?? this.selectedCategory,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      originalTransactionId:
          clearOriginalTransactionId
              ? null
              : originalTransactionId ?? this.originalTransactionId,
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
    if (selectedType == TransactionType.refund) {
      return senderPocket != null && originalTransactionId != null;
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
    final dbTransactions = await _transactionRepository.getAllTransactions();
    final transactions = dbTransactions.map(Transaction.fromDb).toList();

    final initialType = TransactionType.expense;
    final filteredCategories =
        categories.where((c) => c.type == initialType).toList();

    return AddTransactionState(
      pockets: pockets,
      allCategories: categories,
      allTransactions: transactions,
      selectedType: initialType,
      senderPocket: pockets.isNotEmpty ? pockets.first : null,
      selectedCategory:
          filteredCategories.isNotEmpty ? filteredCategories.first : null,
    );
  }

  void setType(TransactionType type) {
    final current = state.valueOrNull;
    if (current == null) return;
    // When switching type, clear category so user picks from the new filtered list
    final newFiltered =
        current.allCategories
            .where(
              (c) =>
                  c.type ==
                  (type == TransactionType.refund
                      ? TransactionType.expense
                      : type),
            )
            .toList();
    state = AsyncData(
      current
          .copyWith(
            selectedType: type,
            clearReceiverPocket: type != TransactionType.transfer,
            clearCategory: true,
            clearOriginalTransactionId: type != TransactionType.refund,
          )
          .copyWith(
            selectedCategory: newFiltered.isNotEmpty ? newFiltered.first : null,
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

  void setOriginalTransactionId(int? id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        originalTransactionId: id,
        clearOriginalTransactionId: id == null,
      ),
    );
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
        originalTransactionId: current.originalTransactionId,
      );
      await _transactionRepository.insertTransaction(
        transaction.toInsertCompanion(),
      );

      // Update pocket balance(s) based on transaction type
      final amount = current.amount;
      final sender = current.senderPocket;
      final receiver = current.receiverPocket;

      if (current.selectedType == TransactionType.transfer) {
        // Deduct from sender, credit receiver
        if (sender != null) {
          await _pocketRepository.updatePocket(
            sender.copyWith(balance: sender.balance - amount),
          );
        }
        if (receiver != null) {
          await _pocketRepository.updatePocket(
            receiver.copyWith(balance: receiver.balance + amount),
          );
        }
      } else if (current.selectedType.isPositive) {
        // income / refund — credit the pocket
        if (sender != null) {
          await _pocketRepository.updatePocket(
            sender.copyWith(balance: sender.balance + amount),
          );
        }
      } else {
        // expense — deduct from pocket
        if (sender != null) {
          await _pocketRepository.updatePocket(
            sender.copyWith(balance: sender.balance - amount),
          );
        }
      }

      // Reset form after successful submit
      state = AsyncData(current.copyWith(description: '', amount: 0));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
