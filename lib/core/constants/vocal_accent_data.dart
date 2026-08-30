import 'dialect_style_data.dart';



/// One accent entry — key, UI label, and Layer 1 descriptor set stay aligned.

class AccentOption {

  final String key;

  final String label;

  final String description;



  /// When set, used in the top-level accent dropdown instead of [label].

  final String? topLevelLabel;



  const AccentOption({

    required this.key,

    required this.label,

    required this.description,

    this.topLevelLabel,

  });

}



/// Preset **singing / rap delivery accents** (pronunciation & cadence — style only, not voice cloning).

///

/// Stored values are machine keys consumed by **STAGING AND ACCENT RULES — Section B**

/// (`user_selected_accent`). Display labels are UI-only.

class VocalAccentData {

  VocalAccentData._();



  static const accentVsDialectConstraint =

      'ACCENT VS. DIALECT CONSTRAINT: When a regional accent or delivery style is specified, '

      'write lyrics in clear, standard English. You are strictly forbidden from translating '

      'text into slang, broken dialects, or patois (completely ban words like dey, na, wahala, '

      'gonna in lyric lines). Let vocal performance style remain purely phonetic in staging '

      'tags; the written lyric text must stay pristine, high-end, and universally legible.';



  static const regionalTagDedupConstraint =

      'ZERO REGIONAL TAG DUPLICATION: Regional delivery modifiers, vocal textures, or accent '

      'descriptors must appear once per section inside the single staging bracket — never '

      'repeat the same regional/accent phrase across consecutive brackets, section headers, '

      'or lyric lines. Block 1 carries primary vocal-accent prose; Block 2 tags reference '

      'delivery phonetically without re-stacking identical regional labels every section.';



  /// Single source of truth — Layer 1 descriptors must stay aligned with

  /// tools/staging_and_accent_rules.txt §B.

  static const List<AccentOption> accentOptions = [

    AccentOption(

      key: 'american',

      label: 'American',

      description:

          'polished vocal, bright EQ, vocal-forward mix, glossy doubles, warm chest lead, pop-radio sheen',

    ),

    AccentOption(

      key: 'british',

      label: 'British',

      description:

          'dry room close-mic, jangly vocal, mid-Atlantic pop tone, restrained belt, minimal plate reverb',

    ),

    AccentOption(

      key: 'irish',

      label: 'Irish',

      description:

          'warm room vocal, folk-leaning lead, intimate delivery, slight cadence lilt, sparse room',

    ),

    AccentOption(

      key: 'nigerian',

      label: 'Lagos / Standard',

      topLevelLabel: 'Nigerian',

      description:

          'Afrobeats vocal pocket, Lagos pop mix, warm midrange, conversational cadence, Yoruba-staccato undertone, syncopated vowel pacing, glossy vocal-forward mix',

    ),

    AccentOption(

      key: 'nigerian_rivers_state',

      label: 'Rivers State (Harbour Pidgin)',

      description:

          'hard consonant treatment, clipped syllable endings, tight rhythmic pocket, Niger Delta rap tone, Harbour Pidgin pacing, vocal-forward gritty mix, fast consonant-to-consonant transitions, minimal vowel elongation, oil-city delivery weight',

    ),

    AccentOption(

      key: 'nigerian_igbo',

      label: 'Igbo Pidgin',

      description:

          'tonal percussive delivery, sharp pitch contours on vowels, Igbo Pidgin cadence, staccato vocal pocket, percussive consonants, Eastern highlife warmth, vocal-forward mix with tight midrange presence, pitch-rise phrase endings, rhythmic consonant clusters',

    ),

    AccentOption(

      key: 'nigerian_ibibio',

      label: 'Ibibio / Akwa Ibom State (Recommended)',

      description:

          'triplet-feel vocal pocket, Cross-river coastal cadence, soft consonant treatment, melodic terminal rise, open vowel phrasing, maritime lyrical swing, flowing triplet flow, Akwa Ibom vocal warmth, musical terminal elongation, Cross-river melodic lilt, breathy close-mic intimacy on verses, rising intonation on statement endings, Ibibio cadence signature',

    ),

    AccentOption(

      key: 'west_african',

      label: 'West African',

      description:

          'syncopated vocal pocket, call-and-response texture, coastal pop mix, rhythmic lead',

    ),

    AccentOption(

      key: 'south_african',

      label: 'South African',

      description:

          'Amapiano vocal stack, chantable delivery, warm log-drum-friendly pocket, wide harmonies',

    ),

    AccentOption(

      key: 'australian',

      label: 'Australian',

      description:

          'dry-room close-mic, relaxed indie vocal, warm lead, laid-back belt, minimal verb',

    ),

    AccentOption(

      key: 'canadian',

      label: 'Canadian',

      description:

          'polished vocal, soft consonants, vocal-forward, bright mix, warm chest lead',

    ),

    AccentOption(

      key: 'caribbean',

      label: 'Caribbean',

      description:

          'Dancehall vocal pocket, sharp consonants, rhythmic lead, reverb tails, dub-friendly space',

    ),

    AccentOption(

      key: 'latin_american',

      label: 'Latin American',

      description:

          'warm intimate vocal, Spanish consonant treatment, breathy belt, close-mic, romantic sheen',

    ),

  ];



  /// All canonical accent keys (persistence + routing).

  static final List<String?> dropdownValues = [

    null,

    ...accentOptions.map((opt) => opt.key),

  ];



  /// Top-level accent picker (Nigerian sub-regions chosen separately).

  static final List<String?> topLevelDropdownValues = [

    null,

    ...accentOptions

        .where(

          (opt) => opt.key == 'nigerian' || !opt.key.startsWith('nigerian_'),

        )

        .map((opt) => opt.key),

  ];



  static final List<String> nigerianSubAccentValues = accentOptions

      .where((opt) => opt.key.startsWith('nigerian'))

      .map((opt) => opt.key)

      .toList(growable: false);



  /// Sub-regions only — excludes top-level [nigerian] (Lagos / Standard).

  static List<String> get nigerianRegionalAccentValues =>

      nigerianSubAccentValues.where((k) => k != 'nigerian').toList(growable: false);



  /// Default when user picks Nigerian without choosing a region.

  static const String defaultNigerianSubAccent = 'nigerian_ibibio';



  static const Map<String, String> _legacyKeyAliases = {

    'West African (Nigeria)': 'nigerian',

    'West African (Ghana)': 'west_african',

    'West African (general)': 'west_african',

    'Caribbean': 'caribbean',

    'American (General)': 'american',

    'American (Southern)': 'american',

    'British (England)': 'british',

    'Scottish': 'british',

    'Irish': 'irish',

    'Australian / New Zealand': 'australian',

    'Indian English': 'american',

    'French English': 'british',

    'Spanish / Latin American English': 'latin_american',

    'South African English': 'south_african',

    'East African (general)': 'west_african',

  };



  static AccentOption? optionFor(String? key) {

    if (key == null || key.isEmpty) return null;

    for (final opt in accentOptions) {

      if (opt.key == key) return opt;

    }

    return null;

  }



  static String menuLabel(String? value) {

    if (value == null || value.isEmpty) {

      return 'Not specified — infer from genre & language';

    }

    return optionFor(value)?.label ?? value;

  }



  static String topLevelMenuLabel(String? value) {

    if (value == null || value.isEmpty) {

      return 'Not specified — infer from genre & language';

    }

    final opt = optionFor(value);

    if (opt == null) return value;

    return opt.topLevelLabel ?? opt.label;

  }



  static String nigerianRegionMenuLabel(String key) => menuLabel(key);



  /// Layer 1 descriptor prose for UI tooltips and prompt injection.

  static String descriptionFor(String? accentKey) =>

      layer1DescriptorFor(accentKey);



  /// Split persisted accent into top-level UI + Nigerian sub-region.

  static ({String? topLevel, String? nigerianSub}) splitForUi(String? stored) {

    final key = coerceStored(stored);

    if (key == null) return (topLevel: null, nigerianSub: null);

    if (isNigerianFamily(key)) {
      if (key == 'nigerian') {
        return (topLevel: 'nigerian', nigerianSub: null);
      }
      return (topLevel: 'nigerian', nigerianSub: key);
    }

    return (topLevel: key, nigerianSub: null);

  }



  /// Resolve accent key written to [UserInputModel] from UI state.

  static String? resolveEffectiveAccent({
    required String? topLevel,
    required String? nigerianSub,
    bool useNigerianSubRegion = false,
  }) {
    final top = coerceStored(topLevel);
    if (top == null || top.isEmpty) return null;
    if (top == 'nigerian') {
      if (!useNigerianSubRegion) return 'nigerian';
      final sub = coerceStored(nigerianSub) ?? defaultNigerianSubAccent;
      return nigerianRegionalAccentValues.contains(sub)
          ? sub
          : defaultNigerianSubAccent;
    }
    return top;
  }



  /// Normalize persisted UI values to canonical accent keys.

  static String? coerceStored(String? raw) {

    if (raw == null || raw.isEmpty) return null;

    if (optionFor(raw) != null) return raw;

    return _legacyKeyAliases[raw];

  }



  static String? canonicalKey(String? raw) => coerceStored(raw);



  static String layer1DescriptorFor(String? accentKey) {

    final key = coerceStored(accentKey);

    if (key == null || key.isEmpty) return '';

    return optionFor(key)?.description ?? '';

  }



  static bool isNigerianFamily(String? accentKey) {

    final key = coerceStored(accentKey);

    if (key == null) return false;

    return key.startsWith('nigerian');

  }



  /// Strong user-block directive when an accent is selected (style only — not cloning).

  static String userBlockDirective({

    required String? accent,

    String vocalSpec = '',

    String language = 'English',

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    final key = coerceStored(accent);

    if (key == null || key.isEmpty) return '';

    final selectedOption = optionFor(key);

    if (selectedOption == null) return '';

    final spec = vocalSpec.trim();

    final lang = language.trim().isEmpty ? 'English' : language.trim();

    final specLine = spec.isNotEmpty ? '\n- Lead vocal type: $spec' : '';

    final pidgin = DialectStyleData.isNigerianPidgin(dialectStyleId);

    final descriptors = selectedOption.description;

    final lyricLine = pidgin

        ? '- Block 2 lyrics: Nigerian Pidgin dialect active — use Layer 2 sub-variant vocabulary from STAGING AND ACCENT RULES (Section B) when accent is nigerian_*; never Lagos-default Pidgin when a sub-variant is selected.'

        : '- Block 2 lyrics: English only — accent is production delivery via Layer 1 descriptors in staging, NOT nationality adjectives or raw accent labels in brackets.';

    return '''

VOCAL ACCENT / DELIVERY (USER-SELECTED — NON-NEGOTIABLE):

- user_selected_accent: $key

- Display label (internal only): ${menuLabel(key)}

- STAGING AND ACCENT RULES — Section B (mandatory): inject Layer 1 descriptor set below into Block 1 vocal prose and Block 2 staging brackets. **BANNED:** raw forms like "American vocal", "British delivery", "Nigerian breath", "Ibibio stack", "Rivers State lead".

- Layer 1 descriptor set: $descriptors

- Language context: $lang$specLine

- Block 1: Weave the Layer 1 descriptor set into vocal production prose (style/delivery only — never impersonate a real person). Do not print the accent key or nationality adjective in user output.

- Block 2 staging: Use ONLY the Layer 1 descriptor tokens in section staging brackets — never duplicate nationality labels per section.

$lyricLine

- Preserve singability; accent is delivery style, not a dialect caricature.

'''.trim();

  }



  /// Post-process context for theme / humanize / compress passes.

  static String postProcessContextLine(

    String? accent, {

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    final key = coerceStored(accent);

    if (key == null || key.isEmpty) return '';

    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {

      return 'VOCAL ACCENT (Layer 1 descriptors only): $key — lyric dialect is Nigerian Pidgin.';

    }

    return 'VOCAL ACCENT (Layer 1 descriptors only — lyrics stay standard English): $key';

  }



  static String accentVsDialectConstraintLine(

    String? accent, {

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    if ((coerceStored(accent) ?? '').isEmpty) return '';

    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) return '';

    return accentVsDialectConstraint;

  }



  static String regionalTagDedupConstraintLine({

    String? accent,

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    if ((coerceStored(accent) ?? '').isEmpty &&

        !DialectStyleData.isNigerianPidgin(dialectStyleId)) {

      return '';

    }

    return regionalTagDedupConstraint;

  }



  static String postProcessCompactLine(

    String? accent, {

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    final key = coerceStored(accent);

    if (key == null || key.isEmpty) return '';

    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {

      return 'ACCENT:$key|layer1-descriptors-only|lyrics=Pidgin';

    }

    return 'ACCENT:$key|layer1-descriptors-only|lyrics=standard English';

  }



  static String accentVsDialectCompactLine(

    String? accent, {

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    if ((coerceStored(accent) ?? '').isEmpty) return '';

    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) return '';

    return 'RULE:accent-only|lyrics=standard English|no dey/na/wahala in lines';

  }



  static String regionalTagDedupCompactLine({

    String? accent,

    String dialectStyleId = DialectStyleData.standardEnglishId,

  }) {

    if ((coerceStored(accent) ?? '').isEmpty &&

        !DialectStyleData.isNigerianPidgin(dialectStyleId)) {

      return '';

    }

    return 'RULE:regional-tag-once|layer1-descriptors-once-per-section';

  }

}


