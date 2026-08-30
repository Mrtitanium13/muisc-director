import 'package:flutter/foundation.dart';

/// Lightweight in-process metrics for Ibibio + V1 fallback visibility.
class MusicPromptRoutingMonitor {
  MusicPromptRoutingMonitor._();

  static int ibibioV1FallbackCount = 0;
  static int totalRoutingGateChecks = 0;

  static void recordRoutingGateCheck() {
    totalRoutingGateChecks++;
  }

  static void warnIbibioV1Fallback({
    String? userId,
    String? requestId,
  }) {
    ibibioV1FallbackCount++;
    debugPrint(
      '[MusicPromptRouter] WARNING: Ibibio cadence selected but V2 routing '
      'disabled — falling back to V1 generic path. Quality degradation expected.'
      '${userId != null ? ' user_id=$userId' : ''}'
      '${requestId != null ? ' request_id=$requestId' : ''}',
    );
  }

  /// Optional rolling alert hook — returns true when fallback rate exceeds [threshold].
  static bool ibibioV1FallbackRateExceeds(double threshold) {
    if (totalRoutingGateChecks == 0) return false;
    return ibibioV1FallbackCount / totalRoutingGateChecks > threshold;
  }

  @visibleForTesting
  static void resetMetrics() {
    ibibioV1FallbackCount = 0;
    totalRoutingGateChecks = 0;
  }
}
