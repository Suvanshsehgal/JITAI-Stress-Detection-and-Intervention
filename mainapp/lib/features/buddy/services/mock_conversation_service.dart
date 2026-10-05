import 'dart:async';
import '../../onboarding/models/onboarding_state.dart';

class MockConversationService {
  Future<String> getResponse({
    required String userMessage,
    required BuddyTone tone,
  }) async {
    // Artificial delay to simulate network/typing
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simulate an error for a specific keyword to test error handling
    if (userMessage.trim().toLowerCase() == 'error') {
      throw Exception('Simulated network failure');
    }

    final lowerMsg = userMessage.toLowerCase();

    // Responses based on Tone
    if (lowerMsg.contains('stress')) {
      switch (tone) {
        case BuddyTone.gentle:
          return 'I hear you. Stress can feel overwhelming. Take a slow breath, I am here for you.';
        case BuddyTone.playful:
          return 'Oh no, stress monsters! Let\'s take a breather and shrink them down together.';
        case BuddyTone.straightTalking:
          return 'Stress happens. Let\'s ground ourselves and focus on what we can control.';
      }
    }

    if (lowerMsg.contains('sleep')) {
      switch (tone) {
        case BuddyTone.gentle:
          return 'Rest is so important. Let\'s try a wind-down exercise to help you settle.';
        case BuddyTone.playful:
          return 'Time to count sheep? Let\'s relax your mind so you can drift off easily.';
        case BuddyTone.straightTalking:
          return 'Good sleep is foundational. Let\'s establish a clear wind-down routine now.';
      }
    }

    if (lowerMsg.contains('focus')) {
      return 'Focusing can be hard. Let\'s try a quick grounding technique to bring your attention back.';
    }

    // Default neutral fallback
    switch (tone) {
      case BuddyTone.gentle:
        return 'Thank you for sharing that with me. I\'m always here to listen.';
      case BuddyTone.playful:
        return 'Got it! I\'m always around when you want to chat some more.';
      case BuddyTone.straightTalking:
        return 'I understand. Let me know what you want to focus on next.';
    }
  }
}
