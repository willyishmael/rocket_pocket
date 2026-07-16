import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/add_loan_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'submit creates schedule-backed loan with computed total payable',
    () async {
      await container.read(addLoanViewModelProvider.future);
      final notifier = container.read(addLoanViewModelProvider.notifier);

      notifier.setCounterpartyName('Installment Bank');
      notifier.setAmount(1200);
      notifier.setInstallmentCount(3);
      notifier.setAnnualInterestRatePercent(12);
      notifier.setStartDate(fixedDate(1));
      notifier.setDueDate(fixedDate(15));

      await notifier.submit();

      final loans = await db.select(db.loans).get();
      final installments = await db.select(db.loanInstallments).get();

      expect(loans, hasLength(1));
      expect(loans.single.amount, closeTo(1236, 0.01));
      expect(loans.single.principalAmount, 1200);
      expect(loans.single.installmentCount, 3);
      expect(loans.single.firstInstallmentDate, fixedDate(15));
      expect(loans.single.dueDate, DateTime(2026, 6, 15, 10));

      expect(installments, hasLength(3));
      expect(installments.map((e) => e.sequenceNo).toList(), [1, 2, 3]);
      expect(
        installments.fold<double>(0, (sum, row) => sum + row.totalDue),
        closeTo(1236, 0.01),
      );
    },
  );

  test('submit records pocket transaction using principal amount', () async {
    final initialState = await container.read(addLoanViewModelProvider.future);
    final notifier = container.read(addLoanViewModelProvider.notifier);
    final pocket = initialState.pockets.first;

    notifier.setType(LoanType.taken);
    notifier.setSelectedPocket(pocket);
    notifier.setCounterpartyName('Cash Lender');
    notifier.setAmount(600);
    notifier.setInstallmentCount(2);
    notifier.setAnnualInterestRatePercent(10);
    notifier.setStartDate(fixedDate(1));
    notifier.setDueDate(fixedDate(15));

    await notifier.submit();

    final transactions = await db.select(db.transactions).get();
    final updatedPocket =
        await (db.select(db.pockets)
          ..where((tbl) => tbl.id.equals(pocket.id!))).getSingle();

    expect(transactions, hasLength(1));
    expect(transactions.single.type, TransactionType.loanTaken);
    expect(transactions.single.amount, 600);
    expect(updatedPocket.balance, 600);
  });
}
