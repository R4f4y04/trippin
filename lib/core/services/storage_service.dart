import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';
import '../models/expense_revision.dart';
import '../models/split_type_adapter.dart';
import '../models/sync_envelope.dart';
import '../models/trip.dart';
import '../models/trip_history_event.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import '../utils/safe_execute.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _usersBoxName = 'users';
  static const _tripsBoxName = 'trips';
  static const _expensesBoxName = 'expenses';
  static const _expenseRevisionsBoxName = 'expense_revisions';
  static const _tripHistoryBoxName = 'trip_history';
  static const _syncQueueBoxName = 'sync_queue';

  Box<User>? _usersBox;
  Box<Trip>? _tripsBox;
  Box<Expense>? _expensesBox;
  Box<ExpenseRevision>? _expenseRevisionsBox;
  Box<TripHistoryEvent>? _tripHistoryBox;
  Box<String>? _syncQueueBox;

  Future<void> initialize() async {
    await safeExecute(
      operation: () async {
        await Hive.initFlutter();
        _registerAdapters();
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to initialize Hive', error, stackTrace);
      },
    );
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SplitTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ExpenseRevisionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TripHistoryEventAdapter());
    }
  }

  Future<Box<User>> _openUsersBox() async {
    if (_usersBox?.isOpen ?? false) return _usersBox!;
    _usersBox = await Hive.openBox<User>(_usersBoxName);
    return _usersBox!;
  }

  Future<Box<Trip>> _openTripsBox() async {
    if (_tripsBox?.isOpen ?? false) return _tripsBox!;
    _tripsBox = await Hive.openBox<Trip>(_tripsBoxName);
    return _tripsBox!;
  }

  Future<Box<Expense>> _openExpensesBox() async {
    if (_expensesBox?.isOpen ?? false) return _expensesBox!;
    _expensesBox = await Hive.openBox<Expense>(_expensesBoxName);
    return _expensesBox!;
  }

  Future<Box<ExpenseRevision>> _openExpenseRevisionsBox() async {
    if (_expenseRevisionsBox?.isOpen ?? false) return _expenseRevisionsBox!;
    _expenseRevisionsBox = await Hive.openBox<ExpenseRevision>(
      _expenseRevisionsBoxName,
    );
    return _expenseRevisionsBox!;
  }

  Future<Box<TripHistoryEvent>> _openTripHistoryBox() async {
    if (_tripHistoryBox?.isOpen ?? false) return _tripHistoryBox!;
    _tripHistoryBox = await Hive.openBox<TripHistoryEvent>(_tripHistoryBoxName);
    return _tripHistoryBox!;
  }

  Future<Box<String>> _openSyncQueueBox() async {
    if (_syncQueueBox?.isOpen ?? false) return _syncQueueBox!;
    _syncQueueBox = await Hive.openBox<String>(_syncQueueBoxName);
    return _syncQueueBox!;
  }

  Future<void> clearAllData() async {
    final usersBox = await _openUsersBox();
    final tripsBox = await _openTripsBox();
    final expensesBox = await _openExpensesBox();
    final revisionsBox = await _openExpenseRevisionsBox();
    final historyBox = await _openTripHistoryBox();
    final queueBox = await _openSyncQueueBox();

    await safeExecute(
      operation: () async {
        await usersBox.clear();
        await tripsBox.clear();
        await expensesBox.clear();
        await revisionsBox.clear();
        await historyBox.clear();
        await queueBox.clear();
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to clear storage data', error, stackTrace);
      },
    );
  }

  Future<void> enqueueSyncEnvelope(SyncEnvelope envelope) async {
    final box = await _openSyncQueueBox();
    await safeExecute(
      operation: () async {
        await box.put(envelope.id, envelope.encode());
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to enqueue sync envelope', error, stackTrace);
      },
    );
  }

  Future<List<SyncEnvelope>> getQueuedSyncEnvelopes() async {
    final box = await _openSyncQueueBox();
    final envelopes = <SyncEnvelope>[];
    final malformedKeys = <dynamic>[];

    for (final entry in box.toMap().entries) {
      final decoded = SyncEnvelope.tryDecode(entry.value);
      if (decoded == null) {
        malformedKeys.add(entry.key);
        continue;
      }
      envelopes.add(decoded);
    }

    if (malformedKeys.isNotEmpty) {
      await safeExecute(
        operation: () async {
          await box.deleteAll(malformedKeys);
        },
        onError: (error, stackTrace) {
          AppLogger.error(
            'Failed to clean malformed queued envelopes',
            error,
            stackTrace,
          );
        },
      );
    }

    envelopes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return envelopes;
  }

  Future<void> removeQueuedSyncEnvelope(String envelopeId) async {
    final box = await _openSyncQueueBox();
    await safeExecute(
      operation: () async {
        await box.delete(envelopeId);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to remove queued envelope', error, stackTrace);
      },
    );
  }

  Future<int> getQueuedSyncEnvelopeCount() async {
    final box = await _openSyncQueueBox();
    return box.length;
  }

  Future<Trip?> getActiveTrip() async {
    final box = await _openTripsBox();
    if (box.isEmpty) return null;
    final trips = box.values.toList();
    trips.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
    try {
      return trips.firstWhere((trip) => !trip.isClosed);
    } catch (_) {
      return null;
    }
  }

  Future<User?> getDeviceOwner() async {
    final box = await _openUsersBox();
    try {
      return box.values.firstWhere((user) => user.isDeviceOwner);
    } catch (_) {
      return null;
    }
  }

  Future<User> setOrCreateDeviceOwner({required String name}) async {
    final box = await _openUsersBox();
    final existing = await getDeviceOwner();
    if (existing != null) {
      final updated = existing.copyWith(name: name);
      await box.put(updated.id, updated);
      return updated;
    } else {
      final owner = User.createDeviceOwner(name: name);
      await box.put(owner.id, owner);
      return owner;
    }
  }

  Future<List<User>> getUsersByIds(List<String> ids) async {
    final box = await _openUsersBox();
    final idSet = ids.toSet();
    return box.values.where((user) => idSet.contains(user.id)).toList();
  }

  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final box = await _openExpensesBox();
    return box.values.where((expense) => expense.tripId == tripId).toList();
  }

  Future<Expense?> getExpense(String expenseId) async {
    final box = await _openExpensesBox();
    return box.get(expenseId);
  }

  Future<Trip> createTripWithOwner({
    required String title,
    required String ownerName,
  }) async {
    final tripsBox = await _openTripsBox();
    final usersBox = await _openUsersBox();

    final trip = Trip.create(title: title);
    final owner = User.createDeviceOwner(name: ownerName);
    final updatedTrip = trip.copyWith(memberIds: [owner.id]);

    await safeExecute(
      operation: () async {
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await usersBox.put(owner.id, owner);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'CREATE_TRIP',
          summary: 'Trip created by ${owner.name}',
          actorId: owner.id,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to create trip', error, stackTrace);
      },
    );

    return updatedTrip;
  }

  Future<Trip?> createSampleTrip() async {
    final trip = await createTripWithOwner(
      title: 'Sample Trip',
      ownerName: 'You',
    );

    if (trip.memberIds.isEmpty) return trip;
    final ownerId = trip.memberIds.first;

    final memberA = await addMemberToTrip(
      tripId: trip.id,
      name: 'Ayesha',
      managedBy: ownerId,
    );
    final memberB = await addMemberToTrip(
      tripId: trip.id,
      name: 'Hassan',
      managedBy: ownerId,
    );

    final members = [
      ownerId,
      if (memberA != null) memberA.id,
      if (memberB != null) memberB.id,
    ];

    if (members.isNotEmpty) {
      await addExpense(
        tripId: trip.id,
        payerId: ownerId,
        amount: 1200,
        beneficiaryIds: members,
        name: 'Fuel Stop',
        note: 'Highway fuel',
      );
      await addExpense(
        tripId: trip.id,
        payerId: memberA?.id ?? ownerId,
        amount: 650,
        beneficiaryIds: members,
        name: 'Snacks',
      );
      await addExpense(
        tripId: trip.id,
        payerId: memberB?.id ?? ownerId,
        amount: 900,
        beneficiaryIds: members,
        name: 'Boat Ride',
      );
    }

    return trip;
  }

  Future<User?> addMemberToTrip({
    required String tripId,
    required String name,
    required String managedBy,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) {
      AppLogger.warning('Attempted to add member to missing trip');
      return null;
    }
    if (trip.isClosed) {
      AppLogger.warning('Attempted to add member to closed trip');
      return null;
    }

    final usersBox = await _openUsersBox();
    final tripsBox = await _openTripsBox();

    final member = User.createMember(name: name, managedBy: managedBy);
    final updatedTrip = trip.copyWith(
      memberIds: [...trip.memberIds, member.id],
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        await usersBox.put(member.id, member);
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'ADD_MEMBER',
          summary: 'Added member ${member.name}',
          actorId: managedBy,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to add member', error, stackTrace);
      },
    );

    return member;
  }

  Future<Expense?> addExpense({
    required String tripId,
    required String payerId,
    required double amount,
    required List<String> beneficiaryIds,
    required String name,
    String? note,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) {
      AppLogger.warning('Attempted to add expense to missing trip');
      return null;
    }
    if (trip.isClosed) {
      AppLogger.warning('Attempted to add expense to closed trip');
      return null;
    }

    final expensesBox = await _openExpensesBox();
    final tripsBox = await _openTripsBox();

    final expense = Expense.create(
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      beneficiaryIds: beneficiaryIds,
      name: name,
      note: note,
    );

    final updatedTrip = trip.copyWith(
      expenseIds: [...trip.expenseIds, expense.id],
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        await expensesBox.put(expense.id, expense);
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'ADD_EXPENSE',
          summary: 'Added expense ${expense.name}',
          actorId: payerId,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to add expense', error, stackTrace);
      },
    );

    return expense;
  }

  Future<void> mergeSyncedExpense({required Expense expense}) async {
    final trip = await getTrip(expense.tripId);
    if (trip == null) {
      AppLogger.warning('Received synced expense for missing trip.');
      return;
    }

    final expensesBox = await _openExpensesBox();
    final tripsBox = await _openTripsBox();
    final alreadyExists = expensesBox.containsKey(expense.id);

    final nextExpenseIds = alreadyExists
        ? trip.expenseIds
        : [...trip.expenseIds, expense.id];
    final updatedTrip = trip.copyWith(
      expenseIds: nextExpenseIds,
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        await expensesBox.put(expense.id, expense);
        await tripsBox.put(updatedTrip.id, updatedTrip);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to merge synced expense', error, stackTrace);
      },
    );
  }

  Future<void> replaceTripExpensesFromSync({
    required String tripId,
    required List<Expense> expenses,
    String? tripTitle,
    List<User>? members,
  }) async {
    final tripsBox = await _openTripsBox();
    final expensesBox = await _openExpensesBox();
    final usersBox = await _openUsersBox();

    var trip = await getTrip(tripId);

    await safeExecute(
      operation: () async {
        if (members != null) {
          for (final member in members) {
            await usersBox.put(member.id, member);
          }
        }

        if (trip == null) {
          trip = Trip.create(title: tripTitle ?? 'Synced Trip').copyWith(
            id: tripId,
            deviceRole: 'guest',
            memberIds: members?.map((m) => m.id).toList() ?? [],
          );
        } else if (members != null) {
          trip = trip!.copyWith(
            memberIds: members.map((m) => m.id).toList(),
          );
        }

        final existing = await getExpensesByTrip(tripId);
        for (final expense in existing) {
          await expensesBox.delete(expense.id);
        }

        for (final expense in expenses) {
          await expensesBox.put(expense.id, expense);
        }

        final updatedTrip = trip!.copyWith(
          expenseIds: expenses.map((item) => item.id).toList(),
          lastModifiedAt: DateTime.now(),
        );
        await tripsBox.put(updatedTrip.id, updatedTrip);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to apply synced ledger', error, stackTrace);
      },
    );
  }

  /// Updates lightweight trip metadata (e.g. deviceRole) without
  /// triggering history events.
  Future<void> updateTripMeta({
    required String tripId,
    String? deviceRole,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) return;

    final updated = trip.copyWith(deviceRole: deviceRole);
    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        await tripsBox.put(updated.id, updated);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to update trip meta', error, stackTrace);
      },
    );
  }

  Future<Trip?> getTrip(String id) async {
    final box = await _openTripsBox();
    return box.get(id);
  }

  Future<List<TripHistoryEvent>> getTripHistory(String tripId) async {
    final box = await _openTripHistoryBox();
    return box.values.where((event) => event.tripId == tripId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ExpenseRevision>> getExpenseRevisions(String expenseId) async {
    final box = await _openExpenseRevisionsBox();
    return box.values
        .where((revision) => revision.expenseId == expenseId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Trip>> getTrips() async {
    final box = await _openTripsBox();
    final trips = box.values.toList();
    trips.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
    return trips;
  }

  Future<Trip?> closeTrip({required String tripId, String? actorId}) async {
    final trip = await getTrip(tripId);
    if (trip == null) return null;
    if (trip.isClosed) return trip;

    final updatedTrip = trip.copyWith(
      isClosed: true,
      closedAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'CLOSE_TRIP',
          summary: 'Trip closed',
          actorId: actorId,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to close trip', error, stackTrace);
      },
    );

    return updatedTrip;
  }

  Future<Trip?> reopenTrip({required String tripId, String? actorId}) async {
    final trip = await getTrip(tripId);
    if (trip == null) return null;
    if (!trip.isClosed) return trip;

    final updatedTrip = trip.copyWith(
      isClosed: false,
      closedAt: null,
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'REOPEN_TRIP',
          summary: 'Trip reopened',
          actorId: actorId,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to reopen trip', error, stackTrace);
      },
    );

    return updatedTrip;
  }

  Future<Expense?> updateExpense({
    required String expenseId,
    required String name,
    required double amount,
    required String payerId,
    required List<String> beneficiaryIds,
    String? note,
    String? editorId,
  }) async {
    final expensesBox = await _openExpensesBox();
    final existing = expensesBox.get(expenseId);
    if (existing == null) return null;

    final trip = await getTrip(existing.tripId);
    if (trip == null) return null;
    if (trip.isClosed) {
      AppLogger.warning('Attempted to edit expense in closed trip');
      return null;
    }

    final revision = ExpenseRevision.create(
      expense: existing,
      editorId: editorId,
    );

    final updated = existing.copyWith(
      name: name,
      amount: amount,
      payerId: payerId,
      beneficiaryIds: beneficiaryIds,
      note: note,
      createdAt: existing.createdAt,
    );

    final updatedTrip = trip.copyWith(lastModifiedAt: DateTime.now());

    await safeExecute(
      operation: () async {
        final revisionBox = await _openExpenseRevisionsBox();
        final tripsBox = await _openTripsBox();
        await revisionBox.put(revision.id, revision);
        await expensesBox.put(updated.id, updated);
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'EDIT_EXPENSE',
          summary: 'Edited expense ${updated.name}',
          actorId: editorId ?? payerId,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to update expense', error, stackTrace);
      },
    );

    return updated;
  }

  Future<bool> deleteExpense({
    required String expenseId,
    String? editorId,
  }) async {
    final expensesBox = await _openExpensesBox();
    final existing = expensesBox.get(expenseId);
    if (existing == null) return false;

    final trip = await getTrip(existing.tripId);
    if (trip == null) return false;
    if (trip.isClosed) {
      AppLogger.warning('Attempted to delete expense in closed trip');
      return false;
    }

    final revision = ExpenseRevision.create(
      expense: existing,
      editorId: editorId,
    );

    final updatedTrip = trip.copyWith(
      expenseIds: trip.expenseIds.where((id) => id != expenseId).toList(),
      lastModifiedAt: DateTime.now(),
    );

    await safeExecute(
      operation: () async {
        final revisionBox = await _openExpenseRevisionsBox();
        final tripsBox = await _openTripsBox();
        await revisionBox.put(revision.id, revision);
        await expensesBox.delete(expenseId);
        await tripsBox.put(updatedTrip.id, updatedTrip);
        await _appendHistoryEvent(
          tripId: updatedTrip.id,
          type: 'DELETE_EXPENSE',
          summary: 'Deleted expense ${existing.name}',
          actorId: editorId ?? existing.payerId,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to delete expense', error, stackTrace);
      },
    );

    return true;
  }

  Future<bool> deleteTrip(String tripId) async {
    final trip = await getTrip(tripId);
    if (trip == null) return false;

    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        final expensesBox = await _openExpensesBox();
        final revisionBox = await _openExpenseRevisionsBox();
        final historyBox = await _openTripHistoryBox();

        for (final expenseId in trip.expenseIds) {
          await expensesBox.delete(expenseId);
        }

        final revisionKeys = revisionBox.values
            .where((revision) => revision.tripId == tripId)
            .map((revision) => revision.id)
            .toList();
        for (final key in revisionKeys) {
          await revisionBox.delete(key);
        }

        final historyKeys = historyBox.values
            .where((event) => event.tripId == tripId)
            .map((event) => event.id)
            .toList();
        for (final key in historyKeys) {
          await historyBox.delete(key);
        }

        await tripsBox.delete(tripId);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to delete trip', error, stackTrace);
      },
    );

    return true;
  }

  Future<void> resetAll() async {
    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        final usersBox = await _openUsersBox();
        final expensesBox = await _openExpensesBox();
        final revisionsBox = await _openExpenseRevisionsBox();
        final historyBox = await _openTripHistoryBox();
        final syncQueueBox = await _openSyncQueueBox();
        await tripsBox.clear();
        await usersBox.clear();
        await expensesBox.clear();
        await revisionsBox.clear();
        await historyBox.clear();
        await syncQueueBox.clear();
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to reset storage', error, stackTrace);
      },
    );
  }

  Future<void> _appendHistoryEvent({
    required String tripId,
    required String type,
    required String summary,
    String? actorId,
  }) async {
    final historyBox = await _openTripHistoryBox();
    final event = TripHistoryEvent.create(
      tripId: tripId,
      type: type,
      summary: summary,
      actorId: actorId,
    );
    await historyBox.put(event.id, event);
  }
}
