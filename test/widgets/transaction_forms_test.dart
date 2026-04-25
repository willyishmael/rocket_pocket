import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/screens/transaction/widgets/add_transaction_header.dart';
import 'package:rocket_pocket/screens/transaction/widgets/expense_transaction_form.dart';
import 'package:rocket_pocket/screens/transaction/widgets/income_transaction_form.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transfer_transaction_form.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  Future<void> pumpTestWidget(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  AddTransactionState buildState({
    required TransactionType type,
    bool includeBudgets = false,
  }) {
    final sender = buildPocketModel(id: 1, name: 'Wallet');
    final receiver = buildPocketModel(id: 2, name: 'Bank');
    final categoryType =
        type == TransactionType.transfer ? TransactionType.expense : type;
    final category = buildCategoryRow(
      id: 1,
      name: 'Category',
      type: categoryType,
    );

    return AddTransactionState(
      pockets: [sender, receiver],
      allCategories: [category],
      allTransactions: const [],
      allBudgets: includeBudgets ? [buildBudgetModel()] : const [],
      selectedType: type,
      senderPocket: sender,
      receiverPocket: type == TransactionType.transfer ? receiver : null,
      selectedCategory: type == TransactionType.transfer ? null : category,
      description: 'Test transaction',
      amount: 25,
      date: fixedDate(),
    );
  }

  group('AddTransactionHeader', () {
    testWidgets('renders type selector and date/time controls', (tester) async {
      await pumpTestWidget(
        tester,
        AddTransactionHeader(state: buildState(type: TransactionType.income)),
      );

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('2026-04-15'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });
  });

  group('Transaction forms', () {
    testWidgets('income form shows only income fields', (tester) async {
      await pumpTestWidget(
        tester,
        IncomeTransactionForm(state: buildState(type: TransactionType.income)),
      );

      expect(find.text('Pocket'), findsOneWidget);
      expect(find.text('Category'), findsAtLeastNWidgets(1));
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Save Income'), findsOneWidget);
      expect(find.text('Budget (optional)'), findsNothing);
      expect(find.text('Tip (optional)'), findsNothing);
      expect(find.text('Tax (optional)'), findsNothing);
      expect(find.text('Admin Fee (optional)'), findsNothing);
      expect(find.text('To Pocket'), findsNothing);
    });

    testWidgets('expense form shows expense-specific fields', (tester) async {
      await pumpTestWidget(
        tester,
        ExpenseTransactionForm(
          state: buildState(
            type: TransactionType.expense,
            includeBudgets: true,
          ),
        ),
      );

      expect(find.text('Pocket'), findsOneWidget);
      expect(find.text('Category'), findsAtLeastNWidgets(1));
      expect(find.text('Budget (optional)'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Tip (optional)'), findsOneWidget);
      expect(find.text('Tax (optional)'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);
      expect(find.text('Admin Fee (optional)'), findsNothing);
      expect(find.text('To Pocket'), findsNothing);
    });

    testWidgets('transfer form shows transfer-specific fields', (tester) async {
      await pumpTestWidget(
        tester,
        TransferTransactionForm(
          state: buildState(type: TransactionType.transfer),
        ),
      );

      expect(find.text('From Pocket'), findsOneWidget);
      expect(find.text('To Pocket'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Admin Fee (optional)'), findsOneWidget);
      expect(find.text('Save Transfer'), findsOneWidget);
      expect(find.text('Category'), findsNothing);
      expect(find.text('Budget (optional)'), findsNothing);
      expect(find.text('Tip (optional)'), findsNothing);
      expect(find.text('Tax (optional)'), findsNothing);
    });
  });
}
