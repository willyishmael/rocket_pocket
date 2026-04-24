import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late MockLoanRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      LoansCompanion.insert(
        type: LoanType.given,
        counterpartyName: 'Fallback',
        amount: 1,
        description: 'Fallback',
        startDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 1, 2),
        status: LoanStatus.ongoing,
        repaidAmount: 0,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockLoanRepository();
  });

  test('build and getLoansByStatus map repository rows', () async {
    final row = buildLoanRow(id: 1, status: LoanStatus.ongoing);
    when(() => mockRepository.getAllLoans()).thenAnswer((_) async => [row]);
    when(
      () => mockRepository.getLoansByStatus(LoanStatus.ongoing),
    ).thenAnswer((_) async => [row]);

    final container = ProviderContainer(
      overrides: [loanRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(loanViewModelProvider.future), hasLength(1));
    expect(
      (await container
          .read(loanViewModelProvider.notifier)
          .getLoansByStatus(LoanStatus.ongoing)).first.status,
      LoanStatus.ongoing,
    );
  });

  test('updateStatus refreshes state on success', () async {
    final row = buildLoanRow(id: 2, status: LoanStatus.completed);
    when(() => mockRepository.getAllLoans()).thenAnswer((_) async => [row]);
    when(
      () => mockRepository.updateLoanStatus(2, LoanStatus.completed),
    ).thenAnswer((_) async => 1);

    final container = ProviderContainer(
      overrides: [loanRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await container.read(loanViewModelProvider.future);
    await container
        .read(loanViewModelProvider.notifier)
        .updateStatus(2, LoanStatus.completed);

    verify(
      () => mockRepository.updateLoanStatus(2, LoanStatus.completed),
    ).called(1);
    expect(container.read(loanViewModelProvider).requireValue, hasLength(1));
  });

  test('addLoan stores AsyncError and rethrows on failure', () async {
    when(() => mockRepository.getAllLoans()).thenAnswer((_) async => []);
    when(
      () => mockRepository.insertLoan(any()),
    ).thenThrow(DatabaseError('Failed to insert loan', StackTrace.empty));

    final container = ProviderContainer(
      overrides: [loanRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await container.read(loanViewModelProvider.future);

    await expectLater(
      () => container
          .read(loanViewModelProvider.notifier)
          .addLoan(
            LoansCompanion.insert(
              type: LoanType.given,
              counterpartyName: 'Test',
              amount: 5,
              description: 'Test',
              startDate: DateTime(2026, 1, 1),
              dueDate: DateTime(2026, 1, 2),
              status: LoanStatus.ongoing,
              repaidAmount: 0,
              updatedAt: DateTime(2026, 1, 1),
            ),
          ),
      throwsA(isA<DatabaseError>()),
    );

    expect(container.read(loanViewModelProvider).hasError, isTrue);
  });
}
