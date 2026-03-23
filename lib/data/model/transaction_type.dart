import 'package:drift/drift.dart';

enum TransactionType {
  expense,
  income,
  transfer,
  refund,
  loanGiven,
  loanTaken,
  loanRepayment,
  loanCollection,
  adjustment,
}

extension TransactionTypeExtension on TransactionType {
  String toReadableString() {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.loanGiven:
        return 'Loan Out';
      case TransactionType.loanTaken:
        return 'Loan In';
      case TransactionType.loanRepayment:
        return 'Loan Repayment';
      case TransactionType.loanCollection:
        return 'Loan Collection';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  /// Whether this type represents money coming in (positive).
  bool get isPositive =>
      this == TransactionType.income ||
      this == TransactionType.refund ||
      this == TransactionType.loanTaken ||
      this == TransactionType.loanCollection;
}

// This converter is used to convert the TransactionType enum to a string for storage in the database
// and back to the enum when reading from the database.
class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) =>
      TransactionType.values.byName(fromDb);

  @override
  String toSql(TransactionType value) => value.name;
}
