import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../services/storage_service.dart';

final tripControllerProvider = AsyncNotifierProvider<TripController, Trip?>(
  TripController.new,
);

class TripController extends AsyncNotifier<Trip?> {
  final _storage = StorageService.instance;

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
    state = AsyncData(trip);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _storage.getActiveTrip());
  }
}
