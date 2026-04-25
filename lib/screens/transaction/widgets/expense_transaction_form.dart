import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

class ExpenseTransactionForm extends ConsumerWidget {
  const ExpenseTransactionForm({required this.state, super.key});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        DropdownButtonFormField(
          value: state.senderPocket,
          decoration: const InputDecoration(
            labelText: 'Pocket',
            border: OutlineInputBorder(),
            icon: Icon(Icons.account_balance_wallet),
          ),
          items:
              state.pockets
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.emoticon}  ${p.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (p) {
            if (p != null) {
              ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setSenderPocket(p);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<db.TransactionCategory>(
          value: state.selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            icon: Icon(Icons.category),
          ),
          items:
              state.filteredCategories
                  .map(
                    (c) => DropdownMenuItem<db.TransactionCategory>(
                      value: c,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
          onChanged: (c) {
            if (c != null) {
              ref.read(addTransactionViewModelProvider.notifier).setCategory(c);
            }
          },
        ),
        if (state.allBudgets.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<budget_model.Budget?>(
            value: state.selectedBudget,
            decoration: const InputDecoration(
              labelText: 'Budget (optional)',
              border: OutlineInputBorder(),
              icon: Icon(Icons.savings),
            ),
            items: [
              const DropdownMenuItem<budget_model.Budget?>(
                value: null,
                child: Text('None'),
              ),
              ...state.allBudgets.map(
                (budget) => DropdownMenuItem<budget_model.Budget?>(
                  value: budget,
                  child: Text(budget.name),
                ),
              ),
            ],
            onChanged:
                (budget) => ref
                    .read(addTransactionViewModelProvider.notifier)
                    .setBudget(budget),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            icon: Icon(Icons.notes),
          ),
          onChanged:
              (value) => ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setDescription(value),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
            icon: Icon(Icons.payments),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setAmount(amount);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Tip (optional)',
            border: OutlineInputBorder(),
            icon: Icon(Icons.card_giftcard),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setTipAmount(amount);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Tax (optional)',
            border: OutlineInputBorder(),
            icon: Icon(Icons.percent),
          ),
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
