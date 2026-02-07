import 'dart:math';

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'trip.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Trip {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<String> memberIds;

  @HiveField(4)
  final List<String> expenseIds;

  @HiveField(5)
  final String joinCode;

  @HiveField(6)
  final String? coverImagePath;

  Trip({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.memberIds,
    required this.expenseIds,
    required this.joinCode,
    required this.coverImagePath,
  });

  factory Trip.create({required String title}) {
    return Trip(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      memberIds: const [],
      expenseIds: const [],
      joinCode: _generateJoinCode(),
      coverImagePath: null,
    );
  }

  Trip copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<String>? memberIds,
    List<String>? expenseIds,
    String? joinCode,
    String? coverImagePath,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      expenseIds: expenseIds ?? List<String>.from(this.expenseIds),
      joinCode: joinCode ?? this.joinCode,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);
}

String _generateJoinCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 1;

  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Trip(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      memberIds: (fields[3] as List).cast<String>(),
      expenseIds: (fields[4] as List).cast<String>(),
      joinCode: fields[5] as String,
      coverImagePath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.memberIds)
      ..writeByte(4)
      ..write(obj.expenseIds)
      ..writeByte(5)
      ..write(obj.joinCode)
      ..writeByte(6)
      ..write(obj.coverImagePath);
  }
}
