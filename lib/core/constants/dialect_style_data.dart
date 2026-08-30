// Lyric dialect / language mode for Block 2 (Stage 3 humanization + Stage 5 compression).

class DialectStyleData {

  DialectStyleData._();



  static const String standardEnglishId = 'standard_english';

  static const String nigerianPidginId = 'nigerian_pidgin';

  static const String generalVariantId = 'general';



  static const List<DialectStyleOption> options = [

    DialectStyleOption(

      id: standardEnglishId,

      label: 'Standard English (with Accent)',

      promptLine:

          'Write lyrics in standard, grammatically clean English. Let the style tags handle the phonetic vocal accent.',

    ),

    DialectStyleOption(

      id: nigerianPidginId,

      label: 'Nigerian Pidgin English (Dialect Mode)',

      promptLine:

          'CRITICAL DIRECTIVE: Write the lyrics natively in authentic Nigerian Pidgin English. Utilize true regional vocabulary (e.g., dey, na, wahala, e don set, small small) to craft deep, culturally accurate, rhythmic storytelling while maintaining the Lyric Fourth-Wall Law.',

    ),

  ];



  /// Shown when [nigerianPidginId] is selected — regional language inflection on Pidgin.

  static const List<DialectVariantOption> pidginVariants = [

    DialectVariantOption(

      id: generalVariantId,

      label: 'General Nigerian Pidgin',

      promptLine:

          'Pan-Nigerian Pidgin flow — dey, na, wahala, e don set, small small — without forcing one ethnic tongue.',

    ),

    DialectVariantOption(

      id: 'ibibio',

      label: 'Ibibio-inflected Pidgin',

      promptLine:

          'Inflect Pidgin with Ibibio (Akwa Ibom / Cross River) color: warm vowels, local proverb rhythm, '

          'community-call phrasing; optional Ibibio loanwords where singable (e.g., ñkpọ/thing-as-presence spirit — '

          'keep lines Suno-readable). Ground worship/street story in South-South Nigerian lived texture.',

    ),

    DialectVariantOption(

      id: 'efik',

      label: 'Efik-inflected Pidgin',

      promptLine:

          'Efik (Calabar) inflection on Pidgin — melodic call-and-response cadence, coastal warmth, '

          'congregational hook phrasing; keep performable English-Pidgin spelling in lyric lines.',

    ),

    DialectVariantOption(

      id: 'yoruba',

      label: 'Yoruba-inflected Pidgin',

      promptLine:

          'Yoruba color on Pidgin — percussive syllables, praise-call energy, proverb turns; '

          'optional Yoruba loanwords where singable (o, se, mo) without breaking Suno legibility.',

    ),

    DialectVariantOption(

      id: 'igbo',

      label: 'Igbo-inflected Pidgin',

      promptLine:

          'Igbo inflection on Pidgin — declarative hook lines, testimony cadence, Eastern Nigerian street warmth; '

          'keep Pidgin grammar core with Igbo rhythmic stress.',

    ),

    DialectVariantOption(

      id: 'hausa',

      label: 'Hausa-inflected Pidgin',

      promptLine:

          'Hausa color on Pidgin — north Nigerian phrasing, measured groove, market/street imagery; '

          'Pidgin backbone with Hausa melodic lift on hooks.',

    ),

    DialectVariantOption(

      id: 'urhobo',

      label: 'Urhobo-inflected Pidgin',

      promptLine:

          'Urhobo (Delta) inflection on Pidgin — riverine storytelling, communal chorus feel, '

          'Delta Nigerian emotional directness on Pidgin syntax.',

    ),

  ];



  static DialectStyleOption? optionForId(String? id) {

    final raw = (id ?? '').trim();

    if (raw.isEmpty) return null;

    for (final o in options) {

      if (o.id == raw) return o;

    }

    return null;

  }



  static DialectVariantOption? variantForId(String? id) {

    final raw = (id ?? '').trim();

    if (raw.isEmpty) return null;

    for (final v in pidginVariants) {

      if (v.id == raw) return v;

    }

    return null;

  }



  static String coerceId(String? raw) {

    return optionForId(raw)?.id ?? standardEnglishId;

  }



  static String coerceVariantId(String? raw) {

    return variantForId(raw)?.id ?? generalVariantId;

  }



  static bool isNigerianPidgin(String? id) => coerceId(id) == nigerianPidginId;



  static String resolvedVariantPromptLine(String? dialectStyleId, String? variantId) {

    if (!isNigerianPidgin(dialectStyleId)) return '';

    final variant = variantForId(coerceVariantId(variantId))!;

    return variant.promptLine;

  }



  /// Runtime user-block injection for initial generation.

  static String userBlockDirective(

    String? dialectStyleId, {

    String? dialectVariantId,

  }) {

    final opt = optionForId(coerceId(dialectStyleId));

    if (opt == null || opt.id == standardEnglishId) return '';

    final variant = variantForId(coerceVariantId(dialectVariantId))!;

    final variantLine = variant.id == generalVariantId

        ? ''

        : '\n- Regional flavor: ${variant.label}\n- ${variant.promptLine}';

    return '''

LYRIC DIALECT MODE (USER-SELECTED — NON-NEGOTIABLE):

- Mode: ${opt.label}

- ${opt.promptLine}$variantLine

- Apply LAYER 4.5 Nigerian Pidgin Dialect Module (system prompt). Stage 3 humanization must write natively in this dialect.

- Stage 5 compression: preserve Pidgin grammar — do NOT normalize to standard English.

'''.trim();

  }



  /// Post-process context for theme / humanize / compress passes.

  static String postProcessContextLine(

    String? dialectStyleId, {

    String? dialectVariantId,

  }) {

    final opt = optionForId(coerceId(dialectStyleId));

    if (opt == null || opt.id == standardEnglishId) return '';

    final variant = variantForId(coerceVariantId(dialectVariantId))!;

    final variantSuffix = variant.id == generalVariantId

        ? ''

        : ' · ${variant.label}: ${variant.promptLine}';

    return 'LYRIC DIALECT (NON-NEGOTIABLE — preserve in all lyric lines): ${opt.label}$variantSuffix — ${opt.promptLine}';

  }

  static String postProcessCompactLine(
    String? dialectStyleId, {
    String? dialectVariantId,
  }) {
    if (!isNigerianPidgin(dialectStyleId)) return '';
    final variant = coerceVariantId(dialectVariantId);
    final variantSuffix =
        variant == generalVariantId ? '' : '|variant:$variant';
    return 'DIALECT:pidgin|preserve dey/na/wahala|no normalize$variantSuffix';
  }

}



enum LyricLanguageMode {

  standardEnglish,

  nigerianPidgin,

}



extension LyricLanguageModeIds on LyricLanguageMode {

  String get dialectStyleId => switch (this) {

        LyricLanguageMode.standardEnglish =>

          DialectStyleData.standardEnglishId,

        LyricLanguageMode.nigerianPidgin =>

          DialectStyleData.nigerianPidginId,

      };



  static LyricLanguageMode fromDialectStyleId(String? id) =>

      DialectStyleData.isNigerianPidgin(id)

          ? LyricLanguageMode.nigerianPidgin

          : LyricLanguageMode.standardEnglish;

}



class DialectStyleOption {

  const DialectStyleOption({

    required this.id,

    required this.label,

    required this.promptLine,

  });



  final String id;

  final String label;



  /// Injected into Stage 3 (lyricist) and Stage 5 (compression) workflow.

  final String promptLine;

}



class DialectVariantOption {

  const DialectVariantOption({

    required this.id,

    required this.label,

    required this.promptLine,

  });



  final String id;

  final String label;

  final String promptLine;

}


