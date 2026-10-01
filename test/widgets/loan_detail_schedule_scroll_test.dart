import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/local/database.dart'
    show AppDatabase, appDatabaseProvider;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/screens/loan/loan_detail_screen.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets('scrolling Loan Details does not reload the schedule', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final loan = buildLoanModel(
      id: 1,
      amount: 1200,
      installmentCount: 12,
      dueDate: DateTime.now().add(const Duration(days: 365)),
    );
    final repository = _CountingLoanRepository(database, [
      for (var sequence = 1; sequence <= 12; sequence++)
        db.LoanInstallment(
          id: sequence,
          loanId: 1,
          sequenceNo: sequence,
          dueDate: DateTime(2026, sequence, 10),
          principalDue: 100,
          interestDue: 0,
          feeDue: 0,
          totalDue: 100,
          paidAmount: 0,
          paidAt: null,
          status: InstallmentStatus.unpaid.name,
          reminderScheduledAt: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
    ]);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        loanRepositoryProvider.overrideWithValue(repository),
        loanViewModelProvider.overrideWith(() => _FakeLoanViewModel(loan)),
        transactionViewModelProvider.overrideWith(
          _FakeTransactionViewModel.new,
        ),
        pocketViewModelProvider.overrideWith(_FakePocketViewModel.new),
        categoryNamesProvider.overrideWith((ref) async => {}),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: LoanDetailScreen(loan: loan)),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.scheduleReads, 1);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(repository.scheduleReads, 1);
    expect(find.text('Installment Schedule'), findsOneWidget);
  });
}

class _CountingLoanRepository extends LoanRepository {
  final List<db.LoanInstallment> installments;
  int scheduleReads = 0;

  _CountingLoanRepository(super.db, this.installments);

  @override
  Future<List<db.LoanInstallment>> getInstallmentsByLoanId(int loanId) async {
    scheduleReads++;
    return installments;
  }
}

class _FakeLoanViewModel extends LoanViewModel {
  final Loan loan;

  _FakeLoanViewModel(this.loan);

  @override
  Future<List<Loan>> build() async => [loan];
}

class _FakeTransactionViewModel extends TransactionViewModel {
  @override
  Future<List<Transaction>> build() async => [];
}

class _FakePocketViewModel extends PocketViewModel {
  @override
  Future<List<Pocket>> build() async => <Pocket>[];
}
