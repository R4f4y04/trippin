// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  payerId: json['payerId'] as String,
  amount: (json['amount'] as num).toDouble(),
  beneficiaryIds: (json['beneficiaryIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  splitType: $enumDecode(_$SplitTypeEnumMap, json['splitType']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  note: json['note'] as String?,
  name: json['name'] as String? ?? 'Untitled',
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'payerId': instance.payerId,
  'amount': instance.amount,
  'beneficiaryIds': instance.beneficiaryIds,
  'splitType': _$SplitTypeEnumMap[instance.splitType]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'note': instance.note,
  'name': instance.name,
};

const _$SplitTypeEnumMap = {SplitType.equal: 'EQUAL'};
