import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rocket_pocket/data/local/default_values/default_categories.dart';
import 'package:rocket_pocket/data/local/default_values/default_gradients.dart';
import 'package:rocket_pocket/data/local/tables/budgets.dart';
import 'package:rocket_pocket/data/local/tables/color_gradients.dart';
import 'package:rocket_pocket/data/local/tables/loan_installments.dart';
import 'package:rocket_pocket/data/local/tables/loans.dart';
import 'package:rocket_pocket/data/local/tables/pockets.dart';
import 'package:rocket_pocket/data/local/tables/transaction_categories.dart';
import 'package:rocket_pocket/data/local/tables/transactions.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/data/model/type_converter/budget_period_converter.dart';
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
  tables: [
    Pockets,
    TransactionCategories,
    Loans,
    LoanInstallments,
    Transactions,
    ColorGradients,
    Budgets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
          icon: '💰',
          colorGradientId: 1,
          currency: 'IDR',
          balance: 0,
          updatedAt: DateTime.now(),
        ),
      );
    },
    beforeOpen: (details) async {
      await _reconcileLoanLifecycle();
    },
  );

  Future<void> _reconcileLoanLifecycle() async {
    final now = DateTime.now();

    await (update(loanInstallments)..where(
      (tbl) =>
          tbl.status.equals(InstallmentStatus.unpaid.name) &
          tbl.dueDate.isSmallerThanValue(now),
    )).write(
      LoanInstallmentsCompanion(
        status: Value(InstallmentStatus.overdue.name),
        updatedAt: Value(now),
      ),
    );

    final allLoans = await select(loans).get();
    for (final loan in allLoans) {
      final lines =
          await (select(loanInstallments)
            ..where((tbl) => tbl.loanId.equals(loan.id))).get();
      if (lines.isEmpty) {
        continue;
      }

      final repaidAmount = lines.fold<double>(
        0,
        (sum, line) => sum + line.paidAmount,
      );
      final hasOutstanding = lines.any(
        (line) => line.status != InstallmentStatus.paid.name,
      );
      final hasOverdue = lines.any(
        (line) => line.status == InstallmentStatus.overdue.name,
      );

      final nextStatus =
          !hasOutstanding
              ? LoanStatus.completed
              : hasOverdue
              ? LoanStatus.overdue
              : LoanStatus.ongoing;

      await (update(loans)..where((tbl) => tbl.id.equals(loan.id))).write(
        LoansCompanion(
          repaidAmount: Value(repaidAmount),
          status: Value(nextStatus),
          updatedAt: Value(now),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
