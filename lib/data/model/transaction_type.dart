import 'package:drift/drift.dart';

enum TransactionType { expense, income, transfer, refund }

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
    }
  }
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
