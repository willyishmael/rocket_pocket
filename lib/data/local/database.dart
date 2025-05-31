import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rocket_pocket/data/local/tables/color_gradients.dart';
import 'package:rocket_pocket/data/local/tables/loans.dart';
import 'package:rocket_pocket/data/local/tables/pockets.dart';
import 'package:rocket_pocket/data/local/tables/transaction_categories.dart';
import 'package:rocket_pocket/data/local/tables/transactions.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/data/model/type_converter/color_list_converter.dart';
import 'package:rocket_pocket/data/model/type_converter/loan_status_converter.dart';
import 'package:rocket_pocket/data/model/type_converter/loan_type_converter.dart';

part 'database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Create the database
@DriftDatabase(
  tables: [Pockets, TransactionCategories, Loans, Transactions, ColorGradients],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
