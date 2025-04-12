import 'package:drift/drift.dart';

enum TransactionType { expense, income, transfer, refund }

// This converter is used to convert the TransactionType enum to a string for storage in the database
// and back to the enum when reading from the database.
class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) => TransactionType.values.byName(fromDb);

  @override
  String toSql(TransactionType value) => value.name;
}
