import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/connection_state.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/app_logger.dart';
import 'connection_provider.dart';
import 'expense_sync_status_provider.dart';
import 'trip_provider.dart';

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(
      ExpensesController.new,
    );

class ExpensesController extends AsyncNotifier<List<Expense>> {
  final _storage = StorageService.instance;
  final _syncService = SyncService.instance;

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
    final savedExpense = await _storage.addExpense(
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      beneficiaryIds: beneficiaryIds,
      name: name,
      note: note,
    );

    await _syncAfterLocalMutation(tripId: tripId, createdExpense: savedExpense);
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
    final expense = await _storage.getExpense(expenseId);
    await _syncAfterLocalMutation(tripId: expense?.tripId);
    await refresh();
  }

  Future<void> deleteExpense({required String expenseId}) async {
    final existing = await _storage.getExpense(expenseId);
    await _storage.deleteExpense(expenseId: expenseId);
    await _syncAfterLocalMutation(tripId: existing?.tripId);
    await refresh();
  }

  Future<void> _syncAfterLocalMutation({
    required String? tripId,
    Expense? createdExpense,
  }) async {
    if (tripId == null) return;

    final connectionState = ref.read(connectionControllerProvider);
    final isConnected =
        connectionState.status == ConnectionStatus.connected &&
        connectionState.activeConnectionId != null;
    if (!isConnected) {
      if (connectionState.role == ConnectionRole.guest &&
          createdExpense != null) {
        ref
            .read(expenseSyncStatusProvider.notifier)
            .markRetrying(createdExpense.id);
        await _syncService.queueAddExpense(
          tripId: tripId,
          expense: createdExpense,
        );
        AppLogger.info('Guest queued ADD_EXPENSE for trip $tripId.');
      }
      return;
    }

    if (connectionState.role == ConnectionRole.guest &&
        createdExpense != null) {
      ref
          .read(expenseSyncStatusProvider.notifier)
          .markPending(createdExpense.id);
      await _syncService.sendAddExpense(
        tripId: tripId,
        expense: createdExpense,
      );
      AppLogger.info('Guest sent ADD_EXPENSE for trip $tripId.');
      return;
    }

    if (connectionState.role == ConnectionRole.host) {
      final expenses = await _storage.getExpensesByTrip(tripId);
      await _syncService.sendSyncLedger(tripId: tripId, expenses: expenses);
      AppLogger.info('Host broadcasted SYNC_LEDGER for trip $tripId.');
    }
  }

  Future<void> refresh() async {
    ref.read(expenseSyncStatusProvider.notifier).clearSynced();
    state = const AsyncLoading();
    final trip = await ref.read(tripControllerProvider.future);
    if (trip == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(await _storage.getExpensesByTrip(trip.id));
  }
}
