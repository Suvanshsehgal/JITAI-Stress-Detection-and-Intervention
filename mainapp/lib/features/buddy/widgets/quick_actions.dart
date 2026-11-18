import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/buddy_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  static const _actions = [
    'Try breathing',
    'Talk it out',
    'Not now',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(buddyProvider).isTyping;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(action),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pill,
                side: const BorderSide(color: AppColors.lightAccent, width: 1.2),
              ),
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(
                color: AppColors.lightTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              onPressed: isTyping
                  ? null
                  : () {
                      ref.read(buddyProvider.notifier).sendMessage(action);
                    },
            ),
          );
        }).toList(),
      ),
    );
  }
}
