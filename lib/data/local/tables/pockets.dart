import 'package:drift/drift.dart';

class Pockets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get purpose => text()();
  TextColumn get emoticon => text()();
  TextColumn get currency => text()();
  RealColumn get balance => real()();
  IntColumn get colorGradientId =>
      integer().customConstraint('REFERENCES color_gradients(id)')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
}