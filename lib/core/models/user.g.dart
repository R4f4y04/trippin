// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      name: json['name'] as String,
      isDeviceOwner: json['isDeviceOwner'] as bool,
      managedBy: json['managedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isDeviceOwner': instance.isDeviceOwner,
      'managedBy': instance.managedBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
