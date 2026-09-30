abstract final class Paths {
  // ── Root ────────────────────────────────────────────────────────────────────
  static const String root = '/';

  // ── Ledger and pockets ─────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String ledger = '/ledger';
  static const String pockets = '$ledger/pockets';
  static const String createPocket = '$pockets/create';
  static const String pocketDetails = '$pockets/:pocketId';
  static const String pocketTransactions = '$pocketDetails/pocket-transactions';
  static const String editPocket = '$pocketDetails/edit';

  static String pocketDetailsRoute(int pocketId) => '$pockets/$pocketId';
  static String pocketTransactionsRoute(int pocketId) =>
      '$pockets/$pocketId/pocket-transactions';
  static String editPocketRoute(int pocketId) => '$pockets/$pocketId/edit';

  // ── Transaction ─────────────────────────────────────────────────────────────
  static const String transaction = '/transaction';
  static const String addTransaction = '$transaction/add';
  static const String transactionDetails = '$transaction/:transactionId';
  static const String editTransaction = '$transaction/:transactionId/edit';

  static String transactionDetailsRoute(int transactionId) =>
      '$transaction/$transactionId';
  static String editTransactionRoute(int transactionId) =>
      '$transaction/$transactionId/edit';

  // ── Budget ──────────────────────────────────────────────────────────────────
  static const String budget = '/budget';
  static const String addBudget = '$budget/add';
  static const String budgetDetails = '$budget/:budgetId';
  static const String editBudget = '$budget/:budgetId/edit';

  static String budgetDetailsRoute(int budgetId) => '$budget/$budgetId';
  static String editBudgetRoute(int budgetId) => '$budget/$budgetId/edit';

  // ── Loan ────────────────────────────────────────────────────────────────────
  static const String loan = '/loan';
  static const String addLoan = '$loan/add';
  static const String loanDetails = '$loan/:loanId';
  static const String editLoan = '$loan/:loanId/edit';
  static const String addRepayment = '$loan/:loanId/repayment';
  static const String loanInstallments = '$loan/:loanId/installments';

  static String loanDetailsRoute(int loanId) => '$loan/$loanId';
  static String editLoanRoute(int loanId) => '$loan/$loanId/edit';
  static String addRepaymentRoute(int loanId) => '$loan/$loanId/repayment';
  static String loanInstallmentsRoute(int loanId) =>
      '$loan/$loanId/installments';

  // ── Statistics ─────────────────────────────────────────────────────────────
  static const String statistics = '/statistics';
  static const String statisticsShowMore = '$statistics/show-more';
  static const String statisticsCategoryTransactions =
      '$statistics/category-transactions';

  // ── Settings ────────────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String manageCategories = '$settings/categories';
}
