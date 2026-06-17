import 'elite_human_lyricist_directive.dart';

/// Human Realism slider (0–100) — lyric authenticity vs polished AI writing.
class HumanRealismConfig {
  HumanRealismConfig._();

  static const int defaultLevel = 75;
  static const int minLevel = 0;
  static const int maxLevel = 100;

  static const String helperText =
      'Controls how closely lyrics resemble authentic human songwriting instead of '
      'polished AI writing.\n\n'
      'Low values produce highly lyrical, poetic, and technically impressive lyrics.\n\n'
      'High values produce more natural, imperfect, conversational, and believable lyrics.';

  static int clampLevel(int value) =>
      value.clamp(minLevel, maxLevel).toInt();

  /// Short label shown under the slider for the current band.
  static String bandLabel(int raw) {
    final v = clampLevel(raw);
    if (v <= 20) return 'Highly poetic and stylized';
    if (v <= 40) return 'Professional songwriter';
    if (v <= 60) return 'Balanced';
    if (v <= 80) return 'Authentic artist';
    return 'Raw human realism';
  }

  /// Injected into the Suno user block when Block 2 lyrics are expected.
  static String userBlockDirective(int raw) {
    final level = clampLevel(raw);
    final band = _bandInstructions(level);
    final lines = <String>[
      EliteHumanLyricistDirective.userBlockPrefix(),
      '',
      'HUMAN REALISM (scales poetic polish vs authentic grit on top of Elite Human Lyricist; Block 2 only):',
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
      lines.add(
        'At this Human Realism level you MAY increase poetic density, metaphors, and rhyme craft '
        'per the band instructions above, but you MUST still obey the Elite Human Lyricist core bans '
        '(no motivational clichés, no AI-favored vocabulary spam, no making every line profound).',
      );
    }
    return lines.join('\n');
  }

  static String _bandInstructions(int level) {
    if (level <= 20) {
      return '''
Generate highly lyrical and artistic lyrics.

Use:
• Dense rhyme schemes
• Metaphors
• Symbolism
• Strong imagery
• Technical writing
• Polished songwriting

Minimize:
• Everyday details
• Imperfections
• Conversational language''';
    }
    if (level <= 40) {
      return '''
Generate professional commercial songwriting.

Use:
• Strong hooks
• Good imagery
• Clean structure
• Controlled storytelling

Allow some realism but maintain polished writing.''';
    }
    if (level <= 60) {
      return '''
Balance artistry and realism.

Use:
• Personal observations
• Memorable hooks
• Occasional imperfections
• Natural speech

Avoid excessive poetic language.''';
    }
    if (level <= 80) {
      return '''
Prioritize authenticity.

Use:
• Real-life situations
• Personal details
• Specific observations
• Natural conversations
• Human contradictions

Reduce:
• Excessive metaphors
• Forced rhymes
• Abstract imagery

Allow some rough edges.''';
    }
    return '''
Maximum human realism.

Write as if a real artist drafted the lyrics in a notebook.

Requirements:
• Use specific details.
• Use realistic situations.
• Include flaws.
• Include uncertainty.
• Include opinions.
• Include unique observations.
• Include occasional incomplete thoughts.
• Allow imperfect rhyme schemes.
• Allow conversational language.
• Allow surprising topic shifts.

Avoid:
• AI-style motivational language
• Generic inspiration
• Excessive imagery
• Every line sounding profound
• Constant metaphors
• Overly polished writing

Lyrics should feel lived-in rather than written.
The listener should believe a real person experienced these events.''';
  }
}
