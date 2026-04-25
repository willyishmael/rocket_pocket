import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';
import 'package:rocket_pocket/viewmodels/edit_transaction_view_model.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({this.transaction, this.transactionId, super.key})
    : assert(transaction != null || transactionId != null);

  final Transaction? transaction;
  final int? transactionId;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late int _txId;

  @override
  void initState() {
    super.initState();
    _txId = widget.transactionId ?? widget.transaction?.id ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_txId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    final editAsync = ref.watch(editTransactionViewModelProvider(_txId));

    return editAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Edit Transaction')),
            body: const Center(child: Text('Error loading transaction')),
          ),
      data: (_) => _EditTransactionContent(txId: _txId),
    );
  }
}

class _EditTransactionContent extends ConsumerWidget {
  const _EditTransactionContent({required this.txId});

  final int txId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(editTransactionViewModelProvider(txId)).value!;
    final notifier = ref.read(editTransactionViewModelProvider(txId).notifier);

    final original = viewModel.original;
    final supportsFullEdit =
        original != null &&
        (original.type == TransactionType.income ||
            original.type == TransactionType.expense ||
            original.type == TransactionType.transfer);

    if (original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    if (!supportsFullEdit) {
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

    Future<void> onSave() async {
      try {
        await notifier.submitUpdate();
        if (context.mounted) context.pop(true);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update transaction.')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TransactionTypeDateSection(
            selectedType: viewModel.selectedType,
            date: viewModel.date,
            onTypeChanged: notifier.setType,
            onDateChanged: notifier.setDate,
          ),
          const SizedBox(height: 16),
          TransactionPocketDropdown(
            label:
                viewModel.selectedType == TransactionType.transfer
                    ? 'From Pocket'
                    : 'Pocket',
            pockets: viewModel.pockets,
            value: viewModel.senderPocket,
            onChanged: (p) {
              if (p != null) notifier.setSenderPocket(p);
            },
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
              onChanged: (p) {
                if (p != null) notifier.setReceiverPocket(p);
              },
            ),
          ],
          if (viewModel.selectedType != TransactionType.transfer) ...[
            const SizedBox(height: 16),
            TransactionCategoryDropdown(
              categories: viewModel.filteredCategories,
              value: viewModel.selectedCategory,
              onChanged: (c) {
                if (c != null) notifier.setCategory(c);
              },
            ),
          ],
          if (viewModel.selectedType == TransactionType.expense &&
              viewModel.allBudgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            TransactionBudgetDropdown(
              budgets: viewModel.allBudgets,
              value: viewModel.selectedBudget,
              onChanged: notifier.setBudget,
            ),
          ],
          const SizedBox(height: 16),
          TransactionTextField(
            label: 'Description',
            icon: Icons.notes,
            initialValue: viewModel.description,
            onChanged: notifier.setDescription,
          ),
          const SizedBox(height: 16),
          TransactionTextField(
            label: 'Amount',
            icon: Icons.payments,
            initialValue: viewModel.amount.toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => notifier.setAmount(double.tryParse(v) ?? 0.0),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: viewModel.isSaving || !viewModel.isValid ? null : onSave,
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
