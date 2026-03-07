import 'package:drift/drift.dart' show Value;
import 'package:rocket_pocket/data/local/database.dart' as db_provider;
import 'package:rocket_pocket/data/model/transaction_type.dart';

class Transaction {
  final int? id;
  final int? senderPocketId;
  final int? receiverPocketId;
  final TransactionType type;
  final int? categoryId;
  final int? loanId;
  final int? originalTransactionId;
  final String description;
  final double amount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    this.senderPocketId,
    this.receiverPocketId,
    required this.type,
    this.categoryId,
    this.loanId,
    this.originalTransactionId,
    required this.description,
    required this.amount,
    this.createdAt,
    this.updatedAt,
  });

  /// Helper getters to determine the transaction type
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isRefund => type == TransactionType.refund;

  /// Returns the amount prefixed with + or - based on transaction type.
  String get formattedAmount {
    final sign = (isIncome || isRefund) ? '+' : '-';
    return '$sign$amount';
  }

  /// Create a copy of this Transaction with updated values.
  Transaction copyWith({
    int? id,
    int? senderPocketId,
    int? receiverPocketId,
    TransactionType? type,
    int? categoryId,
    int? loanId,
    int? originalTransactionId,
    String? description,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      senderPocketId: senderPocketId ?? this.senderPocketId,
      receiverPocketId: receiverPocketId ?? this.receiverPocketId,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      loanId: loanId ?? this.loanId,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a Transaction instance from a database row.
  static Transaction fromDb(db_provider.Transaction dbRow) {
    return Transaction(
      id: dbRow.id,
      senderPocketId: dbRow.senderPocketId,
      receiverPocketId: dbRow.receiverPocketId,
      type: dbRow.type,
      categoryId: dbRow.categoryId,
      loanId: dbRow.loanId,
      originalTransactionId: dbRow.originalTransactionId,
      description: dbRow.description,
      amount: dbRow.amount,
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
    );
  }

  /// Convert this Transaction to a Companion for inserting a new row.
  /// Uses Value.absent() for id so the database auto-increments it.
  db_provider.TransactionsCompanion toInsertCompanion() {
    return db_provider.TransactionsCompanion.insert(
      senderPocketId: Value(senderPocketId),
      receiverPocketId: Value(receiverPocketId),
      type: type,
      categoryId: Value(categoryId),
      loanId: Value(loanId),
      originalTransactionId: Value(originalTransactionId),
      description: description,
      amount: amount,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert this Transaction to a Companion for updating an existing row.
  /// Requires a non-null id (the row must already exist).
  db_provider.TransactionsCompanion toUpdateCompanion() {
    assert(
      id != null,
      'toUpdateCompanion() requires a non-null id. Use toInsertCompanion() for new transactions.',
    );
    return db_provider.TransactionsCompanion(
      id: Value(id!),
      senderPocketId: Value(senderPocketId),
      receiverPocketId: Value(receiverPocketId),
      type: Value(type),
      categoryId: Value(categoryId),
      loanId: Value(loanId),
      originalTransactionId: Value(originalTransactionId),
      description: Value(description),
      amount: Value(amount),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Convert this Transaction to a database row for updates.
  /// Requires a non-null id (the row must already exist).
  db_provider.Transaction toDb() {
    assert(
      id != null,
      'toDb() requires a non-null id. Use toInsertCompanion() for new transactions.',
    );
    return db_provider.Transaction(
      id: id!,
      senderPocketId: senderPocketId,
      receiverPocketId: receiverPocketId,
      type: type,
      categoryId: categoryId,
      loanId: loanId,
      originalTransactionId: originalTransactionId,
      description: description,
      amount: amount,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
