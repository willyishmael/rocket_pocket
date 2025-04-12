import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_status.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_type.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

class LoanRepository {
  final AppDatabase db;
  LoanRepository(this.db);

  Future<List<Loan>> getAllLoans() async {
    try {
      return await db.select(db.loans).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all loans', stack).throwError();
    }
  }

  Future<int> insertLoan(LoansCompanion loan) async {
    try {
      return await db.into(db.loans).insert(loan);
    } catch (e, stack) {
      DatabaseError('Failed to insert loan', stack).throwError();
    }
  }

  Future<Loan?> getLoanById(int id) async {
    try {
      return await (db.select(db.loans)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError('Failed to fetch loan by ID', stack).throwError();
    }
  }

  Future<List<Loan>> getLoansByStatus(LoanStatus status) async {
    try {
      return await (db.select(db.loans)
        ..where((tbl) => tbl.status.equals(status.name))).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch loans by status', stack).throwError();
    }
  }

  Future<List<Loan>> getLoansByType(LoanType type) async {
    try {
      return await (db.select(db.loans)
        ..where((tbl) => tbl.type.equals(type.name))).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch loans by type', stack).throwError();
    }
  }

  Future<List<Loan>> getLoansByCounterpartyName(String counterpartyName) async {
    try {
      return await (db.select(db.loans)
        ..where((tbl) => tbl.counterpartyName.equals(counterpartyName))).get();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch loans by counterparty name',
        stack,
      ).throwError();
    }
  }

  Future<List<Loan>> getLoansByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await (db.select(db.loans)..where(
        (tbl) => tbl.startDate.isBetweenValues(startDate, endDate),
      )).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch loans by date range', stack).throwError();
    }
  }

  Future updateRepaidAmount(int id, double repaidAmount) async {
    try {
      return await (db.update(db.loans)..where(
        (tbl) => tbl.id.equals(id),
      )).write(LoansCompanion(repaidAmount: Value(repaidAmount)));
    } catch (e, stack) {
      DatabaseError('Failed to update repaid amount', stack).throwError();
    }
  }

  Future updateLoan(LoansCompanion loan) async {
    try {
      return await (db.update(db.loans)
        ..where((tbl) => tbl.id.equals(loan.id.value))).write(loan);
    } catch (e, stack) {
      DatabaseError('Failed to update loan', stack).throwError();
    }
  }

  Future updateLoanStatus(int id, LoanStatus status) async {
    try {
      return await (db.update(db.loans)..where(
        (tbl) => tbl.id.equals(id),
      )).write(LoansCompanion(status: Value(status.name)));
    } catch (e, stack) {
      DatabaseError('Failed to update loan status', stack).throwError();
    }
  }
}
