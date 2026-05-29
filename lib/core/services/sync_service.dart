import 'dart:async';

import '../models/expense.dart';
import '../models/sync_envelope.dart';
import '../models/sync_payloads.dart';
import '../utils/app_logger.dart';
import 'p2p_service.dart';
import 'storage_service.dart';

enum SyncRole { host, guest }

enum SyncEventType {
  envelopeReceived,
  envelopeSent,
  invalidEnvelope,
  expenseMergedOnHost,
  ledgerAppliedOnGuest,
  queueFlushed,
  finishTripReceived,
}

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
  final StorageService _storage = StorageService.instance;
  final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();

  StreamSubscription<P2PEvent>? _p2pSubscription;
  SyncRole? _role;

  Stream<SyncEvent> get events => _eventController.stream;

  void start({required SyncRole role}) {
    _role = role;
    _p2pSubscription ??= _p2pService.events.listen(_handleP2PEvent);
    AppLogger.info('Sync service started as ${role.name}.');

    if (role == SyncRole.guest) {
      unawaited(flushGuestQueue());
    }
  }

  Future<void> stop() async {
    await _p2pSubscription?.cancel();
    _p2pSubscription = null;
    _role = null;
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

  Future<void> queueAddExpense({
    required String tripId,
    required Expense expense,
  }) async {
    final payload = AddExpensePayload(tripId: tripId, expense: expense);
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.addExpense,
      payload: payload.toJson(),
    );
    await _storage.enqueueSyncEnvelope(envelope);
    AppLogger.info('Queued ADD_EXPENSE envelope ${envelope.id}.');
  }

  Future<void> sendSyncLedger({
    required String tripId,
    required List<Expense> expenses,
  }) async {
    final trip = await _storage.getTrip(tripId);
    final members = trip != null ? await _storage.getUsersByIds(trip.memberIds) : null;

    final payload = SyncLedgerPayload(
      tripId: tripId,
      tripTitle: trip?.title,
      expenses: expenses,
      members: members,
    );
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

  Future<void> sendFinishTrip({required String tripId}) async {
    final envelope = SyncEnvelope.create(
      type: SyncMessageType.finishTrip,
      payload: {'tripId': tripId},
    );
    await _sendEnvelope(envelope);
  }

  Future<void> _sendEnvelope(SyncEnvelope envelope) async {
    await _p2pService.sendTextPayload(text: envelope.encode());
    _eventController.add(
      SyncEvent(type: SyncEventType.envelopeSent, envelope: envelope),
    );
  }

  Future<void> flushGuestQueue() async {
    if (_role != SyncRole.guest || !_p2pService.hasActiveConnection) {
      return;
    }

    final queued = await _storage.getQueuedSyncEnvelopes();
    if (queued.isEmpty) {
      return;
    }

    var sentCount = 0;
    var failedCount = 0;
    for (final envelope in queued) {
      try {
        await _sendEnvelope(envelope);
        await _storage.removeQueuedSyncEnvelope(envelope.id);
        sentCount += 1;
      } catch (error, stackTrace) {
        AppLogger.error('Queue flush interrupted', error, stackTrace);
        failedCount += 1;
        if (!_p2pService.hasActiveConnection) {
          break;
        }
      }
    }

    _eventController.add(
      SyncEvent(
        type: SyncEventType.queueFlushed,
        message:
            'Flushed $sentCount queued envelope(s), $failedCount failed this attempt.',
      ),
    );
  }

  Future<void> _handleP2PEvent(P2PEvent event) async {
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

    await _applyIncomingEnvelope(envelope);
  }

  Future<void> _applyIncomingEnvelope(SyncEnvelope envelope) async {
    final role = _role;
    if (role == null) {
      return;
    }

    if (role == SyncRole.host && envelope.type == SyncMessageType.addExpense) {
      final payload = AddExpensePayload.fromJson(envelope.payload);
      await _storage.mergeSyncedExpense(expense: payload.expense);
      final ledger = await _storage.getExpensesByTrip(payload.tripId);
      await sendSyncLedger(tripId: payload.tripId, expenses: ledger);
      _eventController.add(
        SyncEvent(type: SyncEventType.expenseMergedOnHost, envelope: envelope),
      );
      return;
    }

    if (role == SyncRole.guest && envelope.type == SyncMessageType.syncLedger) {
      final payload = SyncLedgerPayload.fromJson(envelope.payload);
      await _storage.replaceTripExpensesFromSync(
        tripId: payload.tripId,
        expenses: payload.expenses,
        tripTitle: payload.tripTitle,
        members: payload.members,
      );
      _eventController.add(
        SyncEvent(type: SyncEventType.ledgerAppliedOnGuest, envelope: envelope),
      );
      return;
    }

    if (role == SyncRole.guest && envelope.type == SyncMessageType.finishTrip) {
      final tripId = envelope.payload['tripId'] as String;
      await _storage.closeTrip(tripId: tripId);
      _eventController.add(
        SyncEvent(type: SyncEventType.finishTripReceived, envelope: envelope),
      );
      return;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}
