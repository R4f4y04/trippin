import 'package:json_annotation/json_annotation.dart';

import 'expense.dart';

part 'sync_payloads.g.dart';

@JsonSerializable(explicitToJson: true)
class HandshakePayload {
  final String deviceId;
  final String deviceName;
  final List<String> managedMemberIds;

  const HandshakePayload({
    required this.deviceId,
    required this.deviceName,
    required this.managedMemberIds,
  });

  factory HandshakePayload.fromJson(Map<String, dynamic> json) =>
      _$HandshakePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$HandshakePayloadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AddExpensePayload {
  final String tripId;
  final Expense expense;

  const AddExpensePayload({required this.tripId, required this.expense});

  factory AddExpensePayload.fromJson(Map<String, dynamic> json) =>
      _$AddExpensePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AddExpensePayloadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SyncLedgerPayload {
  final String tripId;
  final List<Expense> expenses;

  const SyncLedgerPayload({required this.tripId, required this.expenses});

  factory SyncLedgerPayload.fromJson(Map<String, dynamic> json) =>
      _$SyncLedgerPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SyncLedgerPayloadToJson(this);
}

@JsonSerializable()
class HeartbeatPayload {
  final String senderId;

  const HeartbeatPayload({required this.senderId});

  factory HeartbeatPayload.fromJson(Map<String, dynamic> json) =>
      _$HeartbeatPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$HeartbeatPayloadToJson(this);
}
