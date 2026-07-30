import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/screens/loan/loan_installment_section.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets('LoanInstallmentSection renders timeline and summary', (
    tester,
  ) async {
    final loan = buildLoanModel(
      amount: 1500,
      repaidAmount: 300,
      dueDate: DateTime(2026, 9, 10, 10),
      startDate: DateTime(2026, 4, 10, 10),
      createdAt: DateTime(2026, 4, 10, 10),
    );

    final installments = <db.LoanInstallment>[
      db.LoanInstallment(
        id: 1,
        loanId: 1,
        sequenceNo: 1,
        dueDate: DateTime(2026, 5, 10, 10),
        principalDue: 500,
        interestDue: 20,
        feeDue: 5,
        totalDue: 525,
        paidAmount: 525,
        paidAt: DateTime(2026, 5, 8, 10),
        status: InstallmentStatus.paid.name,
        reminderScheduledAt: null,
        createdAt: DateTime(2026, 4, 10, 10),
        updatedAt: DateTime(2026, 5, 8, 10),
      ),
      db.LoanInstallment(
        id: 2,
        loanId: 1,
        sequenceNo: 2,
        dueDate: DateTime(2026, 6, 10, 10),
        principalDue: 500,
        interestDue: 20,
        feeDue: 5,
        totalDue: 525,
        paidAmount: 100,
        paidAt: DateTime(2026, 6, 1, 10),
        status: InstallmentStatus.partial.name,
        reminderScheduledAt: null,
        createdAt: DateTime(2026, 4, 10, 10),
        updatedAt: DateTime(2026, 6, 1, 10),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanInstallmentSection(loan: loan, installments: installments),
        ),
      ),
    );

    expect(find.text('Installment Schedule'), findsOneWidget);
    expect(find.text('Installment #1'), findsOneWidget);
    expect(find.text('Installment #2'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Interest'), findsOneWidget);
    expect(find.text('Fee'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
  });
}
