import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionViewModelProvider);

    return Scaffold(
      floatingActionButton: _addTransactionButton(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150.0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Transactions'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
            ],
          ),
          transactionsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No transactions yet.')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      TransactionListTile(transaction: transactions[index]),
                  childCount: transactions.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  FloatingActionButton _addTransactionButton(
    BuildContext context,
    WidgetRef ref,
  ) {
    return FloatingActionButton(
      onPressed: () async {
        await context.push(Paths.addTransaction);
        if (!context.mounted) return;
        await ref
            .read(transactionViewModelProvider.notifier)
            .refreshTransactions();
      },
      child: const Icon(Icons.add),
    );
  }
}
