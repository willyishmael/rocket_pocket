class Account {
  static int _nextId = 1;
  int id;
  String name;
  String currency;
  double balance;
  int accentColor;

  Account({
    required this.name,
    required this.currency,
    required this.balance,
    required this.accentColor,
  }) : id = _nextId++;
}
