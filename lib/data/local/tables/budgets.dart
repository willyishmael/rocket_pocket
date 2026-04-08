import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/type_converter/budget_period_converter.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get period => text().map(const BudgetPeriodConverter())();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
}
