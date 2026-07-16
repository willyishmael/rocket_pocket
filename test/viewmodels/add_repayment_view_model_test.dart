import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart' as loan_model;
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/utils/loan_installment_schedule.dart';
import 'package:rocket_pocket/viewmodels/add_repayment_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late LoanRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LoanRepository(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'submit allocates repayment across installments and updates loan totals',
    () async {
      final loanId = await repository.createLoanWithSchedule(
        loan:
            loan_model.Loan(
              type: LoanType.given,
              financingKind: LoanFinancingKind.cashLoan,
              counterpartyName: 'Installment Borrower',
              currency: 'IDR',
              amount: 330,
              principalAmount: 300,
              financedAmount: 300,
              monthlyInterestRatePercent: 1,
              installmentCount: 3,
              installmentMode: InstallmentMode.fixed,
              paymentDayOfMonth: 15,
              firstInstallmentDate: DateTime(2026, 4, 15, 10),
              description: 'Installment collection',
              startDate: fixedDate(1),
              dueDate: DateTime(2026, 6, 15, 10),
              status: LoanStatus.ongoing,
              repaidAmount: 0,
              createdAt: fixedDate(1),
            ).toInsertCompanion(),
        scheduleLines: [
          LoanInstallmentLine(
            sequence: 1,
            dueDate: DateTime(2026, 4, 15, 10),
            principalDue: 100,
            interestDue: 10,
            feeDue: 0,
            totalDue: 110,
          ),
          LoanInstallmentLine(
            sequence: 2,
            dueDate: DateTime(2026, 5, 15, 10),
            principalDue: 100,
            interestDue: 10,
            feeDue: 0,
            totalDue: 110,
          ),
          LoanInstallmentLine(
            sequence: 3,
            dueDate: DateTime(2026, 6, 15, 10),
            principalDue: 100,
            interestDue: 10,
            feeDue: 0,
            totalDue: 110,
          ),
        ],
      );

      final loanRow = await repository.getLoanById(loanId);
      final loan = loan_model.Loan.fromDb(loanRow!);

      final initialState = await container.read(
        addRepaymentViewModelProvider.future,
      );
      final notifier = container.read(addRepaymentViewModelProvider.notifier);

      notifier.setSelectedPocket(initialState.pockets.first);
      notifier.setAmount(150);
      notifier.setDate(fixedDate(16));

      await notifier.submit(loan);

      final installments = await repository.getInstallmentsByLoanId(loanId);
      final updatedLoan = await repository.getLoanById(loanId);
      final transactions = await db.select(db.transactions).get();
      final updatedPocket =
          await (db.select(db.pockets)..where(
            (tbl) => tbl.id.equals(initialState.pockets.first.id!),
          )).getSingle();

      expect(installments[0].paidAmount, 110);
      expect(installments[0].status, InstallmentStatus.paid.name);
      expect(installments[1].paidAmount, 40);
      expect(installments[1].status, InstallmentStatus.partial.name);
      expect(installments[2].paidAmount, 0);
      expect(updatedLoan!.repaidAmount, 150);
      expect(updatedLoan.status, LoanStatus.ongoing);
      expect(transactions.single.type, TransactionType.loanCollection);
      expect(transactions.single.amount, 150);
      expect(updatedPocket.balance, 150);
    },
  );
}
