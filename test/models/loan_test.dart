import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart' as model;

import '../helpers/test_data_builders.dart';

void main() {
  group('Loan', () {
    test('copyWith updates selected fields and keeps others', () {
      final original = buildLoanModel();
      final updated = original.copyWith(
        counterpartyName: 'Taylor',
        repaidAmount: 125,
        status: LoanStatus.completed,
      );

      expect(updated.id, original.id);
      expect(updated.counterpartyName, 'Taylor');
      expect(updated.repaidAmount, 125);
      expect(updated.status, LoanStatus.completed);
      expect(updated.amount, original.amount);
    });

    test('fromDb maps row fields to model', () {
      final row = buildLoanRow(
        id: 4,
        type: LoanType.taken,
        counterpartyName: 'Jordan',
        status: LoanStatus.overdue,
      );

      final loan = model.Loan.fromDb(row);

      expect(loan.id, 4);
      expect(loan.type, LoanType.taken);
      expect(loan.counterpartyName, 'Jordan');
      expect(loan.status, LoanStatus.overdue);
      expect(loan.startDate, row.startDate);
      expect(loan.createdAt, row.createdAt);
    });
  });
}
