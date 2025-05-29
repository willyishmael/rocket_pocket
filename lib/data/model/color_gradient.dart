import 'dart:convert';
import 'dart:ui';
import 'package:drift/drift.dart';
import '../local/database.dart' as db_provider;

// Custom gradient representation for UI
class ColorGradient {
  final int id;
  final String name;
  final List<Color> colors;
  final DateTime createdAt;

  ColorGradient({
    required this.id,
    required this.name,
    required this.colors,
    required this.createdAt,
  });

  // Factory constructor to create a ColorGradient from a database row
  static ColorGradient fromDb(db_provider.ColorGradient dbGradient) {
    return ColorGradient(
      id: dbGradient.id,
      name: dbGradient.name,
      colors: dbGradient.colors,
      createdAt: dbGradient.createdAt,
    );
  }

  // Converts the ColorGradient to a database-friendly format
  db_provider.ColorGradient toDb() {
    return db_provider.ColorGradient(
      id: id,
      name: name,
      colors: colors,
      createdAt: createdAt,
    );
  }
}

class ColorListConverter extends TypeConverter<List<Color>, String> {
  const ColorListConverter();

  @override
  List<Color> fromSql(String fromDb) {
    final List<dynamic> jsonList = jsonDecode(fromDb);
    return jsonList.map((value) => Color(value as int)).toList();
  }

  @override
  String toSql(List<Color> value) {
    return jsonEncode(value.map((color) => color.toARGB32()).toList());
  }
}
