import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      BudgetsCompanion.insert(
        name: 'Fallback',
        amount: 1,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockBudgetRepository();
  });

  group('BudgetViewModel', () {
    test('build loads budgets with spent amounts', () async {
      final row = buildBudgetRow(
        id: 1,
        amount: 1000,
        period: BudgetPeriod.monthly,
      );

      when(() => mockRepository.getAllBudgets()).thenAnswer((_) async => [row]);
      when(
        () => mockRepository.getSpentAmount(1, row.period, row.startDate),
      ).thenAnswer((_) async => 800);

      final container = ProviderContainer(
        overrides: [budgetRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      final values = await container.read(budgetViewModelProvider.future);

      expect(values, hasLength(1));
      expect(values.first.remaining, 200);
      expect(values.first.status, BudgetStatus.nearLimit);
    });

    test('addBudget updates state on success', () async {
      final row = buildBudgetRow(
        id: 1,
        amount: 500,
        period: BudgetPeriod.weekly,
      );
      final modelBudget = buildBudgetModel(
        id: null,
        amount: 500,
        period: BudgetPeriod.weekly,
      );

      when(() => mockRepository.getAllBudgets()).thenAnswer((_) async => [row]);
      when(
        () => mockRepository.getSpentAmount(1, row.period, row.startDate),
      ).thenAnswer((_) async => 0);
      when(() => mockRepository.insertBudget(any())).thenAnswer((_) async => 1);

      final container = ProviderContainer(
        overrides: [budgetRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      await container.read(budgetViewModelProvider.future);
      final notifier = container.read(budgetViewModelProvider.notifier);

      await notifier.addBudget(modelBudget);

      final state = container.read(budgetViewModelProvider);
      expect(state.hasValue, isTrue);
      verify(() => mockRepository.insertBudget(any())).called(1);
    });

    test('addBudget sets AsyncError and rethrows on failure', () async {
      final row = buildBudgetRow(id: 1, amount: 500);
      final modelBudget = buildBudgetModel(id: null, amount: 500);

      when(() => mockRepository.getAllBudgets()).thenAnswer((_) async => [row]);
      when(
        () => mockRepository.getSpentAmount(1, row.period, row.startDate),
      ).thenAnswer((_) async => 0);
      when(
        () => mockRepository.insertBudget(any()),
      ).thenThrow(DatabaseError('Failed to insert budget', StackTrace.empty));

      final container = ProviderContainer(
        overrides: [budgetRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      await container.read(budgetViewModelProvider.future);
      final notifier = container.read(budgetViewModelProvider.notifier);

      await expectLater(
        () => notifier.addBudget(modelBudget),
        throwsA(isA<DatabaseError>()),
      );

      final state = container.read(budgetViewModelProvider);
      expect(state.hasError, isTrue);
    });
  });
}
