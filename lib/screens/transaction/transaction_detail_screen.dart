import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/transaction_detail_view_model.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({
    this.transaction,
    this.transactionId,
    super.key,
  }) : assert(transaction != null || transactionId != null);

  final Transaction? transaction;
  final int? transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
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
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    final loadAsync = ref.watch(transactionDetailLoadProvider(_txId));

    return loadAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Transaction Detail')),
            body: const Center(child: Text('Transaction not found.')),
          ),
      data: (data) {
        Future(() {
          ref
              .read(transactionDetailViewModelProvider.notifier)
              .initializeFrom(data.$1, data.$2);
        });
        return _TransactionDetailContent(txId: _txId);
      },
    );
  }
}

class _TransactionDetailContent extends ConsumerWidget {
  const _TransactionDetailContent({required this.txId});

  final int txId;

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {
    final tx = ref.read(transactionDetailViewModelProvider).transaction;
    if (tx == null || tx.id == null) return;

    final result = await context.push(
      Paths.editTransactionRoute(tx.id!),
      extra: tx,
    );

    if (result != true) return;
    await ref
        .read(transactionDetailViewModelProvider.notifier)
        .refreshTransaction();
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text(
              'This will permanently remove the transaction and adjust pocket balances.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(transactionDetailViewModelProvider.notifier)
          .deleteTransaction();
      if (context.mounted) context.pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(transactionDetailViewModelProvider);
    final tx = viewModel.transaction;

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    final sender =
        tx.senderPocketId != null ? viewModel.pockets[tx.senderPocketId] : null;
    final receiver =
        tx.receiverPocketId != null
            ? viewModel.pockets[tx.receiverPocketId]
            : null;
    final currency = sender?.currency ?? receiver?.currency ?? 'IDR';
    final amountText = CurrencyUtils.format(tx.amount, currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${tx.type.toReadableString()}'),
                  const SizedBox(height: 4),
                  Text('Amount: $amountText'),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${DateFormat.yMMMd().add_Hm().format(tx.date ?? tx.createdAt ?? DateTime.now())}',
                  ),
                  const SizedBox(height: 4),
                  if (sender != null)
                    Text('From: ${sender.emoticon} ${sender.name}'),
                  if (receiver != null)
                    Text('To: ${receiver.emoticon} ${receiver.name}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: viewModel.isSaving ? null : () => _onEdit(context, ref),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Transaction'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                viewModel.isSaving ? null : () => _onDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Transaction'),
          ),
        ],
      ),
    );
  }
}
