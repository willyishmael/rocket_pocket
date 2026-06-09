import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';

class EditPocketState {
  final Pocket pocket;
  final List<ColorGradient> gradients;

  const EditPocketState({required this.pocket, required this.gradients});

  EditPocketState copyWith({Pocket? pocket, List<ColorGradient>? gradients}) {
    return EditPocketState(
      pocket: pocket ?? this.pocket,
      gradients: gradients ?? this.gradients,
    );
  }
}

final editPocketViewModelProvider =
    AsyncNotifierProvider.family<EditPocketViewModel, EditPocketState, Pocket>(
      EditPocketViewModel.new,
    );

class EditPocketViewModel extends AsyncNotifier<EditPocketState> {
  EditPocketViewModel(this._pocket);

  final Pocket _pocket;
  late final ColorGradientRepository _colorGradientRepository;

  @override
  FutureOr<EditPocketState> build() async {
    _colorGradientRepository = ref.watch(colorGradientRepositoryProvider);
    final gradients = await _fetchGradients();
    return EditPocketState(pocket: _pocket, gradients: gradients);
  }

  Future<List<ColorGradient>> _fetchGradients() async {
    try {
      return _colorGradientRepository.getAllGradients();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
