import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';

/// Provides the user's saved display name for auto-fill on
/// Start Trip and Join Trip screens.
final savedNameProvider =
    AsyncNotifierProvider<SavedNameController, String?>(
  SavedNameController.new,
);

class SavedNameController extends AsyncNotifier<String?> {
  final _profile = ProfileService.instance;

  @override
  Future<String?> build() async {
    return _profile.getSavedName();
  }

  Future<void> updateName(String name) async {
    await _profile.setSavedName(name);
    state = AsyncData(name);
  }
}

/// Provides the persisted device role ('host' / 'guest' / null)
/// for crash-recovery routing.
final deviceRoleProvider =
    AsyncNotifierProvider<DeviceRoleController, String?>(
  DeviceRoleController.new,
);

class DeviceRoleController extends AsyncNotifier<String?> {
  final _profile = ProfileService.instance;

  @override
  Future<String?> build() async {
    return _profile.getDeviceRole();
  }

  Future<void> setRole(String? role) async {
    await _profile.setDeviceRole(role);
    state = AsyncData(role);
  }
}
