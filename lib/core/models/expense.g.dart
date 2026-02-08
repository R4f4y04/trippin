// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      payerId: json['payerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      beneficiaryIds: (json['beneficiaryIds'] as List<dynamic>).cast<String>(),
      splitType: _splitTypeFromJson(json['splitType'] as String),
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
      'splitType': _splitTypeToJson(instance.splitType),
      'createdAt': instance.createdAt.toIso8601String(),
      'note': instance.note,
  'name': instance.name,
    };

const _$SplitTypeEnumMap = {
  SplitType.equal: 'EQUAL',
};

SplitType _splitTypeFromJson(String value) {
  return _$SplitTypeEnumMap.entries
      .firstWhere((entry) => entry.value == value)
      .key;
}

String _splitTypeToJson(SplitType type) => _$SplitTypeEnumMap[type]!;
