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

/// Sentinel used in [EditTransactionState.copyWith] to distinguish
/// "keep existing value" from "explicitly set to null".
const Object _absent = Object();

class EditTransactionState {
  final Transaction? original;
  final List<Pocket> pockets;
  final List<db.TransactionCategory> allCategories;
  final List<budget_model.Budget> allBudgets;
  final TransactionType selectedType;
  final Pocket? senderPocket;
  final Pocket? receiverPocket;
  final db.TransactionCategory? selectedCategory;
  final budget_model.Budget? selectedBudget;
  final String description;
  final double amount;
  final DateTime date;
  final bool isSaving;

  EditTransactionState({
    this.original,
    required this.pockets,
    required this.allCategories,
    this.allBudgets = const [],
    TransactionType? selectedType,
    this.senderPocket,
    this.receiverPocket,
    this.selectedCategory,
    this.selectedBudget,
    this.description = '',
    this.amount = 0,
    DateTime? date,
    this.isSaving = false,
  }) : selectedType = selectedType ?? TransactionType.expense,
       date = date ?? DateTime.now();

  /// Categories filtered to match the selected type.
  List<db.TransactionCategory> get filteredCategories {
    if (selectedType != TransactionType.expense &&
        selectedType != TransactionType.income) {
      return [];
    }
    return allCategories.where((c) => c.type == selectedType).toList();
  }

  /// Whether all required fields are valid for saving.
  bool get isValid {
    if (description.trim().isEmpty) return false;
    if (amount <= 0) return false;
    if (senderPocket == null) return false;
    if (selectedType == TransactionType.transfer) {
      return receiverPocket != null && receiverPocket != senderPocket;
    }
    return selectedCategory != null;
  }

  EditTransactionState copyWith({
    Object? original = _absent,
    List<Pocket>? pockets,
    List<db.TransactionCategory>? allCategories,
    List<budget_model.Budget>? allBudgets,
    TransactionType? selectedType,
    Object? senderPocket = _absent,
    Object? receiverPocket = _absent,
    Object? selectedCategory = _absent,
    Object? selectedBudget = _absent,
    String? description,
    double? amount,
    DateTime? date,
    bool? isSaving,
  }) {
    return EditTransactionState(
      original: original == _absent ? this.original : original as Transaction?,
      pockets: pockets ?? this.pockets,
      allCategories: allCategories ?? this.allCategories,
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
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// StateNotifier for managing edit transaction form state.
/// Parameterized by transaction ID so it loads its own data from all
/// required repositories without any external initialization call.
class EditTransactionNotifier extends AsyncNotifier<EditTransactionState> {
  EditTransactionNotifier(this._transactionId);

  final int _transactionId;
  late PocketRepository _pocketRepository;
  late TransactionRepository _transactionRepository;
  late TransactionCategoriesRepository _categoryRepository;
  late BudgetRepository _budgetRepository;

  @override
  Future<EditTransactionState> build() async {
    _pocketRepository = ref.read(pocketRepositoryProvider);
    _transactionRepository = ref.read(transactionRepositoryProvider);
    _categoryRepository = ref.read(transactionCategoryRepositoryProvider);
    _budgetRepository = ref.read(budgetRepositoryProvider);

    final transactionRow = await _transactionRepository.getTransactionById(
      _transactionId,
    );
    if (transactionRow == null) throw Exception('Transaction not found');

    final transaction = Transaction.fromDb(transactionRow);
    final pockets = await _pocketRepository.getAllPockets();
    final categories = await _categoryRepository.getAllTransactionCategories();
    final budgetRows = await _budgetRepository.getAllBudgets();
    final budgets = budgetRows.map(budget_model.Budget.fromDb).toList();

    return EditTransactionState(
      original: transaction,
      pockets: pockets,
      allCategories: categories,
      allBudgets: budgets,
      selectedType: transaction.type,
      senderPocket: _findPocketById(transaction.senderPocketId, pockets),
      receiverPocket: _findPocketById(transaction.receiverPocketId, pockets),
      selectedCategory: _findCategoryById(transaction.categoryId, categories),
      selectedBudget: _findBudgetById(transaction.budgetId, budgets),
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date ?? transaction.createdAt ?? DateTime.now(),
    );
  }

  Pocket? _findPocketById(int? id, List<Pocket> pockets) {
    if (id == null) return null;
    for (final pocket in pockets) {
      if (pocket.id == id) return pocket;
    }
    return null;
  }

  db.TransactionCategory? _findCategoryById(
    int? id,
    List<db.TransactionCategory> categories,
  ) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  budget_model.Budget? _findBudgetById(
    int? id,
    List<budget_model.Budget> budgets,
  ) {
    if (id == null) return null;
    for (final budget in budgets) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  void setType(TransactionType type) {
    final current = state.value;
    if (current == null) return;
    final newCategory =
        current.allCategories.where((c) => c.type == type).firstOrNull;
    state = AsyncData(
      current.copyWith(
        selectedType: type,
        receiverPocket: type == TransactionType.transfer ? _absent : null,
        selectedCategory: newCategory,
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
    if (current == null || current.selectedType != TransactionType.expense) {
      return;
    }
    state = AsyncData(current.copyWith(selectedBudget: budget));
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

  /// Builds the updated transaction with current form values.
  Transaction _buildUpdatedTransaction(EditTransactionState current) {
    final original = current.original!;
    return original.copyWith(
      type: current.selectedType,
      senderPocketId: current.senderPocket?.id,
      receiverPocketId:
          current.selectedType == TransactionType.transfer
              ? current.receiverPocket?.id
              : null,
      categoryId:
          current.selectedType == TransactionType.transfer
              ? null
              : current.selectedCategory?.id,
      budgetId:
          current.selectedType == TransactionType.expense
              ? current.selectedBudget?.id
              : null,
      description: current.description.trim(),
      amount: current.amount,
      date: current.date,
    );
  }

  /// Applies pocket balance changes (delta) for a transaction.
  Future<void> _applyPocketImpact(
    Transaction tx, {
    required bool revert,
  }) async {
    final multiplier = revert ? -1.0 : 1.0;

    if (tx.type.isPositive) {
      // Income: sender pocket gets credited
      if (tx.senderPocketId != null) {
        final pocket = await _pocketRepository.getPocketById(
          tx.senderPocketId!,
        );
        if (pocket != null) {
          await _pocketRepository.updatePocket(
            pocket.copyWith(balance: pocket.balance + tx.amount * multiplier),
          );
        }
      }
      return;
    }

    if (tx.type == TransactionType.transfer) {
      // Transfer: sender debited, receiver credited
      if (tx.senderPocketId != null) {
        final pocket = await _pocketRepository.getPocketById(
          tx.senderPocketId!,
        );
        if (pocket != null) {
          await _pocketRepository.updatePocket(
            pocket.copyWith(balance: pocket.balance - tx.amount * multiplier),
          );
        }
      }
      if (tx.receiverPocketId != null) {
        final pocket = await _pocketRepository.getPocketById(
          tx.receiverPocketId!,
        );
        if (pocket != null) {
          await _pocketRepository.updatePocket(
            pocket.copyWith(balance: pocket.balance + tx.amount * multiplier),
          );
        }
      }
      return;
    }

    // Expense or other negative type: sender debited
    if (tx.senderPocketId != null) {
      final pocket = await _pocketRepository.getPocketById(tx.senderPocketId!);
      if (pocket != null) {
        await _pocketRepository.updatePocket(
          pocket.copyWith(balance: pocket.balance - tx.amount * multiplier),
        );
      }
    }
  }

  /// Updates the transaction atomically with balance adjustments.
  Future<void> submitUpdate() async {
    final current = state.value;
    if (current == null ||
        current.original?.id == null ||
        !current.isValid ||
        current.isSaving) {
      return;
    }

    state = AsyncData(current.copyWith(isSaving: true));
    try {
      final database = ref.read(db.appDatabaseProvider);
      final original = current.original!;
      final updated = _buildUpdatedTransaction(current);

      await database.transaction(() async {
        // Revert the original transaction's balance impact
        await _applyPocketImpact(original, revert: true);

        // Update the transaction record
        await _transactionRepository.updateTransaction(
          updated.toUpdateCompanion(),
        );

        // Apply the new transaction's balance impact
        await _applyPocketImpact(updated, revert: false);
      });

      // Refresh dependent providers
      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(budgetViewModelProvider);

      // Reset state to reflect success
      state = AsyncData(current.copyWith(isSaving: false, original: updated));
    } catch (e) {
      state = AsyncData(current.copyWith(isSaving: false));
      rethrow;
    }
  }
}

/// Provider for the edit transaction view model, keyed by transaction ID.
final editTransactionViewModelProvider = AsyncNotifierProvider.family<
  EditTransactionNotifier,
  EditTransactionState,
  int
>(EditTransactionNotifier.new);
