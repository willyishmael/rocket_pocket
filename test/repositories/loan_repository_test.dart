import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/utils/loan_installment_schedule.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late LoanRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LoanRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LoanRepository', () {
    test('filters by status, type, counterparty, and date range', () async {
      await repository.insertLoan(
        LoansCompanion.insert(
          type: LoanType.given,
          counterpartyName: 'Alex',
          amount: 500,
          description: 'Bridge',
          startDate: fixedDate(1),
          dueDate: fixedDate(20),
          status: LoanStatus.ongoing,
          repaidAmount: 0,
          updatedAt: fixedDate(1),
        ),
      );
      await repository.insertLoan(
        LoansCompanion.insert(
          type: LoanType.taken,
          counterpartyName: 'Jordan',
          amount: 300,
          description: 'Rent',
          startDate: fixedDate(10),
          dueDate: fixedDate(28),
          status: LoanStatus.completed,
          repaidAmount: 300,
          updatedAt: fixedDate(10),
        ),
      );

      expect((await repository.getLoansByStatus(LoanStatus.ongoing)).length, 1);
      expect((await repository.getLoansByType(LoanType.taken)).length, 1);
      expect((await repository.getLoansByCounterpartyName('Alex')).length, 1);
      expect(
        (await repository.getLoansByDateRange(
          fixedDate(1),
          fixedDate(15),
        )).length,
        2,
      );
    });

    test('updateRepaidAmount and updateLoanStatus persist changes', () async {
      final id = await repository.insertLoan(
        LoansCompanion.insert(
          type: LoanType.given,
          counterpartyName: 'Taylor',
          amount: 200,
          description: 'Test',
          startDate: fixedDate(1),
          dueDate: fixedDate(18),
          status: LoanStatus.ongoing,
          repaidAmount: 0,
          updatedAt: fixedDate(1),
        ),
      );

      await repository.updateRepaidAmount(id, 75);
      await repository.updateLoanStatus(id, LoanStatus.overdue);

      final updated = await repository.getLoanById(id);
      expect(updated!.repaidAmount, 75);
      expect(updated.status, LoanStatus.overdue);
    });

    test('updateLoan writes companion values', () async {
      final id = await repository.insertLoan(
        LoansCompanion.insert(
          type: LoanType.taken,
          counterpartyName: 'Sam',
          amount: 700,
          description: 'Original',
          startDate: fixedDate(2),
          dueDate: fixedDate(22),
          status: LoanStatus.ongoing,
          repaidAmount: 10,
          updatedAt: fixedDate(2),
        ),
      );

      await repository.updateLoan(
        LoansCompanion(
          id: Value(id),
          counterpartyName: const Value('Casey'),
          amount: const Value(900),
          updatedAt: Value(fixedDate(3)),
        ),
      );

      final updated = await repository.getLoanById(id);
      expect(updated!.counterpartyName, 'Casey');
      expect(updated.amount, 900);
    });

    test('throws DatabaseError when table is unavailable', () async {
      await db.customStatement('DROP TABLE loans;');

      expect(repository.getAllLoans, throwsA(isA<DatabaseError>()));
    });

    test('createLoanWithSchedule persists ordered installment lines', () async {
      final plan = LoanInstallmentSchedule.buildFlatMonthlyPlan(
        LoanInstallmentPlanInput(
          principalAmount: 1200,
          monthlyInterestRatePercent: 1,
          installmentCount: 3,
          firstDueDate: fixedDate(15),
          installmentMode: InstallmentMode.fixed,
        ),
      );

      final loanId = await repository.createLoanWithSchedule(
        loan: LoansCompanion.insert(
          type: LoanType.taken,
          counterpartyName: 'Installment Bank',
          amount: 1236,
          principalAmount: const Value(1200),
          financedAmount: const Value(1200),
          monthlyInterestRatePercent: const Value(12),
          installmentCount: const Value(3),
          firstInstallmentDate: Value(fixedDate(15)),
          dueDate: fixedDate(15),
          description: 'Phone purchase',
          startDate: fixedDate(1),
          status: LoanStatus.ongoing,
          repaidAmount: 0,
          updatedAt: fixedDate(1),
        ),
        scheduleLines: plan.lines,
      );

      final installments = await repository.getInstallmentsByLoanId(loanId);
      expect(installments, hasLength(3));
      expect(installments.map((i) => i.sequenceNo), [1, 2, 3]);
      expect(installments.first.status, InstallmentStatus.unpaid.name);
      expect(
        installments.fold<double>(0, (sum, item) => sum + item.totalDue),
        closeTo(plan.totalPayable, 0.01),
      );
    });

    test('getDueInstallments returns only due unpaid-like rows', () async {
      final loanId = await repository.createLoanWithSchedule(
        loan: LoansCompanion.insert(
          type: LoanType.taken,
          counterpartyName: 'Due Bank',
          amount: 500,
          principalAmount: const Value(500),
          financedAmount: const Value(500),
          installmentCount: const Value(2),
          firstInstallmentDate: Value(fixedDate(5)),
          dueDate: fixedDate(5),
          description: 'Due test',
          startDate: fixedDate(1),
          status: LoanStatus.ongoing,
          repaidAmount: 0,
          updatedAt: fixedDate(1),
        ),
        scheduleLines: [
          LoanInstallmentLine(
            sequence: 1,
            dueDate: DateTime(2026, 4, 5, 10),
            principalDue: 250,
            interestDue: 0,
            feeDue: 0,
            totalDue: 250,
          ),
          LoanInstallmentLine(
            sequence: 2,
            dueDate: DateTime(2026, 4, 20, 10),
            principalDue: 250,
            interestDue: 0,
            feeDue: 0,
            totalDue: 250,
          ),
        ],
      );

      final all = await repository.getInstallmentsByLoanId(loanId);
      await repository.markInstallmentPaid(
        installmentId: all.first.id,
        paidAmount: 250,
        paidAt: fixedDate(5),
      );

      final due = await repository.getDueInstallments(
        asOf: DateTime(2026, 4, 1),
        until: DateTime(2026, 4, 30, 23, 59),
      );

      expect(due, hasLength(1));
      expect(due.single.sequenceNo, 2);
    });

    test(
      'markInstallmentPaid updates installment and parent loan totals',
      () async {
        final loanId = await repository.createLoanWithSchedule(
          loan: LoansCompanion.insert(
            type: LoanType.given,
            counterpartyName: 'Taylor',
            amount: 300,
            principalAmount: const Value(300),
            financedAmount: const Value(300),
            installmentCount: const Value(2),
            firstInstallmentDate: Value(fixedDate(15)),
            dueDate: fixedDate(15),
            description: 'Installment collection',
            startDate: fixedDate(1),
            status: LoanStatus.ongoing,
            repaidAmount: 0,
            updatedAt: fixedDate(1),
          ),
          scheduleLines: [
            LoanInstallmentLine(
              sequence: 1,
              dueDate: DateTime(2026, 4, 15, 10),
              principalDue: 150,
              interestDue: 0,
              feeDue: 0,
              totalDue: 150,
            ),
            LoanInstallmentLine(
              sequence: 2,
              dueDate: DateTime(2026, 5, 15, 10),
              principalDue: 150,
              interestDue: 0,
              feeDue: 0,
              totalDue: 150,
            ),
          ],
        );

        final installments = await repository.getInstallmentsByLoanId(loanId);
        await repository.markInstallmentPaid(
          installmentId: installments.first.id,
          paidAmount: 100,
          paidAt: fixedDate(15),
        );

        final partiallyPaid = await repository.getInstallmentsByLoanId(loanId);
        expect(partiallyPaid.first.paidAmount, 100);
        expect(partiallyPaid.first.status, InstallmentStatus.partial.name);

        var updatedLoan = await repository.getLoanById(loanId);
        expect(updatedLoan!.repaidAmount, 100);
        expect(updatedLoan.status, LoanStatus.ongoing);

        await repository.markInstallmentPaid(
          installmentId: installments.first.id,
          paidAmount: 150,
          paidAt: fixedDate(16),
        );
        await repository.markInstallmentPaid(
          installmentId: installments.last.id,
          paidAmount: 150,
          paidAt: fixedDate(17),
        );

        updatedLoan = await repository.getLoanById(loanId);
        expect(updatedLoan!.repaidAmount, 300);
        expect(updatedLoan.status, LoanStatus.completed);
      },
    );
  });
}
