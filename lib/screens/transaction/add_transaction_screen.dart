import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                      SegmentedButton<TransactionType>(
                        showSelectedIcon: false,
                        segments:
                            TransactionType.values
                                .map(
                                  (t) => ButtonSegment(
                                    value: t,
                                    label: Text(t.toReadableString()),
                                  ),
                                )
                                .toList(),
                        selected: {state.selectedType},
                        onSelectionChanged:
                            (value) => ref
                                .read(addTransactionViewModelProvider.notifier)
                                .setType(value.first),
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

                      // ── Original Transaction (Refund only) ────────────
                      if (state.selectedType == TransactionType.refund) ...[
                        DropdownButtonFormField<int>(
                          value: state.originalTransactionId,
                          decoration: const InputDecoration(
                            labelText: 'Original Transaction',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.receipt_long),
                          ),
                          items:
                              state.refundableTransactions
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(
                                        '${t.description} — ${t.formattedAmount}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (id) => ref
                                  .read(
                                    addTransactionViewModelProvider.notifier,
                                  )
                                  .setOriginalTransactionId(id),
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
