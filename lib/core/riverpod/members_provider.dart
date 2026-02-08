import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/storage_service.dart';
import 'trip_provider.dart';

final membersControllerProvider =
    AsyncNotifierProvider<MembersController, List<User>>(
  MembersController.new,
);

class MembersController extends AsyncNotifier<List<User>> {
  final _storage = StorageService.instance;

  @override
  Future<List<User>> build() async {
    final trip = await ref.watch(tripControllerProvider.future);
    if (trip == null) return [];
    return _storage.getUsersByIds(trip.memberIds);
  }

  Future<void> addMember({
    required String tripId,
    required String name,
    required String managedBy,
  }) async {
    await _storage.addMemberToTrip(
      tripId: tripId,
      name: name,
      managedBy: managedBy,
    );
    await ref.read(tripControllerProvider.notifier).refresh();
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final trip = await ref.read(tripControllerProvider.future);
    if (trip == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(await _storage.getUsersByIds(trip.memberIds));
  }
}
