import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetViewModelProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150.0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Budgets'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          budgetsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
            data: (budgets) {
              if (budgets.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No budgets yet.\nTap + to create one.'),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = budgets[index];
                    return _BudgetCard(item: item);
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(Paths.addBudget);
          ref.invalidate(budgetViewModelProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetWithSpent item;
  const _BudgetCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spent = item.spent;
    final total = item.budget.amount;
    final remaining = item.remaining;

    final progressColor =
        item.isOverBudget ? colorScheme.error : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.budget.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Delete Budget'),
                              content: Text(
                                'Delete "${item.budget.name}"? '
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
                            .deleteBudget(item.budget.id!);
                      }
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _periodLabel(item.budget.period),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: item.progress.toDouble(),
                minHeight: 8,
                color: progressColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${spent.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'of ${total.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (item.isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Over budget by ${(-remaining).toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${remaining.toStringAsFixed(0)} remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
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
