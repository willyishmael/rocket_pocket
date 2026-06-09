import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    bool hasGroupedThousands(String output) {
      return RegExp(
        r'\d{1,3}([.,\s\u00A0])\d{3}([.,\s\u00A0])\d{3}',
      ).hasMatch(output);
    }

    bool hasTwoDecimalPlaces(String output) {
      return RegExp(r'[.,]\d{2}(?!\d)').hasMatch(output);
    }

    bool hasNoDecimalPlaces(String output) {
      return !RegExp(r'[.,]\d{1,2}(?!\d)').hasMatch(output);
    }

    test('format uses currency-derived locale for IDR separators', () {
      final output = CurrencyUtils.format(2500000, 'IDR');

      expect(output, startsWith('Rp'));
      expect(output, contains('2.500.000'));
      expect(output, isNot(contains(',00')));
    });

    test('symbolFor prefers Rp for IDR', () {
      expect(CurrencyUtils.symbolFor('IDR'), 'Rp');
    });

    test('format handles common currencies with grouping and symbols', () {
      final cases = <({String code, double amount})>[
        (code: 'EUR', amount: 1234567.89),
        (code: 'GBP', amount: 1234567.89),
        (code: 'JPY', amount: 2500000),
        (code: 'SGD', amount: 1234567.89),
        (code: 'BRL', amount: 1234567.89),
      ];

      for (final testCase in cases) {
        final output = CurrencyUtils.format(testCase.amount, testCase.code);
        final symbol = CurrencyUtils.symbolFor(testCase.code);
        final hasCurrencyMarker =
            output.contains(symbol) || output.contains(testCase.code);

        expect(
          output,
          isNotEmpty,
          reason: 'Expected output for ${testCase.code}',
        );
        expect(
          hasCurrencyMarker,
          isTrue,
          reason: 'Expected symbol or code for ${testCase.code} in "$output"',
        );
        expect(
          hasGroupedThousands(output),
          isTrue,
          reason:
              'Expected grouped thousands for ${testCase.code} in "$output"',
        );
      }
    });

    test('format preserves decimal behavior for common currencies', () {
      final twoDecimalCurrencies = <String>['EUR', 'GBP', 'SGD', 'BRL'];

      for (final code in twoDecimalCurrencies) {
        final output = CurrencyUtils.format(1234.56, code);
        expect(
          hasTwoDecimalPlaces(output),
          isTrue,
          reason: 'Expected two decimals for $code in "$output"',
        );
      }

      final jpyOutput = CurrencyUtils.format(2500000, 'JPY');
      expect(
        hasNoDecimalPlaces(jpyOutput),
        isTrue,
        reason: 'Expected no decimals for JPY in "$jpyOutput"',
      );
    });

    test('symbolFor returns fallback for invalid ISO code', () {
      const code = 'NOT_A_CURRENCY';
      expect(CurrencyUtils.symbolFor(code), code);
    });

    test('format returns fallback for invalid ISO code', () {
      const code = 'NOT_A_CURRENCY';
      final output = CurrencyUtils.format(123.456, code);

      expect(output, contains(code));
      expect(output, contains('123.46'));
    });

    test('format with valid code produces non-empty output', () {
      final output = CurrencyUtils.format(50000, 'USD');
      expect(output, isNotEmpty);
      expect(output, isNot(contains('USD 50000.00')));
    });

    test('format keeps IDR compact without inserted spacing', () {
      final output = CurrencyUtils.format(2500, 'IDR');

      expect(output, contains('Rp2.500'));
    });
  });
}
