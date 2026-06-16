// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandshakePayload _$HandshakePayloadFromJson(Map<String, dynamic> json) =>
    HandshakePayload(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      managedMemberIds: (json['managedMemberIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$HandshakePayloadToJson(HandshakePayload instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'managedMemberIds': instance.managedMemberIds,
    };

AddExpensePayload _$AddExpensePayloadFromJson(Map<String, dynamic> json) =>
    AddExpensePayload(
      tripId: json['tripId'] as String,
      expense: Expense.fromJson(json['expense'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AddExpensePayloadToJson(AddExpensePayload instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'expense': instance.expense.toJson(),
    };

SyncLedgerPayload _$SyncLedgerPayloadFromJson(Map<String, dynamic> json) =>
    SyncLedgerPayload(
      tripId: json['tripId'] as String,
      tripTitle: json['tripTitle'] as String?,
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SyncLedgerPayloadToJson(SyncLedgerPayload instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'tripTitle': instance.tripTitle,
      'expenses': instance.expenses.map((e) => e.toJson()).toList(),
      'members': instance.members?.map((e) => e.toJson()).toList(),
    };

HeartbeatPayload _$HeartbeatPayloadFromJson(Map<String, dynamic> json) =>
    HeartbeatPayload(senderId: json['senderId'] as String);

Map<String, dynamic> _$HeartbeatPayloadToJson(HeartbeatPayload instance) =>
    <String, dynamic>{'senderId': instance.senderId};
