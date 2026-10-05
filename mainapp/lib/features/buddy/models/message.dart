import 'package:flutter/foundation.dart';

enum MessageRole { user, ebb, system, error }
enum MessageStatus { sending, sent, failed }

@immutable
class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          content == other.content &&
          timestamp == other.timestamp &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      role.hashCode ^
      content.hashCode ^
      timestamp.hashCode ^
      status.hashCode;
}
