import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/loan_status.dart';
import 'package:rocket_pocket/data/model/loan_type.dart';

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().map(const LoanTypeConverter())();
  TextColumn get counterpartyName => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().map(const LoanStatusConverter())();
  RealColumn get repaidAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
}