import 'package:flutter/foundation.dart';
import 'data_quality.dart';

enum NotificationCapabilityStatus {
  enabled,
  denied,
  unavailable,
  unknown,
}

extension NotificationCapabilityStatusExtension on NotificationCapabilityStatus {
  String get label {
    switch (this) {
      case NotificationCapabilityStatus.enabled:
        return 'Enabled';
      case NotificationCapabilityStatus.denied:
        return 'Denied';
      case NotificationCapabilityStatus.unavailable:
        return 'Unavailable';
      case NotificationCapabilityStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isCapable => this == NotificationCapabilityStatus.enabled;
}

@immutable
class NotificationCapability {
  final NotificationCapabilityStatus status;
  final DateTime lastChecked;
  final DataQualityStatus quality;

  const NotificationCapability({
    required this.status,
    required this.lastChecked,
    this.quality = DataQualityStatus.available,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'lastChecked': lastChecked.toIso8601String(),
      'quality': quality.name,
    };
  }

  factory NotificationCapability.fromJson(Map<String, dynamic> json) {
    return NotificationCapability(
      status: NotificationCapabilityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationCapabilityStatus.unknown,
      ),
      lastChecked: DateTime.parse(json['lastChecked'] as String),
      quality: DataQualityStatus.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => DataQualityStatus.available,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationCapability &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastChecked == other.lastChecked &&
          quality == other.quality;

  @override
  int get hashCode =>
      status.hashCode ^ lastChecked.hashCode ^ quality.hashCode;
}
