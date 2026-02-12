import 'dart:async';
import 'dart:io';

import 'package:nearby_connections/nearby_connections.dart';

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
  final Nearby _nearby = Nearby();
  final Map<String, DiscoveredDevice> _knownDevices = {};
  static const String _serviceId = 'com.example.trippin.handshake';

  Stream<P2PEvent> get events => _eventController.stream;

  bool _isAdvertising = false;
  bool _isDiscovering = false;
  String? _connectedEndpointId;

  Future<void> startAdvertising({required String hostName}) async {
    if (!Platform.isAndroid) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Nearby handshake is currently supported on Android only.',
        ),
      );
      return;
    }

    AppLogger.info('P2P start advertising: $hostName');
    await stopAdvertising();

    final started = await _nearby.startAdvertising(
      hostName,
      Strategy.P2P_STAR,
      onConnectionInitiated: (id, info) async {
        final device = DiscoveredDevice.create(
          endpointId: id,
          displayName: info.endpointName,
        );
        _knownDevices[id] = device;

        if (_connectedEndpointId != null && _connectedEndpointId != id) {
          await _nearby.rejectConnection(id);
          _eventController.add(
            const P2PEvent(
              type: P2PEventType.error,
              message:
                  'Single guest mode: another device is already connected.',
            ),
          );
          return;
        }

        _eventController.add(
          P2PEvent(type: P2PEventType.connectionRequested, device: device),
        );
      },
      onConnectionResult: (id, status) {
        final device = _knownDevices[id];
        if (status == Status.CONNECTED) {
          _connectedEndpointId = id;
          _eventController.add(
            P2PEvent(
              type: P2PEventType.connectionAccepted,
              device: device,
              connectionId: id,
            ),
          );
          return;
        }

        if (status == Status.REJECTED) {
          _eventController.add(
            P2PEvent(type: P2PEventType.connectionRejected, device: device),
          );
          return;
        }

        _eventController.add(
          const P2PEvent(
            type: P2PEventType.error,
            message: 'Connection failed while advertising.',
          ),
        );
      },
      onDisconnected: (id) {
        _connectedEndpointId = null;
        _eventController.add(
          P2PEvent(
            type: P2PEventType.disconnected,
            connectionId: id,
            device: _knownDevices[id],
          ),
        );
      },
      serviceId: _serviceId,
    );

    if (!started) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Failed to start advertising.',
        ),
      );
      return;
    }

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
    await _nearby.stopAdvertising();
    _isAdvertising = false;
    _eventController.add(
      const P2PEvent(
        type: P2PEventType.advertisingStopped,
        message: 'Lobby stopped',
      ),
    );
  }

  Future<void> startDiscovery() async {
    if (!Platform.isAndroid) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Nearby handshake is currently supported on Android only.',
        ),
      );
      return;
    }

    AppLogger.info('P2P start discovery');
    await stopDiscovery();

    final started = await _nearby.startDiscovery(
      'Trippin Guest',
      Strategy.P2P_STAR,
      onEndpointFound: (id, userName, serviceId) {
        if (serviceId != _serviceId) {
          return;
        }

        final device = DiscoveredDevice.create(
          endpointId: id,
          displayName: userName,
        );
        _knownDevices[id] = device;
        _eventController.add(
          P2PEvent(type: P2PEventType.deviceFound, device: device),
        );
      },
      onEndpointLost: (id) {
        _knownDevices.remove(id);
      },
      serviceId: _serviceId,
    );

    if (!started) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Failed to start discovery.',
        ),
      );
      return;
    }

    _isDiscovering = true;
    _eventController.add(const P2PEvent(type: P2PEventType.discoveryStarted));
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    AppLogger.info('P2P stop discovery');
    await _nearby.stopDiscovery();
    _isDiscovering = false;
    _eventController.add(const P2PEvent(type: P2PEventType.discoveryStopped));
  }

  Future<void> requestConnection(DiscoveredDevice device) async {
    AppLogger.info('P2P request connection to ${device.displayName}');
    final sent = await _nearby.requestConnection(
      'Trippin Guest',
      device.endpointId,
      onConnectionInitiated: (id, info) async {
        await _nearby.acceptConnection(
          id,
          onPayLoadRecieved: (_, __) {},
          onPayloadTransferUpdate: (_, __) {},
        );
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          _connectedEndpointId = id;
          _eventController.add(
            P2PEvent(
              type: P2PEventType.connectionAccepted,
              device: _knownDevices[id] ?? device,
              connectionId: id,
            ),
          );
          return;
        }

        if (status == Status.REJECTED) {
          _eventController.add(
            P2PEvent(
              type: P2PEventType.connectionRejected,
              device: _knownDevices[id] ?? device,
            ),
          );
          return;
        }

        _eventController.add(
          const P2PEvent(
            type: P2PEventType.error,
            message: 'Connection failed while requesting host.',
          ),
        );
      },
      onDisconnected: (id) {
        _connectedEndpointId = null;
        _eventController.add(
          P2PEvent(
            type: P2PEventType.disconnected,
            connectionId: id,
            device: _knownDevices[id] ?? device,
          ),
        );
      },
    );

    if (!sent) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Failed to send connection request.',
        ),
      );
      return;
    }

    _eventController.add(
      P2PEvent(type: P2PEventType.connectionRequestSent, device: device),
    );
  }

  Future<void> respondToConnectionRequest({
    required bool accept,
    DiscoveredDevice? device,
  }) async {
    if (device == null) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'No pending device to respond to.',
        ),
      );
      return;
    }

    final endpointId = device.endpointId;

    if (accept) {
      await _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: (_, __) {},
        onPayloadTransferUpdate: (_, __) {},
      );
      AppLogger.info('P2P connection accepted');
      return;
    }

    await _nearby.rejectConnection(endpointId);
    AppLogger.warning('P2P connection rejected');
  }

  Future<void> disconnect({String? connectionId}) async {
    AppLogger.info('P2P disconnect requested');
    await _nearby.stopAllEndpoints();
    _connectedEndpointId = null;
    _eventController.add(
      P2PEvent(type: P2PEventType.disconnected, connectionId: connectionId),
    );
  }

  Future<void> dispose() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    await _eventController.close();
  }
}
