import 'package:uuid/uuid.dart';

class DiscoveredDevice {
  final String id;
  final String endpointId;
  final String displayName;
  final int? signalStrength;
  final DateTime discoveredAt;

  const DiscoveredDevice({
    required this.id,
    required this.endpointId,
    required this.displayName,
    required this.signalStrength,
    required this.discoveredAt,
  });

  factory DiscoveredDevice.create({
    required String endpointId,
    required String displayName,
    int? signalStrength,
  }) {
    return DiscoveredDevice(
      id: const Uuid().v4(),
      endpointId: endpointId,
      displayName: displayName,
      signalStrength: signalStrength,
      discoveredAt: DateTime.now(),
    );
  }

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveredDevice(
      id: json['id'] as String,
      endpointId: json['endpointId'] as String,
      displayName: json['displayName'] as String,
      signalStrength: json['signalStrength'] as int?,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpointId': endpointId,
      'displayName': displayName,
      'signalStrength': signalStrength,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}
