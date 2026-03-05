import 'package:rocket_pocket/data/model/transaction_type.dart';

class Transaction {
  final int id;
  final int? senderPocketId;
  final int? receiverPocketId;
  final TransactionType type;
  final int? categoryId;
  final int? loanId;
  final int? originalTransactionId;
  final String description;
  final double amount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    this.senderPocketId,
    this.receiverPocketId,
    required this.type,
    this.categoryId,
    this.loanId,
    this.originalTransactionId,
    required this.description,
    required this.amount,
    required this.createdAt,
  });
}
