import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/screens/loan/loan_card.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets('LoanCard shows subtype chip and next-due snippet', (
    tester,
  ) async {
    final loan = buildLoanModel(
      financingKind: LoanFinancingKind.purchaseInstallment,
      installmentCount: 6,
      dueDate: DateTime(2026, 8, 10, 10),
      startDate: DateTime(2026, 3, 1, 10),
      createdAt: DateTime(2026, 3, 1, 10),
    ).copyWith(firstInstallmentDate: DateTime(2026, 4, 10, 10));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LoanCard(loan: loan))),
    );

    expect(find.text('Purchase Installment'), findsOneWidget);
    expect(find.text('6 installments'), findsOneWidget);
    expect(find.text('Next due 2026-04-10'), findsOneWidget);
  });

  testWidgets('LoanCard shows completed schedule label', (tester) async {
    final loan = buildLoanModel(status: LoanStatus.completed);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LoanCard(loan: loan))),
    );

    expect(find.text('Schedule completed'), findsOneWidget);
  });
}
