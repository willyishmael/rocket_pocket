import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
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
  });
}
