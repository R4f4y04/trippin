import 'dart:async';

import '../models/discovered_device.dart';
import '../utils/app_logger.dart';

enum P2PEventType {
  discoveryStarted,
  discoveryStopped,
  advertisingStarted,
  advertisingStopped,
  deviceFound,
  connectionRequested,
  connectionRequestSent,
  connectionAccepted,
  connectionRejected,
  disconnected,
  error,
}

class P2PEvent {
  final P2PEventType type;
  final DiscoveredDevice? device;
  final String? connectionId;
  final String? message;

  const P2PEvent({
    required this.type,
    this.device,
    this.connectionId,
    this.message,
  });
}

class P2PService {
  P2PService._();

  static final P2PService instance = P2PService._();

  final StreamController<P2PEvent> _eventController =
      StreamController<P2PEvent>.broadcast();

  Stream<P2PEvent> get events => _eventController.stream;

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  Future<void> startAdvertising({required String hostName}) async {
    AppLogger.info('P2P start advertising: $hostName');
    _isAdvertising = true;
    _eventController.add(
      const P2PEvent(
        type: P2PEventType.advertisingStarted,
        message: 'Lobby started',
      ),
    );
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    AppLogger.info('P2P stop advertising');
    _isAdvertising = false;
    _eventController.add(
      const P2PEvent(
        type: P2PEventType.advertisingStopped,
        message: 'Lobby stopped',
      ),
    );
  }

  Future<void> startDiscovery() async {
    AppLogger.info('P2P start discovery');
    _isDiscovering = true;
    _eventController.add(const P2PEvent(type: P2PEventType.discoveryStarted));

    // Phase 2 bootstrap: mock a discoverable host entry so UI and provider flow
    // can be validated before native Nearby integration.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (_isDiscovering) {
      _eventController.add(
        P2PEvent(
          type: P2PEventType.deviceFound,
          device: DiscoveredDevice.create(
            endpointId: 'mock-host-endpoint',
            displayName: 'Nearby Host',
            signalStrength: -52,
          ),
        ),
      );
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    AppLogger.info('P2P stop discovery');
    _isDiscovering = false;
    _eventController.add(const P2PEvent(type: P2PEventType.discoveryStopped));
  }

  Future<void> requestConnection(DiscoveredDevice device) async {
    AppLogger.info('P2P request connection to ${device.displayName}');
    _eventController.add(
      P2PEvent(type: P2PEventType.connectionRequestSent, device: device),
    );
  }

  Future<void> simulateIncomingRequest({required String guestName}) async {
    if (!_isAdvertising) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Cannot receive request while not advertising',
        ),
      );
      return;
    }

    _eventController.add(
      P2PEvent(
        type: P2PEventType.connectionRequested,
        device: DiscoveredDevice.create(
          endpointId: 'mock-guest-endpoint',
          displayName: guestName,
          signalStrength: -60,
        ),
      ),
    );
  }

  Future<void> respondToConnectionRequest({
    required bool accept,
    DiscoveredDevice? device,
  }) async {
    if (accept) {
      final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
      AppLogger.info('P2P connection accepted');
      _eventController.add(
        P2PEvent(
          type: P2PEventType.connectionAccepted,
          device: device,
          connectionId: connectionId,
        ),
      );
      return;
    }

    AppLogger.warning('P2P connection rejected');
    _eventController.add(
      P2PEvent(type: P2PEventType.connectionRejected, device: device),
    );
  }

  Future<void> disconnect({String? connectionId}) async {
    AppLogger.info('P2P disconnect requested');
    _eventController.add(
      P2PEvent(
        type: P2PEventType.disconnected,
        connectionId: connectionId,
      ),
    );
  }

  Future<void> dispose() async {
    await _eventController.close();
  }
}
