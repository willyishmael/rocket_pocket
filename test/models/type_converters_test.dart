import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/type_converter/budget_period_converter.dart';
import 'package:rocket_pocket/data/model/type_converter/color_list_converter.dart';
import 'package:rocket_pocket/data/model/type_converter/loan_status_converter.dart';
import 'package:rocket_pocket/data/model/type_converter/loan_type_converter.dart';

void main() {
  test('BudgetPeriodConverter round-trips values', () {
    const converter = BudgetPeriodConverter();
    expect(
      converter.fromSql(converter.toSql(BudgetPeriod.yearly)),
      BudgetPeriod.yearly,
    );
  });

  test('LoanStatusConverter round-trips values', () {
    const converter = LoanStatusConverter();
    expect(
      converter.fromSql(converter.toSql(LoanStatus.cancelled)),
      LoanStatus.cancelled,
    );
  });

  test('LoanTypeConverter round-trips values', () {
    const converter = LoanTypeConverter();
    expect(converter.fromSql(converter.toSql(LoanType.taken)), LoanType.taken);
  });

  test('ColorListConverter round-trips colors', () {
    const converter = ColorListConverter();
    const colors = [Color(0xFF112233), Color(0xFF445566)];

    final encoded = converter.toSql(colors);
    final decoded = converter.fromSql(encoded);

    expect(
      decoded.map((c) => c.toARGB32()).toList(),
      colors.map((c) => c.toARGB32()).toList(),
    );
  });
}
