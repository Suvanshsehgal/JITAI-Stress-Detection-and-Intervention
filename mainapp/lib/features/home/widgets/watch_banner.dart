import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../health/providers/health_providers.dart';
import '../../health/services/watch_service.dart';

class WatchBannerWidget extends ConsumerWidget {
  const WatchBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(watchServiceProvider);
    final isConnected = watch.status == WatchStatus.connected;
    final current = watch.current;

    return EbbCard(
      onTap: () => context.push('/watch'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isConnected ? AppColors.lightCalmSoft : AppColors.lightPaper,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.watch_rounded,
              color: isConnected ? AppColors.lightCalm : AppColors.lightTextSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isConnected ? AppColors.lightCalm : AppColors.lightWarm,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Fireboltt Watch Active' : 'Fireboltt Smartwatch',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected
                      ? (current != null ? 'Live Stream: ${current.bpm} BPM' : 'Monitoring live...')
                      : 'Tap to connect & monitor HR',
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected ? AppColors.lightCalm : AppColors.lightTextSecondary,
                    fontWeight: isConnected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected && current != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightCalm,
                borderRadius: AppRadius.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${current.bpm}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.lightBrand,
                borderRadius: AppRadius.pill,
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
