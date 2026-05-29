// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  memberIds: (json['memberIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  expenseIds: (json['expenseIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  joinCode: json['joinCode'] as String,
  coverImagePath: json['coverImagePath'] as String?,
  isClosed: json['isClosed'] as bool,
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
  deviceRole: json['deviceRole'] as String?,
);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'createdAt': instance.createdAt.toIso8601String(),
  'memberIds': instance.memberIds,
  'expenseIds': instance.expenseIds,
  'joinCode': instance.joinCode,
  'coverImagePath': instance.coverImagePath,
  'isClosed': instance.isClosed,
  'closedAt': instance.closedAt?.toIso8601String(),
  'lastModifiedAt': instance.lastModifiedAt.toIso8601String(),
  'deviceRole': instance.deviceRole,
};
