import 'dart:ui';
import '../local/database.dart' as db_provider;

class ColorGradient {
  final int? id;
  final String name;
  final List<Color> colors;
  final DateTime? createdAt;

  ColorGradient({
    this.id,
    required this.name,
    required this.colors,
    this.createdAt,
  });

  // Factory constructor from database model
  static ColorGradient fromDb(db_provider.ColorGradient dbGradient) {
    return ColorGradient(
      id: dbGradient.id,
      name: dbGradient.name,
      colors: dbGradient.colors,
      createdAt: dbGradient.createdAt,
    );
  }

  // Conversion to database model, handling fallback for nullable fields
  db_provider.ColorGradient toDb() {
    return db_provider.ColorGradient(
      id: id ?? 0, // Or let the table auto-generate it
      name: name,
      colors: colors,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // Factory for an empty ColorGradient (for default state)
  factory ColorGradient.empty() => ColorGradient(
        name: '',
        colors: [],
      );
}