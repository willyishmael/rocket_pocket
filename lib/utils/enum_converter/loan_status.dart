import 'package:drift/drift.dart';

enum LoanStatus { ongoing, completed, overdue, cancelled }

// This converter is used to convert the LoanStatus enum to a string for storage in the database
// and back to the enum when reading from the database.
class LoanStatusConverter extends TypeConverter<LoanStatus, String> {
  const LoanStatusConverter();

  @override
  LoanStatus fromSql(String fromDb) => LoanStatus.values.byName(fromDb);

  @override
  String toSql(LoanStatus value) => value.name;
}
