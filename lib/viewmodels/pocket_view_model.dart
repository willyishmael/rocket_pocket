import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';

final pocketViewModelProvider =
    AsyncNotifierProvider<PocketViewModel, List<Pocket>>(
      (ref) {
            final pocketRepository = ref.watch(pocketRepositoryProvider);
            return PocketViewModel(pocketRepository);
          }
          as PocketViewModel Function(),
    );

class PocketViewModel extends AsyncNotifier<List<Pocket>> {
  late final PocketRepository _pocketRepository;
  PocketViewModel(this._pocketRepository);

  @override
  FutureOr<List<Pocket>> build() async {
    return await _fetchPockets();
  }

  Future<List<Pocket>> _fetchPockets() async {
    try {
      return _pocketRepository.getAllPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> refreshPockets() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPockets());
  }

  Future<void> addPocket(Pocket pocket) async {
    try {
      await _pocketRepository.insertPocket(pocket);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  
  Future<Pocket?> getPocketById(int id) async {
    try {
      return await _pocketRepository.getPocketById(id);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updatePocket(Pocket pocket) async {
    try {
      await _pocketRepository.updatePocket(pocket);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deletePocket(int id) async {
    try {
      await _pocketRepository.deletePocket(id);
      await refreshPockets();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
