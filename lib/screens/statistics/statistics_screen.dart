import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/statistics/statistics_navigation.dart';
import 'package:rocket_pocket/screens/statistics/statistics_section.dart';
import 'package:rocket_pocket/viewmodels/statistics_view_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const _scope = StatisticsScope.defaultScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider(_scope));

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
                              statisticsSelectedMonthProvider(_scope).notifier,
                            )
                            .setMonth(month);
                      },
                    ),
                  ),
                );
              }

              slivers.add(
                SliverToBoxAdapter(
                  child: StatisticsSection(
                    state: statistics,
                    currency: statistics.displayCurrency,
                    onShowMoreForType:
                        (chartType) => context.push(
                          Paths.statisticsShowMore,
                          extra: chartType,
                        ),
                    onCategoryTap: (slice) {
                      final selectedMonth = statistics.selectedMonth;
                      if (selectedMonth == null) return;

                      openCategoryTransactions(
                        context,
                        scope: _scope,
                        month: selectedMonth,
                        slice: slice,
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
