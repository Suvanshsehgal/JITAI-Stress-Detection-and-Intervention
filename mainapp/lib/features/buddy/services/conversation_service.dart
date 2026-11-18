import '../../onboarding/models/onboarding_state.dart';
import '../models/message.dart';

abstract class ConversationService {
  Future<String> getResponse({
    required String userMessage,
    required BuddyTone tone,
    String? buddyName,
    List<Message>? history,
    Map<String, dynamic>? contextData,
  });
}
