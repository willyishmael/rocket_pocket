import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final String? pocketName;
  final VoidCallback? onTap;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.currency = 'IDR',
    this.pocketName,
    this.onTap,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDay = DateTime(local.year, local.month, local.day);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (txDay == today) return 'Today, $time';
    if (txDay == yesterday) return 'Yesterday, $time';
    final dateStr =
        '${_months[local.month - 1]} ${local.day}'
        '${local.year != now.year ? ', ${local.year}' : ''}';
    return '$dateStr, $time';
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction.type;
    final isTransfer = type == TransactionType.transfer;
    final isPositive = type.isPositive;
    final sign = isTransfer ? '' : (isPositive ? '+' : '-');
    final symbol = CurrencyUtils.symbolFor(currency);
    final amountText =
        '${sign.isEmpty ? '' : '$sign '}$symbol ${transaction.amount.toStringAsFixed(2)}';
    final (iconData, iconColor) = switch (type) {
      TransactionType.expense => (Icons.arrow_upward, Colors.red),
      TransactionType.income => (Icons.arrow_downward, Colors.green),
      TransactionType.transfer => (Icons.compare_arrows, Colors.blue),
      TransactionType.refund => (Icons.replay, Colors.orange),
      TransactionType.loanGiven => (Icons.call_made, Colors.deepOrange),
      TransactionType.loanTaken => (Icons.call_received, Colors.teal),
      TransactionType.loanRepayment => (Icons.payment, Colors.deepPurple),
      TransactionType.loanCollection => (Icons.payments, Colors.indigo),
      TransactionType.adjustment => (Icons.tune, Colors.blueGrey),
    };

    return ListTile(
      onTap: onTap,
      title: Text(transaction.description),
      subtitle: Text(
        pocketName != null
            ? '$pocketName  •  ${_formatDateTime(transaction.date ?? transaction.createdAt)}'
            : _formatDateTime(transaction.date ?? transaction.createdAt),
      ),
      leading: Icon(iconData, size: 24, color: iconColor),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            type.toReadableString(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            amountText,
            style: TextStyle(
              color:
                  isTransfer
                      ? Colors.blue
                      : (isPositive ? Colors.green : Colors.red),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
