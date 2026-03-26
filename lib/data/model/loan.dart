import 'package:drift/drift.dart' show Value;
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';

class Loan {
  int? id;
  final LoanType type;
  final String counterpartyName;
  final double amount;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;
  final double repaidAmount;
  final DateTime createdAt;

  Loan({
    this.id,
    required this.type,
    required this.counterpartyName,
    required this.amount,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.repaidAmount,
    required this.createdAt,
  });

  Loan copyWith({
    int? id,
    LoanType? type,
    String? counterpartyName,
    double? amount,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
    double? repaidAmount,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      type: type ?? this.type,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Loan fromDb(db.Loan row) {
    return Loan(
      id: row.id,
      type: row.type,
      counterpartyName: row.counterpartyName,
      amount: row.amount,
      description: row.description,
      startDate: row.startDate,
      dueDate: row.dueDate,
      status: row.status,
      repaidAmount: row.repaidAmount,
      createdAt: row.createdAt,
    );
  }

  /// Convert this Loan to a Companion for inserting a new row.
  /// Uses Value.absent() for id so the database auto-increments it.
  db.LoansCompanion toInsertCompanion() {
    return db.LoansCompanion.insert(
      type: type,
      counterpartyName: counterpartyName,
      amount: amount,
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      status: status,
      repaidAmount: repaidAmount,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert this Loan to a Companion for updating an existing row.
  /// Requires a non-null id. Only writes fields explicitly set as Value(...)
  /// (createdAt is omitted so the original value is preserved).
  db.LoansCompanion toUpdateCompanion() {
    assert(
      id != null,
      'toUpdateCompanion() requires a non-null id.',
    );
    return db.LoansCompanion(
      id: Value(id!),
      type: Value(type),
      counterpartyName: Value(counterpartyName),
      amount: Value(amount),
      description: Value(description),
      startDate: Value(startDate),
      dueDate: Value(dueDate),
      status: Value(status),
      repaidAmount: Value(repaidAmount),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Convert this Loan to a database row for updates.
  /// Requires a non-null id (the row must already exist).
  db.Loan toDb() {
    assert(
      id != null,
      'toDb() requires a non-null id. Use toInsertCompanion() for new loans.',
    );
    return db.Loan(
      id: id!,
      type: type,
      counterpartyName: counterpartyName,
      amount: amount,
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      status: status,
      repaidAmount: repaidAmount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
