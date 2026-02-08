import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';
import '../models/split_type_adapter.dart';
import '../models/trip.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import '../utils/safe_execute.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _usersBoxName = 'users';
  static const _tripsBoxName = 'trips';
  static const _expensesBoxName = 'expenses';

  Box<User>? _usersBox;
  Box<Trip>? _tripsBox;
  Box<Expense>? _expensesBox;

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

  Future<Trip?> getActiveTrip() async {
    final box = await _openTripsBox();
    if (box.isEmpty) return null;
    return box.values.first;
  }

  Future<User?> getDeviceOwner() async {
    final box = await _openUsersBox();
    try {
      return box.values.firstWhere((user) => user.isDeviceOwner);
    } catch (_) {
      return null;
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
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to create trip', error, stackTrace);
      },
    );

    return updatedTrip;
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

    final usersBox = await _openUsersBox();
    final tripsBox = await _openTripsBox();

    final member = User.createMember(name: name, managedBy: managedBy);
    final updatedTrip = trip.copyWith(
      memberIds: [...trip.memberIds, member.id],
    );

    await safeExecute(
      operation: () async {
        await usersBox.put(member.id, member);
        await tripsBox.put(updatedTrip.id, updatedTrip);
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
    );

    await safeExecute(
      operation: () async {
        await expensesBox.put(expense.id, expense);
        await tripsBox.put(updatedTrip.id, updatedTrip);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to add expense', error, stackTrace);
      },
    );

    return expense;
  }

  Future<Trip?> getTrip(String id) async {
    final box = await _openTripsBox();
    return box.get(id);
  }

  Future<List<Trip>> getTrips() async {
    final box = await _openTripsBox();
    return box.values.toList();
  }

  Future<void> resetAll() async {
    await safeExecute(
      operation: () async {
        final tripsBox = await _openTripsBox();
        final usersBox = await _openUsersBox();
        final expensesBox = await _openExpensesBox();
        await tripsBox.clear();
        await usersBox.clear();
        await expensesBox.clear();
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to reset storage', error, stackTrace);
      },
    );
  }
}
