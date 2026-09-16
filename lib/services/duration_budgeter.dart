// Duration Budgeter — estimates song length from lyric structure.

import '../config/engine_config.dart';

class SectionEstimate {
  final String section;
  final int seconds;
  const SectionEstimate(this.section, this.seconds);
}

class DurationResult {
  final int estimatedSeconds;
  final int safeLimitSeconds;
  final int maxSongDurationSec;
  final bool overBudget;
  final String? advice;
  final List<SectionEstimate> breakdown;
  const DurationResult({
    required this.estimatedSeconds,
    required this.safeLimitSeconds,
    required this.maxSongDurationSec,
    required this.overBudget,
    required this.advice,
    required this.breakdown,
  });
}

class DurationBudgeter {
  static DurationResult estimate({
    required String lyrics,
    required String tempo,
    required String modelVersion,
  }) {
    final multiplier =
        EngineConfig.tempoEnergy[tempo]?.durationMultiplier ?? 1.0;
    final profile = EngineConfig.profileFor(modelVersion);
    final safeLimit = profile.maxSafeDurationSec;
    final maxSong = profile.maxSongDurationSec;

    final breakdown = <SectionEstimate>[];
    final bracketRe = RegExp(r'^\[([^\]\-]+)');

    for (final raw in lyrics.split('\n')) {
      final m = bracketRe.firstMatch(raw.trim());
      if (m == null) continue;
      final rawName = m.group(1)!.trim();
      final name = rawName.toLowerCase().replaceAll(RegExp(r'\s*\d+$'), '');
      if (name == 'end') continue;
      final base = EngineConfig.secondsPerSection[name] ?? 20;
      breakdown.add(SectionEstimate(rawName, (base * multiplier).round()));
    }

    final total = breakdown.fold(0, (s, b) => s + b.seconds);
    final over = total > safeLimit;

    return DurationResult(
      estimatedSeconds: total,
      safeLimitSeconds: safeLimit,
      maxSongDurationSec: maxSong,
      overBudget: over,
      advice: over ? EngineConfig.overBudgetAdvice : null,
      breakdown: breakdown,
    );
  }
}
