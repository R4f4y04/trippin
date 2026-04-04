import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExpenseSyncStatus { pending, retrying, synced }

final expenseSyncStatusProvider =
    NotifierProvider<
      ExpenseSyncStatusController,
      Map<String, ExpenseSyncStatus>
    >(ExpenseSyncStatusController.new);

class ExpenseSyncStatusController
    extends Notifier<Map<String, ExpenseSyncStatus>> {
  @override
  Map<String, ExpenseSyncStatus> build() {
    return <String, ExpenseSyncStatus>{};
  }

  void markPending(String expenseId) {
    state = <String, ExpenseSyncStatus>{
      ...state,
      expenseId: ExpenseSyncStatus.pending,
    };
  }

  void markRetrying(String expenseId) {
    state = <String, ExpenseSyncStatus>{
      ...state,
      expenseId: ExpenseSyncStatus.retrying,
    };
  }

  void markSynced(String expenseId) {
    state = <String, ExpenseSyncStatus>{
      ...state,
      expenseId: ExpenseSyncStatus.synced,
    };
  }

  void markManySynced(Iterable<String> expenseIds) {
    final next = <String, ExpenseSyncStatus>{...state};
    for (final expenseId in expenseIds) {
      next[expenseId] = ExpenseSyncStatus.synced;
    }
    state = next;
  }

  void clearSynced() {
    state = Map<String, ExpenseSyncStatus>.fromEntries(
      state.entries.where((entry) => entry.value != ExpenseSyncStatus.synced),
    );
  }

  void removeForExpense(String expenseId) {
    final next = <String, ExpenseSyncStatus>{...state};
    next.remove(expenseId);
    state = next;
  }
}
