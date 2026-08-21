import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/statistics_view_model.dart';

class StatisticsSection extends StatelessWidget {
  final StatisticsState state;
  final String currency;
  final ValueChanged<StatisticsChartType>? onShowMoreForType;
  final ValueChanged<StatisticsChartSlice>? onCategoryTap;
  final int maxVisibleCategoryRows;

  const StatisticsSection({
    super.key,
    required this.state,
    required this.currency,
    this.onShowMoreForType,
    this.onCategoryTap,
    this.maxVisibleCategoryRows = 3,
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
              onCategoryTap: onCategoryTap,
              onOpenDetails: onShowMoreForType,
              maxVisibleCategoryRows: maxVisibleCategoryRows,
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
  final StatisticsState state;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmountColumn(
              label: 'Total Balance',
              value: CurrencyUtils.format(state.totalBalance, currency),
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'Opening',
                    value: CurrencyUtils.format(state.openingBalance, currency),
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Ending',
                    value: CurrencyUtils.format(state.endingBalance, currency),
                    color:
                        state.endingBalance >= state.openingBalance
                            ? colorScheme.primary
                            : colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
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
  final List<StatisticsChartSlice> expenseSlices;
  final List<StatisticsChartSlice> incomeSlices;
  final String currency;
  final ValueChanged<StatisticsChartSlice>? onCategoryTap;
  final ValueChanged<StatisticsChartType>? onOpenDetails;
  final int maxVisibleCategoryRows;

  const _ChartsGrid({
    required this.expenseSlices,
    required this.incomeSlices,
    required this.currency,
    required this.onCategoryTap,
    required this.onOpenDetails,
    required this.maxVisibleCategoryRows,
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
          onCategoryTap: onCategoryTap,
          onOpenDetails:
              onOpenDetails == null
                  ? null
                  : () => onOpenDetails!(StatisticsChartType.expense),
          maxVisibleRows: maxVisibleCategoryRows,
        );
        final incomeCard = _PieChartCard(
          title: 'Income by Category',
          slices: incomeSlices,
          currency: currency,
          onCategoryTap: onCategoryTap,
          onOpenDetails:
              onOpenDetails == null
                  ? null
                  : () => onOpenDetails!(StatisticsChartType.income),
          maxVisibleRows: maxVisibleCategoryRows,
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
  final List<StatisticsChartSlice> slices;
  final String currency;
  final ValueChanged<StatisticsChartSlice>? onCategoryTap;
  final VoidCallback? onOpenDetails;
  final int maxVisibleRows;

  const _PieChartCard({
    required this.title,
    required this.slices,
    required this.currency,
    required this.onCategoryTap,
    required this.onOpenDetails,
    required this.maxVisibleRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              if (slices.isEmpty)
                SizedBox(
                  height: 130,
                  child: Center(
                    child: Text('No data', style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 28,
                            sections: _buildSections(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < slices.take(maxVisibleRows).length;
                            i++
                          )
                            _CategoryBreakdownRow(
                              color: _popPalette[i % _popPalette.length],
                              slice: slices[i],
                              onTap:
                                  onCategoryTap == null
                                      ? null
                                      : () => onCategoryTap!(slices[i]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return [
      for (var index = 0; index < slices.length; index++)
        PieChartSectionData(
          value: slices[index].amount,
          color: _popPalette[index % _popPalette.length],
          radius: 42,
          showTitle: false,
        ),
    ];
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  final Color color;
  final StatisticsChartSlice slice;
  final VoidCallback? onTap;

  const _CategoryBreakdownRow({
    required this.color,
    required this.slice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${slice.percentage.toStringAsFixed(1)}%',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _popPalette = <Color>[
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFFACC15),
  Color(0xFF22C55E),
  Color(0xFF06B6D4),
  Color(0xFF3B82F6),
  Color(0xFF6366F1),
  Color(0xFFEC4899),
];

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
