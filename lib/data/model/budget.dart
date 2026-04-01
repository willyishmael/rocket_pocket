import 'package:drift/drift.dart' show Value;
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';

class Budget {
  final int? id;
  final String name;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.createdAt,
  });

  Budget copyWith({
    int? id,
    String? name,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Budget fromDb(db.Budget row) {
    return Budget(
      id: row.id,
      name: row.name,
      amount: row.amount,
      period: row.period,
      startDate: row.startDate,
      createdAt: row.createdAt,
    );
  }

  db.BudgetsCompanion toInsertCompanion() {
    return db.BudgetsCompanion.insert(
      name: name,
      amount: amount,
      period: period,
      startDate: startDate,
      createdAt: Value(createdAt),
      updatedAt: DateTime.now(),
    );
  }

  db.BudgetsCompanion toUpdateCompanion() {
    assert(id != null, 'toUpdateCompanion() requires a non-null id.');
    return db.BudgetsCompanion(
      id: Value(id!),
      name: Value(name),
      amount: Value(amount),
      period: Value(period),
      startDate: Value(startDate),
      updatedAt: Value(DateTime.now()),
    );
  }

  db.Budget toDb() {
    assert(id != null, 'toDb() requires a non-null id.');
    return db.Budget(
      id: id!,
      name: name,
      amount: amount,
      period: period,
      startDate: startDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
