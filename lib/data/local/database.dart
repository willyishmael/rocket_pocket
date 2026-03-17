import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rocket_pocket/data/local/default_values/default_categories.dart';
import 'package:rocket_pocket/data/local/default_values/default_gradients.dart';
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
import 'package:flutter/material.dart' as material;

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(colorGradients, defaultGradients);
        b.insertAll(transactionCategories, defaultCategories);
      });

      await into(pockets).insert(
        PocketsCompanion.insert(
          name: 'Default Pocket',
          purpose: 'General Savings',
          colorGradientId: 1,
          emoticon: '💰',
          currency: 'IDR',
          balance: 0,
          updatedAt: DateTime.now(),
        ),
      );
    },

    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.date);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
