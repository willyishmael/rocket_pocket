import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

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
  Transaction? _transaction;
  bool _isLoading = true;
  bool _isSaving = false;

  late final TransactionRepository _transactionRepository;
  late final PocketRepository _pocketRepository;

  @override
  void initState() {
    super.initState();
    _transactionRepository = ref.read(transactionRepositoryProvider);
    _pocketRepository = ref.read(pocketRepositoryProvider);
    _transaction = widget.transaction;
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    if (_transaction != null) {
      setState(() => _isLoading = false);
      return;
    }

    final id = widget.transactionId;
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final row = await _transactionRepository.getTransactionById(id);
      if (!mounted) return;
      setState(() {
        _transaction = row == null ? null : Transaction.fromDb(row);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyPocketImpact(
    Transaction tx, {
    required bool revert,
  }) async {
    final multiplier = revert ? -1.0 : 1.0;

    if (tx.type.isPositive) {
      await _updatePocketBalance(tx.senderPocketId, tx.amount * multiplier);
      return;
    }

    if (tx.type == TransactionType.transfer) {
      await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
      await _updatePocketBalance(tx.receiverPocketId, tx.amount * multiplier);
      return;
    }

    await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
  }

  Future<void> _updatePocketBalance(int? pocketId, double delta) async {
    if (pocketId == null || delta == 0) return;
    final pocket = await _pocketRepository.getPocketById(pocketId);
    if (pocket == null) return;
    await _pocketRepository.updatePocket(
      pocket.copyWith(balance: pocket.balance + delta),
    );
  }

  Future<void> _deleteTransaction() async {
    final tx = _transaction;
    if (tx?.id == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
        await _applyPocketImpact(tx!, revert: true);
        await _transactionRepository.deleteTransaction(tx.id!);
      });

      ref.invalidate(transactionViewModelProvider);
      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(budgetViewModelProvider);

      if (!mounted) return;
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete transaction.')),
      );
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editTransaction() async {
    final tx = _transaction;
    if (tx == null || tx.id == null || _isSaving) return;

    final result = await context.push(
      Paths.editTransactionRoute(tx.id!),
      extra: tx,
    );

    if (result != true) return;

    final row = await _transactionRepository.getTransactionById(tx.id!);
    if (!mounted) return;
    if (row == null) {
      setState(() => _transaction = null);
      return;
    }

    setState(() => _transaction = Transaction.fromDb(row));
  }

  Future<Map<int, Pocket>> _loadPocketMap() async {
    final pockets = await _pocketRepository.getAllPockets();
    return {
      for (final p in pockets)
        if (p.id != null) p.id!: p,
    };
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'This will permanently remove the transaction and adjust pocket balances.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteTransaction();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tx = _transaction;
    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    return FutureBuilder<Map<int, Pocket>>(
      future: _loadPocketMap(),
      builder: (context, snapshot) {
        final pockets = snapshot.data ?? const <int, Pocket>{};
        final sender =
            tx.senderPocketId != null ? pockets[tx.senderPocketId] : null;
        final receiver =
            tx.receiverPocketId != null ? pockets[tx.receiverPocketId] : null;
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
                onPressed: _isSaving ? null : _editTransaction,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Transaction'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Transaction'),
              ),
            ],
          ),
        );
      },
    );
  }
}
