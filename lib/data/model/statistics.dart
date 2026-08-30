import 'package:rocket_pocket/data/model/transaction.dart';

enum StatisticsScopeType { allPockets, pocket }

class StatisticsScope {
  final StatisticsScopeType type;
  final int? pocketId;

  // Shared scope constant so statistics screens don't each redeclare it.
  static const StatisticsScope defaultScope = StatisticsScope.allPockets();

  const StatisticsScope.allPockets()
    : type = StatisticsScopeType.allPockets,
      pocketId = null;

  const StatisticsScope.pocket(this.pocketId)
    : type = StatisticsScopeType.pocket;

  @override
  bool operator ==(Object other) {
    return other is StatisticsScope &&
        other.type == type &&
        other.pocketId == pocketId;
  }

  @override
  int get hashCode => Object.hash(type, pocketId);
}

enum StatisticsChartType { expense, income }

class StatisticsCategoryDrilldown {
  final StatisticsScope scope;
  final DateTime month;
  final StatisticsChartType chartType;
  final int? categoryId;
  final String label;

  const StatisticsCategoryDrilldown({
    required this.scope,
    required this.month,
    required this.chartType,
    required this.categoryId,
    required this.label,
  });

  @override
  bool operator ==(Object other) {
    return other is StatisticsCategoryDrilldown &&
        other.scope == scope &&
        other.month == month &&
        other.chartType == chartType &&
        other.categoryId == categoryId &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(scope, month, chartType, categoryId, label);
}

class StatisticsCategoryTransactionRow {
  final Transaction transaction;
  final String currency;
  final String? pocketName;
  final String? categoryName;

  const StatisticsCategoryTransactionRow({
    required this.transaction,
    required this.currency,
    required this.pocketName,
    required this.categoryName,
  });
}
