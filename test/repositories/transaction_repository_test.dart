import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

import '../helpers/test_data_builders.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionRepository', () {
    test('filters by type, category, loan, and pocket', () async {
      final categoryId = await db
          .into(db.transactionCategories)
          .insert(
            TransactionCategoriesCompanion.insert(
              name: 'Travel',
              type: Value(TransactionType.expense),
              updatedAt: fixedDate(2),
            ),
          );

      final loanId = await LoanRepository(db).insertLoan(
        LoansCompanion.insert(
          type: LoanType.given,
          counterpartyName: 'Alex',
          amount: 400,
          description: 'Short-term',
          startDate: fixedDate(1),
          dueDate: fixedDate(20),
          status: LoanStatus.ongoing,
          repaidAmount: 0,
          updatedAt: fixedDate(2),
        ),
      );

      await repository.insertTransaction(
        TransactionsCompanion.insert(
          senderPocketId: const Value(1),
          receiverPocketId: const Value(1),
          type: TransactionType.expense,
          categoryId: Value(categoryId),
          loanId: Value(loanId),
          description: 'Trip',
          amount: 120,
          date: Value(fixedDate(3)),
          updatedAt: fixedDate(3),
        ),
      );
      await repository.insertTransaction(
        TransactionsCompanion.insert(
          senderPocketId: const Value(1),
          type: TransactionType.income,
          description: 'Salary',
          amount: 800,
          date: Value(fixedDate(4)),
          updatedAt: fixedDate(4),
        ),
      );

      expect((await repository.getTransactionsByType('expense')).length, 1);
      expect(
        (await repository.getTransactionsByCategoryId(categoryId)).length,
        1,
      );
      expect((await repository.getTransactionsByLoanId(loanId)).length, 1);
      expect(
        (await repository.getTransactionsBySenderPocketId(1)).length,
        greaterThanOrEqualTo(2),
      );
      expect((await repository.getTransactionsByReceiverPocketId(1)).length, 1);
      expect(
        (await repository.getTransactionsByPocketId(1)).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('updateTransaction persists changes', () async {
      final id = await repository.insertTransaction(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          description: 'Coffee',
          amount: 5,
          date: Value(fixedDate(1)),
          updatedAt: fixedDate(1),
        ),
      );

      await repository.updateTransaction(
        TransactionsCompanion(
          id: Value(id),
          type: const Value(TransactionType.expense),
          description: const Value('Coffee beans'),
          amount: const Value(12),
          updatedAt: Value(fixedDate(2)),
        ),
      );

      final updated = await repository.getTransactionById(id);
      expect(updated!.description, 'Coffee beans');
      expect(updated.amount, 12);
    });

    test('deleteTransaction removes row', () async {
      final id = await repository.insertTransaction(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          description: 'Delete me',
          amount: 1,
          date: Value(fixedDate(1)),
          updatedAt: fixedDate(1),
        ),
      );

      await repository.deleteTransaction(id);

      expect(await repository.getTransactionById(id), isNull);
    });

    test('throws DatabaseError when table is unavailable', () async {
      await db.customStatement('DROP TABLE transactions;');

      expect(repository.getAllTransactions, throwsA(isA<DatabaseError>()));
    });
  });
}
