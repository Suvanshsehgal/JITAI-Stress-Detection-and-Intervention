import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/buddy_provider.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  static const _actions = [
    "I'm stressed",
    "Help me sleep",
    "I need to focus",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(buddyProvider).isTyping;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _actions.map((action) {
          return ActionChip(
            label: Text(action),
            onPressed: isTyping ? null : () {
              ref.read(buddyProvider.notifier).sendMessage(action);
            },
          );
        }).toList(),
      ),
    );
  }
}
