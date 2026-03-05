import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/enums.dart';

class LoanTypeConverter extends TypeConverter<LoanType, String> {
  const LoanTypeConverter();

  @override
  LoanType fromSql(String fromDb) => LoanType.values.byName(fromDb);
  
  @override
  String toSql(LoanType value) => value.name;
}