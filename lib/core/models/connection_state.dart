import 'discovered_device.dart';

enum ConnectionRole { idle, host, guest }

enum ConnectionStatus {
  idle,
  checkingPermissions,
  permissionDenied,
  advertising,
  discovering,
  requestIncoming,
  requestSent,
  awaitingConfirmation,
  connected,
  disconnected,
  error,
}

class ConnectionStateModel {
  final ConnectionRole role;
  final ConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final DiscoveredDevice? selectedDevice;
  final String? activeConnectionId;
  final String? statusMessage;
  final String? errorMessage;

  const ConnectionStateModel({
    required this.role,
    required this.status,
    required this.discoveredDevices,
    required this.selectedDevice,
    required this.activeConnectionId,
    required this.statusMessage,
    required this.errorMessage,
  });

  const ConnectionStateModel.initial()
      : role = ConnectionRole.idle,
        status = ConnectionStatus.idle,
        discoveredDevices = const [],
        selectedDevice = null,
        activeConnectionId = null,
        statusMessage = null,
        errorMessage = null;

  bool get isBusy => status == ConnectionStatus.checkingPermissions;

  bool get isConnected => status == ConnectionStatus.connected;

  ConnectionStateModel copyWith({
    ConnectionRole? role,
    ConnectionStatus? status,
    List<DiscoveredDevice>? discoveredDevices,
    DiscoveredDevice? selectedDevice,
    String? activeConnectionId,
    String? statusMessage,
    String? errorMessage,
    bool clearSelectedDevice = false,
    bool clearStatusMessage = false,
    bool clearErrorMessage = false,
  }) {
    return ConnectionStateModel(
      role: role ?? this.role,
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      selectedDevice: clearSelectedDevice
          ? null
          : (selectedDevice ?? this.selectedDevice),
      activeConnectionId: activeConnectionId ?? this.activeConnectionId,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
