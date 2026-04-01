abstract final class Paths {
  // ── Root ────────────────────────────────────────────────────────────────────
  static const String root = '/';

  // ── Dashboard ───────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String createPocket = '$dashboard/create-pocket';
  static const String pocketDetails = '$dashboard/pocket/:pocketId';
  static const String pocketTransactions = '$pocketDetails/pocket-transactions';
  static const String editPocket = '$pocketDetails/edit';

  static String pocketDetailsRoute(int pocketId) =>
      '$dashboard/pocket/$pocketId';
  static String pocketTransactionsRoute(int pocketId) =>
      '$dashboard/pocket/$pocketId/pocket-transactions';
  static String editPocketRoute(int pocketId) =>
      '$dashboard/pocket/$pocketId/edit';

  // ── Transaction ─────────────────────────────────────────────────────────────
  static const String transaction = '/transaction';
  static const String addTransaction = '$transaction/add';

  // ── Budget ──────────────────────────────────────────────────────────────────
  static const String budget = '/budget';
  static const String addBudget = '$budget/add';
  static const String budgetDetails = '$budget/:budgetId';

  static String budgetDetailsRoute(int budgetId) =>
      '$budget/$budgetId'; // ── Loan ────────────────────────────────────────────────────────────────────
  static const String loan = '/loan';
  static const String addLoan = '$loan/add';
  static const String loanDetails = '$loan/:loanId';
  static const String editLoan = '$loan/:loanId/edit';
  static const String addRepayment = '$loan/:loanId/repayment';

  static String loanDetailsRoute(int loanId) => '$loan/$loanId';
  static String editLoanRoute(int loanId) => '$loan/$loanId/edit';
  static String addRepaymentRoute(int loanId) => '$loan/$loanId/repayment';

  // ── Settings ────────────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String manageCategories = '$settings/categories';
}
