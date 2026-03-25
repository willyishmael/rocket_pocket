class Paths {
  static const String root = '/';
  static const String dashboard = '/dashboard';
  static const String createPocket = '$dashboard/create-Pocket';
  static const String pocketDetails = '$dashboard/pocket/:pocketId';
  static const String pocketTransactions = '$pocketDetails/Pocket-transactions';
  static const String editPocket = '$pocketDetails/edit';

  /// Returns the concrete path for a given pocket id.
  static String pocketDetailsRoute(int pocketId) =>
      '$dashboard/pocket/$pocketId';

  static String editPocketRoute(int pocketId) =>
      '$dashboard/pocket/$pocketId/edit';

  static const String transaction = '/transaction';
  static const String addTransaction = '$transaction/add';

  static const String budget = '/budget';
  static const String settings = '/settings';
  static const String loan = '/loan';
  static const String loanDetails = '$loan/:loanId';

  static String loanDetailsRoute(int loanId) => '$loan/$loanId';
}
