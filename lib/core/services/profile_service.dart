import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_logger.dart';
import '../utils/safe_execute.dart';

/// Persists lightweight user profile data (name, device role) across sessions.
/// Uses a simple Hive string box — no adapters needed.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  static const _boxName = 'profile';
  static const _keyName = 'saved_name';
  static const _keyDeviceRole = 'device_role';

  Box<String>? _box;

  Future<Box<String>> _openBox() async {
    if (_box?.isOpen ?? false) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Initialize the profile box. Call after Hive.initFlutter().
  Future<void> initialize() async {
    await safeExecute(
      operation: () => _openBox(),
      onError: (error, stackTrace) {
        AppLogger.error('Failed to initialize profile box', error, stackTrace);
      },
    );
  }

  /// Returns the user's saved display name, or null if not set.
  Future<String?> getSavedName() async {
    final box = await _openBox();
    return box.get(_keyName);
  }

  /// Persists the user's display name for auto-fill on future trips.
  Future<void> setSavedName(String name) async {
    final box = await _openBox();
    await safeExecute(
      operation: () => box.put(_keyName, name),
      onError: (error, stackTrace) {
        AppLogger.error('Failed to save profile name', error, stackTrace);
      },
    );
  }

  /// Returns the current device role ('host', 'guest') or null.
  Future<String?> getDeviceRole() async {
    final box = await _openBox();
    return box.get(_keyDeviceRole);
  }

  /// Persists the device role for crash recovery routing.
  Future<void> setDeviceRole(String? role) async {
    final box = await _openBox();
    await safeExecute(
      operation: () async {
        if (role == null) {
          await box.delete(_keyDeviceRole);
        } else {
          await box.put(_keyDeviceRole, role);
        }
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to save device role', error, stackTrace);
      },
    );
  }

  /// Clears all profile data.
  Future<void> reset() async {
    final box = await _openBox();
    await safeExecute(
      operation: () => box.clear(),
      onError: (error, stackTrace) {
        AppLogger.error('Failed to reset profile', error, stackTrace);
      },
    );
  }
}
