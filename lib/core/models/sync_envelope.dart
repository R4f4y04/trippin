import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'sync_envelope.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum SyncMessageType { handshake, addExpense, syncLedger, heartbeat, finishTrip }

@JsonSerializable()
class SyncEnvelope {
  final String id;
  final SyncMessageType type;
  final Map<String, dynamic> payload;
  final int timestamp;

  const SyncEnvelope({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  factory SyncEnvelope.create({
    required SyncMessageType type,
    required Map<String, dynamic> payload,
  }) {
    return SyncEnvelope(
      id: const Uuid().v4(),
      type: type,
      payload: payload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory SyncEnvelope.fromJson(Map<String, dynamic> json) =>
      _$SyncEnvelopeFromJson(json);

  Map<String, dynamic> toJson() => _$SyncEnvelopeToJson(this);

  String encode() => jsonEncode(toJson());

  static SyncEnvelope? tryDecode(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return null;
      }
      return SyncEnvelope.fromJson(parsed);
    } catch (_) {
      return null;
    }
  }
}
