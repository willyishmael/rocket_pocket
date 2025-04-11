import 'package:drift/drift.dart' show TypeConverter;

enum LoanType { given, taken }

// This converter is used to convert the LoanType enum to a string for storage in the database
// and back to the enum when reading from the database.
class LoanTypeConverter extends TypeConverter<LoanType, String> {
  const LoanTypeConverter();

  @override
  LoanType fromSql(String fromDb) => LoanType.values.byName(fromDb);
  
  @override
  String toSql(LoanType value) => value.name;
}
