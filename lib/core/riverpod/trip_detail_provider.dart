import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/trip.dart';
import '../models/trip_history_event.dart';
import '../models/user.dart';
import '../services/expense_service.dart';
import '../services/storage_service.dart';

class TripDetail {
  final Trip trip;
  final List<User> members;
  final List<Expense> expenses;
  final Map<String, double> balances;
  final List<TripHistoryEvent> history;

  TripDetail({
    required this.trip,
    required this.members,
    required this.expenses,
    required this.balances,
    required this.history,
  });
}

final tripDetailProvider = FutureProvider.family<TripDetail, String>(
  (ref, tripId) async {
    final storage = StorageService.instance;
    final expenseService = ExpenseService();

    final trip = await storage.getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found');
    }

    final members = await storage.getUsersByIds(trip.memberIds);
    final expenses = await storage.getExpensesByTrip(trip.id);
    final history = await storage.getTripHistory(trip.id);

    final balances = expenseService.calculateNetBalances(
      members: members,
      expenses: expenses,
    );

    return TripDetail(
      trip: trip,
      members: members,
      expenses: expenses,
      balances: balances,
      history: history,
    );
  },
);
