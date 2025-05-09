import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionListTile({super.key, required this.transaction});

  Icon _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icon(Icons.arrow_upward, size: 24);
      case TransactionType.income:
        return Icon(Icons.arrow_downward, size: 24);
      case TransactionType.transfer:
        return Icon(Icons.compare_arrows, size: 24);
      case TransactionType.refund:
        return Icon(Icons.arrow_downward, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(transaction.description),
      subtitle: Text('Account name'),
      leading: _getTransactionIcon(transaction.type),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(transaction.type.toReadableString()),
          Text(
            transaction.type == TransactionType.income
                ? '+\$${transaction.amount.toStringAsFixed(2)}'
                : '-\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: transaction.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16
            ),
          ),
          Text(transaction.createdAt.toLocal().toString().split(' ')[0]),
        ],
      ),
      onTap: () {
        // Handle tap on the transaction
        print('Tapped on transaction: ${transaction.description}');
      },
    );
  }
}
