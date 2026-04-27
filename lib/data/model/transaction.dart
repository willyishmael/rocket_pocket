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
  final int? budgetId;
  final String description;
  final double amount;
  final DateTime? date;
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
    this.budgetId,
    required this.description,
    required this.amount,
    this.date,
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
    int? budgetId,
    String? description,
    double? amount,
    DateTime? date,
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
      budgetId: budgetId ?? this.budgetId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
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
      budgetId: dbRow.budgetId,
      description: dbRow.description,
      amount: dbRow.amount,
      date: dbRow.date,
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
      budgetId: Value(budgetId),
      description: description,
      amount: amount,
      date: Value(date),
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
      budgetId: Value(budgetId),
      description: Value(description),
      amount: Value(amount),
      date: Value(date),
      updatedAt: Value(DateTime.now()),
    );
  }
}
