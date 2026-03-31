import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';

class CreatePocketState {
  final Pocket pocket;
  final List<ColorGradient> gradients;
  CreatePocketState({required this.pocket, required this.gradients});

  CreatePocketState copyWith({Pocket? pocket, List<ColorGradient>? gradients}) {
    return CreatePocketState(
      pocket: pocket ?? this.pocket,
      gradients: gradients ?? this.gradients,
    );
  }
}

final createPocketViewModelProvider =
    AsyncNotifierProvider<CreatePocketViewModel, CreatePocketState>(
      CreatePocketViewModel.new,
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
            : ColorGradient(
              name: 'Platinum',
              colors: [Colors.grey.shade900, Colors.grey.shade800],
            );

    final pocket = Pocket(
      name: '',
      purpose: '',
      emoticon: '💰',
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

  void setName(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pocket: current.pocket.copyWith(name: name)),
    );
  }

  void setPurpose(String purpose) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pocket: current.pocket.copyWith(purpose: purpose)),
    );
  }

  void setEmoticon(String emoticon) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pocket: current.pocket.copyWith(emoticon: emoticon)),
    );
  }

  void setColorGradient(ColorGradient gradient) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        pocket: current.pocket.copyWith(colorGradient: gradient),
      ),
    );
  }

  void setCurrency(String currency) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pocket: current.pocket.copyWith(currency: currency)),
    );
  }

  void setBalance(double balance) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pocket: current.pocket.copyWith(balance: balance)),
    );
  }
}
