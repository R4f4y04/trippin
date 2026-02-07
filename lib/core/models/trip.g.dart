// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberIds: (json['memberIds'] as List<dynamic>).cast<String>(),
      expenseIds: (json['expenseIds'] as List<dynamic>).cast<String>(),
      joinCode: json['joinCode'] as String,
      coverImagePath: json['coverImagePath'] as String?,
    );

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'memberIds': instance.memberIds,
      'expenseIds': instance.expenseIds,
      'joinCode': instance.joinCode,
      'coverImagePath': instance.coverImagePath,
    };
