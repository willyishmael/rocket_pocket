import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

class TransactionScreen extends StatelessWidget {
  TransactionScreen({super.key});

  final List<Transaction> transactions = [
    Transaction(
      id: 1,
      senderAccountId: 1,
      receiverAccountId: null,
      type: TransactionType.expense,
      categoryId: 1,
      loanId: null,
      originalTransactionId: null,
      amount: 50.00,
      description: 'cilok',
      createdAt: DateTime.now(),
    ),
    Transaction(
      id: 2,
      senderAccountId: null,
      receiverAccountId: 2,
      type: TransactionType.income,
      categoryId: 1,
      loanId: null,
      originalTransactionId: null,
      amount: 50.00,
      description: 'steal money from stranger',
      createdAt: DateTime.now(),
    ),
    Transaction(
      id: 3,
      senderAccountId: 1,
      receiverAccountId: 2,
      type: TransactionType.transfer,
      categoryId: 1,
      loanId: null,
      originalTransactionId: null,
      amount: 50.00,
      description: 'transfer money to friend',
      createdAt: DateTime.now(),
    ),
    Transaction(
      id: 4,
      senderAccountId: null,
      receiverAccountId: 2,
      type: TransactionType.refund,
      categoryId: 1,
      loanId: null,
      originalTransactionId: 2,
      amount: 50.00,
      description: 'refund money from friend',
      createdAt: DateTime.now(),
    ),
    // Add more transactions here
  ];

@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: addTransactionActionButton(context),
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
              return TransactionListTile(transaction: transactions[index]);
            },
            childCount: transactions.length,
          ),
        ),
      ],
    ),
  );
}

  FloatingActionButton addTransactionActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        context.go(Paths.addTransaction);
      },
      child: const Icon(Icons.add),
    );
  }
}
