import '../../../core/network/api_client.dart';
import '../../onboarding/models/onboarding_state.dart';
import '../models/message.dart';
import 'conversation_service.dart';
import 'mock_conversation_service.dart';

class RemoteConversationService implements ConversationService {
  final ApiClient apiClient;
  final MockConversationService? mockFallback;

  RemoteConversationService({
    required this.apiClient,
    this.mockFallback,
  });

  @override
  Future<String> getResponse({
    required String userMessage,
    required BuddyTone tone,
    String? buddyName,
    List<Message>? history,
    Map<String, dynamic>? contextData,
  }) async {
    final toneStr = _mapTone(tone);
    final historyPayload = (history ?? []).map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'assistant',
        'content': m.content,
      };
    }).toList();

    final payload = <String, dynamic>{
      'message': userMessage,
      'buddy_name': buddyName ?? 'Pip',
      'tone': toneStr,
      'history': historyPayload,
    };
    if (contextData != null) {
      payload['context'] = contextData;
    }

    try {
      final res = await apiClient.post('/api/v1/buddy/chat', payload);
      if (res is Map && res.containsKey('response')) {
        return res['response'] as String;
      }
      throw ApiException('Invalid response from buddy chat service');
    } catch (e) {
      if (mockFallback != null) {
        return await mockFallback!.getResponse(
          userMessage: userMessage,
          tone: tone,
          buddyName: buddyName,
          history: history,
          contextData: contextData,
        );
      }
      rethrow;
    }
  }

  String _mapTone(BuddyTone tone) {
    switch (tone) {
      case BuddyTone.playful:
        return 'playful';
      case BuddyTone.straightTalking:
        return 'straightTalking';
      case BuddyTone.gentle:
        return 'gentle';
    }
  }
}
