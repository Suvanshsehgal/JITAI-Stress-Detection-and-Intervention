import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/buddy_provider.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';
import 'widgets/quick_actions.dart';
import '../onboarding/providers/onboarding_provider.dart';

class BuddyScreen extends ConsumerStatefulWidget {
  const BuddyScreen({super.key});

  @override
  ConsumerState<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends ConsumerState<BuddyScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buddyState = ref.watch(buddyProvider);
    final buddyName = ref.watch(onboardingProvider).buddyName;

    // Listen for new messages to auto-scroll
    ref.listen(buddyProvider.select((state) => state.messages.length), (previous, next) {
      if (previous != null && next > previous) {
        // Wait a frame for list to build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(buddyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Conversation',
            onPressed: () {
              ref.read(buddyProvider.notifier).startNewConversation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: buddyState.messages.length + (buddyState.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < buddyState.messages.length) {
                    final message = buddyState.messages[index];
                    return MessageBubble(message: message);
                  } else {
                    // Typing indicator
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Text(
                          '$buddyName is typing...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const QuickActionsWidget(),
            const MessageComposer(),
          ],
        ),
      ),
    );
  }
}
