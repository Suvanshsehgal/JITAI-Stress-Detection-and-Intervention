import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../shared/widgets/ebb_button.dart';
import '../../toolbox/providers/intervention_provider.dart';

class SuggestedActionWidget extends ConsumerWidget {
  const SuggestedActionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervention = ref.watch(recommendationProvider);

    final title = intervention?.title ?? '2-minute box breathing';
    final targetId = intervention?.id ?? 'box-breathing';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBrand,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF4A3832), width: 1.2),
        boxShadow: AppShadows.lightCardShadow,
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.lightAccent, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'SUGGESTED FOR YOU',
                      style: TextStyle(
                        color: AppColors.lightBrandSubtext,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$title before your next class',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          EbbButton(
            label: 'Start Session',
            isAccent: true,
            onPressed: () {
              context.push('/intervention/$targetId/run');
            },
          ),
        ],
      ),
    );
  }
}
