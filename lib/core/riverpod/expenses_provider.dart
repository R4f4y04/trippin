import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/storage_service.dart';
import 'trip_provider.dart';

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(
  ExpensesController.new,
);

class ExpensesController extends AsyncNotifier<List<Expense>> {
  final _storage = StorageService.instance;

  @override
  Future<List<Expense>> build() async {
    final trip = await ref.watch(tripControllerProvider.future);
    if (trip == null) return [];
    return _storage.getExpensesByTrip(trip.id);
  }

  Future<void> addExpense({
    required String tripId,
    required String payerId,
    required double amount,
    required List<String> beneficiaryIds,
    required String name,
    String? note,
  }) async {
    await _storage.addExpense(
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      beneficiaryIds: beneficiaryIds,
      name: name,
      note: note,
    );
    await refresh();
  }

  Future<void> updateExpense({
    required String expenseId,
    required String name,
    required double amount,
    required String payerId,
    required List<String> beneficiaryIds,
    String? note,
  }) async {
    await _storage.updateExpense(
      expenseId: expenseId,
      name: name,
      amount: amount,
      payerId: payerId,
      beneficiaryIds: beneficiaryIds,
      note: note,
    );
    await refresh();
  }

  Future<void> deleteExpense({required String expenseId}) async {
    await _storage.deleteExpense(expenseId: expenseId);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final trip = await ref.read(tripControllerProvider.future);
    if (trip == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(await _storage.getExpensesByTrip(trip.id));
  }
}
