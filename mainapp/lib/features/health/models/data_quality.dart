import 'package:flutter/foundation.dart';

enum DataQualityStatus {
  available,
  noData,
  stale,
  permissionRequired,
  disabled,
  unavailable,
  error,
}

extension DataQualityStatusExtension on DataQualityStatus {
  String get label {
    switch (this) {
      case DataQualityStatus.available:
        return 'Available';
      case DataQualityStatus.noData:
        return 'No data';
      case DataQualityStatus.stale:
        return 'Stale';
      case DataQualityStatus.permissionRequired:
        return 'Permission required';
      case DataQualityStatus.disabled:
        return 'Disabled';
      case DataQualityStatus.unavailable:
        return 'Unavailable';
      case DataQualityStatus.error:
        return 'Error';
    }
  }

  bool get isUsable => this == DataQualityStatus.available;
}

@immutable
class DataFreshness {
  final DateTime? lastUpdated;
  final DataQualityStatus status;
  final String? details;

  const DataFreshness({
    this.lastUpdated,
    required this.status,
    this.details,
  });

  bool isFresh({Duration maxAge = const Duration(minutes: 30)}) {
    if (status != DataQualityStatus.available || lastUpdated == null) {
      return false;
    }
    return DateTime.now().difference(lastUpdated!) <= maxAge;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated?.toIso8601String(),
      'status': status.name,
      'details': details,
    };
  }

  factory DataFreshness.fromJson(Map<String, dynamic> json) {
    return DataFreshness(
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      status: DataQualityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DataQualityStatus.unavailable,
      ),
      details: json['details'] as String?,
    );
  }
}
