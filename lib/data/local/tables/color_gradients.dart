import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';

class ColorGradients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get colors => text().map(const ColorListConverter())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}