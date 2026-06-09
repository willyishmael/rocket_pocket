import 'package:country_currency_pickers/utils/utils.dart';
import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static const _idrCode = 'IDR';

  static String? _currencyLocale(String isoCode) {
    try {
      final country = CountryPickerUtils.getCountryByCurrencyCode(isoCode);
      final countryCode = country.isoCode;

      if (countryCode != null && countryCode.isNotEmpty) {
        return countryCode;
      }
    } catch (_) {
      // Fall through to intl's default currency metadata lookup.
    }

    return null;
  }

  static int _displayDecimalDigits(double amount, int fallbackDigits) {
    if (amount == amount.truncateToDouble()) {
      return 0;
    }
    return fallbackDigits;
  }

  static NumberFormat _currencyFormatter(
    String isoCode, {
    required int decimalDigits,
  }) {
    final locale = _currencyLocale(isoCode);
    final symbol = symbolFor(isoCode);

    if (locale != null) {
      try {
        return NumberFormat.currency(
          locale: locale,
          name: isoCode,
          symbol: symbol,
          decimalDigits: decimalDigits,
        );
      } catch (_) {
        // Fall through to intl's default currency metadata lookup.
      }
    }

    return NumberFormat.currency(
      name: isoCode,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
  }

  /// Returns the currency symbol for the given ISO 4217 [isoCode].
  /// Delegates entirely to the intl library — no manual map needed.
  static String symbolFor(String isoCode) {
    if (isoCode == _idrCode) {
      return 'Rp';
    }

    try {
      final locale = _currencyLocale(isoCode);
      if (locale != null) {
        try {
          return NumberFormat.simpleCurrency(
            locale: locale,
            name: isoCode,
          ).currencySymbol;
        } catch (_) {
          // Fall through to intl's default currency metadata lookup.
        }
      }

      return NumberFormat.simpleCurrency(name: isoCode).currencySymbol;
    } catch (_) {
      return isoCode;
    }
  }

  /// Formats [amount] as a currency string.
  ///
  /// - Symbol and decimal digits come from the intl library's built-in
  ///   ISO 4217 data, so all currencies are handled correctly.
  /// - Separator style (dot vs comma) uses the device's current locale,
  ///   which matches what the user is used to reading.
  ///
  /// Example on an id_ID device:
  ///   format(1000000, 'IDR') → 'Rp 1.000.000'
  ///   format(1234.5,  'USD') → 'US$ 1.234,50'
  static String format(double amount, String isoCode) {
    try {
      final fallbackDigits =
          NumberFormat.simpleCurrency(name: isoCode).decimalDigits ?? 2;
      final decimalDigits = _displayDecimalDigits(amount, fallbackDigits);
      return _currencyFormatter(
        isoCode,
        decimalDigits: decimalDigits,
      ).format(amount);
    } catch (_) {
      return '$isoCode ${amount.toStringAsFixed(2)}';
    }
  }

  /// Formats [amount] as a plain number (no symbol) using the device locale.
  /// Useful when the currency code is unknown (e.g. loan screens).
  static String formatAmount(double amount) {
    try {
      return NumberFormat.decimalPattern(
        Intl.getCurrentLocale(),
      ).format(amount);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }
}
