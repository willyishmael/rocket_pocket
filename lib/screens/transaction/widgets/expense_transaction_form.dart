import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';

class ExpenseTransactionForm extends ConsumerWidget {
  const ExpenseTransactionForm({required this.state, super.key});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TransactionPocketDropdown(
          label: 'Pocket',
          pockets: state.pockets,
          value: state.senderPocket,
          onChanged: (p) {
            if (p != null) {
              ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setSenderPocket(p);
            }
          },
        ),
        const SizedBox(height: 16),
        TransactionCategoryDropdown(
          categories: state.filteredCategories,
          value: state.selectedCategory,
          onChanged: (c) {
            if (c != null) {
              ref.read(addTransactionViewModelProvider.notifier).setCategory(c);
            }
          },
        ),
        if (state.allBudgets.isNotEmpty) ...[
          const SizedBox(height: 16),
          TransactionBudgetDropdown(
            budgets: state.allBudgets,
            value: state.selectedBudget,
            onChanged:
                (budget) => ref
                    .read(addTransactionViewModelProvider.notifier)
                    .setBudget(budget),
          ),
        ],
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Description',
          icon: Icons.notes,
          onChanged:
              (value) => ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setDescription(value),
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Amount',
          icon: Icons.payments,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setAmount(amount);
          },
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Tip (optional)',
          icon: Icons.card_giftcard,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setTipAmount(amount);
          },
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Tax (optional)',
          icon: Icons.percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setTaxAmount(amount);
          },
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.check),
          onPressed:
              state.isValid
                  ? () async {
                    await ref
                        .read(addTransactionViewModelProvider.notifier)
                        .submit();
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                  : null,
          label: const Text('Save Expense'),
        ),
      ],
    );
  }
}
