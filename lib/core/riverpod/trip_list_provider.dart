import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../services/storage_service.dart';

final tripListControllerProvider =
    AsyncNotifierProvider<TripListController, List<Trip>>(
  TripListController.new,
);

class TripListController extends AsyncNotifier<List<Trip>> {
  final _storage = StorageService.instance;

  @override
  Future<List<Trip>> build() async {
    return _storage.getTrips();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _storage.getTrips());
  }

  Future<void> deleteTrip(String tripId) async {
    await _storage.deleteTrip(tripId);
    await refresh();
  }
}
