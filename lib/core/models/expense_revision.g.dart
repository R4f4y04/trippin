// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_revision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseRevision _$ExpenseRevisionFromJson(Map<String, dynamic> json) =>
    ExpenseRevision(
      id: json['id'] as String,
      expenseId: json['expenseId'] as String,
      tripId: json['tripId'] as String,
      editorId: json['editorId'] as String?,
      previousAmount: (json['previousAmount'] as num).toDouble(),
      previousName: json['previousName'] as String,
      previousPayerId: json['previousPayerId'] as String,
      previousBeneficiaryIds: (json['previousBeneficiaryIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      previousNote: json['previousNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ExpenseRevisionToJson(ExpenseRevision instance) =>
    <String, dynamic>{
      'id': instance.id,
      'expenseId': instance.expenseId,
      'tripId': instance.tripId,
      'editorId': instance.editorId,
      'previousAmount': instance.previousAmount,
      'previousName': instance.previousName,
      'previousPayerId': instance.previousPayerId,
      'previousBeneficiaryIds': instance.previousBeneficiaryIds,
      'previousNote': instance.previousNote,
      'createdAt': instance.createdAt.toIso8601String(),
    };
