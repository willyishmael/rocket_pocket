import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction.dart' as model;
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  final int budgetId;
  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  ConsumerState<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  static const double _expandedHeight = 280.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final collapsed =
          _scrollController.offset > _expandedHeight - kToolbarHeight - 8;
      if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetViewModelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return budgetsAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (budgets) {
        final item =
            budgets.where((b) => b.budget.id == widget.budgetId).firstOrNull;
        if (item == null) {
          return Scaffold(
            body: Center(child: Text('Budget #${widget.budgetId} not found')),
          );
        }

        final budget = item.budget;
        final headerColor =
            item.isOverBudget ? colorScheme.error : colorScheme.primary;
        final foregroundColor = colorScheme.onPrimary;

        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Expanded header ──────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: _expandedHeight,
                backgroundColor: headerColor,
                foregroundColor: foregroundColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, budget.name),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        kToolbarHeight,
                        20,
                        16,
                      ),
                      child: _BudgetDetailHeader(
                        item: item,
                        foregroundColor: foregroundColor,
                      ),
                    ),
                  ),
                  title:
                      _isCollapsed
                          ? Text(
                            budget.name,
                            style: TextStyle(color: foregroundColor),
                          )
                          : null,
                ),
              ),

              // ── Details card ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: _BudgetDetailInfoCard(item: item),
                ),
              ),

              // ── Transactions header ──────────────────────────────────
              _TransactionsSection(
                budgetId: widget.budgetId,
                period: budget.period,
                startDate: budget.startDate,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String budgetName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Budget'),
            content: Text(
              'Delete "$budgetName"? '
              'Linked transactions will be unlinked.',
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => ctx.pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await ref
          .read(budgetViewModelProvider.notifier)
          .deleteBudget(widget.budgetId);
      if (context.mounted) context.pop();
    }
  }
}

// ── Header widget (inside the colored SliverAppBar) ─────────────────────────

class _BudgetDetailHeader extends StatelessWidget {
  final BudgetWithSpent item;
  final Color foregroundColor;

  const _BudgetDetailHeader({
    required this.item,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: foregroundColor);
    final subtleStyle = TextStyle(
      color: foregroundColor.withValues(alpha: 0.75),
    );
    final budget = item.budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Budget name + period badge
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: foregroundColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.savings_outlined,
                color: foregroundColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.name,
                    style: textStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _periodLabel(budget.period),
                    style: subtleStyle.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Budget amount
        Text('Budget Amount', style: subtleStyle.copyWith(fontSize: 12)),
        Text(
          budget.amount.toStringAsFixed(2),
          style: textStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        // Progress bar
        LinearProgressIndicator(
          value: item.progress.toDouble(),
          borderRadius: BorderRadius.circular(4),
          backgroundColor: foregroundColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          minHeight: 6,
        ),

        const SizedBox(height: 8),

        // Spent / remaining row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${item.spent.toStringAsFixed(2)}',
              style: subtleStyle.copyWith(fontSize: 12),
            ),
            Text(
              item.isOverBudget
                  ? 'Over by ${(-item.remaining).toStringAsFixed(2)}'
                  : 'Remaining: ${item.remaining.toStringAsFixed(2)}',
              style: textStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.once:
        return 'One-time';
    }
  }
}

// ── Info card (below the header) ────────────────────────────────────────────

class _BudgetDetailInfoCard extends StatelessWidget {
  final BudgetWithSpent item;
  const _BudgetDetailInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final budget = item.budget;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.repeat,
              label: 'Period',
              value: _periodLabel(budget.period),
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Start Date',
              value: _formatDate(budget.startDate),
            ),
            if (item.isOverBudget) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.warning_amber_outlined,
                label: 'Status',
                value: 'Over budget by ${(-item.remaining).toStringAsFixed(2)}',
                valueColor: colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.once:
        return 'One-time';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Transactions section (header + list) ────────────────────────────────────

class _TransactionsSection extends ConsumerWidget {
  final int budgetId;
  final BudgetPeriod period;
  final DateTime startDate;

  const _TransactionsSection({
    required this.budgetId,
    required this.period,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(budgetRepositoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pockets = ref.watch(pocketViewModelProvider).value ?? [];
    final pocketCurrency = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.currency,
    };
    final pocketName = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.name,
    };

    return FutureBuilder(
      future: repo.getTransactionsForBudget(budgetId, period, startDate),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return MultiSliver(
          children: [
            // ── Header row ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLoading ? '...' : '${transactions.length} records',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Divider(height: 1)),

            // ── List ─────────────────────────────────────────────────
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (transactions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No transactions in this period',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final dbTx = transactions[index];
                  final tx = model.Transaction.fromDb(dbTx);
                  final currency = pocketCurrency[dbTx.senderPocketId] ?? 'IDR';
                  final pocket = pocketName[dbTx.senderPocketId];
                  return TransactionListTile(
                    transaction: tx,
                    currency: currency,
                    pocketName: pocket,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// A simple widget that renders multiple slivers as children of a single sliver.
/// This avoids needing to flatten logic into the parent CustomScrollView.
class MultiSliver extends StatelessWidget {
  final List<Widget> children;
  const MultiSliver({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    // SliverMainAxisGroup groups multiple slivers into one.
    return SliverMainAxisGroup(slivers: children);
  }
}
