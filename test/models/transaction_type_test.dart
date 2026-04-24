import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

void main() {
  group('TransactionTypeExtension', () {
    test('toReadableString maps every enum value', () {
      expect(TransactionType.expense.toReadableString(), 'Expense');
      expect(TransactionType.income.toReadableString(), 'Income');
      expect(TransactionType.transfer.toReadableString(), 'Transfer');
      expect(TransactionType.refund.toReadableString(), 'Refund');
      expect(TransactionType.loanGiven.toReadableString(), 'Loan Out');
      expect(TransactionType.loanTaken.toReadableString(), 'Loan In');
      expect(
        TransactionType.loanRepayment.toReadableString(),
        'Loan Repayment',
      );
      expect(
        TransactionType.loanCollection.toReadableString(),
        'Loan Collection',
      );
      expect(TransactionType.adjustment.toReadableString(), 'Adjustment');
    });

    test('isPositive is true only for incoming money types', () {
      expect(TransactionType.income.isPositive, isTrue);
      expect(TransactionType.refund.isPositive, isTrue);
      expect(TransactionType.loanTaken.isPositive, isTrue);
      expect(TransactionType.loanCollection.isPositive, isTrue);

      expect(TransactionType.expense.isPositive, isFalse);
      expect(TransactionType.transfer.isPositive, isFalse);
      expect(TransactionType.loanGiven.isPositive, isFalse);
      expect(TransactionType.loanRepayment.isPositive, isFalse);
      expect(TransactionType.adjustment.isPositive, isFalse);
    });
  });

  group('TransactionTypeConverter', () {
    test('converts to and from SQL values', () {
      const converter = TransactionTypeConverter();
      const value = TransactionType.loanGiven;

      final sql = converter.toSql(value);
      final restored = converter.fromSql(sql);

      expect(sql, 'loanGiven');
      expect(restored, value);
    });
  });
}
