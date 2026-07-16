import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/utils/loan_installment_schedule.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LoanRepository(db);
});

class LoanRepository {
  final AppDatabase db;
  LoanRepository(this.db);

  Future<int> createLoanWithSchedule({
    required LoansCompanion loan,
    required List<LoanInstallmentLine> scheduleLines,
  }) async {
    try {
      return await db.transaction(() async {
        final loanId = await db.into(db.loans).insert(loan);

        if (scheduleLines.isNotEmpty) {
          await db.batch((batch) {
            batch.insertAll(
              db.loanInstallments,
              scheduleLines
                  .map(
                    (line) => LoanInstallmentsCompanion.insert(
                      loanId: loanId,
                      sequenceNo: line.sequence,
                      dueDate: line.dueDate,
                      principalDue: Value(line.principalDue),
                      interestDue: Value(line.interestDue),
                      feeDue: Value(line.feeDue),
                      totalDue: line.totalDue,
                      status: Value(InstallmentStatus.unpaid.name),
                    ),
                  )
                  .toList(),
            );
          });
        }

        return loanId;
      });
    } catch (e, stack) {
      DatabaseError('Failed to create loan with schedule', stack).throwError();
    }
  }

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

  Future<List<LoanInstallment>> getInstallmentsByLoanId(int loanId) async {
    try {
      return await (db.select(db.loanInstallments)
            ..where((tbl) => tbl.loanId.equals(loanId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.sequenceNo)]))
          .get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch loan installments', stack).throwError();
    }
  }

  Future<LoanInstallment?> getNextUnpaidInstallment(int loanId) async {
    try {
      return await (db.select(db.loanInstallments)
            ..where((tbl) => tbl.loanId.equals(loanId))
            ..where(
              (tbl) =>
                  tbl.status.equals(InstallmentStatus.unpaid.name) |
                  tbl.status.equals(InstallmentStatus.partial.name) |
                  tbl.status.equals(InstallmentStatus.overdue.name),
            )
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.dueDate),
              (tbl) => OrderingTerm.asc(tbl.sequenceNo),
            ]))
          .getSingleOrNull();
    } catch (e, stack) {
      DatabaseError(
        'Failed to fetch next unpaid installment',
        stack,
      ).throwError();
    }
  }

  Future<List<LoanInstallment>> getDueInstallments({
    DateTime? asOf,
    DateTime? until,
  }) async {
    try {
      final lowerBound = asOf ?? DateTime.now();
      final upperBound = until ?? lowerBound;

      return await (db.select(db.loanInstallments)
            ..where(
              (tbl) =>
                  tbl.dueDate.isBetweenValues(lowerBound, upperBound) &
                  (tbl.status.equals(InstallmentStatus.unpaid.name) |
                      tbl.status.equals(InstallmentStatus.partial.name) |
                      tbl.status.equals(InstallmentStatus.overdue.name)),
            )
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.dueDate),
              (tbl) => OrderingTerm.asc(tbl.sequenceNo),
            ]))
          .get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch due installments', stack).throwError();
    }
  }

  Future<double> applyRepaymentToInstallments({
    required int loanId,
    required double amount,
    DateTime? paidAt,
  }) async {
    try {
      final normalizedAmount = amount < 0 ? 0.0 : amount;
      if (normalizedAmount == 0) return 0.0;

      final installments = await getInstallmentsByLoanId(loanId);
      if (installments.isEmpty) return 0.0;

      var remainingAmount = normalizedAmount;
      var appliedAmount = 0.0;

      for (final installment in installments) {
        if (remainingAmount <= 0) break;
        if (installment.status == InstallmentStatus.paid.name) continue;

        final remainingForLine = installment.totalDue - installment.paidAmount;
        if (remainingForLine <= 0) continue;

        final allocation =
            remainingAmount > remainingForLine
                ? remainingForLine
                : remainingAmount;
        final nextPaidAmount = installment.paidAmount + allocation;
        final nextStatus = _statusForInstallment(
          totalDue: installment.totalDue,
          paidAmount: nextPaidAmount,
          dueDate: installment.dueDate,
        );

        await (db.update(db.loanInstallments)
          ..where((tbl) => tbl.id.equals(installment.id))).write(
          LoanInstallmentsCompanion(
            paidAmount: Value(nextPaidAmount),
            paidAt: Value(
              nextPaidAmount > 0 ? (paidAt ?? DateTime.now()) : null,
            ),
            status: Value(nextStatus.name),
            updatedAt: Value(DateTime.now()),
          ),
        );

        remainingAmount -= allocation;
        appliedAmount += allocation;
      }

      if (appliedAmount > 0) {
        await _syncLoanAggregate(loanId);
      }

      return appliedAmount;
    } catch (e, stack) {
      DatabaseError(
        'Failed to apply repayment to installments',
        stack,
      ).throwError();
    }
  }

  Future<int> markInstallmentPaid({
    required int installmentId,
    required double paidAmount,
    DateTime? paidAt,
  }) async {
    try {
      return await db.transaction(() async {
        final installment =
            await (db.select(db.loanInstallments)
              ..where((tbl) => tbl.id.equals(installmentId))).getSingleOrNull();

        if (installment == null) {
          throw StateError('Installment $installmentId not found.');
        }

        final normalizedPaidAmount = paidAmount < 0 ? 0.0 : paidAmount;
        final clampedPaidAmount =
            normalizedPaidAmount > installment.totalDue
                ? installment.totalDue
                : normalizedPaidAmount;
        final status = _statusForInstallment(
          totalDue: installment.totalDue,
          paidAmount: clampedPaidAmount,
          dueDate: installment.dueDate,
        );
        final effectivePaidAt =
            clampedPaidAmount > 0 ? (paidAt ?? DateTime.now()) : null;

        final affected = await (db.update(db.loanInstallments)
          ..where((tbl) => tbl.id.equals(installmentId))).write(
          LoanInstallmentsCompanion(
            paidAmount: Value(clampedPaidAmount),
            paidAt: Value(effectivePaidAt),
            status: Value(status.name),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await _syncLoanAggregate(installment.loanId);
        return affected;
      });
    } catch (e, stack) {
      DatabaseError('Failed to mark installment paid', stack).throwError();
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

  Future<int> updateRepaidAmount(int id, double repaidAmount) async {
    try {
      return await (db.update(db.loans)..where(
        (tbl) => tbl.id.equals(id),
      )).write(LoansCompanion(repaidAmount: Value(repaidAmount)));
    } catch (e, stack) {
      DatabaseError('Failed to update repaid amount', stack).throwError();
    }
  }

  Future<int> updateLoan(LoansCompanion loan) async {
    try {
      return await (db.update(db.loans)
        ..where((tbl) => tbl.id.equals(loan.id.value))).write(loan);
    } catch (e, stack) {
      DatabaseError('Failed to update loan', stack).throwError();
    }
  }

  Future<int> updateLoanStatus(int id, LoanStatus status) async {
    try {
      return await (db.update(db.loans)..where(
        (tbl) => tbl.id.equals(id),
      )).write(LoansCompanion(status: Value(status)));
    } catch (e, stack) {
      DatabaseError('Failed to update loan status', stack).throwError();
    }
  }

  Future<void> _syncLoanAggregate(int loanId) async {
    final loan = await getLoanById(loanId);
    if (loan == null) return;

    final installments = await getInstallmentsByLoanId(loanId);
    if (installments.isEmpty) return;

    final repaidAmount = installments.fold<double>(
      0,
      (sum, line) => sum + line.paidAmount,
    );
    final hasOutstanding = installments.any(
      (line) => line.status != InstallmentStatus.paid.name,
    );
    final hasOverdue = installments.any(
      (line) => line.status == InstallmentStatus.overdue.name,
    );

    final nextStatus =
        !hasOutstanding
            ? LoanStatus.completed
            : hasOverdue
            ? LoanStatus.overdue
            : LoanStatus.ongoing;

    await (db.update(db.loans)..where((tbl) => tbl.id.equals(loanId))).write(
      LoansCompanion(
        repaidAmount: Value(repaidAmount),
        status: Value(nextStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  InstallmentStatus _statusForInstallment({
    required double totalDue,
    required double paidAmount,
    required DateTime dueDate,
  }) {
    if (paidAmount >= totalDue) return InstallmentStatus.paid;
    if (paidAmount > 0) return InstallmentStatus.partial;
    if (dueDate.isBefore(DateTime.now())) return InstallmentStatus.overdue;
    return InstallmentStatus.unpaid;
  }
}
