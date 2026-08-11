import 'package:rocket_pocket/data/model/transaction.dart';

enum DashboardStatisticsScopeType { allPockets, pocket }

class DashboardStatisticsScope {
  final DashboardStatisticsScopeType type;
  final int? pocketId;

  const DashboardStatisticsScope.allPockets()
    : type = DashboardStatisticsScopeType.allPockets,
      pocketId = null;

  const DashboardStatisticsScope.pocket(this.pocketId)
    : type = DashboardStatisticsScopeType.pocket;

  @override
  bool operator ==(Object other) {
    return other is DashboardStatisticsScope &&
        other.type == type &&
        other.pocketId == pocketId;
  }

  @override
  int get hashCode => Object.hash(type, pocketId);
}

enum DashboardChartType { expense, income }

class DashboardCategoryDrilldown {
  final DashboardStatisticsScope scope;
  final DateTime month;
  final DashboardChartType chartType;
  final int? categoryId;
  final String label;

  const DashboardCategoryDrilldown({
    required this.scope,
    required this.month,
    required this.chartType,
    required this.categoryId,
    required this.label,
  });

  @override
  bool operator ==(Object other) {
    return other is DashboardCategoryDrilldown &&
        other.scope == scope &&
        other.month == month &&
        other.chartType == chartType &&
        other.categoryId == categoryId &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(scope, month, chartType, categoryId, label);
}

class DashboardCategoryTransactionRow {
  final Transaction transaction;
  final String currency;
  final String? pocketName;
  final String? categoryName;

  const DashboardCategoryTransactionRow({
    required this.transaction,
    required this.currency,
    required this.pocketName,
    required this.categoryName,
  });
}
