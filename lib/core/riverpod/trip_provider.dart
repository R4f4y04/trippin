import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';

final tripControllerProvider = AsyncNotifierProvider<TripController, Trip?>(
  TripController.new,
);

class TripController extends AsyncNotifier<Trip?> {
  final _storage = StorageService.instance;
  final _profile = ProfileService.instance;

  @override
  Future<Trip?> build() async {
    return _storage.getActiveTrip();
  }

  Future<void> createTrip({
    required String title,
    required String ownerName,
  }) async {
    state = const AsyncLoading();
    final trip = await _storage.createTripWithOwner(
      title: title,
      ownerName: ownerName,
    );

    // Persist host role and owner name for future sessions.
    await _profile.setDeviceRole('host');
    await _profile.setSavedName(ownerName);

    // Tag the trip with the device role.
    final tagged = trip.copyWith(deviceRole: 'host');
    await _storage.updateTripMeta(tripId: tagged.id, deviceRole: 'host');

    state = AsyncData(tagged);
  }

  Future<void> createSampleTrip() async {
    state = const AsyncLoading();
    await _storage.createSampleTrip();
    state = AsyncData(await _storage.getActiveTrip());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _storage.getActiveTrip());
  }

  Future<void> closeTrip(String tripId) async {
    state = const AsyncLoading();
    await _storage.closeTrip(tripId: tripId);
    // Clear device role since trip is finished.
    await _profile.setDeviceRole(null);
    state = AsyncData(await _storage.getActiveTrip());
  }

  Future<void> reopenTrip(String tripId) async {
    state = const AsyncLoading();
    await _storage.reopenTrip(tripId: tripId);
    state = AsyncData(await _storage.getActiveTrip());
  }

  /// Clears the active trip reference so the app returns to Home Hub.
  /// Used after viewing the settlement summary.
  Future<void> clearActiveTrip() async {
    await _profile.setDeviceRole(null);
    state = const AsyncData(null);
  }
}
