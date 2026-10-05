import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/buddy_state.dart';
import '../models/message.dart';
import '../services/mock_conversation_service.dart';
import '../../onboarding/providers/onboarding_provider.dart';

final mockConversationServiceProvider = Provider<MockConversationService>((ref) {
  return MockConversationService();
});

final buddyProvider = StateNotifierProvider.autoDispose<BuddyNotifier, BuddyState>((ref) {
  final service = ref.read(mockConversationServiceProvider);
  final buddyName = ref.read(onboardingProvider).buddyName;
  final tone = ref.read(onboardingProvider).tone;
  return BuddyNotifier(service, buddyName, tone);
});

class BuddyNotifier extends StateNotifier<BuddyState> {
  final MockConversationService _service;
  final String _buddyName;
  final dynamic _tone;
  final _uuid = const Uuid();

  BuddyNotifier(this._service, this._buddyName, this._tone) : super(const BuddyState()) {
    _initializeWelcomeMessage();
  }

  void _initializeWelcomeMessage() {
    final welcomeMsg = Message(
      id: _uuid.v4(),
      role: MessageRole.ebb,
      content: 'Hi! I\'m $_buddyName. How are you feeling today?',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [welcomeMsg]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isTyping) return;

    final userMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      final responseText = await _service.getResponse(
        userMessage: text,
        tone: _tone,
      );

      final ebbMessage = Message(
        id: _uuid.v4(),
        role: MessageRole.ebb,
        content: responseText,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        state = state.copyWith(
          messages: [...state.messages, ebbMessage],
          isTyping: false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = Message(
          id: _uuid.v4(),
          role: MessageRole.error,
          content: 'I had trouble connecting. Please try again.',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isTyping: false,
        );
      }
    }
  }

  void startNewConversation() {
    state = const BuddyState();
    _initializeWelcomeMessage();
  }

  void retryLastMessage() {
    // Find the last user message to retry
    final messages = state.messages;
    final lastUserMsg = messages.lastWhere((m) => m.role == MessageRole.user, orElse: () => messages.first);
    if (lastUserMsg.role == MessageRole.user) {
      // Remove error messages at the end if any
      final cleanMessages = messages.where((m) => m.role != MessageRole.error).toList();
      state = state.copyWith(messages: cleanMessages);
      
      // Resend the content
      // We do not re-add the user message to UI since it's already there
      // We just trigger the service call again
      _resend(lastUserMsg.content);
    }
  }

  Future<void> _resend(String text) async {
    state = state.copyWith(isTyping: true);
    try {
      final responseText = await _service.getResponse(
        userMessage: text,
        tone: _tone,
      );

      final ebbMessage = Message(
        id: _uuid.v4(),
        role: MessageRole.ebb,
        content: responseText,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        state = state.copyWith(
          messages: [...state.messages, ebbMessage],
          isTyping: false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = Message(
          id: _uuid.v4(),
          role: MessageRole.error,
          content: 'I had trouble connecting. Please try again.',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isTyping: false,
        );
      }
    }
  }
}
