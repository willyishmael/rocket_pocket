import 'package:rocket_pocket/data/model/transaction_type.dart';

class Transaction {
  final int id;
  final int? senderAccountId;
  final int? receiverAccountId;
  final TransactionType type;
  final int? categoryId;
  final int? loanId;
  final int? originalTransactionId;
  final String description;
  final double amount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    this.senderAccountId,
    this.receiverAccountId,
    required this.type,
    this.categoryId,
    this.loanId,
    this.originalTransactionId,
    required this.description,
    required this.amount,
    required this.createdAt,
  });
}