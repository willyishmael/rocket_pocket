import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  /// Returns the currency symbol for the given ISO 4217 [isoCode].
  /// Falls back to the code itself if unrecognised.
  /// Example: symbolFor('IDR') → 'Rp', symbolFor('USD') → 'US$'
  static String symbolFor(String isoCode) {
    try {
      return NumberFormat.simpleCurrency(name: isoCode).currencySymbol;
    } catch (_) {
      return isoCode;
    }
  }

  /// Formats [amount] as a currency string with the correct symbol and
  /// locale-appropriate separators.
  /// Example: format(50000, 'IDR') → 'Rp 50,000'
  static String format(double amount, String isoCode) {
    try {
      return NumberFormat.simpleCurrency(name: isoCode).format(amount);
    } catch (_) {
      return '$isoCode ${amount.toStringAsFixed(2)}';
    }
  }
}
