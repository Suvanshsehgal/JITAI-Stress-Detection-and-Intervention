import 'package:flutter/foundation.dart';
import 'jitai_recommendation.dart';

@immutable
class JitaiDecisionResult {
  final bool isRecommended;
  final JitaiRecommendation? recommendation;
  final String statusReason; // e.g. "recommended", "calendar_busy", "in_cooldown", "steady_no_action_needed", "insufficient_data"

  const JitaiDecisionResult({
    required this.isRecommended,
    this.recommendation,
    required this.statusReason,
  });

  static const JitaiDecisionResult notRecommendedBusy = JitaiDecisionResult(
    isRecommended: false,
    statusReason: 'calendar_busy',
  );

  static const JitaiDecisionResult notRecommendedCooldown = JitaiDecisionResult(
    isRecommended: false,
    statusReason: 'in_cooldown',
  );

  static const JitaiDecisionResult notRecommendedSteady = JitaiDecisionResult(
    isRecommended: false,
    statusReason: 'steady_no_action_needed',
  );

  static const JitaiDecisionResult notRecommendedInsufficientData = JitaiDecisionResult(
    isRecommended: false,
    statusReason: 'insufficient_data',
  );
}
