import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/local/tables/loans.dart';

class LoanInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get loanId => integer().references(Loans, #id)();

  IntColumn get sequenceNo => integer()();
  DateTimeColumn get dueDate => dateTime()();

  RealColumn get principalDue => real().withDefault(const Constant(0))();
  RealColumn get interestDue => real().withDefault(const Constant(0))();
  RealColumn get feeDue => real().withDefault(const Constant(0))();
  RealColumn get totalDue => real()();

  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get paidAt => dateTime().nullable()();

  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  DateTimeColumn get reminderScheduledAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {loanId, sequenceNo},
  ];
}
