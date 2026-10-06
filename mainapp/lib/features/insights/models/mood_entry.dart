import 'package:flutter/foundation.dart';

@immutable
class MoodEntry {
  final String id;
  final int moodValue; // 1 to 5, where 1 is Bad, 5 is Great
  final DateTime timestamp;
  final String? note;

  const MoodEntry({
    required this.id,
    required this.moodValue,
    required this.timestamp,
    this.note,
  });

  MoodEntry copyWith({
    String? id,
    int? moodValue,
    DateTime? timestamp,
    String? note,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      moodValue: moodValue ?? this.moodValue,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodValue': moodValue,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      moodValue: json['moodValue'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );
  }
}
