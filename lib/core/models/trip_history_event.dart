import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'trip_history_event.g.dart';

@HiveType(typeId: 5)
@JsonSerializable()
class TripHistoryEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String? actorId;

  @HiveField(4)
  final String summary;

  @HiveField(5)
  final DateTime createdAt;

  TripHistoryEvent({
    required this.id,
    required this.tripId,
    required this.type,
    required this.actorId,
    required this.summary,
    required this.createdAt,
  });

  factory TripHistoryEvent.create({
    required String tripId,
    required String type,
    required String summary,
    String? actorId,
  }) {
    return TripHistoryEvent(
      id: const Uuid().v4(),
      tripId: tripId,
      type: type,
      actorId: actorId,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  factory TripHistoryEvent.fromJson(Map<String, dynamic> json) =>
      _$TripHistoryEventFromJson(json);
  Map<String, dynamic> toJson() => _$TripHistoryEventToJson(this);
}

class TripHistoryEventAdapter extends TypeAdapter<TripHistoryEvent> {
  @override
  final int typeId = 5;

  @override
  TripHistoryEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TripHistoryEvent(
      id: fields[0] as String,
      tripId: fields[1] as String,
      type: fields[2] as String,
      actorId: fields[3] as String?,
      summary: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TripHistoryEvent obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.actorId)
      ..writeByte(4)
      ..write(obj.summary)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
