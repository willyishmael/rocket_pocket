import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart'
    show TransactionCategory, TransactionCategoriesCompanion;
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';

final categoryViewModelProvider =
    AsyncNotifierProvider<CategoryViewModel, List<TransactionCategory>>(
      CategoryViewModel.new,
    );

class CategoryViewModel extends AsyncNotifier<List<TransactionCategory>> {
  late TransactionRepository _repository;

  @override
  Future<List<TransactionCategory>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    return await _repository.getAllCategories();
  }

  Future<void> addCategory(String name, TransactionType type) async {
    try {
      await _repository.insertCategory(
        TransactionCategoriesCompanion.insert(
          name: name,
          type: Value(type),
          updatedAt: DateTime.now(),
        ),
      );
      state = await AsyncValue.guard(() => _repository.getAllCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> renameCategory(int id, String name) async {
    try {
      await _repository.updateCategoryName(id, name);
      state = await AsyncValue.guard(() => _repository.getAllCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      state = await AsyncValue.guard(() => _repository.getAllCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
