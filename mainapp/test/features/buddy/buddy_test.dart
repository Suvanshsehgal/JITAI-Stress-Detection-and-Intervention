import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mainapp/features/buddy/buddy_screen.dart';
import 'package:mainapp/features/buddy/providers/buddy_provider.dart';
import 'package:mainapp/features/buddy/services/mock_conversation_service.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';
import 'package:mainapp/features/onboarding/models/onboarding_state.dart';

class FastMockConversationService extends MockConversationService {
  @override
  Future<String> getResponse({
    required String userMessage,
    required BuddyTone tone,
  }) async {
    // Return immediately for tests instead of 1500ms delay
    if (userMessage.trim().toLowerCase() == 'error') {
      throw Exception('Simulated network failure');
    }
    
    // Reproduce logic without delay
    final lowerMsg = userMessage.toLowerCase();
    if (lowerMsg.contains('stress')) return 'I hear you. Stress can feel overwhelming. Take a slow breath, I am here for you.';
    if (lowerMsg.contains('sleep')) return 'Rest is so important. Let\'s try a wind-down exercise to help you settle.';
    if (lowerMsg.contains('focus')) return 'Focusing can be hard. Let\'s try a quick grounding technique to bring your attention back.';
    return 'Thank you for sharing that with me. I\'m always here to listen.';
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'buddyName': 'Pip Test',
      'tone': 'gentle',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mockConversationServiceProvider.overrideWithValue(FastMockConversationService()),
      ],
      child: const MaterialApp(
        home: BuddyScreen(),
      ),
    );
  }

  testWidgets('BuddyScreen renders initial welcome message', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text("Hi! I'm Pip Test. How are you feeling today?"), findsOneWidget);
    expect(find.text('Pip Test'), findsWidgets); // App bar title
  });

  testWidgets('Sending a message creates user bubble and ebb response', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Enter text and send
    await tester.enterText(find.byType(TextField), 'I am stress');
    await tester.pump();
    
    // Tap send button
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify user message appears
    expect(find.text('I am stress'), findsOneWidget);
    
    // Wait for the mock future to resolve
    await tester.pumpAndSettle();

    // Verify the typing indicator is gone
    expect(find.text('Pip Test is typing...'), findsNothing);

    // Verify mock response for 'stress' and gentle tone
    expect(find.text('I hear you. Stress can feel overwhelming. Take a slow breath, I am here for you.'), findsOneWidget);
  });

  testWidgets('Quick actions populate and send message', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Tap a quick action
    await tester.tap(find.text('I need to focus'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify user message appears (it will be found twice: once in the chip, once in the message bubble)
    expect(find.text('I need to focus'), findsNWidgets(2));
    
    expect(find.text('Focusing can be hard. Let\'s try a quick grounding technique to bring your attention back.'), findsOneWidget);
  });

  testWidgets('Error message appears on failure and retry works', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Trigger error keyword
    await tester.enterText(find.byType(TextField), 'error');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    
    await tester.pumpAndSettle(); // Resolve future

    // Error bubble appears
    expect(find.text('I had trouble connecting. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tap retry
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle(); // Fast service resolves instantly
    
    // It should immediately fail again and show the error message
    expect(find.text('I had trouble connecting. Please try again.'), findsOneWidget);
  });

  testWidgets('New conversation resets chat', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Enter message
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    expect(find.text('Hello'), findsOneWidget);

    // Tap refresh
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Verify 'Hello' is gone
    expect(find.text('Hello'), findsNothing);
    // Welcome message remains
    expect(find.text("Hi! I'm Pip Test. How are you feeling today?"), findsOneWidget);
  });
}
