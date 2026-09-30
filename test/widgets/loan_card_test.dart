import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/screens/loan/loan_card.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

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
      MaterialApp(
        home: Scaffold(
          body: LoanCard(loan: loan, isOverdue: isLoanOverdue(loan)),
        ),
      ),
    );

    expect(find.text('Purchase Installment'), findsOneWidget);
    expect(find.text('6 installments'), findsOneWidget);
    expect(find.text('Next due 2026-04-10'), findsOneWidget);
  });

  testWidgets('LoanCard shows completed schedule label', (tester) async {
    final loan = buildLoanModel(status: LoanStatus.completed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanCard(loan: loan, isOverdue: isLoanOverdue(loan)),
        ),
      ),
    );

    expect(find.text('Schedule completed'), findsOneWidget);
  });

  testWidgets('LoanCard uses the preview installment date for urgency', (
    tester,
  ) async {
    final nextDueDate = DateTime.now().subtract(const Duration(days: 1));
    final loan = buildLoanModel(
      dueDate: DateTime.now().add(const Duration(days: 30)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanCard(
            loan: loan,
            nextDueDate: nextDueDate,
            isOverdue: isLoanOverdue(loan, dueDate: nextDueDate),
          ),
        ),
      ),
    );

    final dateLabel =
        'Next due ${nextDueDate.year}-${nextDueDate.month.toString().padLeft(2, '0')}-${nextDueDate.day.toString().padLeft(2, '0')}';
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text(dateLabel), findsOneWidget);
  });

  testWidgets('LoanCard does not mark an installment due today overdue', (
    tester,
  ) async {
    final today = DateTime.now();
    final dueToday = DateTime(today.year, today.month, today.day);
    final loan = buildLoanModel(
      dueDate: DateTime.now().add(const Duration(days: 30)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanCard(
            loan: loan,
            nextDueDate: dueToday,
            isOverdue: isLoanOverdue(loan, dueDate: dueToday),
          ),
        ),
      ),
    );

    expect(find.text('Ongoing'), findsOneWidget);
  });
}
