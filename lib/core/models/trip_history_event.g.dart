// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_history_event.dart';

TripHistoryEvent _$TripHistoryEventFromJson(Map<String, dynamic> json) =>
    TripHistoryEvent(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      type: json['type'] as String,
      actorId: json['actorId'] as String?,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TripHistoryEventToJson(TripHistoryEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'type': instance.type,
      'actorId': instance.actorId,
      'summary': instance.summary,
      'createdAt': instance.createdAt.toIso8601String(),
    };
