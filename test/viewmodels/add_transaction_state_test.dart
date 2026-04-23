import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  group('AddTransactionState', () {
    test('filteredCategories returns expense categories for refund', () {
      final expense = buildCategoryRow(id: 1, type: TransactionType.expense);
      final income = buildCategoryRow(id: 2, type: TransactionType.income);

      final state = AddTransactionState(
        pockets: const [],
        allCategories: [expense, income],
        allTransactions: const [],
        selectedType: TransactionType.refund,
      );

      expect(state.filteredCategories, [expense]);
    });

    test('filteredCategories is empty for transfer', () {
      final state = AddTransactionState(
        pockets: const [],
        allCategories: [buildCategoryRow(type: TransactionType.expense)],
        allTransactions: const [],
        selectedType: TransactionType.transfer,
      );

      expect(state.filteredCategories, isEmpty);
    });

    test('refundableTransactions only returns expense transactions', () {
      final expense = buildTransactionModel(
        type: TransactionType.expense,
        amount: 20,
      );
      final income = buildTransactionModel(
        type: TransactionType.income,
        amount: 30,
      );

      final state = AddTransactionState(
        pockets: const [],
        allCategories: const [],
        allTransactions: [expense, income],
      );

      expect(state.refundableTransactions, [expense]);
    });

    test('isValid enforces transfer constraints', () {
      final sender = buildPocketModel(id: 1, name: 'Sender');
      final receiver = buildPocketModel(id: 2, name: 'Receiver');

      final valid = AddTransactionState(
        pockets: [sender, receiver],
        allCategories: const [],
        allTransactions: const [],
        selectedType: TransactionType.transfer,
        senderPocket: sender,
        receiverPocket: receiver,
        description: 'Move money',
        amount: 10,
      );

      final invalidSamePocket = valid.copyWith(receiverPocket: sender);
      final invalidNoReceiver = valid.copyWith(receiverPocket: null);

      expect(valid.isValid, isTrue);
      expect(invalidSamePocket.isValid, isFalse);
      expect(invalidNoReceiver.isValid, isFalse);
    });
  });
}
