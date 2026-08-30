import '../../core/constants/songwriter_prompts_data.dart';

/// Deterministic forbidden-phrase scan (complements server stage 10).
class ForbiddenPhraseScrubber {
  ForbiddenPhraseScrubber._();

  static List<String> findHits(String lyrics, {bool allowCliches = false}) {
    if (allowCliches) return const [];
    final cfg = SongwriterPromptsData.config('forbidden_phrases');
    final phrases = (cfg['phrases'] as List?) ?? const [];
    final lower = lyrics.toLowerCase();
    final hits = <String>[];
    for (final p in phrases) {
      final phrase = '$p'.toLowerCase();
      if (phrase.isNotEmpty && lower.contains(phrase)) {
        hits.add('$p');
      }
    }
    return hits;
  }
}
