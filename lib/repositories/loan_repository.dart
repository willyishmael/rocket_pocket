import 'package:drift/drift.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_status.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_type.dart';

class LoanRepository {
  final AppDatabase db;
  LoanRepository([AppDatabase? database]) : db = database ?? AppDatabase();

  Future<List<Loan>> getAllLoans() => db.select(db.loans).get();

  Future<int> insertLoan(LoansCompanion loan) => db.into(db.loans).insert(loan);

  Future<Loan?> getLoanById(int id) {
    return (db.select(db.loans)
      ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Loan>> getLoansByStatus(LoanStatus status) {
    return (db.select(db.loans)
      ..where((tbl) => tbl.status.equals(status.name))).get();
  }

  Future<List<Loan>> getLoansByType(LoanType type) {
    return (db.select(db.loans)
      ..where((tbl) => tbl.type.equals(type.name))).get();
  }

  Future<List<Loan>> getLoansByCounterpartyName(String counterpartyName) {
    return (db.select(db.loans)
      ..where((tbl) => tbl.counterpartyName.equals(counterpartyName))).get();
  }

  Future<List<Loan>> getLoansByDateRange(DateTime startDate, DateTime endDate) {
    return (db.select(
      db.loans,
    )..where((tbl) => tbl.startDate.isBetweenValues(startDate, endDate))).get();
  }

  Future<List<Loan>> getLoansByAmountRange(double minAmount, double maxAmount) {
    return (db.select(db.loans)
      ..where((tbl) => tbl.amount.isBetweenValues(minAmount, maxAmount))).get();
  }

  Future updateRepaidAmount(int id, double repaidAmount) {
    return (db.update(db.loans)..where(
      (tbl) => tbl.id.equals(id),
    )).write(LoansCompanion(repaidAmount: Value(repaidAmount)));
  }

  Future updateLoan(LoansCompanion loan) {
    return (db.update(db.loans)
      ..where((tbl) => tbl.id.equals(loan.id.value))).write(loan);
  }

  Future updateLoanStatus(int id, LoanStatus status) {
    return (db.update(db.loans)..where(
      (tbl) => tbl.id.equals(id),
    )).write(LoansCompanion(status: Value(status.name)));
  }
}
