import 'color_gradient.dart';
import '../local/database.dart' as db_provider;

/// Represents a financial pocket with various attributes
class Pocket {
  int? id;
  String name;
  String purpose;
  String currency;
  double balance;
  String emoticon;
  ColorGradient colorGradient;
  DateTime? createdAt;
  DateTime? updatedAt;

  Pocket({
    this.id,
    required this.name,
    required this.purpose,
    required this.currency,
    required this.balance,
    required this.emoticon,
    required this.colorGradient,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a Pocket instance from a database row
  /// [fetchColorGradientById] is a function that retrieves the ColorGradient by its ID
  static Future<Pocket> fromDb(
    db_provider.Pocket dbRow,
    Future<ColorGradient> Function(int) fetchColorGradientById,
  ) async {
    final gradient = await fetchColorGradientById(dbRow.colorGradientId);
    return Pocket(
      id: dbRow.id,
      name: dbRow.name,
      purpose: dbRow.purpose,
      currency: dbRow.currency,
      balance: dbRow.balance,
      emoticon: dbRow.emoticon,
      colorGradient: gradient,
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
    );
  }

  /// Convert this Pocket instance to a database row
  db_provider.Pocket toDb() {
    final generatedId = id ?? DateTime.now().millisecondsSinceEpoch;
    return db_provider.Pocket(
      id: generatedId,
      name: name,
      purpose: purpose,
      currency: currency,
      balance: balance,
      emoticon: emoticon,
      colorGradientId: colorGradient.id ?? 0,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
