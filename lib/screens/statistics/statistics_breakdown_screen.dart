import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';

class StatisticsBreakdownScreen extends ConsumerWidget {
  const StatisticsBreakdownScreen({super.key});

  static const _scope = DashboardStatisticsScope.allPockets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(dashboardStatisticsProvider(_scope));

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
              Text(
                'Expenses',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (statistics.expenseSlices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No expense categories for this month.'),
                  ),
                )
              else
                ...statistics.expenseSlices.map(
                  (slice) => _CategoryBreakdownTile(
                    label: slice.label,
                    percentage: slice.percentage,
                    amount: slice.amount,
                    currency: statistics.displayCurrency,
                    onTap: () {
                      context.push(
                        Paths.statisticsCategoryTransactions,
                        extra: DashboardCategoryDrilldown(
                          scope: _scope,
                          month: selectedMonth,
                          chartType: slice.chartType,
                          categoryId: slice.categoryId,
                          label: slice.label,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Income',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (statistics.incomeSlices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No income categories for this month.'),
                  ),
                )
              else
                ...statistics.incomeSlices.map(
                  (slice) => _CategoryBreakdownTile(
                    label: slice.label,
                    percentage: slice.percentage,
                    amount: slice.amount,
                    currency: statistics.displayCurrency,
                    onTap: () {
                      context.push(
                        Paths.statisticsCategoryTransactions,
                        extra: DashboardCategoryDrilldown(
                          scope: _scope,
                          month: selectedMonth,
                          chartType: slice.chartType,
                          categoryId: slice.categoryId,
                          label: slice.label,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
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
