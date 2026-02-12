import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';

class PermissionStatusResult {
  final bool isGranted;
  final String? message;

  const PermissionStatusResult({required this.isGranted, this.message});
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

    if (!Platform.isAndroid) {
      return const PermissionStatusResult(
        isGranted: false,
        message: 'Nearby handshake is currently supported on Android only.',
      );
    }

    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();

    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();

    if (denied.isNotEmpty) {
      final hasPermanentDenial = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      final message = hasPermanentDenial
          ? 'Permissions permanently denied. Enable Bluetooth/Location permissions in app settings.'
          : 'Bluetooth and location permissions are required for nearby discovery.';
      return PermissionStatusResult(isGranted: false, message: message);
    }

    final locationServiceEnabled =
        await Permission.locationWhenInUse.serviceStatus.isEnabled;
    if (!locationServiceEnabled) {
      return const PermissionStatusResult(
        isGranted: false,
        message:
            'Location service is off. Please enable location to use nearby discovery.',
      );
    }

    return const PermissionStatusResult(
      isGranted: true,
      message: 'Nearby permissions granted.',
    );
  }
}
