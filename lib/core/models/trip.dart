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

  @HiveField(7)
  final bool isClosed;

  @HiveField(8)
  final DateTime? closedAt;

  @HiveField(9)
  final DateTime lastModifiedAt;

  /// 'host', 'guest', or null — used for crash-recovery routing.
  @HiveField(10)
  final String? deviceRole;

  Trip({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.memberIds,
    required this.expenseIds,
    required this.joinCode,
    required this.coverImagePath,
    required this.isClosed,
    required this.closedAt,
    required this.lastModifiedAt,
    this.deviceRole,
  });

  factory Trip.create({required String title}) {
    final now = DateTime.now();
    return Trip(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      memberIds: const [],
      expenseIds: const [],
      joinCode: _generateJoinCode(),
      coverImagePath: null,
      isClosed: false,
      closedAt: null,
      lastModifiedAt: now,
      deviceRole: null,
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
    bool? isClosed,
    DateTime? closedAt,
    DateTime? lastModifiedAt,
    String? deviceRole,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      expenseIds: expenseIds ?? List<String>.from(this.expenseIds),
      joinCode: joinCode ?? this.joinCode,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deviceRole: deviceRole ?? this.deviceRole,
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
      isClosed: fields[7] as bool? ?? false,
      closedAt: fields[8] as DateTime?,
      lastModifiedAt:
          fields[9] as DateTime? ?? (fields[2] as DateTime),
      deviceRole: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.coverImagePath)
      ..writeByte(7)
      ..write(obj.isClosed)
      ..writeByte(8)
      ..write(obj.closedAt)
      ..writeByte(9)
      ..write(obj.lastModifiedAt)
      ..writeByte(10)
      ..write(obj.deviceRole);
  }
}
