import 'color_gradient.dart';
import '../local/database.dart' as db_provider;
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

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

  /// Create a copy of this Pocket with updated values
  /// If a value is not provided, the original value is retained
  /// This is useful for immutability and state management
  Pocket copyWith({
    int? id,
    String? name,
    String? purpose,
    String? currency,
    double? balance,
    String? emoticon,
    ColorGradient? colorGradient,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pocket(
      id: id ?? this.id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      emoticon: emoticon ?? this.emoticon,
      colorGradient: colorGradient ?? this.colorGradient,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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

  /// Convert this Pocket to a Companion for inserting a new row.
  /// Uses Value.absent() for id so the database auto-increments it.
  /// Throws [ValidationError] if [colorGradient] has no id (i.e. has not been
  /// persisted to the database yet).
  db_provider.PocketsCompanion toInsertCompanion() {
    final gradientId = colorGradient.id;
    if (gradientId == null) {
      throw ValidationError(
        'Cannot insert pocket: the selected color gradient has not been saved to the database. '
        'Ensure a valid gradient is chosen before creating a pocket.',
        StackTrace.current,
      );
    }
    return db_provider.PocketsCompanion.insert(
      name: name,
      purpose: purpose,
      currency: currency,
      balance: balance,
      emoticon: emoticon,
      colorGradientId: gradientId,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert this Pocket to a database row for updates.
  /// Requires a non-null id (the row must already exist).
  /// Throws [ValidationError] if [colorGradient] has no id.
  db_provider.Pocket toDb() {
    assert(
      id != null,
      'toDb() requires a non-null id. Use toInsertCompanion() for new pockets.',
    );
    final gradientId = colorGradient.id;
    if (gradientId == null) {
      throw ValidationError(
        'Cannot update pocket: the selected color gradient has not been saved to the database. '
        'Ensure a valid gradient is chosen before updating a pocket.',
        StackTrace.current,
      );
    }
    return db_provider.Pocket(
      id: id!,
      name: name,
      purpose: purpose,
      currency: currency,
      balance: balance,
      emoticon: emoticon,
      colorGradientId: gradientId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
