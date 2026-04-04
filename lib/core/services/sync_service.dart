import 'dart:async';

import '../models/expense.dart';
import '../models/sync_envelope.dart';
import '../models/sync_payloads.dart';
import '../utils/app_logger.dart';
import 'p2p_service.dart';

enum SyncRole { host, guest }

enum SyncEventType { envelopeReceived, envelopeSent, invalidEnvelope }

class SyncEvent {
  final SyncEventType type;
  final SyncEnvelope? envelope;
  final String? message;

  const SyncEvent({required this.type, this.envelope, this.message});
}

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final P2PService _p2pService = P2PService.instance;
  final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();

  StreamSubscription<P2PEvent>? _p2pSubscription;

  Stream<SyncEvent> get events => _eventController.stream;

  void start({required SyncRole role}) {
    _p2pSubscription ??= _p2pService.events.listen(_handleP2PEvent);
    AppLogger.info('Sync service started as ${role.name}.');
  }

  Future<void> stop() async {
    await _p2pSubscription?.cancel();
    _p2pSubscription = null;
    AppLogger.info('Sync service stopped.');
  }

  Future<void> sendHandshake(HandshakePayload payload) async {
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.handshake,
      payload: payload.toJson(),
    );
    await _sendEnvelope(envelope);
  }

  Future<void> sendAddExpense({
    required String tripId,
    required Expense expense,
  }) async {
    final payload = AddExpensePayload(tripId: tripId, expense: expense);
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.addExpense,
      payload: payload.toJson(),
    );
    await _sendEnvelope(envelope);
  }

  Future<void> sendSyncLedger({
    required String tripId,
    required List<Expense> expenses,
  }) async {
    final payload = SyncLedgerPayload(tripId: tripId, expenses: expenses);
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.syncLedger,
      payload: payload.toJson(),
    );
    await _sendEnvelope(envelope);
  }

  Future<void> sendHeartbeat({required String senderId}) async {
    final payload = HeartbeatPayload(senderId: senderId);
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.heartbeat,
      payload: payload.toJson(),
    );
    await _sendEnvelope(envelope);
  }

  Future<void> _sendEnvelope(SyncEnvelope envelope) async {
    await _p2pService.sendTextPayload(text: envelope.encode());
    _eventController.add(
      SyncEvent(type: SyncEventType.envelopeSent, envelope: envelope),
    );
  }

  void _handleP2PEvent(P2PEvent event) {
    if (event.type != P2PEventType.payloadReceived) {
      return;
    }

    final rawPayload = event.payload;
    if (rawPayload == null || rawPayload.isEmpty) {
      _eventController.add(
        const SyncEvent(
          type: SyncEventType.invalidEnvelope,
          message: 'Received empty payload.',
        ),
      );
      return;
    }

    final envelope = SyncEnvelope.tryDecode(rawPayload);
    if (envelope == null) {
      AppLogger.warning('Sync payload parse failed.');
      _eventController.add(
        const SyncEvent(
          type: SyncEventType.invalidEnvelope,
          message: 'Received malformed sync payload.',
        ),
      );
      return;
    }

    _eventController.add(
      SyncEvent(type: SyncEventType.envelopeReceived, envelope: envelope),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}
