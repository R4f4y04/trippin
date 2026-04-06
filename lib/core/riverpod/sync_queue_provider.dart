import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

final syncQueueCountProvider =
    AsyncNotifierProvider<SyncQueueCountController, int>(
      SyncQueueCountController.new,
    );

class SyncQueueCountController extends AsyncNotifier<int> {
  final _storage = StorageService.instance;

  @override
  Future<int> build() async {
    return _storage.getQueuedSyncEnvelopeCount();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _storage.getQueuedSyncEnvelopeCount());
  }
}
