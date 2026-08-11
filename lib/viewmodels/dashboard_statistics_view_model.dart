import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

final dashboardSelectedMonthProvider =
    NotifierProvider.family<DashboardSelectedMonthViewModel, DateTime?, int>(
      DashboardSelectedMonthViewModel.new,
    );

class DashboardSelectedMonthViewModel extends Notifier<DateTime?> {
  DashboardSelectedMonthViewModel(this.pocketId);

  final int pocketId;

  @override
  DateTime? build() => null;

  void setMonth(DateTime month) {
    state = month;
  }
}

final dashboardStatisticsProvider =
    Provider.family<AsyncValue<DashboardStatisticsState>, int>((ref, pocketId) {
      final transactionsAsync = ref.watch(transactionViewModelProvider);
      final budgetsAsync = ref.watch(budgetViewModelProvider);
      final loansAsync = ref.watch(loanViewModelProvider);
      final categoryNamesAsync = ref.watch(categoryNamesProvider);
      final requestedMonth = ref.watch(
        dashboardSelectedMonthProvider(pocketId),
      );

      final error =
          transactionsAsync.asError ??
          budgetsAsync.asError ??
          loansAsync.asError ??
          categoryNamesAsync.asError;
      if (error != null) {
        return AsyncError(error.error, error.stackTrace);
      }

      if (!transactionsAsync.hasValue ||
          !budgetsAsync.hasValue ||
          !loansAsync.hasValue ||
          !categoryNamesAsync.hasValue) {
        return const AsyncLoading();
      }

      return AsyncData(
        _buildDashboardStatistics(
          pocketId: pocketId,
          transactions: transactionsAsync.requireValue,
          budgets: budgetsAsync.requireValue,
          loans: loansAsync.requireValue,
          categoryNames: categoryNamesAsync.requireValue,
          requestedMonth: requestedMonth,
        ),
      );
    });

class DashboardStatisticsState {
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final DashboardSummaryTotals totals;
  final List<DashboardChartSlice> expenseSlices;
  final List<DashboardChartSlice> incomeSlices;
  final DashboardBudgetHighlight budgetHighlight;
  final DashboardLoanHighlight loanHighlight;

  const DashboardStatisticsState({
    required this.availableMonths,
    required this.selectedMonth,
    required this.totals,
    required this.expenseSlices,
    required this.incomeSlices,
    required this.budgetHighlight,
    required this.loanHighlight,
  });

  bool get hasCharts => expenseSlices.isNotEmpty || incomeSlices.isNotEmpty;
}

class DashboardSummaryTotals {
  final double income;
  final double expense;
  final int transactionCount;

  const DashboardSummaryTotals({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  double get net => income - expense;
}

class DashboardChartSlice {
  final String label;
  final double amount;

  const DashboardChartSlice({required this.label, required this.amount});
}

class DashboardBudgetHighlight {
  final int activeBudgetCount;
  final int overBudgetCount;
  final double spentTotal;
  final double budgetedTotal;

  const DashboardBudgetHighlight({
    required this.activeBudgetCount,
    required this.overBudgetCount,
    required this.spentTotal,
    required this.budgetedTotal,
  });
}

class DashboardLoanHighlight {
  final int relatedLoanCount;
  final int ongoingCount;
  final int overdueCount;
  final double inflow;
  final double outflow;
  final double outstandingTotal;

  const DashboardLoanHighlight({
    required this.relatedLoanCount,
    required this.ongoingCount,
    required this.overdueCount,
    required this.inflow,
    required this.outflow,
    required this.outstandingTotal,
  });
}

DashboardStatisticsState _buildDashboardStatistics({
  required int pocketId,
  required List<Transaction> transactions,
  required List<BudgetWithSpent> budgets,
  required List<Loan> loans,
  required Map<int, String> categoryNames,
  required DateTime? requestedMonth,
}) {
  // Build a month-scoped statistics snapshot for the selected pocket only.
  final pocketTransactions =
      transactions.where((tx) => _belongsToPocket(tx, pocketId)).toList()
        ..sort(_compareByNewestDate);

  final availableMonths = _deriveAvailableMonths(pocketTransactions);
  final effectiveMonth = _resolveSelectedMonth(availableMonths, requestedMonth);
  final monthTransactions =
      effectiveMonth == null
          ? const <Transaction>[]
          : pocketTransactions
              .where((tx) => _isInMonth(tx, effectiveMonth))
              .toList();

  final mainChartTransactions =
      monthTransactions.where(_isMainChartTransaction).toList();
  final incomeTransactions =
      mainChartTransactions.where(_isIncomeChartTransaction).toList();
  final expenseTransactions =
      mainChartTransactions.where(_isExpenseChartTransaction).toList();

  return DashboardStatisticsState(
    availableMonths: availableMonths,
    selectedMonth: effectiveMonth,
    totals: DashboardSummaryTotals(
      income: _sumAmounts(incomeTransactions),
      expense: _sumAmounts(expenseTransactions),
      transactionCount: mainChartTransactions.length,
    ),
    incomeSlices: _buildSlices(
      incomeTransactions,
      categoryNames,
      fallbackLabel: 'Income',
    ),
    expenseSlices: _buildSlices(
      expenseTransactions,
      categoryNames,
      fallbackLabel: 'Expense',
    ),
    budgetHighlight: _buildBudgetHighlight(monthTransactions, budgets),
    loanHighlight: _buildLoanHighlight(monthTransactions, loans),
  );
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

List<DashboardChartSlice> _buildSlices(
  List<Transaction> transactions,
  Map<int, String> categoryNames, {
  required String fallbackLabel,
}) {
  // Aggregate absolute amounts per category label for pie chart slices.
  final totalsByLabel = <String, double>{};

  for (final transaction in transactions) {
    final label =
        transaction.categoryId != null
            ? categoryNames[transaction.categoryId!] ?? fallbackLabel
            : fallbackLabel;
    totalsByLabel.update(
      label,
      (current) => current + transaction.amount.abs(),
      ifAbsent: () => transaction.amount.abs(),
    );
  }

  final slices =
      totalsByLabel.entries
          .map(
            (entry) =>
                DashboardChartSlice(label: entry.key, amount: entry.value),
          )
          .toList();
  slices.sort((left, right) => right.amount.compareTo(left.amount));
  return slices;
}

DashboardBudgetHighlight _buildBudgetHighlight(
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
    return const DashboardBudgetHighlight(
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

  return DashboardBudgetHighlight(
    activeBudgetCount: budgetTotals.length,
    overBudgetCount: overBudgetCount,
    spentTotal: budgetTotals.values.fold(0.0, (sum, value) => sum + value),
    budgetedTotal: budgetedTotal,
  );
}

DashboardLoanHighlight _buildLoanHighlight(
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

  return DashboardLoanHighlight(
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

const _loanTransactionTypes = {
  TransactionType.loanGiven,
  TransactionType.loanTaken,
  TransactionType.loanRepayment,
  TransactionType.loanCollection,
};
