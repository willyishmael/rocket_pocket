import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    test('symbolFor returns fallback for invalid ISO code', () {
      const code = 'NOT_A_CURRENCY';
      expect(CurrencyUtils.symbolFor(code), code);
    });

    test('format returns fallback for invalid ISO code', () {
      const code = 'NOT_A_CURRENCY';
      expect(CurrencyUtils.format(123.456, code), '${code} 123.46');
    });

    test('format with valid code produces non-empty output', () {
      final output = CurrencyUtils.format(50000, 'USD');
      expect(output, isNotEmpty);
      expect(output, contains('50'));
    });
  });
}
