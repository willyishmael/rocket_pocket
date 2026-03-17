import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get senderPocketId =>
      integer().nullable().customConstraint('NULL REFERENCES pockets(id)')();
  IntColumn get receiverPocketId =>
      integer().nullable().customConstraint('NULL REFERENCES pockets(id)')();
  TextColumn get type => text().map(const TransactionTypeConverter())();
  IntColumn get categoryId =>
      integer().nullable().customConstraint(
        'NULL REFERENCES transaction_categories(id)',
      )();
  IntColumn get loanId =>
      integer().nullable().customConstraint('NULL REFERENCES loans(id)')();
  IntColumn get originalTransactionId =>
      integer().nullable().customConstraint(
        'NULL REFERENCES transactions(id)',
      )();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
}
