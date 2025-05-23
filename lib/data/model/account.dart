import 'package:rocket_pocket/data/model/color_gradient.dart';

class Account {
  static int _nextId = 1;
  int id;
  String name;
  String purpose;
  String currency;
  double balance;
  ColorGradient colorGradient;
  String emoticon = '💰';

  Account({
    required this.name,
    required this.purpose,
    required this.currency,
    required this.balance,
    required this.colorGradient,
    required this.emoticon,
  }) : id = _nextId++;
}
