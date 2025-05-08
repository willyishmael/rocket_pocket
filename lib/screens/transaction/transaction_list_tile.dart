import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/local/database.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionListTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(transaction.description),
      subtitle: Text(transaction.type),
      trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
      onTap: () {
        // Handle tap on the transaction
        print('Tapped on transaction: ${transaction.description}');
      },
    );
  }
}
