// GENERATED from tools/human_realism_config.json — do not edit by hand.
// Rebuild: python tools/gen_human_realism_config.py

import 'elite_human_lyricist_directive.dart';

/// Human Realism slider (0–100) — lyric authenticity vs polished AI writing.
class HumanRealismConfig {
  HumanRealismConfig._();

  static const int defaultLevel = 75;
  static const int minLevel = 0;
  static const int maxLevel = 100;

  static const String helperText = "Controls how closely lyrics resemble authentic human songwriting instead of polished AI writing.\n\nLow values produce highly lyrical, poetic, and technically impressive lyrics.\n\nHigh values produce more natural, imperfect, conversational, and believable lyrics.";

  static const Map<(int, int), String> _bandLabels = {
    (0, 20): "Highly poetic and stylized",
    (21, 40): "Professional songwriter",
    (41, 60): "Balanced",
    (61, 80): "Authentic artist",
    (81, 100): "Raw human realism",
  };

  static const Map<(int, int), String> _bandInstructions = {
    (0, 20): "Generate highly lyrical and artistic lyrics.\n\nUse:\n• Dense rhyme schemes\n• Metaphors\n• Symbolism\n• Strong imagery\n• Technical writing\n• Polished songwriting\n\nMinimize:\n• Everyday details\n• Imperfections\n• Conversational language",
    (21, 40): "Generate professional commercial songwriting.\n\nUse:\n• Strong hooks\n• Good imagery\n• Clean structure\n• Controlled storytelling\n\nAllow some realism but maintain polished writing.",
    (41, 60): "Balance artistry and realism.\n\nUse:\n• Personal observations\n• Memorable hooks\n• Occasional imperfections\n• Natural speech\n\nAvoid excessive poetic language.",
    (61, 80): "Prioritize authenticity.\n\nUse:\n• Real-life situations\n• Personal details\n• Specific observations\n• Natural conversations\n• Human contradictions\n\nReduce:\n• Excessive metaphors\n• Forced rhymes\n• Abstract imagery\n\nAllow some rough edges.",
    (81, 100): "Maximum human realism.\n\nWrite as if a real artist drafted the lyrics in a notebook.\n\nRequirements:\n• Use specific details.\n• Use realistic situations.\n• Include flaws.\n• Include uncertainty.\n• Include opinions.\n• Include unique observations.\n• Include occasional incomplete thoughts.\n• Allow imperfect rhyme schemes.\n• Allow conversational language.\n• Allow surprising topic shifts.\n\nAvoid:\n• AI-style motivational language\n• Generic inspiration\n• Excessive imagery\n• Every line sounding profound\n• Constant metaphors\n• Overly polished writing\n\nLyrics should feel lived-in rather than written.\nThe listener should believe a real person experienced these events.",
  };

  static const String _userBlockHeader = "HUMAN REALISM (scales poetic polish vs authentic grit on top of Elite Human Lyricist; Block 2 only):";
  static const String _lowPoeticGuardrail = "At this Human Realism level you MAY increase poetic density, metaphors, and rhyme craft per the band instructions above, but you MUST still obey the Elite Human Lyricist core bans (no motivational clichés, no AI-favored vocabulary spam, no making every line profound).";

  static int clampLevel(int value) =>
      value.clamp(minLevel, maxLevel).toInt();

  static String bandLabel(int raw) {
    final v = clampLevel(raw);
    for (final entry in _bandLabels.entries) {
      final (lo, hi) = entry.key;
      if (v >= lo && v <= hi) return entry.value;
    }
    return 'Balanced';
  }

  static String _instructionsFor(int level) {
    final v = clampLevel(level);
    for (final entry in _bandInstructions.entries) {
      final (lo, hi) = entry.key;
      if (v >= lo && v <= hi) return entry.value;
    }
    return _bandInstructions[(41, 60)]!;
  }

  /// Injected into the Suno user block when Block 2 lyrics are expected.
  static String userBlockDirective(
    int raw, {
    String? dialectStyleId,
  }) {
    final level = clampLevel(raw);
    final band = _instructionsFor(level);
    final lines = <String>[
      EliteHumanLyricistDirective.userBlockPrefix(
        dialectStyleId: dialectStyleId,
      ),
      '',
      _userBlockHeader,
      band,
      '',
      'Human Realism Level: $level/100',
      'Adjust lyric generation accordingly.',
      'Higher values: increase authenticity, specificity, conversational language, and imperfections; '
      'decrease metaphor density, poetic abstraction, and forced rhyming.',
      'Lower values: increase lyricism, poetic imagery, technical rhymes, and stylization.',
      'Maintain genre conventions while applying the realism level.',
    ];
    if (level <= 40) {
      lines.add(_lowPoeticGuardrail);
    }
    return lines.join('\n');
  }
}
