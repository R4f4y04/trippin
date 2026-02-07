import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isDeviceOwner;

  @HiveField(3)
  final String? managedBy;

  @HiveField(4)
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.isDeviceOwner,
    required this.managedBy,
    required this.createdAt,
  });

  factory User.createDeviceOwner({required String name}) {
    return User(
      id: const Uuid().v4(),
      name: name,
      isDeviceOwner: true,
      managedBy: null,
      createdAt: DateTime.now(),
    );
  }

  factory User.createMember({
    required String name,
    required String managedBy,
  }) {
    return User(
      id: const Uuid().v4(),
      name: name,
      isDeviceOwner: false,
      managedBy: managedBy,
      createdAt: DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? name,
    bool? isDeviceOwner,
    String? managedBy,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      isDeviceOwner: isDeviceOwner ?? this.isDeviceOwner,
      managedBy: managedBy ?? this.managedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      isDeviceOwner: fields[2] as bool,
      managedBy: fields[3] as String?,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isDeviceOwner)
      ..writeByte(3)
      ..write(obj.managedBy)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
