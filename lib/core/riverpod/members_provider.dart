import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/connection_state.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'connection_provider.dart';
import 'trip_provider.dart';

final membersControllerProvider =
    AsyncNotifierProvider<MembersController, List<User>>(MembersController.new);

class MembersController extends AsyncNotifier<List<User>> {
  final _storage = StorageService.instance;

  @override
  Future<List<User>> build() async {
    final trip = await ref.watch(tripControllerProvider.future);
    if (trip == null) return [];
    return _storage.getUsersByIds(trip.memberIds);
  }

  Future<bool> addMember({
    required String tripId,
    required String name,
    required String managedBy,
  }) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      AppLogger.warning('Guest role cannot add members in Phase 3.');
      return false;
    }

    try {
      final member = await _storage.addMemberToTrip(
        tripId: tripId,
        name: name,
        managedBy: managedBy,
      );
      unawaited(ref.read(tripControllerProvider.notifier).refresh());
      unawaited(refresh());
      return member != null;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to add member', error, stackTrace);
      return false;
    }
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
