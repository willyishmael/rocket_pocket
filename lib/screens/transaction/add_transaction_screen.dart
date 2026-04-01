// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelAsync = ref.watch(addTransactionViewModelProvider);

    return Scaffold(
      body: viewModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                expandedHeight: 120.0,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Add Transaction'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Transaction type selector ──────────────────────
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<TransactionType>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.income,
                              label: Text('Income'),
                            ),
                            ButtonSegment(
                              value: TransactionType.expense,
                              label: Text('Expense'),
                            ),
                            ButtonSegment(
                              value: TransactionType.transfer,
                              label: Text('Transfer'),
                            ),
                          ],
                          selected: {state.selectedType},
                          onSelectionChanged:
                              (value) => ref
                                  .read(
                                    addTransactionViewModelProvider.notifier,
                                  )
                                  .setType(value.first),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Transaction date & time ───────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: state.date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  // Preserve existing time
                                  final current = state.date;
                                  ref
                                      .read(
                                        addTransactionViewModelProvider
                                            .notifier,
                                      )
                                      .setDate(
                                        DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          current.hour,
                                          current.minute,
                                        ),
                                      );
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  icon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${state.date.year}-'
                                  '${state.date.month.toString().padLeft(2, '0')}-'
                                  '${state.date.day.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    state.date,
                                  ),
                                );
                                if (picked != null) {
                                  // Preserve existing date
                                  final current = state.date;
                                  ref
                                      .read(
                                        addTransactionViewModelProvider
                                            .notifier,
                                      )
                                      .setDate(
                                        DateTime(
                                          current.year,
                                          current.month,
                                          current.day,
                                          picked.hour,
                                          picked.minute,
                                        ),
                                      );
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  icon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  '${state.date.hour.toString().padLeft(2, '0')}:'
                                  '${state.date.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Pocket selector(s) ────────────────────────────
                      DropdownButtonFormField(
                        value: state.senderPocket,
                        decoration: InputDecoration(
                          labelText:
                              state.selectedType == TransactionType.transfer
                                  ? 'From Pocket'
                                  : 'Pocket',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.account_balance_wallet),
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

                      if (state.selectedType == TransactionType.transfer) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField(
                          value: state.receiverPocket,
                          decoration: const InputDecoration(
                            labelText: 'To Pocket',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.account_balance_wallet),
                          ),
                          items:
                              state.pockets
                                  .where((p) => p != state.senderPocket)
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
                                  .read(
                                    addTransactionViewModelProvider.notifier,
                                  )
                                  .setReceiverPocket(p);
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Category (hidden for Transfer) ────────────────
                      if (state.selectedType != TransactionType.transfer) ...[
                        DropdownButtonFormField(
                          value: state.selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.category),
                          ),
                          items:
                              state.filteredCategories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (c) {
                            if (c != null) {
                              ref
                                  .read(
                                    addTransactionViewModelProvider.notifier,
                                  )
                                  .setCategory(c);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Budget (optional) ─────────────────────────────
                      if (state.allBudgets.isNotEmpty) ...[
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
                              (b) => DropdownMenuItem<budget_model.Budget?>(
                                value: b,
                                child: Text(b.name),
                              ),
                            ),
                          ],
                          onChanged: (b) {
                            ref
                                .read(addTransactionViewModelProvider.notifier)
                                .setBudget(b);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Description ───────────────────────────────────
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.notes),
                        ),
                        onChanged:
                            (v) => ref
                                .read(addTransactionViewModelProvider.notifier)
                                .setDescription(v),
                      ),

                      const SizedBox(height: 16),

                      // ── Amount ────────────────────────────────────────
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.payments),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) {
                          final amount = double.tryParse(v) ?? 0.0;
                          ref
                              .read(addTransactionViewModelProvider.notifier)
                              .setAmount(amount);
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Submit ────────────────────────────────────────
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        icon: const Icon(Icons.check),
                        onPressed:
                            state.isValid
                                ? () async {
                                  await ref
                                      .read(
                                        addTransactionViewModelProvider
                                            .notifier,
                                      )
                                      .submit();
                                  if (context.mounted) context.pop();
                                }
                                : null,
                        label: const Text('Save Transaction'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
