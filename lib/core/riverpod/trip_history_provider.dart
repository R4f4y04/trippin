import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_history_event.dart';
import '../services/storage_service.dart';

final tripHistoryControllerProvider =
    AsyncNotifierProviderFamily<
      TripHistoryController,
      List<TripHistoryEvent>,
      String
    >(TripHistoryController.new);

class TripHistoryController
    extends FamilyAsyncNotifier<List<TripHistoryEvent>, String> {
  final _storage = StorageService.instance;
  late String _tripId;

  @override
  Future<List<TripHistoryEvent>> build(String tripId) async {
    _tripId = tripId;
    return _storage.getTripHistory(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _storage.getTripHistory(_tripId));
  }
}
