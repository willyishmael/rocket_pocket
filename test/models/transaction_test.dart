import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

import '../helpers/test_data_builders.dart';

void main() {
  group('Transaction', () {
    test('formattedAmount uses plus sign for positive transaction types', () {
      final income = buildTransactionModel(
        type: TransactionType.income,
        amount: 55,
      );
      final refund = buildTransactionModel(
        type: TransactionType.refund,
        amount: 21.5,
      );

      expect(income.formattedAmount, '+55.0');
      expect(refund.formattedAmount, '+21.5');
    });

    test(
      'formattedAmount uses minus sign for expense-like transaction types',
      () {
        final expense = buildTransactionModel(
          type: TransactionType.expense,
          amount: 12.34,
        );
        final transfer = buildTransactionModel(
          type: TransactionType.transfer,
          amount: 9,
        );

        expect(expense.formattedAmount, '-12.34');
        expect(transfer.formattedAmount, '-9.0');
      },
    );

    test('copyWith updates provided fields and keeps the rest', () {
      final original = buildTransactionModel(
        id: 7,
        type: TransactionType.expense,
        amount: 88,
        description: 'Original',
        categoryId: 1,
      );

      final updated = original.copyWith(
        amount: 99,
        description: 'Updated',
        type: TransactionType.income,
      );

      expect(updated.id, 7);
      expect(updated.amount, 99);
      expect(updated.description, 'Updated');
      expect(updated.type, TransactionType.income);
      expect(updated.categoryId, 1);
    });
  });
}
