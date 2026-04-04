import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../models/discovered_device.dart';
import '../utils/app_logger.dart';

enum P2PEventType {
  discoveryStarted,
  discoveryStopped,
  advertisingStarted,
  advertisingStopped,
  deviceFound,
  deviceLost,
  connectionRequested,
  connectionRequestSent,
  connectionAccepted,
  connectionRejected,
  disconnected,
  payloadReceived,
  payloadSent,
  error,
}

class P2PEvent {
  final P2PEventType type;
  final DiscoveredDevice? device;
  final String? connectionId;
  final String? message;
  final String? payload;

  const P2PEvent({
    required this.type,
    this.device,
    this.connectionId,
    this.message,
    this.payload,
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
  static const Duration _nearbyTimeout = Duration(seconds: 12);

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

    _isAdvertising = true;
    _eventController.add(
      const P2PEvent(
        type: P2PEventType.advertisingStarted,
        message: 'Lobby starting...',
      ),
    );

    final startFuture = _nearby.startAdvertising(
      hostName,
      Strategy.P2P_STAR,
      onConnectionInitiated: (id, info) async {
        AppLogger.info(
          'P2P onConnectionInitiated (host): $id ${info.endpointName}',
        );
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
        AppLogger.info('P2P onConnectionResult (host): $id $status');
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
        AppLogger.info('P2P onDisconnected (host): $id');
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

    unawaited(
      startFuture
          .timeout(_nearbyTimeout)
          .then((started) {
            AppLogger.info('P2P advertising started result: $started');
            if (started) {
              _eventController.add(
                const P2PEvent(
                  type: P2PEventType.advertisingStarted,
                  message: 'Lobby started',
                ),
              );
              return;
            }

            _isAdvertising = false;
            _eventController.add(
              const P2PEvent(
                type: P2PEventType.error,
                message: 'Failed to start advertising.',
              ),
            );
          })
          .catchError((error, stackTrace) {
            if (error is TimeoutException) {
              AppLogger.warning(
                'P2P start advertising timed out. Keeping lobby active and waiting for callbacks.',
              );
              return;
            }

            _isAdvertising = false;
            AppLogger.error('P2P start advertising failed', error, stackTrace);
            _eventController.add(
              P2PEvent(
                type: P2PEventType.error,
                message: 'Failed to start advertising: $error',
              ),
            );
          }),
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

    final started = await _nearby
        .startDiscovery(
          'Trippin Guest',
          Strategy.P2P_STAR,
          onEndpointFound: (id, userName, serviceId) {
            AppLogger.info('P2P onEndpointFound: $id $userName $serviceId');
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
            AppLogger.info('P2P onEndpointLost: $id');
            final lost = _knownDevices.remove(id);
            _eventController.add(
              P2PEvent(type: P2PEventType.deviceLost, device: lost),
            );
          },
          serviceId: _serviceId,
        )
        .timeout(_nearbyTimeout);

    AppLogger.info('P2P discovery started result: $started');

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
    final sent = await _nearby
        .requestConnection(
          'Trippin Guest',
          device.endpointId,
          onConnectionInitiated: (id, info) async {
            AppLogger.info(
              'P2P onConnectionInitiated (guest): $id ${info.endpointName}',
            );
            await _nearby.acceptConnection(
              id,
              onPayLoadRecieved: _handlePayloadReceived,
              onPayloadTransferUpdate: (endpointId, update) {},
            );
          },
          onConnectionResult: (id, status) {
            AppLogger.info('P2P onConnectionResult (guest): $id $status');
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
            AppLogger.info('P2P onDisconnected (guest): $id');
            _connectedEndpointId = null;
            _eventController.add(
              P2PEvent(
                type: P2PEventType.disconnected,
                connectionId: id,
                device: _knownDevices[id] ?? device,
              ),
            );
          },
        )
        .timeout(_nearbyTimeout);

    AppLogger.info('P2P requestConnection result: $sent');

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
        onPayLoadRecieved: _handlePayloadReceived,
        onPayloadTransferUpdate: (resolvedEndpointId, update) {},
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

  Future<void> sendTextPayload({
    required String text,
    String? connectionId,
  }) async {
    final endpointId = connectionId ?? _connectedEndpointId;
    if (endpointId == null) {
      _eventController.add(
        const P2PEvent(
          type: P2PEventType.error,
          message: 'Cannot send payload without an active connection.',
        ),
      );
      return;
    }

    await _nearby.sendBytesPayload(
      endpointId,
      Uint8List.fromList(utf8.encode(text)),
    );

    _eventController.add(
      P2PEvent(
        type: P2PEventType.payloadSent,
        connectionId: endpointId,
        payload: text,
      ),
    );
  }

  void _handlePayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES) {
      return;
    }

    final payloadBytes = payload.bytes ?? Uint8List(0);
    final text = utf8.decode(payloadBytes, allowMalformed: true);
    _eventController.add(
      P2PEvent(
        type: P2PEventType.payloadReceived,
        connectionId: endpointId,
        payload: text,
      ),
    );
  }

  Future<void> dispose() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    await _eventController.close();
  }
}
