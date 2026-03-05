import 'dart:convert';
import 'dart:ui';
import 'package:drift/drift.dart';

/// A type converter for converting a list of [Color] objects to a JSON string
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