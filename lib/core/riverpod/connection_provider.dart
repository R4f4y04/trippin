import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_state.dart';
import '../models/discovered_device.dart';
import '../services/p2p_service.dart';
import '../services/permissions_service.dart';
import '../services/sync_service.dart';
import '../utils/app_logger.dart';
import '../utils/safe_execute.dart';

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionStateModel>(
      ConnectionController.new,
    );

class ConnectionController extends Notifier<ConnectionStateModel> {
  final PermissionsService _permissionsService = const PermissionsService();
  final P2PService _p2pService = P2PService.instance;
  final SyncService _syncService = SyncService.instance;

  StreamSubscription<P2PEvent>? _subscription;

  @override
  ConnectionStateModel build() {
    _subscription = _p2pService.events.listen(_handleP2PEvent);
    ref.onDispose(() {
      _subscription?.cancel();
      unawaited(_syncService.stop());
    });
    return const ConnectionStateModel.initial();
  }

  Future<void> startHost({required String hostName}) async {
    state = state.copyWith(
      role: ConnectionRole.host,
      status: ConnectionStatus.checkingPermissions,
      clearErrorMessage: true,
      statusMessage: 'Checking permissions...',
    );

    final permission = await _permissionsService.ensureNearbyPermissions();
    if (!permission.isGranted) {
      state = state.copyWith(
        status: ConnectionStatus.permissionDenied,
        errorMessage: permission.message ?? 'Permissions are required.',
      );
      return;
    }

    await safeExecute(
      operation: () async {
        await _p2pService.startAdvertising(hostName: hostName);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to start host mode', error, stackTrace);
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Failed to start host mode.',
        );
      },
    );
  }

  Future<bool> requestPermissionsOnly() async {
    state = state.copyWith(
      status: ConnectionStatus.checkingPermissions,
      clearErrorMessage: true,
      statusMessage: 'Requesting permissions...',
    );

    final permission = await _permissionsService.ensureNearbyPermissions();
    if (!permission.isGranted) {
      state = state.copyWith(
        status: ConnectionStatus.permissionDenied,
        errorMessage: permission.message ?? 'Permissions are required.',
      );
      return false;
    }

    state = state.copyWith(
      status: ConnectionStatus.idle,
      statusMessage: 'Permissions granted.',
      clearErrorMessage: true,
    );
    return true;
  }

  Future<void> stopHost() async {
    await safeExecute(
      operation: () async {
        await _p2pService.stopAdvertising();
      },
    );

    state = state.copyWith(
      role: ConnectionRole.idle,
      status: ConnectionStatus.idle,
      clearSelectedDevice: true,
      activeConnectionId: null,
      statusMessage: 'Host stopped.',
    );
    await _syncService.stop();
  }

  Future<void> startGuestScan() async {
    state = state.copyWith(
      role: ConnectionRole.guest,
      status: ConnectionStatus.checkingPermissions,
      discoveredDevices: const [],
      clearSelectedDevice: true,
      clearErrorMessage: true,
      statusMessage: 'Checking permissions...',
    );

    final permission = await _permissionsService.ensureNearbyPermissions();
    if (!permission.isGranted) {
      state = state.copyWith(
        status: ConnectionStatus.permissionDenied,
        errorMessage: permission.message ?? 'Permissions are required.',
      );
      return;
    }

    await safeExecute(
      operation: () async {
        await _p2pService.startDiscovery();
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to start guest scan', error, stackTrace);
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Failed to start scan.',
        );
      },
    );
  }

  Future<void> stopGuestScan() async {
    await safeExecute(
      operation: () async {
        await _p2pService.stopDiscovery();
      },
    );

    state = state.copyWith(
      status: ConnectionStatus.idle,
      statusMessage: 'Scan stopped.',
    );
  }

  Future<void> requestConnection(DiscoveredDevice device) async {
    state = state.copyWith(
      status: ConnectionStatus.requestSent,
      selectedDevice: device,
      statusMessage: 'Connection request sent.',
    );

    await safeExecute(
      operation: () async {
        await _p2pService.requestConnection(device);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to send connection request', error, stackTrace);
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Failed to send request.',
        );
      },
    );
  }

  Future<void> hostRespondToIncomingRequest({required bool accept}) async {
    final selectedDevice = state.selectedDevice;
    await safeExecute(
      operation: () async {
        await _p2pService.respondToConnectionRequest(
          accept: accept,
          device: selectedDevice,
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('Failed to respond to request', error, stackTrace);
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Failed to respond to request.',
        );
      },
    );
  }

  Future<void> disconnect() async {
    await safeExecute(
      operation: () async {
        await _p2pService.disconnect(connectionId: state.activeConnectionId);
      },
    );

    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      activeConnectionId: null,
      clearSelectedDevice: true,
      statusMessage: 'Disconnected.',
    );
    await _syncService.stop();
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  Future<void> openPermissionSettings() async {
    await _permissionsService.openAppPermissionSettings();
  }

  void _handleP2PEvent(P2PEvent event) {
    AppLogger.info(
      'Connection event: ${event.type.name} '
      'device=${event.device?.displayName ?? '-'} '
      'connectionId=${event.connectionId ?? '-'} '
      'message=${event.message ?? '-'}',
    );

    switch (event.type) {
      case P2PEventType.advertisingStarted:
        state = state.copyWith(
          status: ConnectionStatus.advertising,
          statusMessage: event.message ?? 'Lobby started.',
          clearErrorMessage: true,
        );
        break;
      case P2PEventType.advertisingStopped:
        state = state.copyWith(
          status: ConnectionStatus.idle,
          statusMessage: event.message ?? 'Lobby stopped.',
        );
        break;
      case P2PEventType.discoveryStarted:
        state = state.copyWith(
          status: ConnectionStatus.discovering,
          statusMessage: 'Scanning nearby devices...',
          clearErrorMessage: true,
        );
        break;
      case P2PEventType.discoveryStopped:
        state = state.copyWith(
          status: ConnectionStatus.idle,
          statusMessage: 'Scan stopped.',
        );
        break;
      case P2PEventType.deviceFound:
        final device = event.device;
        if (device == null) {
          break;
        }
        final devices = <DiscoveredDevice>[...state.discoveredDevices];
        final index = devices.indexWhere(
          (item) => item.endpointId == device.endpointId,
        );
        if (index >= 0) {
          devices[index] = device;
        } else {
          devices.add(device);
        }
        state = state.copyWith(
          discoveredDevices: devices,
          statusMessage: 'Found ${devices.length} nearby device(s).',
        );
        break;
      case P2PEventType.deviceLost:
        final lostDevice = event.device;
        if (lostDevice == null) {
          break;
        }

        final devices = state.discoveredDevices
            .where((item) => item.endpointId != lostDevice.endpointId)
            .toList();

        final selectedWasLost =
            state.selectedDevice?.endpointId == lostDevice.endpointId;

        state = state.copyWith(
          discoveredDevices: devices,
          status: selectedWasLost
              ? ConnectionStatus.disconnected
              : state.status,
          clearSelectedDevice: selectedWasLost,
          statusMessage: selectedWasLost
              ? '${lostDevice.displayName} is no longer available.'
              : 'Found ${devices.length} nearby device(s).',
        );
        break;
      case P2PEventType.connectionRequested:
        state = state.copyWith(
          status: ConnectionStatus.requestIncoming,
          selectedDevice: event.device,
          statusMessage:
              'Incoming request from ${event.device?.displayName ?? 'device'}.',
        );
        break;
      case P2PEventType.connectionRequestSent:
        state = state.copyWith(
          status: ConnectionStatus.awaitingConfirmation,
          selectedDevice: event.device,
          statusMessage: 'Awaiting confirmation...',
        );
        break;
      case P2PEventType.connectionAccepted:
        _syncService.start(
          role: state.role == ConnectionRole.host
              ? SyncRole.host
              : SyncRole.guest,
        );
        state = state.copyWith(
          status: ConnectionStatus.connected,
          selectedDevice: event.device,
          activeConnectionId: event.connectionId,
          statusMessage: 'Connected to ${event.device?.displayName ?? 'peer'}.',
          clearErrorMessage: true,
        );
        break;
      case P2PEventType.connectionRejected:
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          statusMessage: 'Connection request rejected.',
          activeConnectionId: null,
        );
        break;
      case P2PEventType.disconnected:
        unawaited(_syncService.stop());
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          activeConnectionId: null,
          clearSelectedDevice: true,
          statusMessage: 'Disconnected from peer.',
        );
        break;
      case P2PEventType.payloadReceived:
      case P2PEventType.payloadSent:
        break;
      case P2PEventType.error:
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: event.message ?? 'Unknown connection error.',
        );
        break;
    }
  }
}
