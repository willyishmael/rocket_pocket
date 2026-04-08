import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/enums.dart';

class BudgetPeriodConverter extends TypeConverter<BudgetPeriod, String> {
  const BudgetPeriodConverter();

  @override
  BudgetPeriod fromSql(String fromDb) => BudgetPeriod.values.byName(fromDb);

  @override
  String toSql(BudgetPeriod value) => value.name;
}
