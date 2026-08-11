import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/dashboard/dashboard_statistics_section.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const _scope = DashboardStatisticsScope.allPockets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(dashboardStatisticsProvider(_scope));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Statistics'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          ...statisticsAsync.when(
            loading:
                () => const [
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
            error:
                (error, _) => [
                  SliverFillRemaining(
                    child: Center(
                      child: Text('Unable to load statistics: $error'),
                    ),
                  ),
                ],
            data: (statistics) {
              final slivers = <Widget>[];
              if (statistics.availableMonths.isNotEmpty &&
                  statistics.selectedMonth != null) {
                slivers.add(
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MonthSelectorDelegate(
                      months: statistics.availableMonths,
                      selectedMonth: statistics.selectedMonth!,
                      onMonthSelected: (month) {
                        ref
                            .read(
                              dashboardSelectedMonthProvider(_scope).notifier,
                            )
                            .setMonth(month);
                      },
                    ),
                  ),
                );
              }

              slivers.add(
                SliverToBoxAdapter(
                  child: DashboardStatisticsSection(
                    state: statistics,
                    currency: statistics.displayCurrency,
                    onShowMore: () => context.push(Paths.statisticsShowMore),
                    onCategoryTap: (slice) {
                      final selectedMonth = statistics.selectedMonth;
                      if (selectedMonth == null) return;

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
              );
              return slivers;
            },
          ),
        ],
      ),
    );
  }
}
