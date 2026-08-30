import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/viewmodels/statistics_view_model.dart';

// Shared by all statistics screens so the drilldown route is pushed consistently.
void openCategoryTransactions(
  BuildContext context, {
  required StatisticsScope scope,
  required DateTime month,
  required StatisticsChartSlice slice,
}) {
  context.push(
    Paths.statisticsCategoryTransactions,
    extra: StatisticsCategoryDrilldown(
      scope: scope,
      month: month,
      chartType: slice.chartType,
      categoryId: slice.categoryId,
      label: slice.label,
    ),
  );
}
