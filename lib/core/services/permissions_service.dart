import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

class PermissionStatusResult {
  final bool isGranted;
  final String? message;

  const PermissionStatusResult({
    required this.isGranted,
    this.message,
  });
}

class PermissionsService {
  const PermissionsService();

  Future<PermissionStatusResult> ensureNearbyPermissions() async {
    AppLogger.info('Checking nearby permissions');

    if (kIsWeb) {
      return const PermissionStatusResult(
        isGranted: false,
        message: 'Nearby connections are not supported on web.',
      );
    }

    // Phase 2 bootstrap: no native permission plugin wired yet.
    // We keep this service modular so we can swap in permission_handler later.
    return const PermissionStatusResult(
      isGranted: true,
      message: 'Permissions available.',
    );
  }
}
