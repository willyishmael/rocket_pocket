import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_status.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_type.dart';
import 'package:rocket_pocket/utils/enum_converter/transaction_type.dart';

part 'database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Define the Account table
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  IntColumn get balance => integer()();
  RealColumn get accentColor => real()();
}

// Define the TransactionCategory table
class TransactionCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// Define the Loan table
class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().map(const LoanTypeConverter())();
  TextColumn get counterpartyName => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().map(const LoanStatusConverter())();
  RealColumn get repaidAmount => real()();
  DateTimeColumn get createdAt => dateTime()();
}

// Define the Transaction table
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get senderAccountId =>
      integer().nullable().customConstraint('NULL REFERENCES accounts(id)')();
  IntColumn get receiverAccountId =>
      integer().nullable().customConstraint('NULL REFERENCES accounts(id)')();
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
  DateTimeColumn get createdAt => dateTime()();
}

// Create the database
@DriftDatabase(tables: [Accounts, TransactionCategories, Loans, Transactions])
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
