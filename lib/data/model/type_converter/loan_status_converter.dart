import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/enums.dart';

/// A type converter for converting [LoanStatus] enum to a string for database storage
class LoanStatusConverter extends TypeConverter<LoanStatus, String> {
  const LoanStatusConverter();

  @override
  LoanStatus fromSql(String fromDb) => LoanStatus.values.byName(fromDb);

  @override
  String toSql(LoanStatus value) => value.name;
}