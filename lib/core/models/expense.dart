import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'split_type.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class Expense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final String payerId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final List<String> beneficiaryIds;

  @HiveField(5)
  final SplitType splitType;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  @JsonKey(defaultValue: 'Untitled')
  final String name;

  Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.amount,
    required this.beneficiaryIds,
    required this.splitType,
    required this.createdAt,
    required this.note,
    required this.name,
  });

  factory Expense.create({
    required String tripId,
    required String payerId,
    required double amount,
    required List<String> beneficiaryIds,
    required String name,
    SplitType splitType = SplitType.equal,
    String? note,
  }) {
    return Expense(
      id: const Uuid().v4(),
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      beneficiaryIds: List<String>.from(beneficiaryIds),
      splitType: splitType,
      createdAt: DateTime.now(),
      note: note,
      name: name,
    );
  }

  Expense copyWith({
    String? id,
    String? tripId,
    String? payerId,
    double? amount,
    List<String>? beneficiaryIds,
    SplitType? splitType,
    DateTime? createdAt,
    String? note,
    String? name,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      payerId: payerId ?? this.payerId,
      amount: amount ?? this.amount,
      beneficiaryIds: beneficiaryIds ?? List<String>.from(this.beneficiaryIds),
      splitType: splitType ?? this.splitType,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      name: name ?? this.name,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseToJson(this);
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Expense(
      id: fields[0] as String,
      tripId: fields[1] as String,
      payerId: fields[2] as String,
      amount: fields[3] as double,
      beneficiaryIds: (fields[4] as List).cast<String>(),
      splitType: fields[5] as SplitType,
      createdAt: fields[6] as DateTime,
      note: fields[7] as String?,
      name: fields[8] as String? ?? 'Untitled',
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.payerId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.beneficiaryIds)
      ..writeByte(5)
      ..write(obj.splitType)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.name);
  }
}
