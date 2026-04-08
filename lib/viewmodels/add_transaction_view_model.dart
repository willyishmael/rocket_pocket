import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

/// Sentinel used in [AddTransactionState.copyWith] to distinguish
/// "keep existing value" from "explicitly set to null".
const Object _absent = Object();

class AddTransactionState {
  final List<Pocket> pockets;
  final List<db.TransactionCategory> allCategories;
  final List<Transaction> allTransactions;
  final List<budget_model.Budget> allBudgets;
  final TransactionType selectedType;
  final Pocket? senderPocket;
  final Pocket? receiverPocket;
  final db.TransactionCategory? selectedCategory;
  final budget_model.Budget? selectedBudget;
  final String description;
  final double amount;
  final DateTime date;
  final int? originalTransactionId;

  AddTransactionState({
    required this.pockets,
    required this.allCategories,
    required this.allTransactions,
    this.allBudgets = const [],
    this.selectedType = TransactionType.expense,
    this.senderPocket,
    this.receiverPocket,
    this.selectedCategory,
    this.selectedBudget,
    this.description = '',
    this.amount = 0,
    DateTime? date,
    this.originalTransactionId,
  }) : date = date ?? DateTime.now();

  /// Categories filtered to match the selected type.
  /// Only expense and income have categories; refund borrows expense categories.
  /// All other types (transfer, loan*, adjustment) return empty.
  List<db.TransactionCategory> get filteredCategories {
    final lookup =
        selectedType == TransactionType.refund
            ? TransactionType.expense
            : selectedType;
    if (lookup != TransactionType.expense && lookup != TransactionType.income) {
      return [];
    }
    return allCategories.where((c) => c.type == lookup).toList();
  }

  /// Expense transactions available to link as originals for a refund.
  List<Transaction> get refundableTransactions =>
      allTransactions.where((t) => t.type == TransactionType.expense).toList();

  AddTransactionState copyWith({
    List<Pocket>? pockets,
    List<db.TransactionCategory>? allCategories,
    List<Transaction>? allTransactions,
    List<budget_model.Budget>? allBudgets,
    TransactionType? selectedType,
    // Nullable fields — pass null to clear, omit to keep existing value.
    Object? senderPocket = _absent,
    Object? receiverPocket = _absent,
    Object? selectedCategory = _absent,
    Object? selectedBudget = _absent,
    Object? originalTransactionId = _absent,
    // Non-nullable fields.
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return AddTransactionState(
      pockets: pockets ?? this.pockets,
      allCategories: allCategories ?? this.allCategories,
      allTransactions: allTransactions ?? this.allTransactions,
      allBudgets: allBudgets ?? this.allBudgets,
      selectedType: selectedType ?? this.selectedType,
      senderPocket:
          senderPocket == _absent ? this.senderPocket : senderPocket as Pocket?,
      receiverPocket:
          receiverPocket == _absent
              ? this.receiverPocket
              : receiverPocket as Pocket?,
      selectedCategory:
          selectedCategory == _absent
              ? this.selectedCategory
              : selectedCategory as db.TransactionCategory?,
      selectedBudget:
          selectedBudget == _absent
              ? this.selectedBudget
              : selectedBudget as budget_model.Budget?,
      originalTransactionId:
          originalTransactionId == _absent
              ? this.originalTransactionId
              : originalTransactionId as int?,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
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
  late TransactionCategoriesRepository _categoryRepository;
  late BudgetRepository _budgetRepository;

  @override
  FutureOr<AddTransactionState> build() async {
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    _transactionRepository = ref.watch(transactionRepositoryProvider);
    _categoryRepository = ref.watch(transactionCategoryRepositoryProvider);
    _budgetRepository = ref.watch(budgetRepositoryProvider);

    final pockets = await _pocketRepository.getAllPockets();
    final categories = await _categoryRepository.getAllTransactionCategories();
    final dbTransactions = await _transactionRepository.getAllTransactions();
    final transactions = dbTransactions.map(Transaction.fromDb).toList();
    final dbBudgets = await _budgetRepository.getAllBudgets();
    final budgets = dbBudgets.map(budget_model.Budget.fromDb).toList();

    final initialType = TransactionType.expense;
    final filteredCategories =
        categories.where((c) => c.type == initialType).toList();

    return AddTransactionState(
      pockets: pockets,
      allCategories: categories,
      allTransactions: transactions,
      allBudgets: budgets,
      selectedType: initialType,
      senderPocket: pockets.isNotEmpty ? pockets.first : null,
      selectedCategory:
          filteredCategories.isNotEmpty ? filteredCategories.first : null,
    );
  }

  void setType(TransactionType type) {
    final current = state.value;
    if (current == null) return;

    final categoryLookup =
        type == TransactionType.refund ? TransactionType.expense : type;
    final newCategory =
        current.allCategories
            .where((c) => c.type == categoryLookup)
            .firstOrNull;

    state = AsyncData(
      current.copyWith(
        selectedType: type,
        // Keep receiverPocket only when switching to transfer
        receiverPocket: type == TransactionType.transfer ? _absent : null,
        // Auto-select first matching category (null for types with no categories)
        selectedCategory: newCategory,
        // Keep originalTransactionId only when switching to refund
        originalTransactionId: type == TransactionType.refund ? _absent : null,
        // Budget only applies to expenses — clear it for other types
        selectedBudget: type == TransactionType.expense ? _absent : null,
      ),
    );
  }

  void setSenderPocket(Pocket pocket) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(senderPocket: pocket));
  }

  void setReceiverPocket(Pocket pocket) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(receiverPocket: pocket));
  }

  void setCategory(db.TransactionCategory category) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCategory: category));
  }

  void setBudget(budget_model.Budget? budget) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedBudget: budget));
  }

  void setOriginalTransactionId(int? id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(originalTransactionId: id));
  }

  void setDescription(String description) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(description: description));
  }

  void setAmount(double amount) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(amount: amount));
  }

  void setDate(DateTime date) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(date: date));
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      final transaction = Transaction(
        type: current.selectedType,
        senderPocketId: current.senderPocket?.id,
        receiverPocketId: current.receiverPocket?.id,
        categoryId: current.selectedCategory?.id,
        budgetId:
            current.selectedType == TransactionType.expense
                ? current.selectedBudget?.id
                : null,
        description: current.description.trim(),
        amount: current.amount,
        date: current.date,
        originalTransactionId: current.originalTransactionId,
      );

      // Ensure the insert and all balance updates happen atomically.
      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
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
      });

      // Ensure pocket balances in the UI are refreshed after DB updates
      ref.invalidate(pocketViewModelProvider);
      // Refresh budget spent amounts after the new transaction
      ref.invalidate(budgetViewModelProvider);
      // Reset form after successful submit
      state = AsyncData(current.copyWith(description: '', amount: 0));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
