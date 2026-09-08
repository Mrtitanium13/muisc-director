import 'api_constants.dart';

import '../../data/models/suno_field_output_mode.dart';



/// Suno-facing limits: V2 **Block 1** (Style / Description) producer prose +

/// **Block 2** lyrics. Block 1 cap is **fixed** (~1000 chars / ~150 words) for

/// all Suno model versions — the UI limit does not scale with v4.5 / v5.0 / v5.5.

class SunoPromptLimits {

  SunoPromptLimits._();



  /// Custom Mode — Style of Music field (hard cap, ~Suno UI).

  static const int block1CustomModeCharMax = 1000;



  static const int block1CustomModeCharTargetMin = 850;



  /// Simple Mode — Description field (same prose budget as Custom).

  static const int block1SimpleModeCharMax = 1000;



  static const int block1SimpleModeCharTargetMin = 850;



  /// Block 1 word band (all Suno versions, including /BEASTMODE).

  static const int block1StyleWordTargetMin = 130;



  static const int block1StyleWordHardMax = 150;



  /// Lyrics field (Custom Mode).

  static const int lyricsCharLimit = 2500;



  static const int lyricsCharTargetMin = 1500;



  /// Legacy helper for remix copy and older docs (Simple-style paragraph ceiling).

  static int styleCharLimitFor(String sunoVersion) {

    switch (sunoVersion.trim()) {

      case 'v3':

      case 'v4':

        return 200;

      default:

        return 400;

    }

  }



  static const int structureWordHardMax = 300;



  /// **Block 1** prose word target (same for every Suno version).

  static ({int min, int max}) block1StyleWordRangeFor(String sunoVersion) {

    return (

      min: block1StyleWordTargetMin,

      max: block1StyleWordHardMax,

    );

  }



  /// Character hard cap for Block 1 by mode (V2 unified output).

  static int block1CharHardCapForMode(SunoFieldOutputMode mode) => switch (mode) {

        SunoFieldOutputMode.custom => block1CustomModeCharMax,

        SunoFieldOutputMode.simple => block1SimpleModeCharMax,

      };



  /// First lines of user message when [ApiConstants.useSunoPromptV2Candidate] is on.

  static String v2FieldBudgetUserLine(

    String sunoVersion, {

    required bool hasPastedLyrics,

    required bool generateLyrics,

    SunoFieldOutputMode fieldMode = SunoFieldOutputMode.custom,

    bool block2OptOut = false,

  }) {

    final w = block1StyleWordRangeFor(sunoVersion);

    if (block2OptOut) {

      final cap = fieldMode == SunoFieldOutputMode.simple

          ? block1SimpleModeCharMax

          : block1CustomModeCharMax;

      final mode =

          fieldMode == SunoFieldOutputMode.simple ? 'SIMPLE' : 'CUSTOM';

      final tgt = fieldMode == SunoFieldOutputMode.simple

          ? '$block1SimpleModeCharTargetMin–$block1SimpleModeCharMax'

          : '$block1CustomModeCharTargetMin–$block1CustomModeCharMax';

      return 'SUNO OUTPUT MODE: $mode. USER REQUESTED BLOCK 1 ONLY (explicit opt-out: '

          'style only / no lyrics / no song structure / block 1 only). '

          'Output Block 1 **only** — producer prose **${w.min}–${w.max} words** (max ${w.max}), '

          '**≤$cap** characters (target $tgt). '

          'Do **not** output a Block 2 banner or Lyrics-field content.';

    }

    if (fieldMode == SunoFieldOutputMode.simple) {

      return 'SUNO OUTPUT MODE: SIMPLE. BLOCK 1 — Suno Description: rich producer '

          'prose **${w.min}–${w.max} words** (max ${w.max}), **≤$block1SimpleModeCharMax** '

          'characters (target $block1SimpleModeCharTargetMin–$block1SimpleModeCharMax). '

          'One cohesive paragraph — not tag-only lists; optional final comma-dense clause when SECTION 1D/1E apply (system SECTION 0B). '

          'BLOCK 2 — Lyrics: max $lyricsCharLimit chars through [End] — **always** '

          '(genre template or instrumental sections); still output Block 2 even though Simple mode uses Description only in Suno.';

    }

    if (hasPastedLyrics) {

      return 'SUNO OUTPUT MODE: CUSTOM. BLOCK 1 — STYLE: producer prose **${w.min}–${w.max} words** '

          '(max ${w.max}), **≤$block1CustomModeCharMax** characters (target '

          '$block1CustomModeCharTargetMin–$block1CustomModeCharMax). Narrative prose first — not tag-only; optional 1D/1E tail per SECTION 0B. '

          'BLOCK 2 — Lyrics: max $lyricsCharLimit chars through [End]. Path A — copy USER LYRICS verbatim; do not rewrite sung lines.';

    }

    if (generateLyrics) {

      return 'SUNO OUTPUT MODE: CUSTOM. BLOCK 1 prose **${w.min}–${w.max} words**, '

          '≤$block1CustomModeCharMax chars. BLOCK 2 ≤$lyricsCharLimit chars. Path C — GENERATE LYRICS.';

    }

    return 'SUNO OUTPUT MODE: CUSTOM. BLOCK 1 prose **${w.min}–${w.max} words**, '

        '≤$block1CustomModeCharMax chars. BLOCK 2 ≤$lyricsCharLimit chars through [End] — **always** '

        '(Path B: genre template or instrumental sections; original lyric lines when the genre is vocal).';

  }



  /// Inclusive word range [min, max] for the **SUNO STYLE** paragraph only (legacy v1).

  static ({int min, int max}) wordRangeFor(String sunoVersion) {

    switch (sunoVersion.trim()) {

      case 'v4.5':

        return (min: 80, max: 150);

      case 'v5.5':

        return (min: 200, max: 350);

      case 'v5.0':

      default:

        return (min: 150, max: 250);

    }

  }



  /// Completion cap: V2 = Block 1 prose + optional Block 2.

  static int maxCompletionTokensFor(

    String sunoVersion, {

    required bool hasUserLyrics,

    int userLyricsWordCount = 0,

    bool generateLyrics = false,

    bool useV2FormatLawStyle = false,

    SunoFieldOutputMode sunoFieldOutputMode = SunoFieldOutputMode.custom,

    bool block2OptOut = false,

  }) {

    final sr = structureWordRangeFor(sunoVersion);

    final r = wordRangeFor(sunoVersion);

    const tokensPerWord = 1.35;

    if (useV2FormatLawStyle) {

      final b1w = block1StyleWordHardMax;

      final block1Tokens = (b1w * tokensPerWord).ceil() + 320;

      if (block2OptOut) {

        if (sunoFieldOutputMode == SunoFieldOutputMode.simple) {

          return block1Tokens.clamp(900, 3200);

        }

        return block1Tokens.clamp(1000, 3400);

      }

      if (sunoFieldOutputMode == SunoFieldOutputMode.simple) {

        return (block1Tokens + 900).clamp(1400, 4200);

      }

      if (!hasUserLyrics) {

        return (block1Tokens + 900).clamp(1400, 4200);

      }

      final lw = userLyricsWordCount > 0 ? userLyricsWordCount : 80;

      final lyricsTokens =

          (lw.clamp(0, 5000) * tokensPerWord).ceil() + 220;

      return (block1Tokens + lyricsTokens).clamp(1500, 4500);

    }

    final structureStyleTokens =

        ((sr.max + r.max) * tokensPerWord).ceil() + 130;

    if (!hasUserLyrics && generateLyrics) {

      return (structureStyleTokens + 1300).clamp(1200, 3200);

    }

    if (!hasUserLyrics) {

      return structureStyleTokens.clamp(400, 1100);

    }

    final lw = userLyricsWordCount > 0 ? userLyricsWordCount : 80;

    final lyricsTokens =

        (lw.clamp(0, 5000) * tokensPerWord).ceil() + 200;

    return (structureStyleTokens + lyricsTokens).clamp(700, 4000);

  }



  static ({int min, int max}) structureWordRangeFor(String sunoVersion) {

    switch (sunoVersion.trim()) {

      case 'v4.5':

        return (min: 50, max: 130);

      case 'v5.5':

        return (min: 80, max: 200);

      case 'v5.0':

      default:

        return (min: 60, max: 160);

    }

  }



  static String wordBudgetUserLine(

    String sunoVersion, {

    required bool hasUserLyrics,

  }) {

    final r = wordRangeFor(sunoVersion);

    final sr = structureWordRangeFor(sunoVersion);

    final v = sunoVersion.trim().isEmpty ? 'v5.5' : sunoVersion.trim();

    if (!hasUserLyrics) {

      return 'WORD BUDGET (Suno $v): Output SUNO STRUCTURE then SUNO STYLE in that order. '

          'SUNO STRUCTURE: between ${sr.min} and ${sr.max} words — MUST use bracketed section lines [Intro], [Verse], etc., each on its own line; optional (parenthetical staging notes) on the following lines — see system prompt BRACKET STRUCTURE FORMAT; '

          'no plain prose paragraph for structure. '

          'SUNO STYLE: between ${r.min} and ${r.max} words — production and sonic description only; '

          'must include genre-appropriate pro studio, microphone/instrument capture, and mix polish (see system prompt); '

          'do not repeat the full roadmap here; do not invent a full song lyric.\n'

          'HARD LIMITS (Suno fields truncate): SUNO STRUCTURE body ≤ ${sr.max} words total (count every word: [Section] labels + all parenthetical notes). '

          'SUNO STYLE paragraph ≤ ${r.max} words. Never exceed these maximums — shorten (notes) first, then compress STYLE; Power Codes do not increase caps.';

    }

    return 'WORD BUDGET (Suno $v): Output SUNO STRUCTURE, then SUNO STYLE, then SUNO LYRICS in that order. '

        'SUNO STRUCTURE: ${sr.min}–${sr.max} words — bracketed [Section] format with optional (notes) per system prompt; not a prose paragraph. '

        'SUNO STYLE: ${r.min}–${r.max} words (music/production only — not the section roadmap); '

        'must include genre-appropriate pro studio, microphone/instrument capture, and mix polish (see system prompt). '

        'SUNO LYRICS: not counted in those budgets; format for Suno’s Lyrics box with section tags.\n'

        'HARD LIMITS: SUNO STRUCTURE ≤ ${sr.max} words; SUNO STYLE ≤ ${r.max} words — never exceed; shorten (notes) and dense-phrase STYLE if over; Power Codes do not raise caps.';

  }



  static String remixFromAnalyzerUserBlockSupplementV2(String sunoVersion) {

    final v = sunoVersion.trim().isEmpty ? 'v5.5' : sunoVersion.trim();

    final w = block1StyleWordRangeFor(sunoVersion);

    return 'REMIX / GENRE-FLIP (from audio analysis): Describe the transformation in '

        '**Block 1** producer prose (**${w.min}–${w.max} words**, ≤$block1CustomModeCharMax chars) — '

        'weave analyzer cues; do not paste raw analysis. '

        'Suno $v. Block 2 ≤ $lyricsCharLimit chars when lyrics apply.';

  }



  static String remixFromAnalyzerUserBlockSupplement(String sunoVersion) {

    final r = wordRangeFor(sunoVersion);

    final sr = structureWordRangeFor(sunoVersion);

    final v = sunoVersion.trim().isEmpty ? 'v5.5' : sunoVersion.trim();

    return 'REMIX / GENRE-FLIP (from audio analysis): Describe how the source becomes the target '

        'genre in SUNO STYLE only — weave analyzer cues briefly; do not paste or summarize raw '

        'analysis at length. Suno inputs are size-limited: strictly honor the WORD BUDGET line '

        'above for this Suno $v tier (SUNO STRUCTURE ${sr.min}-${sr.max} words; SUNO STYLE '

        '${r.min}-${r.max} words). Keep bracket (notes) concise; no preamble or postscript outside '

        'the three blocks when lyrics are provided, or two blocks when not.';

  }

}

