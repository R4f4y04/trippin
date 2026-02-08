import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'expense.dart';

part 'expense_revision.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class ExpenseRevision {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String expenseId;

  @HiveField(2)
  final String tripId;

  @HiveField(3)
  final String? editorId;

  @HiveField(4)
  final double previousAmount;

  @HiveField(5)
  final String previousName;

  @HiveField(6)
  final String previousPayerId;

  @HiveField(7)
  final List<String> previousBeneficiaryIds;

  @HiveField(8)
  final String? previousNote;

  @HiveField(9)
  final DateTime createdAt;

  ExpenseRevision({
    required this.id,
    required this.expenseId,
    required this.tripId,
    required this.editorId,
    required this.previousAmount,
    required this.previousName,
    required this.previousPayerId,
    required this.previousBeneficiaryIds,
    required this.previousNote,
    required this.createdAt,
  });

  factory ExpenseRevision.create({
    required Expense expense,
    String? editorId,
  }) {
    return ExpenseRevision(
      id: const Uuid().v4(),
      expenseId: expense.id,
      tripId: expense.tripId,
      editorId: editorId,
      previousAmount: expense.amount,
      previousName: expense.name,
      previousPayerId: expense.payerId,
      previousBeneficiaryIds: List<String>.from(expense.beneficiaryIds),
      previousNote: expense.note,
      createdAt: DateTime.now(),
    );
  }

  factory ExpenseRevision.fromJson(Map<String, dynamic> json) =>
      _$ExpenseRevisionFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseRevisionToJson(this);
}

class ExpenseRevisionAdapter extends TypeAdapter<ExpenseRevision> {
  @override
  final int typeId = 4;

  @override
  ExpenseRevision read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ExpenseRevision(
      id: fields[0] as String,
      expenseId: fields[1] as String,
      tripId: fields[2] as String,
      editorId: fields[3] as String?,
      previousAmount: fields[4] as double,
      previousName: fields[5] as String,
      previousPayerId: fields[6] as String,
      previousBeneficiaryIds: (fields[7] as List).cast<String>(),
      previousNote: fields[8] as String?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseRevision obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.expenseId)
      ..writeByte(2)
      ..write(obj.tripId)
      ..writeByte(3)
      ..write(obj.editorId)
      ..writeByte(4)
      ..write(obj.previousAmount)
      ..writeByte(5)
      ..write(obj.previousName)
      ..writeByte(6)
      ..write(obj.previousPayerId)
      ..writeByte(7)
      ..write(obj.previousBeneficiaryIds)
      ..writeByte(8)
      ..write(obj.previousNote)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
