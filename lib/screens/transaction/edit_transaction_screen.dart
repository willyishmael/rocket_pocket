import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';
import 'package:rocket_pocket/viewmodels/edit_transaction_view_model.dart';

class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({this.transaction, this.transactionId, super.key})
    : assert(transaction != null || transactionId != null);

  final Transaction? transaction;
  final int? transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txId = transactionId ?? transaction?.id;
    if (txId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    // Import the provider from edit_transaction_view_model.dart
    final loadAsync = ref.watch(_editTransactionLoadProvider(txId));

    return loadAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Edit Transaction')),
            body: Center(child: Text('Error loading transaction')),
          ),
      data: (data) {
        // Initialize the notifier with loaded data
        ref
            .read(editTransactionViewModelProvider.notifier)
            .initializeFromData(data.$1, data.$2, data.$3, data.$4);

        return _EditTransactionContent(ref: ref);
      },
    );
  }
}

final _editTransactionLoadProvider = FutureProvider.family<
  (
    Transaction,
    List<Pocket>,
    List<db.TransactionCategory>,
    List<budget_model.Budget>,
  ),
  int
>((ref, transactionId) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final pocketRepository = ref.watch(pocketRepositoryProvider);
  final categoryRepository = ref.watch(transactionCategoryRepositoryProvider);
  final budgetRepository = ref.watch(budgetRepositoryProvider);

  final transactionRow = await transactionRepository.getTransactionById(
    transactionId,
  );
  final pockets = await pocketRepository.getAllPockets();
  final categories = await categoryRepository.getAllTransactionCategories();
  final budgetRows = await budgetRepository.getAllBudgets();
  final budgets = budgetRows.map(budget_model.Budget.fromDb).toList();

  if (transactionRow == null) {
    throw Exception('Transaction not found');
  }

  final transaction = Transaction.fromDb(transactionRow);
  return (transaction, pockets, categories, budgets);
});

class _EditTransactionContent extends ConsumerWidget {
  const _EditTransactionContent({required this.ref});

  final WidgetRef ref;

  bool get _supportsFullEdit {
    final viewModel = ref.watch(editTransactionViewModelProvider);
    final original = viewModel.original;
    return original != null &&
        (original.type == TransactionType.income ||
            original.type == TransactionType.expense ||
            original.type == TransactionType.transfer);
  }

  void _onTypeChanged(TransactionType type) {
    ref.read(editTransactionViewModelProvider.notifier).setType(type);
  }

  void _onSenderPocketChanged(dynamic pocket) {
    if (pocket != null) {
      ref
          .read(editTransactionViewModelProvider.notifier)
          .setSenderPocket(pocket);
    }
  }

  void _onReceiverPocketChanged(dynamic pocket) {
    if (pocket != null) {
      ref
          .read(editTransactionViewModelProvider.notifier)
          .setReceiverPocket(pocket);
    }
  }

  void _onCategoryChanged(dynamic category) {
    if (category != null) {
      ref.read(editTransactionViewModelProvider.notifier).setCategory(category);
    }
  }

  void _onBudgetChanged(dynamic budget) {
    ref.read(editTransactionViewModelProvider.notifier).setBudget(budget);
  }

  void _onDescriptionChanged(String value) {
    ref.read(editTransactionViewModelProvider.notifier).setDescription(value);
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    ref.read(editTransactionViewModelProvider.notifier).setAmount(amount);
  }

  void _onDateChanged(DateTime date) {
    ref.read(editTransactionViewModelProvider.notifier).setDate(date);
  }

  Future<void> _onSave() async {
    try {
      await ref.read(editTransactionViewModelProvider.notifier).submitUpdate();
      // Pop on success; the notifier will invalidate other providers
      if (ref.context.mounted) {
        ref.context.pop(true);
      }
    } catch (_) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(content: Text('Failed to update transaction.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(editTransactionViewModelProvider);

    if (viewModel.original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    if (!_supportsFullEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This transaction type is not supported in the full editor yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TransactionTypeDateSection(
            selectedType: viewModel.selectedType,
            date: viewModel.date,
            onTypeChanged: _onTypeChanged,
            onDateChanged: _onDateChanged,
          ),
          const SizedBox(height: 16),
          TransactionPocketDropdown(
            label:
                viewModel.selectedType == TransactionType.transfer
                    ? 'From Pocket'
                    : 'Pocket',
            pockets: viewModel.pockets,
            value: viewModel.senderPocket,
            onChanged: _onSenderPocketChanged,
          ),
          if (viewModel.selectedType == TransactionType.transfer) ...[
            const SizedBox(height: 16),
            TransactionPocketDropdown(
              label: 'To Pocket',
              pockets:
                  viewModel.pockets
                      .where((p) => p != viewModel.senderPocket)
                      .toList(),
              value: viewModel.receiverPocket,
              onChanged: _onReceiverPocketChanged,
            ),
          ],
          if (viewModel.selectedType != TransactionType.transfer) ...[
            const SizedBox(height: 16),
            TransactionCategoryDropdown(
              categories: viewModel.filteredCategories,
              value: viewModel.selectedCategory,
              onChanged: _onCategoryChanged,
            ),
          ],
          if (viewModel.selectedType == TransactionType.expense &&
              viewModel.allBudgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            TransactionBudgetDropdown(
              budgets: viewModel.allBudgets,
              value: viewModel.selectedBudget,
              onChanged: _onBudgetChanged,
            ),
          ],
          const SizedBox(height: 16),
          TransactionTextField(
            label: 'Description',
            icon: Icons.notes,
            initialValue: viewModel.description,
            onChanged: _onDescriptionChanged,
          ),
          const SizedBox(height: 16),
          TransactionTextField(
            label: 'Amount',
            icon: Icons.payments,
            initialValue: viewModel.amount.toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onAmountChanged,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed:
                viewModel.isSaving || !viewModel.isValid ? null : _onSave,
            icon:
                viewModel.isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: Text(viewModel.isSaving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
