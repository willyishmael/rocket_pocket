import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';

class CreatePocketState {
  final Pocket pocket;
  final List<ColorGradient> gradients;
  CreatePocketState({required this.pocket, required this.gradients});
}

final createPocketViewModelProvider =
    AsyncNotifierProvider<CreatePocketViewModel, CreatePocketState>(
      (ref) {
            final pocketRepository = ref.watch(pocketRepositoryProvider);
            final colorGradientRepository = ref.watch(
              colorGradientRepositoryProvider,
            );
            return CreatePocketViewModel()
              .._pocketRepository = pocketRepository
              .._colorGradientRepository = colorGradientRepository;
          }
          as CreatePocketViewModel Function(),
    );

class CreatePocketViewModel extends AsyncNotifier<CreatePocketState> {
  late final PocketRepository _pocketRepository;
  late final ColorGradientRepository _colorGradientRepository;

  @override
  FutureOr<CreatePocketState> build() async {
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    _colorGradientRepository = ref.watch(colorGradientRepositoryProvider);

    final gradients = await _fetchGradients();
    final defaultGradient =
        gradients.isNotEmpty
            ? gradients.first
            : ColorGradient(name: 'Default', colors: []);

    final pocket = Pocket(
      name: '',
      purpose: '',
      emoticon: '',
      colorGradient: defaultGradient,
      currency: 'IDR',
      balance: 0,
    );

    return CreatePocketState(pocket: pocket, gradients: gradients);
  }

  Future<List<ColorGradient>> _fetchGradients() async {
    try {
      return _colorGradientRepository.getAllGradients();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> createPocket(Pocket pocket) async {
    state = const AsyncLoading();
    try {
      await _pocketRepository.insertPocket(pocket);
      state = AsyncData(
        CreatePocketState(pocket: pocket, gradients: (await _fetchGradients())),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
