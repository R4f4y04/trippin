// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncEnvelope _$SyncEnvelopeFromJson(Map<String, dynamic> json) => SyncEnvelope(
  id: json['id'] as String,
  type: $enumDecode(_$SyncMessageTypeEnumMap, json['type']),
  payload: json['payload'] as Map<String, dynamic>,
  timestamp: (json['timestamp'] as num).toInt(),
);

Map<String, dynamic> _$SyncEnvelopeToJson(SyncEnvelope instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SyncMessageTypeEnumMap[instance.type]!,
      'payload': instance.payload,
      'timestamp': instance.timestamp,
    };

const _$SyncMessageTypeEnumMap = {
  SyncMessageType.handshake: 'HANDSHAKE',
  SyncMessageType.addExpense: 'ADD_EXPENSE',
  SyncMessageType.syncLedger: 'SYNC_LEDGER',
  SyncMessageType.heartbeat: 'HEARTBEAT',
  SyncMessageType.finishTrip: 'FINISH_TRIP',
};
