// ignore_for_file: lines_longer_than_80_chars
//
// **Generated** — do not edit by hand. Source: tools/elite_human_lyricist_directive.txt
// Rebuild: python tools/merge_suno_v2_prompt.py

import '../../prompts/elite_human_lyricist.dart';
import 'dialect_style_data.dart';

/// Elite human lyricist core — Block 2 authenticity.
class EliteHumanLyricistDirective {
  EliteHumanLyricistDirective._();

  /// Back-compat alias for [kEliteHumanLyricist].
  static const String directive = kEliteHumanLyricist;

  /// Runtime phonetic rule — dialect-aware (injected into user block).
  static String buildPhoneticIntegrityRule({String? dialectStyleId}) {
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {
      return 'PHONETIC INTEGRITY (runtime): User LYRIC DIALECT is Nigerian Pidgin. '
          'DO NOT normalize lyric lines back to standard English. Preserve words like '
          "dey, na, wahala, e don set, small small exactly as intended by the story.";
    }
    return 'PHONETIC INTEGRITY (runtime): Do not use trailing apostrophes to simulate '
        'loose casual speech (write breathing not breathin, going to not gonna) unless '
        'genre/dialect explicitly permits (Reggae/Dub patois, Hip Hop AAVE). '
        'Ensures clean phoneme mapping in downstream vocal synthesis.';
  }

  static String userBlockPrefix({String? dialectStyleId}) {
    final phonetic = buildPhoneticIntegrityRule(dialectStyleId: dialectStyleId);
    return 'ELITE HUMAN LYRICIST (Block 2 — mandatory craft layer; '
        'maintain genre conventions):\n$directive\n\n$phonetic';
  }
}
