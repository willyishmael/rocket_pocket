import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

final statisticsSelectedMonthProvider = NotifierProvider.family<
  StatisticsSelectedMonthViewModel,
  DateTime?,
  StatisticsScope
>(StatisticsSelectedMonthViewModel.new);

class StatisticsSelectedMonthViewModel extends Notifier<DateTime?> {
  StatisticsSelectedMonthViewModel(this.scope);

  final StatisticsScope scope;

  @override
  DateTime? build() => null;

  void setMonth(DateTime month) {
    state = month;
  }
}

final statisticsProvider =
    Provider.family<AsyncValue<StatisticsState>, StatisticsScope>((ref, scope) {
      final transactionsAsync = ref.watch(transactionViewModelProvider);
      final budgetsAsync = ref.watch(budgetViewModelProvider);
      final loansAsync = ref.watch(loanViewModelProvider);
      final pocketsAsync = ref.watch(pocketViewModelProvider);
      final categoryNamesAsync = ref.watch(categoryNamesProvider);
      final requestedMonth = ref.watch(statisticsSelectedMonthProvider(scope));

      final error =
          transactionsAsync.asError ??
          budgetsAsync.asError ??
          loansAsync.asError ??
          pocketsAsync.asError ??
          categoryNamesAsync.asError;
      if (error != null) {
        return AsyncError(error.error, error.stackTrace);
      }

      if (!transactionsAsync.hasValue ||
          !budgetsAsync.hasValue ||
          !loansAsync.hasValue ||
          !pocketsAsync.hasValue ||
          !categoryNamesAsync.hasValue) {
        return const AsyncLoading();
      }

      return AsyncData(
        _buildStatistics(
          scope: scope,
          transactions: transactionsAsync.requireValue,
          budgets: budgetsAsync.requireValue,
          loans: loansAsync.requireValue,
          pockets: pocketsAsync.requireValue,
          categoryNames: categoryNamesAsync.requireValue,
          requestedMonth: requestedMonth,
        ),
      );
    });

final categoryTransactionsProvider = Provider.family<
  AsyncValue<List<Transaction>>,
  StatisticsCategoryDrilldown
>((ref, drilldown) {
  final transactionsAsync = ref.watch(transactionViewModelProvider);
  if (transactionsAsync.hasError) {
    final error = transactionsAsync.asError!;
    return AsyncError(error.error, error.stackTrace);
  }
  if (!transactionsAsync.hasValue) {
    return const AsyncLoading();
  }

  final scopedTransactions = _filterTransactionsByScope(
    transactionsAsync.requireValue,
    drilldown.scope,
  );
  final filtered = _buildCategoryTransactions(scopedTransactions, drilldown)
    ..sort(_compareByNewestDate);
  return AsyncData(filtered);
});

final categoryTransactionRowsProvider = Provider.family<
  AsyncValue<List<StatisticsCategoryTransactionRow>>,
  StatisticsCategoryDrilldown
>((ref, drilldown) {
  final transactionsAsync = ref.watch(categoryTransactionsProvider(drilldown));
  final pocketsAsync = ref.watch(pocketViewModelProvider);
  final categoryNamesAsync = ref.watch(categoryNamesProvider);

  final error =
      transactionsAsync.asError ??
      pocketsAsync.asError ??
      categoryNamesAsync.asError;
  if (error != null) {
    return AsyncError(error.error, error.stackTrace);
  }

  if (!transactionsAsync.hasValue ||
      !pocketsAsync.hasValue ||
      !categoryNamesAsync.hasValue) {
    return const AsyncLoading();
  }

  final categoryNames = categoryNamesAsync.requireValue;
  final pocketCurrency = {
    for (final pocket in pocketsAsync.requireValue)
      if (pocket.id != null) pocket.id!: pocket.currency,
  };
  final pocketName = {
    for (final pocket in pocketsAsync.requireValue)
      if (pocket.id != null) pocket.id!: pocket.name,
  };

  // Prepare display-ready drilldown rows so the widget only renders UI.
  final rows =
      transactionsAsync.requireValue
          .map(
            (transaction) => StatisticsCategoryTransactionRow(
              transaction: transaction,
              currency:
                  pocketCurrency[transaction.senderPocketId] ??
                  pocketCurrency[transaction.receiverPocketId] ??
                  'IDR',
              pocketName: _resolveDrilldownPocketName(transaction, pocketName),
              categoryName:
                  transaction.categoryId != null
                      ? categoryNames[transaction.categoryId]
                      : null,
            ),
          )
          .toList();
  return AsyncData(rows);
});

class StatisticsState {
  final StatisticsScope scope;
  final String displayCurrency;
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final double totalBalance;
  final double openingBalance;
  final double endingBalance;
  final StatisticsSummaryTotals totals;
  final List<StatisticsChartSlice> expenseSlices;
  final List<StatisticsChartSlice> incomeSlices;
  final StatisticsBudgetHighlight budgetHighlight;
  final StatisticsLoanHighlight loanHighlight;

  const StatisticsState({
    required this.scope,
    required this.displayCurrency,
    required this.availableMonths,
    required this.selectedMonth,
    required this.totalBalance,
    required this.openingBalance,
    required this.endingBalance,
    required this.totals,
    required this.expenseSlices,
    required this.incomeSlices,
    required this.budgetHighlight,
    required this.loanHighlight,
  });

  bool get hasCharts => expenseSlices.isNotEmpty || incomeSlices.isNotEmpty;
}

class StatisticsSummaryTotals {
  final double income;
  final double expense;
  final int transactionCount;

  const StatisticsSummaryTotals({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  double get net => income - expense;
}

class StatisticsChartSlice {
  final StatisticsChartType chartType;
  final int? categoryId;
  final String label;
  final double amount;
  final double percentage;

  const StatisticsChartSlice({
    required this.chartType,
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.percentage,
  });
}

class StatisticsBudgetHighlight {
  final int activeBudgetCount;
  final int overBudgetCount;
  final double spentTotal;
  final double budgetedTotal;

  const StatisticsBudgetHighlight({
    required this.activeBudgetCount,
    required this.overBudgetCount,
    required this.spentTotal,
    required this.budgetedTotal,
  });
}

class StatisticsLoanHighlight {
  final int relatedLoanCount;
  final int ongoingCount;
  final int overdueCount;
  final double inflow;
  final double outflow;
  final double outstandingTotal;

  const StatisticsLoanHighlight({
    required this.relatedLoanCount,
    required this.ongoingCount,
    required this.overdueCount,
    required this.inflow,
    required this.outflow,
    required this.outstandingTotal,
  });
}

StatisticsState _buildStatistics({
  required StatisticsScope scope,
  required List<Transaction> transactions,
  required List<BudgetWithSpent> budgets,
  required List<Loan> loans,
  required List<Pocket> pockets,
  required Map<int, String> categoryNames,
  required DateTime? requestedMonth,
}) {
  // Build a month-scoped statistics snapshot for the selected scope.
  final scopedTransactions = _filterTransactionsByScope(transactions, scope)
    ..sort(_compareByNewestDate);

  final availableMonths = _deriveAvailableMonths(scopedTransactions);
  final effectiveMonth = _resolveSelectedMonth(availableMonths, requestedMonth);
  final monthTransactions =
      effectiveMonth == null
          ? const <Transaction>[]
          : scopedTransactions
              .where((tx) => _isInMonth(tx, effectiveMonth))
              .toList();

  final mainChartTransactions =
      monthTransactions.where(_isMainChartTransaction).toList();
  final incomeTransactions =
      mainChartTransactions.where(_isIncomeChartTransaction).toList();
  final expenseTransactions =
      mainChartTransactions.where(_isExpenseChartTransaction).toList();

  final monthStart =
      effectiveMonth != null
          ? DateTime(effectiveMonth.year, effectiveMonth.month)
          : null;
  final openingBalance =
      monthStart == null
          ? 0.0
          : scopedTransactions
              .where((tx) {
                final date = tx.date ?? tx.createdAt;
                return date != null && date.isBefore(monthStart);
              })
              .fold(
                0.0,
                (sum, tx) => sum + _signedContributionForScope(tx, scope),
              );
  final endingBalance =
      openingBalance +
      monthTransactions.fold(
        0.0,
        (sum, tx) => sum + _signedContributionForScope(tx, scope),
      );

  return StatisticsState(
    scope: scope,
    displayCurrency: _resolveDisplayCurrency(scope, pockets),
    availableMonths: availableMonths,
    selectedMonth: effectiveMonth,
    totalBalance: _resolveTotalBalance(scope, pockets),
    openingBalance: openingBalance,
    endingBalance: endingBalance,
    totals: StatisticsSummaryTotals(
      income: _sumAmounts(incomeTransactions),
      expense: _sumAmounts(expenseTransactions),
      transactionCount: mainChartTransactions.length,
    ),
    incomeSlices: _buildSlices(
      incomeTransactions,
      categoryNames,
      chartType: StatisticsChartType.income,
      fallbackLabel: 'Income',
    ),
    expenseSlices: _buildSlices(
      expenseTransactions,
      categoryNames,
      chartType: StatisticsChartType.expense,
      fallbackLabel: 'Expense',
    ),
    budgetHighlight: _buildBudgetHighlight(monthTransactions, budgets),
    loanHighlight: _buildLoanHighlight(monthTransactions, loans),
  );
}

List<Transaction> _filterTransactionsByScope(
  List<Transaction> transactions,
  StatisticsScope scope,
) {
  if (scope.type == StatisticsScopeType.allPockets) {
    return [...transactions];
  }

  final pocketId = scope.pocketId;
  if (pocketId == null) {
    return const [];
  }

  return transactions.where((tx) => _belongsToPocket(tx, pocketId)).toList();
}

List<DateTime> _deriveAvailableMonths(List<Transaction> transactions) {
  // Keep unique month buckets in first-seen order before final newest-first sort.
  final months = <DateTime>[];
  final seenMonths = <DateTime>{};

  for (final transaction in transactions) {
    final transactionDate = transaction.date ?? transaction.createdAt;
    if (transactionDate == null) continue;
    final month = DateTime(transactionDate.year, transactionDate.month);
    if (seenMonths.add(month)) {
      months.add(month);
    }
  }

  months.sort((left, right) => right.compareTo(left));
  return months;
}

DateTime? _resolveSelectedMonth(
  List<DateTime> months,
  DateTime? requestedMonth,
) {
  if (months.isEmpty) return null;
  if (requestedMonth == null) return months.first;
  return months.contains(requestedMonth) ? requestedMonth : months.first;
}

bool _belongsToPocket(Transaction transaction, int pocketId) {
  return transaction.senderPocketId == pocketId ||
      transaction.receiverPocketId == pocketId;
}

bool _isInMonth(Transaction transaction, DateTime month) {
  final transactionDate = transaction.date ?? transaction.createdAt;
  return transactionDate != null &&
      transactionDate.year == month.year &&
      transactionDate.month == month.month;
}

bool _isMainChartTransaction(Transaction transaction) {
  return transaction.type != TransactionType.transfer &&
      transaction.type != TransactionType.adjustment &&
      !_loanTransactionTypes.contains(transaction.type);
}

bool _isIncomeChartTransaction(Transaction transaction) {
  return transaction.type == TransactionType.income ||
      transaction.type == TransactionType.refund;
}

bool _isExpenseChartTransaction(Transaction transaction) {
  return transaction.type == TransactionType.expense;
}

List<StatisticsChartSlice> _buildSlices(
  List<Transaction> transactions,
  Map<int, String> categoryNames, {
  required StatisticsChartType chartType,
  required String fallbackLabel,
}) {
  // Aggregate absolute amounts per category for pie chart slices.
  final totalsByCategory = <_SliceCategoryKey, double>{};

  for (final transaction in transactions) {
    final categoryId = transaction.categoryId;
    final label =
        categoryId != null
            ? categoryNames[categoryId] ?? fallbackLabel
            : fallbackLabel;
    final key = _SliceCategoryKey(categoryId, label);
    totalsByCategory.update(
      key,
      (current) => current + transaction.amount.abs(),
      ifAbsent: () => transaction.amount.abs(),
    );
  }

  final grandTotal = totalsByCategory.values.fold(
    0.0,
    (sum, value) => sum + value,
  );

  final slices =
      totalsByCategory.entries
          .map(
            (entry) => StatisticsChartSlice(
              chartType: chartType,
              categoryId: entry.key.categoryId,
              label: entry.key.label,
              amount: entry.value,
              percentage:
                  grandTotal == 0.0 ? 0.0 : (entry.value / grandTotal) * 100,
            ),
          )
          .toList();
  slices.sort((left, right) => right.amount.compareTo(left.amount));
  return slices;
}

List<Transaction> _buildCategoryTransactions(
  List<Transaction> scopedTransactions,
  StatisticsCategoryDrilldown drilldown,
) {
  final monthTransactions =
      scopedTransactions.where((tx) => _isInMonth(tx, drilldown.month)).where((
        tx,
      ) {
        switch (drilldown.chartType) {
          case StatisticsChartType.expense:
            return _isExpenseChartTransaction(tx);
          case StatisticsChartType.income:
            return _isIncomeChartTransaction(tx);
        }
      }).toList();

  return monthTransactions.where((tx) {
    if (drilldown.categoryId != null) {
      return tx.categoryId == drilldown.categoryId;
    }
    return tx.categoryId == null;
  }).toList();
}

String? _resolveDrilldownPocketName(
  Transaction transaction,
  Map<int, String> pocketName,
) {
  if (transaction.isTransfer) {
    final sender = pocketName[transaction.senderPocketId] ?? '?';
    final receiver = pocketName[transaction.receiverPocketId] ?? '?';
    return '$sender -> $receiver';
  }
  return pocketName[transaction.senderPocketId] ??
      pocketName[transaction.receiverPocketId];
}

double _resolveTotalBalance(StatisticsScope scope, List<Pocket> pockets) {
  if (scope.type == StatisticsScopeType.allPockets) {
    return pockets.fold(0.0, (sum, pocket) => sum + pocket.balance);
  }

  final pocketId = scope.pocketId;
  if (pocketId == null) {
    return 0.0;
  }
  return pockets
      .where((pocket) => pocket.id == pocketId)
      .fold(0.0, (sum, pocket) => sum + pocket.balance);
}

String _resolveDisplayCurrency(StatisticsScope scope, List<Pocket> pockets) {
  if (scope.type == StatisticsScopeType.allPockets) {
    // Assumption: first pocket currency represents the default app display currency.
    return pockets.isNotEmpty ? pockets.first.currency : 'IDR';
  }

  final pocketId = scope.pocketId;
  if (pocketId == null) {
    return 'IDR';
  }

  final scopedPocket = pockets.where((pocket) => pocket.id == pocketId);
  return scopedPocket.isNotEmpty ? scopedPocket.first.currency : 'IDR';
}

double _signedContributionForScope(
  Transaction transaction,
  StatisticsScope scope,
) {
  if (transaction.type == TransactionType.transfer) {
    if (scope.type == StatisticsScopeType.allPockets) {
      return 0.0;
    }

    final pocketId = scope.pocketId;
    if (pocketId == null) {
      return 0.0;
    }
    if (transaction.senderPocketId == pocketId) {
      return -transaction.amount.abs();
    }
    if (transaction.receiverPocketId == pocketId) {
      return transaction.amount.abs();
    }
    return 0.0;
  }

  if (transaction.type == TransactionType.adjustment) {
    return transaction.amount;
  }

  return transaction.type.isPositive
      ? transaction.amount.abs()
      : -transaction.amount.abs();
}

StatisticsBudgetHighlight _buildBudgetHighlight(
  List<Transaction> monthTransactions,
  List<BudgetWithSpent> budgets,
) {
  // Summarize monthly expense spending only for transactions linked to budgets.
  final budgetTotals = <int, double>{};
  for (final transaction in monthTransactions) {
    final budgetId = transaction.budgetId;
    if (budgetId == null || transaction.type != TransactionType.expense) {
      continue;
    }
    budgetTotals.update(
      budgetId,
      (current) => current + transaction.amount.abs(),
      ifAbsent: () => transaction.amount.abs(),
    );
  }

  if (budgetTotals.isEmpty) {
    return const StatisticsBudgetHighlight(
      activeBudgetCount: 0,
      overBudgetCount: 0,
      spentTotal: 0,
      budgetedTotal: 0,
    );
  }

  final budgetLookup = {
    for (final item in budgets)
      if (item.budget.id != null) item.budget.id!: item.budget,
  };

  var budgetedTotal = 0.0;
  var overBudgetCount = 0;

  for (final entry in budgetTotals.entries) {
    final budget = budgetLookup[entry.key];
    if (budget == null) continue;
    budgetedTotal += budget.amount;
    if (entry.value > budget.amount) {
      overBudgetCount++;
    }
  }

  return StatisticsBudgetHighlight(
    activeBudgetCount: budgetTotals.length,
    overBudgetCount: overBudgetCount,
    spentTotal: budgetTotals.values.fold(0.0, (sum, value) => sum + value),
    budgetedTotal: budgetedTotal,
  );
}

StatisticsLoanHighlight _buildLoanHighlight(
  List<Transaction> monthTransactions,
  List<Loan> loans,
) {
  // Join month loan-related transactions with loan records for status highlights.
  final relatedTransactions =
      monthTransactions.where(_isLoanRelatedTransaction).toList();
  final relatedLoanIds =
      relatedTransactions
          .map((transaction) => transaction.loanId)
          .whereType<int>()
          .toSet();
  final relatedLoans =
      loans
          .where((loan) => loan.id != null && relatedLoanIds.contains(loan.id))
          .toList();

  var inflow = 0.0;
  var outflow = 0.0;
  // Normalize amounts to absolute values so inflow/outflow is direction-based only.
  for (final transaction in relatedTransactions) {
    switch (transaction.type) {
      case TransactionType.loanTaken:
      case TransactionType.loanCollection:
        inflow += transaction.amount.abs();
        break;
      case TransactionType.loanGiven:
      case TransactionType.loanRepayment:
        outflow += transaction.amount.abs();
        break;
      default:
        break;
    }
  }

  return StatisticsLoanHighlight(
    relatedLoanCount: relatedLoans.length,
    ongoingCount:
        relatedLoans.where((loan) => loan.status == LoanStatus.ongoing).length,
    overdueCount:
        relatedLoans.where((loan) => loan.status == LoanStatus.overdue).length,
    inflow: inflow,
    outflow: outflow,
    outstandingTotal: relatedLoans
        .where(
          (loan) =>
              loan.status == LoanStatus.ongoing ||
              loan.status == LoanStatus.overdue,
        )
        .fold(0.0, (sum, loan) => sum + (loan.amount - loan.repaidAmount)),
  );
}

bool _isLoanRelatedTransaction(Transaction transaction) {
  return _loanTransactionTypes.contains(transaction.type) ||
      transaction.loanId != null;
}

double _sumAmounts(List<Transaction> transactions) {
  return transactions.fold(
    0.0,
    (sum, transaction) => sum + transaction.amount.abs(),
  );
}

int _compareByNewestDate(Transaction left, Transaction right) {
  final leftDate = left.date ?? left.createdAt ?? DateTime(0);
  final rightDate = right.date ?? right.createdAt ?? DateTime(0);
  return rightDate.compareTo(leftDate);
}

class _SliceCategoryKey {
  final int? categoryId;
  final String label;

  const _SliceCategoryKey(this.categoryId, this.label);

  @override
  bool operator ==(Object other) {
    return other is _SliceCategoryKey &&
        other.categoryId == categoryId &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(categoryId, label);
}

const _loanTransactionTypes = {
  TransactionType.loanGiven,
  TransactionType.loanTaken,
  TransactionType.loanRepayment,
  TransactionType.loanCollection,
};
