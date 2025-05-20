import 'package:rocket_pocket/data/model/color_gradient.dart';

class Account {
  static int _nextId = 1;
  int id;
  String name;
  String currency;
  double balance;
  ColorGradient colorGradient;

  Account({
    required this.name,
    required this.currency,
    required this.balance,
    required this.colorGradient,
  }) : id = _nextId++;
}
