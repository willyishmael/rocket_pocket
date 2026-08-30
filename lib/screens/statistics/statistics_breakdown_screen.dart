import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/screens/statistics/statistics_navigation.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/statistics_view_model.dart';

class StatisticsBreakdownScreen extends ConsumerWidget {
  final StatisticsChartType? initialChartType;

  const StatisticsBreakdownScreen({super.key, this.initialChartType});

  static const _scope = StatisticsScope.defaultScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider(_scope));
    final showExpenses = initialChartType != StatisticsChartType.income;
    final showIncome = initialChartType != StatisticsChartType.expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Full Category Breakdown')),
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Text('Unable to load category breakdown: $error'),
            ),
        data: (statistics) {
          final selectedMonth = statistics.selectedMonth;
          if (selectedMonth == null) {
            return const Center(child: Text('No available month to show.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (showExpenses)
                _CategorySectionList(
                  title: 'Expenses',
                  slices: statistics.expenseSlices,
                  emptyMessage: 'No expense categories for this month.',
                  currency: statistics.displayCurrency,
                  trailingSpace: showIncome,
                  onTileTap:
                      (slice) => openCategoryTransactions(
                        context,
                        scope: _scope,
                        month: selectedMonth,
                        slice: slice,
                      ),
                ),
              if (showIncome)
                _CategorySectionList(
                  title: 'Income',
                  slices: statistics.incomeSlices,
                  emptyMessage: 'No income categories for this month.',
                  currency: statistics.displayCurrency,
                  trailingSpace: false,
                  onTileTap:
                      (slice) => openCategoryTransactions(
                        context,
                        scope: _scope,
                        month: selectedMonth,
                        slice: slice,
                      ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Local-only: groups a category title, empty state, and tile list for one chart type.
class _CategorySectionList extends StatelessWidget {
  final String title;
  final List<StatisticsChartSlice> slices;
  final String emptyMessage;
  final String currency;
  final bool trailingSpace;
  final ValueChanged<StatisticsChartSlice> onTileTap;

  const _CategorySectionList({
    required this.title,
    required this.slices,
    required this.emptyMessage,
    required this.currency,
    required this.trailingSpace,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (slices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(emptyMessage),
            ),
          )
        else
          ...slices.map(
            (slice) => _CategoryBreakdownTile(
              label: slice.label,
              percentage: slice.percentage,
              amount: slice.amount,
              currency: currency,
              onTap: () => onTileTap(slice),
            ),
          ),
        if (trailingSpace) const SizedBox(height: 16),
      ],
    );
  }
}

// Local-only: this tile matches this screen's one-off layout and drilldown CTA.
class _CategoryBreakdownTile extends StatelessWidget {
  final String label;
  final double percentage;
  final double amount;
  final String currency;
  final VoidCallback onTap;

  const _CategoryBreakdownTile({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(label),
        subtitle: Text('${percentage.toStringAsFixed(1)}%'),
        trailing: Text(
          CurrencyUtils.format(amount, currency),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
