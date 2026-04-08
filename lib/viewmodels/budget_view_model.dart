import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/budget.dart' as model;
import 'package:rocket_pocket/repositories/budget_repository.dart';

enum BudgetStatus { onTrack, nearLimit, overBudget }

class BudgetWithSpent {
  final model.Budget budget;
  final double spent;

  BudgetWithSpent({required this.budget, required this.spent});

  double get remaining => budget.amount - spent;
  double get progress =>
      budget.amount > 0 ? (spent / budget.amount).clamp(0, 1) : 0;
  bool get isOverBudget => spent > budget.amount;

  BudgetStatus get status {
    final ratio = budget.amount > 0 ? spent / budget.amount : 0;
    if (ratio >= 1.0) return BudgetStatus.overBudget;
    if (ratio >= 0.8) return BudgetStatus.nearLimit;
    return BudgetStatus.onTrack;
  }
}

final budgetViewModelProvider =
    AsyncNotifierProvider<BudgetViewModel, List<BudgetWithSpent>>(
      BudgetViewModel.new,
    );

class BudgetViewModel extends AsyncNotifier<List<BudgetWithSpent>> {
  late BudgetRepository _repository;

  @override
  FutureOr<List<BudgetWithSpent>> build() async {
    _repository = ref.watch(budgetRepositoryProvider);
    return _loadBudgets();
  }

  Future<List<BudgetWithSpent>> _loadBudgets() async {
    final dbBudgets = await _repository.getAllBudgets();
    final budgets = dbBudgets.map(model.Budget.fromDb).toList();
    final spentAmounts = await Future.wait(
      budgets.map(
        (budget) => _repository.getSpentAmount(
          budget.id!,
          budget.period,
          budget.startDate,
        ),
      ),
    );

    final result = <BudgetWithSpent>[];
    for (var i = 0; i < budgets.length; i++) {
      result.add(BudgetWithSpent(budget: budgets[i], spent: spentAmounts[i]));
    }

    return result;
  }

  Future<void> addBudget(model.Budget budget) async {
    state = const AsyncLoading();
    try {
      await _repository.insertBudget(budget.toInsertCompanion());
      state = AsyncData(await _loadBudgets());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateBudget(model.Budget budget) async {
    state = const AsyncLoading();
    try {
      await _repository.updateBudget(budget.toUpdateCompanion());
      state = AsyncData(await _loadBudgets());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteBudget(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteBudget(id);
      state = AsyncData(await _loadBudgets());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _loadBudgets());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

/// Provider that loads all budgets (without spent calculation) for use in dropdowns.
final allBudgetsProvider = FutureProvider<List<model.Budget>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final dbBudgets = await repo.getAllBudgets();
  return dbBudgets.map(model.Budget.fromDb).toList();
});
