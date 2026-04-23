import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

import '../helpers/test_data_builders.dart';

class MockPocketRepository extends Mock implements PocketRepository {}

void main() {
  late MockPocketRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(buildPocketModel());
  });

  setUp(() {
    mockRepository = MockPocketRepository();
  });

  test('build loads pockets and addPocket refreshes them', () async {
    final pockets = [buildPocketModel(id: 1, name: 'Wallet')];
    when(() => mockRepository.getAllPockets()).thenAnswer((_) async => pockets);
    when(() => mockRepository.insertPocket(any())).thenAnswer((_) async => 1);

    final container = ProviderContainer(
      overrides: [pocketRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(pocketViewModelProvider.future), pockets);
    await container
        .read(pocketViewModelProvider.notifier)
        .addPocket(buildPocketModel(id: null, name: 'Wallet'));

    verify(() => mockRepository.insertPocket(any())).called(1);
    expect(container.read(pocketViewModelProvider).requireValue, pockets);
  });

  test('deletePocket stores AsyncError and rethrows on failure', () async {
    when(() => mockRepository.getAllPockets()).thenAnswer((_) async => []);
    when(
      () => mockRepository.deletePocket(1),
    ).thenThrow(DatabaseError('Failed to delete pocket', StackTrace.empty));

    final container = ProviderContainer(
      overrides: [pocketRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await container.read(pocketViewModelProvider.future);

    await expectLater(
      () => container.read(pocketViewModelProvider.notifier).deletePocket(1),
      throwsA(isA<DatabaseError>()),
    );

    expect(container.read(pocketViewModelProvider).hasError, isTrue);
  });
}
