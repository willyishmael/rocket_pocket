import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/utils/enum_converter/transaction_type.dart';

class TransactionScreen extends StatelessWidget {
  TransactionScreen({super.key});

  final List<Transaction> transactions = [
    Transaction(
      id: 1,
      senderAccountId: 1,
      receiverAccountId: 2,
      type: TransactionType.expense.toString(),
      categoryId: 1,
      loanId: null,
      originalTransactionId: null,
      amount: 50.00,
      description: 'Groceries',
      createdAt: DateTime.now(),
    ),
    // Add more transactions here
  ];

@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: addTransactionActionButton(),
    floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,

    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          expandedHeight: 150.0,
          flexibleSpace: const FlexibleSpaceBar(
            title: Text('Transactions'),
            centerTitle: false,
            titlePadding: EdgeInsets.only(left: 16, bottom: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Handle filter action
                print('Filter transactions');
              },
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TransactionListTile(transaction: transactions[0]);
            },
            childCount: 30,
          ),
        ),
      ],
    ),
  );
}

  FloatingActionButton addTransactionActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Handle adding a new transaction
        print('Add new transaction');
      },
      child: const Icon(Icons.add),
    );
  }
}
