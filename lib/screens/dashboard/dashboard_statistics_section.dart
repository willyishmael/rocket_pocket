import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';

class DashboardStatisticsSection extends StatelessWidget {
  final DashboardStatisticsState state;
  final String currency;

  const DashboardStatisticsSection({
    super.key,
    required this.state,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(state: state, currency: currency),
          const SizedBox(height: 12),
          if (state.hasCharts)
            _ChartsGrid(
              expenseSlices: state.expenseSlices,
              incomeSlices: state.incomeSlices,
              currency: currency,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No income or expense chart data for this month.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HighlightCard(
                title: 'Budget',
                tint: colorScheme.secondaryContainer,
                lines: [
                  '${state.budgetHighlight.activeBudgetCount} active budgets',
                  '${state.budgetHighlight.overBudgetCount} over budget',
                  '${CurrencyUtils.format(state.budgetHighlight.spentTotal, currency)} spent',
                ],
              ),
              _HighlightCard(
                title: 'Loans',
                tint: colorScheme.tertiaryContainer,
                lines: [
                  '${state.loanHighlight.relatedLoanCount} linked loans',
                  '${state.loanHighlight.overdueCount} overdue',
                  '${CurrencyUtils.format(state.loanHighlight.outstandingTotal, currency)} outstanding',
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// These private widgets are scoped to this section because they compose one
// screen-specific statistics layout and are not reused across other screens.
class _SummaryCard extends StatelessWidget {
  final DashboardStatisticsState state;
  final String currency;

  const _SummaryCard({required this.state, required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final net = state.totals.net;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _AmountColumn(
                label: 'Income',
                value: CurrencyUtils.format(state.totals.income, currency),
                color: colorScheme.primary,
              ),
            ),
            Expanded(
              child: _AmountColumn(
                label: 'Expense',
                value: CurrencyUtils.format(state.totals.expense, currency),
                color: colorScheme.error,
              ),
            ),
            Expanded(
              child: _AmountColumn(
                label: 'Net',
                value: CurrencyUtils.format(net, currency),
                color: net >= 0 ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  final List<DashboardChartSlice> expenseSlices;
  final List<DashboardChartSlice> incomeSlices;
  final String currency;

  const _ChartsGrid({
    required this.expenseSlices,
    required this.incomeSlices,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final expenseCard = _PieChartCard(
          title: 'Expenses by Category',
          slices: expenseSlices,
          currency: currency,
        );
        final incomeCard = _PieChartCard(
          title: 'Income by Category',
          slices: incomeSlices,
          currency: currency,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: expenseCard),
              const SizedBox(width: 12),
              Expanded(child: incomeCard),
            ],
          );
        }

        return Column(
          children: [expenseCard, const SizedBox(height: 12), incomeCard],
        );
      },
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final String title;
  final List<DashboardChartSlice> slices;
  final String currency;

  const _PieChartCard({
    required this.title,
    required this.slices,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child:
                  slices.isEmpty
                      ? Center(
                        child: Text(
                          'No data',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                      : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: _buildSections(theme.colorScheme),
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            ...slices
                .take(3)
                .map(
                  (slice) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            slice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyUtils.format(slice.amount, currency),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(ColorScheme colorScheme) {
    final palette = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    return [
      for (var index = 0; index < slices.length; index++)
        PieChartSectionData(
          value: slices[index].amount,
          color: palette[index % palette.length],
          radius: 42,
          showTitle: false,
        ),
    ];
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final Color tint;
  final List<String> lines;

  const _HighlightCard({
    required this.title,
    required this.tint,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: tint.withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
