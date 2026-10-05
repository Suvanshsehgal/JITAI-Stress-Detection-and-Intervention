import 'package:flutter/foundation.dart';
import 'message.dart';

@immutable
class BuddyState {
  final List<Message> messages;
  final bool isTyping;

  const BuddyState({
    this.messages = const [],
    this.isTyping = false,
  });

  BuddyState copyWith({
    List<Message>? messages,
    bool? isTyping,
  }) {
    return BuddyState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
