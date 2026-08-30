import 'package:flutter/foundation.dart';

import 'genre_data.dart';

// ────────────────────────── Dropdown option model ──────────────────────────

@immutable
final class Option {
  const Option({
    required this.value,
    required this.label,
    this.tags = const <String>[],
  });

  final String value;
  final String label;
  final List<String> tags;

  bool get isCustom => value == PromptFlowData.customOption;

  @override
  String toString() => 'Option($value: $label)';
}

/// Back-compat alias for older call sites.
typedef PromptFlowOption = Option;

// ────────────────────────── Prompt flow data ──────────────────────────

/// Dropdown presets for prompt form flow (mood, tone, era, language, BPM).
/// Optimized to align with Platinum Songwriting Engine v4.0+.
abstract final class PromptFlowData {
  PromptFlowData._();

  static const String customOption = '__custom__';
  static const String customLabel = 'Custom';

  // ────────────────────────── Mood tones ──────────────────────────

  static const List<String> moodTones = [
    'Euphoric',
    'Kinetic',
    'Hypnotic',
    'Brooding',
    'Yearning',
    'Defiant',
    'Meditative',
    'Frenetic',
    'Sensual',
    'Anthemic',
    'Introspective',
    'Dark',
    'Joyful',
    'Melancholic',
    'Cyberpunk',
    'Existential',
    'Aggressive',
    'Triumphant',
    'Rustic',
    'Nostalgic',
    'Rebellious',
    'Vulnerable',
    'Empowered',
    'Seductive',
    'Playful',
    'Bittersweet',
    'Dreamy',
    'Wistful',
    'Hopeful',
    'Tense',
    'Cinematic',
    customLabel,
  ];

  // ────────────────────────── Groove feels ──────────────────────────

  static const List<String> _defaultGrooveFeels = [
    'Standard 4/4',
    'Relaxed',
    'Driving',
    'Swung',
    'Syncopated',
    'Shuffle',
    'Half-time feel',
    customLabel,
  ];

  static const Map<String, List<String>> _grooveFeelsByFamily = {
    GenreFamily.defaultKey: _defaultGrooveFeels,
    GenreFamily.edm: [
      'Four-on-the-floor',
      'Breakbeat',
      'Driving trance gate',
      'Pounding hardstyle kick',
      'Hypnotic grid',
      'Pumping sidechain',
      'Half-time feel',
      'Rolling bassline',
      'Stutter groove',
      'Uplifting build',
      customLabel,
    ],
    GenreFamily.dnb: [
      'Breakbeat',
      'Amen chop feel',
      'Rolling sub-bass drive',
      'Half-time DnB',
      'Liquid roller',
      customLabel,
    ],
    GenreFamily.hardstyle: [
      'Pounding hardstyle kick',
      'Reverse-bass pump',
      'Festival mainstage drive',
      'Euphoric build energy',
      'Rawstyle kick drive',
      customLabel,
    ],
    GenreFamily.hiphop: [
      'Boom-bap',
      'Trap hi-hat rolls',
      'Swung Dilla feel',
      'Laid-back G-funk',
      'Sliding 808s',
      'Half-time feel',
      'Drill bounce',
      'Jersey club kick pattern',
      'Memphis pocket',
      customLabel,
    ],
    GenreFamily.amapiano: [
      'Syncopated log-drum',
      'Log drum bounce',
      'Offbeat bounce grooves',
      'Shuffled hats',
      'Private school piano glide',
      customLabel,
    ],
    GenreFamily.afrobeats: [
      'Syncopated log-drum',
      'Offbeat bounce grooves',
      'Talking drum pocket',
      'Driving loops',
      'Highlife guitar pocket',
      customLabel,
    ],
    GenreFamily.jazz: [
      'Swing',
      'Latin feel (Bossa/Samba)',
      'Ballad feel',
      'Walking bassline',
      'Swung 16ths',
      'Modal jazz float',
      customLabel,
    ],
    GenreFamily.rock: [
      'Driving rock beat',
      'Half-time shuffle',
      'Punk rock energy',
      'Power ballad',
      'Acoustic strum pocket',
      'Double-kick thrash',
      customLabel,
    ],
    GenreFamily.country: [
      'Acoustic strum pocket',
      'Two-step country swing',
      'Gospel country lift pocket',
      'Driving rock beat',
      'Train beat',
      customLabel,
    ],
    GenreFamily.gospel: [
      'Call-and-response pocket',
      'Worship lift build',
      'Gospel country lift pocket',
      'Ballad feel',
      'Clap-along praise pocket',
      customLabel,
    ],
    GenreFamily.latin: [
      'Dem bow drum grid',
      'Salsa clave pocket',
      'Bachata romantic sway',
      'Offbeat bounce grooves',
      'Cumbia guacharaca pulse',
      'Merengue tambora drive',
      'Baile funk bounce',
      'Reggaeton perreo pocket',
      customLabel,
    ],
    GenreFamily.pop: [
      'Four-on-the-floor',
      'Driving loops',
      'Half-time feel',
      'Standard 4/4',
      'Trap-pop pocket',
      customLabel,
    ],
    GenreFamily.rnb: [
      'Slow jam pocket',
      'Bouncy 808/R&B',
      'Two-step',
      'Trap-soul groove',
      'Half-time feel',
      customLabel,
    ],
    GenreFamily.cinematic: [
      'Ballad feel',
      'Driving loops',
      'Half-time feel',
      'Relaxed',
      'Epic crescendo pulse',
      customLabel,
    ],
    GenreFamily.reggae: [
      'One drop',
      'Steppers',
      'Rockers',
      'Offbeat skank',
      customLabel,
    ],
    GenreFamily.funk: [
      'Pocket',
      'Four-on-the-floor funk',
      'Swung 16ths',
      'Slap bass bounce',
      customLabel,
    ],
    GenreFamily.soul: [
      'Slow 6/8 feel',
      'Shuffle',
      'Backbeat pocket',
      'Ballad feel',
      customLabel,
    ],
    GenreFamily.blues: [
      'Shuffle',
      'Slow blues',
      'Boogie',
      'Walking bassline',
      customLabel,
    ],
    GenreFamily.folk: [
      'Fingerpick pocket',
      'Strum-forward',
      'Waltz feel',
      'Ballad feel',
      customLabel,
    ],
    GenreFamily.electronicExperimental: [
      'Glitch stutter',
      'Ambient drift',
      'Industrial grid',
      'IDM breakbeat',
      customLabel,
    ],
  };

  // ────────────────────────── Era / scene presets ──────────────────────────

  static const List<String> _defaultEraScenes = [
    'Modern club/streaming',
    'Late-night studio session',
    'Festival main stage',
    'Intimate bedroom session',
    'DIY basement session',
    customLabel,
  ];

  static const Map<String, List<String>> _eraScenesByFamily = {
    GenreFamily.defaultKey: _defaultEraScenes,
    GenreFamily.edm: [
      'Modern club/streaming',
      'Afterlife Melodic Techno vibe',
      'Festival Hardstyle Mainstage',
      '90s Detroit techno',
      'Late-70s disco',
      'Early-80s boogie',
      'Mid-2000s UK Funky',
      'Ibiza sunrise set',
      'Warehouse rave',
      customLabel,
    ],
    GenreFamily.dnb: [
      '90s jungle warehouse',
      'Liquid lounge session',
      'Festival bass tent',
      'Modern club/streaming',
      customLabel,
    ],
    GenreFamily.hardstyle: [
      'Festival Hardstyle Mainstage',
      'Defqon.1-style arena',
      'European rave heritage',
      'Rawstyle underground',
      customLabel,
    ],
    GenreFamily.hiphop: [
      'Golden-era boom bap',
      'Dark plugg mood',
      'Modern trap streaming era',
      '90s West Coast cruise',
      'Drill street cipher',
      'Underground SoundCloud era',
      'Memphis phonk tape era',
      customLabel,
    ],
    GenreFamily.amapiano: [
      'Modern Amapiano lounge',
      'Authentic Amapiano',
      'Johannesburg late-night',
      'Yanos outdoor groove',
      customLabel,
    ],
    GenreFamily.afrobeats: [
      '2010s Afrobeats wave',
      'Lagos rooftop session',
      'High-energy Vinahouse',
      'Accra beach party',
      'Afro-fusion studio',
      customLabel,
    ],
    GenreFamily.jazz: [
      'Smoky late-night lounge',
      'Blue Note era intimacy',
      'Modern jazz club',
      'Speakeasy vinyl session',
      customLabel,
    ],
    GenreFamily.rock: [
      'Garage rehearsal room',
      'Stadium rock legacy',
      'Indie basement show',
      'Modern arena rock',
      customLabel,
    ],
    GenreFamily.country: [
      '2000s Nashville',
      'Polished modern country',
      'Gospel Country Lift',
      'Front-porch acoustic',
      'Texas honky-tonk',
      customLabel,
    ],
    GenreFamily.gospel: [
      'Modern Praise & Worship',
      'Soulful prayerful testimony',
      'Afro-Gospel worship',
      'Church sanctuary live',
      'Stadium worship night',
      customLabel,
    ],
    GenreFamily.latin: [
      'Urban Latin Pop',
      'Caribbean street party',
      'Romantic bachata night',
      'Salsa club',
      'Reggaeton block party',
      'Baile funk favela party',
      customLabel,
    ],
    GenreFamily.pop: [
      'Modern club/streaming',
      '2020s Saigon Pop',
      'Radio hit polish era',
      'Bedroom pop',
      'Stadium pop',
      customLabel,
    ],
    GenreFamily.rnb: [
      '90s slow jam',
      'Modern trap-soul bedroom',
      'Smooth neo-soul lounge',
      '00s crunk&B club',
      customLabel,
    ],
    GenreFamily.cinematic: [
      'Film trailer climax',
      'Orchestral scoring stage',
      'Epic game soundtrack mood',
      'Intimate indie film cue',
      customLabel,
    ],
    GenreFamily.reggae: [
      'Jamaican sound system',
      'Roots reggae studio',
      'Modern dancehall yard',
      'Beach sunset session',
      customLabel,
    ],
    GenreFamily.funk: [
      '70s P-Funk jam room',
      'Modern funk revival',
      'Gogo pocket',
      customLabel,
    ],
    GenreFamily.soul: [
      'Motown studio',
      'Memphis soul room',
      'Modern soul lounge',
      customLabel,
    ],
    GenreFamily.blues: [
      'Delta porch',
      'Chicago blues club',
      'Modern blues bar',
      customLabel,
    ],
    GenreFamily.folk: [
      'Front porch session',
      'Coffeehouse open mic',
      'Appalachian cabin',
      customLabel,
    ],
    GenreFamily.electronicExperimental: [
      'Modular synth lab',
      'Berghain basement',
      'Experimental radio room',
      customLabel,
    ],
  };

  // ────────────────────────── Vocal tones ──────────────────────────

  static const List<String> vocalTones = [
    'Intimate close-mic',
    'Rhythmic sung-rap',
    'Call-and-response',
    'Ethereal reverb wash',
    'Pitched-down processed',
    'Belted vocal stack',
    'Cinematic spoken word',
    'Breathy',
    'Husky',
    'Raspy',
    'Velvety',
    'Warm',
    'Piercing',
    'Gritty',
    'Airy',
    'Whispered',
    'Sharp autotuned transients',
    'Twang-forward',
    'Chopped vocal',
    'Ad-lib heavy',
    'Soulful run-heavy',
    'Conversational',
    'Distant room mic',
    'Double-tracked intimacy',
    'Distorted vocal',
    'Falsetto airy',
    customLabel,
  ];

  // ────────────────────────── Languages ──────────────────────────

  static const List<String> languages = [
    'English',
    'Nigerian Pidgin-English',
    'Zulu / Xhosa',
    'Yoruba / Igbo',
    'Efik / Ibibio',
    'Twi / Akan',
    'Ga',
    'Shona',
    'Swahili',
    'Spanish',
    'French',
    'Portuguese',
    'Korean',
    'Japanese',
    'Mandarin Chinese',
    'Vietnamese',
    'Hindi',
    'Arabic',
    'Tamil',
    'Bengali',
    'Tagalog',
    'Pidgin',
    'Instrumental (no lyrics)',
    customLabel,
  ];

  // ────────────────────────── BPM presets ──────────────────────────

  /// Numeric BPM presets. Custom is [customOption] — always appended by
  /// [bpmDropdownValuesForGenre] (cannot live in a [List<int>]).
  static const List<int> defaultBpmPresets = [
    60,
    65,
    68,
    72,
    76,
    80,
    85,
    88,
    90,
    94,
    95,
    98,
    102,
    105,
    108,
    110,
    112,
    115,
    118,
    120,
    124,
    128,
    130,
    132,
    138,
    140,
    145,
    150,
    155,
    160,
    165,
    170,
    174,
    180,
  ];

  /// BPM dropdown values: genre suggestions (or defaults) + Custom sentinel.
  static List<String> bpmDropdownValuesForGenre(String? genreLabel) => [
        for (final n in bpmSuggestionsForGenre(genreLabel)) '$n',
        customOption,
      ];

  // ────────────────────────── Precomputed unions ──────────────────────────

  static final List<String> _allGrooveFeels =
      _dedupe(_grooveFeelsByFamily.values);
  static final List<String> _allEraScenes = _dedupe(_eraScenesByFamily.values);

  static List<String> _dedupe(Iterable<List<String>> lists) {
    final seen = <String>{};
    return [
      for (final list in lists)
        for (final item in list)
          if (seen.add(item)) item,
    ];
  }

  // ────────────────────────── Dropdown option getters ──────────────────────────

  static List<Option> get moodToneOptions => _toOptions(moodTones);

  static List<Option> get vocalToneOptions => _toOptions(vocalTones);

  static List<Option> get languageOptions => _toOptions(languages);

  static List<Option> grooveOptionsForGenre(String? genreFamily) =>
      _toOptions(getGrooveFeelsForGenre(genreFamily));

  static List<Option> eraOptionsForGenre(String? genreFamily) =>
      _toOptions(getEraScenesForGenre(genreFamily));

  static List<Option> bpmOptionsForGenre(String? genreLabel) =>
      List<Option>.unmodifiable([
        for (final v in bpmDropdownValuesForGenre(genreLabel))
          Option(
            value: v,
            label: v == customOption ? customLabel : '$v BPM',
          ),
      ]);

  static Option? findOptionByValue(List<Option> options, String value) {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  static List<Option> _toOptions(List<String> labels) => List<Option>.unmodifiable([
        for (final l in labels)
          Option(
            value: l == customLabel ? customOption : l,
            label: l,
          ),
      ]);

  // ────────────────────────── Genre family resolution ──────────────────────────

  static String resolveVibeGenreFamily({
    String? primaryGenre,
    String? fusionGenre,
  }) {
    final blob = '${primaryGenre ?? ''} ${fusionGenre ?? ''}'.trim();
    if (blob.isEmpty) return GenreFamily.defaultKey;
    return GenreFamily.resolve(blob) ?? GenreFamily.defaultKey;
  }

  // ────────────────────────── Dropdown getters ──────────────────────────

  /// Back-compat: default groove list (genre-agnostic fallback).
  static List<String> get grooveFeels =>
      getGrooveFeelsForGenre(GenreFamily.defaultKey);

  /// Back-compat: union of all era options for legacy parsers.
  static List<String> get eraScenes => _allEraScenes;

  static List<String> getGrooveFeelsForGenre(String? genreFamily) {
    final family =
        (genreFamily ?? GenreFamily.defaultKey).trim().toLowerCase();
    final source = _grooveFeelsByFamily[family] ??
        _grooveFeelsByFamily[GenreFamily.defaultKey]!;
    return List<String>.unmodifiable(source);
  }

  static List<String> getEraScenesForGenre(String? genreFamily) {
    final family =
        (genreFamily ?? GenreFamily.defaultKey).trim().toLowerCase();
    final source = _eraScenesByFamily[family] ??
        _eraScenesByFamily[GenreFamily.defaultKey]!;
    return List<String>.unmodifiable(source);
  }

  // ────────────────────────── Coercion ──────────────────────────

  static String? coerceGrooveForGenre(String? value, String? genreFamily) {
    if (value == null) return null;
    final options = getGrooveFeelsForGenre(genreFamily);
    return options.contains(value) ? value : null;
  }

  static String? coerceEraForGenre(String? value, String? genreFamily) {
    if (value == null) return null;
    final options = getEraScenesForGenre(genreFamily);
    return options.contains(value) ? value : null;
  }

  static String? coerceBpm(String? value, String? genreLabel) {
    if (value == null || value.isEmpty) return null;
    final options = bpmDropdownValuesForGenre(genreLabel);
    return options.contains(value) ? value : customOption;
  }

  // ────────────────────────── BPM suggestions ──────────────────────────

  /// Suggested BPM integers extracted from genre metadata.
  static List<int> bpmSuggestionsForGenre(String? genreLabel) {
    final hint = GenreData.bpmHintForLabel(genreLabel);
    if (hint == null || hint.isEmpty) {
      return defaultBpmPresets;
    }

    final nums = _bpmRegex
        .allMatches(hint)
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList();

    if (nums.isEmpty) return defaultBpmPresets;
    if (nums.length == 1) return List<int>.unmodifiable(nums);

    final lo = nums.reduce((a, b) => a < b ? a : b);
    final hi = nums.reduce((a, b) => a > b ? a : b);
    if (lo == hi) return [lo];

    final mid = ((lo + hi) / 2).round();
    return List<int>.unmodifiable({lo, mid, hi}.toList()..sort());
  }

  static final RegExp _bpmRegex = RegExp(r'\b\d{2,3}\b');

  // ────────────────────────── Vibe parsing / composing ──────────────────────────

  static ({String? mood, String? era, String? groove, String detail})
      parseStoredVibe(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (mood: null, era: null, groove: null, detail: '');
    }

    final parts = trimmed
        .split(_vibeDelimiter)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return (mood: null, era: null, groove: null, detail: trimmed);
    }

    String? mood;
    String? era;
    String? groove;
    final leftovers = <String>[];

    for (final p in parts) {
      if (mood == null) {
        final matched = _matchInList(p, moodTones);
        if (matched != null && matched != customLabel) {
          mood = matched;
          continue;
        }
      }

      if (era == null) {
        final matched = _matchInList(p, _allEraScenes);
        if (matched != null && matched != customLabel) {
          era = matched;
          continue;
        }
      }

      if (groove == null) {
        final matched = _matchInList(p, _allGrooveFeels);
        if (matched != null && matched != customLabel) {
          groove = matched;
          continue;
        }
      }

      leftovers.add(p);
    }

    return (
      mood: mood,
      era: era,
      groove: groove,
      detail: leftovers.isEmpty ? '' : leftovers.join(' · '),
    );
  }

  static final RegExp _vibeDelimiter = RegExp(r'\s*[·,;\n]\s*');

  static String composeVibe({
    String? mood,
    String? era,
    String? groove,
    String detail = '',
  }) {
    final safeDetail = detail.trim().replaceAll(' · ', ' - ');
    final out = <String>[
      if (mood != null && mood.isNotEmpty && mood != customLabel) mood.trim(),
      if (era != null && era.isNotEmpty && era != customLabel) era.trim(),
      if (groove != null && groove.isNotEmpty && groove != customLabel)
        groove.trim(),
      if (safeDetail.isNotEmpty) safeDetail,
    ];
    return out.join(' · ');
  }

  // ────────────────────────── Source-text branching ──────────────────────────

  static const String _sourceTextForLyricsHeader =
      '[SOURCE TEXT FOR LYRICS] (ROLE: Master Lyricist/Storyteller. TASK: The following '
      'text is the raw material. Your goal is to transform its core themes, narrative, '
      'emotions, and imagery into compelling song lyrics. Deconstruct it, rephrase it, '
      'and find the musicality within the prose. STRICTLY FORBIDDEN: Do NOT simply copy '
      'the text verbatim or treat it as a descriptive note. It is the foundational '
      'content for lyrical creation.)';

  static const String _scriptureSourceNote =
      '(NOTE: Source text appears to be scriptural. Maintain a tone of reverence, or '
      'adapt its message into a modern spiritual context, guided by the overall vibe '
      'and genre.)';

  static const String _quotedSourceNote =
      '(NOTE: Source text appears to be a quotation. Preserve its intent while adapting '
      'phrasing into singable lyric form.)';

  static bool looksLikeScripture(String text) =>
      _scriptureRegex.hasMatch(text);

  static bool looksLikeQuotedText(String text) {
    final t = text.trim();
    if (t.length < 4) return false;
    if ((t.startsWith('"') && t.endsWith('"')) ||
        (t.startsWith("'") && t.endsWith("'"))) {
      return true;
    }
    return _quotedRegex.hasMatch(t);
  }

  static final RegExp _scriptureRegex = RegExp(
    r'\b[1-3]?\s?[A-Za-z]+\s\d+[:]\d+\b',
  );
  static final RegExp _quotedRegex = RegExp(r'[“"].+[”"]');

  /// User-block lines for vibe brief vs source-text-for-lyrics branching.
  static List<String> buildVibeUserBlockLines({
    required String vibe,
    required bool useVibeAsLyricSource,
  }) {
    final parts = parseStoredVibe(vibe);
    final vibeDetail = parts.detail.trim();
    final coreVibe = composeVibe(
      mood: parts.mood,
      era: parts.era,
      groove: parts.groove,
    );
    final lines = <String>[];

    if (coreVibe.isNotEmpty) {
      lines.add('[VIBE BRIEF] (Mood · Era/Scene · Groove Feel): $coreVibe');
    } else if (!useVibeAsLyricSource && vibe.trim().isNotEmpty) {
      lines.add(
        '[VIBE BRIEF] (Mood · Era/Scene · Groove Feel · Detail): ${vibe.trim()}',
      );
    }

    if (useVibeAsLyricSource && vibeDetail.isNotEmpty) {
      lines.add(_sourceTextForLyricsHeader);
      if (looksLikeScripture(vibeDetail)) {
        lines.add(_scriptureSourceNote);
      } else if (looksLikeQuotedText(vibeDetail)) {
        lines.add(_quotedSourceNote);
      }
      lines.add(vibeDetail);
    } else if (vibeDetail.isNotEmpty) {
      lines.add('Vibe / idea detail: $vibeDetail');
    }

    return lines;
  }

  // ────────────────────────── Language / vocal coercion ──────────────────────────

  static String? coerceVocalTone(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final matched = _matchInList(raw, vocalTones);
    if (matched == customLabel) return customOption;
    return matched ?? customOption;
  }

  static String? coerceLanguage(String raw) {
    if (raw.trim().isEmpty) return 'English';
    final matched = _matchInList(raw, languages);
    if (matched == customLabel) return customOption;
    return matched ?? customOption;
  }

  static String vocalToneForCommit({
    required String? preset,
    required String customText,
  }) {
    if (preset == null ||
        preset.isEmpty ||
        preset == customOption ||
        preset == customLabel) {
      return customText.trim();
    }
    return preset;
  }

  static String languageForCommit({
    required String? preset,
    required String customText,
  }) {
    if (preset == null ||
        preset.isEmpty ||
        preset == customOption ||
        preset == customLabel) {
      final t = customText.trim();
      return t.isEmpty ? 'English' : t;
    }
    return preset;
  }

  // ────────────────────────── Matching helpers ──────────────────────────

  static String? _matchInList(String value, List<String> options) {
    final lower = value.toLowerCase().trim();
    if (lower == customOption.toLowerCase() ||
        lower == customLabel.toLowerCase()) {
      return customLabel;
    }
    for (final o in options) {
      if (o.toLowerCase().trim() == lower) return o;
    }
    return null;
  }
}

// ────────────────────────── Genre family registry ──────────────────────────

/// Normalized genre family keys and their trigger tokens.
abstract final class GenreFamily {
  GenreFamily._();

  static const String defaultKey = 'default';
  static const String edm = 'edm';
  static const String dnb = 'dnb';
  static const String hardstyle = 'hardstyle';
  static const String hiphop = 'hiphop';
  static const String amapiano = 'amapiano';
  static const String afrobeats = 'afrobeats';
  static const String jazz = 'jazz';
  static const String rock = 'rock';
  static const String country = 'country';
  static const String gospel = 'gospel';
  static const String latin = 'latin';
  static const String pop = 'pop';
  static const String rnb = 'rnb';
  static const String cinematic = 'cinematic';
  static const String reggae = 'reggae';
  static const String funk = 'funk';
  static const String soul = 'soul';
  static const String blues = 'blues';
  static const String folk = 'folk';
  static const String electronicExperimental = 'electronic_experimental';

  static const List<({List<String> tokens, String family})> _rules = [
    (
      tokens: [
        'amapiano',
        'vinahouse',
        'yanos',
        'private school piano',
        'gqom',
      ],
      family: amapiano,
    ),
    (
      tokens: [
        'afrobeat',
        'afrobeats',
        'afro beat',
        'afro house',
        'afrohouse',
        'afro fusion',
        'afro-fusion',
        'highlife',
        'high life',
        'bongo flava',
        'gengetone',
        'afroswing',
        'azonto',
        'coupe decale',
        'coupé décalé',
        'semba',
        'mapouka',
        'kuduro',
        'tarraxinha',
        'singeli',
      ],
      family: afrobeats,
    ),
    (
      tokens: ['gospel', 'worship', 'ccm', 'praise', 'christian'],
      family: gospel,
    ),
    (
      tokens: [
        'country',
        'americana',
        'bluegrass',
        'nashville',
        'honky-tonk',
        'honky tonk',
        'outlaw country',
        'alt country',
        'alternative country',
        'country pop',
        'bro country',
        'red dirt',
        'texas country',
        'country rock',
        'gospel country',
        'country folk',
        'sertanejo',
      ],
      family: country,
    ),
    (
      tokens: [
        'jazz',
        'bebop',
        'bossa nova',
        'bossa',
        'swing jazz',
        'swing',
        'fusion',
        'jazz fusion',
        'smooth jazz',
        'cool jazz',
        'hard bop',
        'modal jazz',
        'free jazz',
        'avant garde jazz',
        'vocal jazz',
        'jazz rap',
        'nu jazz',
        'acid jazz',
        'ethio jazz',
        'ethio-jazz',
        'latin jazz',
      ],
      family: jazz,
    ),
    (
      tokens: [
        'latin',
        'reggaeton',
        'bachata',
        'salsa',
        'cumbia',
        'dembow',
        'merengue',
        'vallenato',
        'tango',
        'latino',
        'baile funk',
        'funk carioca',
        'kompa',
        'zouk',
        'kizomba',
        'bolero',
        'ranchera',
        'mariachi',
        'latin pop',
        'latin rock',
        'latin trap',
        'perreo',
        'guaracha',
        'champeta',
        'afro latino',
        'afro-latino',
        'soca',
        'calypso',
        'moombahton',
        'brega funk',
        'tecno brega',
      ],
      family: latin,
    ),
    (
      tokens: [
        'drum and bass',
        'drum & bass',
        'dnb',
        'jungle',
        'neurofunk',
        'liquid funk',
        'jump up',
        'techstep',
        'atmospheric',
      ],
      family: dnb,
    ),
    (
      tokens: [
        'hardstyle',
        'rawstyle',
        'hard bounce',
        'frenchcore',
        'tekstyle',
        'speedcore',
        'extratone',
        'happy hardcore',
        'uk hardcore',
        'gabber',
      ],
      family: hardstyle,
    ),
    (
      tokens: [
        'house',
        'deep house',
        'tech house',
        'progressive house',
        'electro house',
        'future house',
        'bass house',
        'g house',
        'tropical house',
        'melbourne bounce',
        'electro swing',
        'techno',
        'melodic techno',
        'detroit techno',
        'minimal techno',
        'industrial techno',
        'acid techno',
        'peak time techno',
        'trance',
        'progressive trance',
        'uplifting trance',
        'psytrance',
        'goa trance',
        'big room',
        'festival edm',
        'dubstep',
        'brostep',
        'riddim',
        'melodic dubstep',
        'trap edm',
        'future bass',
        'electro',
        'synthwave',
        'retrowave',
        'outrun',
        'garage',
        'uk garage',
        'future garage',
        'bass music',
        'nu disco',
        'disco',
        'italo disco',
        'french house',
        'indie dance',
        'eurodance',
        'hyperpop',
        'digicore',
        'glitchcore',
        'bubblegum bass',
        'nightcore',
        'future funk',
        'vaporwave',
        'seapunk',
        'wonky',
        'microhouse',
        'minimal',
        'deconstructed club',
        'weightless',
      ],
      family: edm,
    ),
    (
      tokens: [
        'r&b',
        'rnb',
        'rhythm and blues',
        'rhythm & blues',
        'neo soul',
        'neo-soul',
        'neosoul',
        'trap soul',
        'trap-soul',
        'trapsoul',
        'alt r&b',
        'alt rnb',
        'alternative r&b',
        'alternative rnb',
        'pbr&b',
        'pbrnb',
        'contemporary r&b',
        'contemporary rnb',
        'bedroom r&b',
        'afrobeats r&b',
        'latin r&b',
      ],
      family: rnb,
    ),
    (
      tokens: [
        'hip hop',
        'hip-hop',
        'hiphop',
        'rap',
        'trap',
        'drill',
        'brooklyn drill',
        'chicago drill',
        'uk drill',
        'boom bap',
        'boom-bap',
        'phonk',
        'drift phonk',
        'memphis rap',
        'memphis phonk',
        'brazilian phonk',
        'cloud rap',
        'plugg',
        'pluggnb',
        'rage',
        'rage rap',
        'detroit trap',
        'trap metal',
        'emo rap',
        'jerk rap',
        'jersey club',
        'chicago footwork',
        'juke',
        'vogue beat',
        'crunk',
        'hyphy',
        'mumble rap',
        'soundcloud rap',
        'underground hip hop',
        'alternative hip hop',
        'conscious hip hop',
        'grime',
        'uk rap',
        'dancehall rap',
      ],
      family: hiphop,
    ),
    (
      tokens: [
        'rock',
        'indie rock',
        'alternative rock',
        'alt rock',
        'punk',
        'pop punk',
        'emo',
        'screamo',
        'post hardcore',
        'post-hardcore',
        'hardcore punk',
        'metalcore',
        'deathcore',
        'djent',
        'prog rock',
        'progressive rock',
        'psychedelic rock',
        'garage rock',
        'stoner rock',
        'doom metal',
        'black metal',
        'death metal',
        'thrash metal',
        'power metal',
        'symphonic metal',
        'folk metal',
        'nu metal',
        'rap rock',
        'industrial rock',
        'math rock',
        'midwest emo',
        'grunge',
        'shoegaze',
        'britpop',
        'post punk',
        'post-punk',
        'new wave',
        'slowcore',
        'slacker rock',
        'indie sleaze',
        'krautrock',
      ],
      family: rock,
    ),
    (
      tokens: [
        'pop',
        'dance pop',
        'electropop',
        'synthpop',
        'indie pop',
        'dream pop',
        'bedroom pop',
        'hyperpop',
        'art pop',
        'chamber pop',
        'baroque pop',
        'twee pop',
        'sophisti pop',
        'bubblegum pop',
        'k pop',
        'k-pop',
        'kpop',
        'j pop',
        'j-pop',
        'jpop',
        'mandopop',
        'city pop',
        'dark wave',
        'cold wave',
        'darkwave',
        'coldwave',
        'future pop',
        'bhangra',
      ],
      family: pop,
    ),
    (
      tokens: [
        'cinematic',
        'orchestral',
        'film score',
        'trailer',
        'soundtrack',
        'epic',
        'dark ambient',
        'neoclassical',
      ],
      family: cinematic,
    ),
    (
      tokens: [
        'reggae',
        'dancehall',
        'dub',
        'ska',
        'rocksteady',
        'roots reggae',
        'reggae fusion',
        'bashment',
      ],
      family: reggae,
    ),
    (
      tokens: [
        'funk',
        'gogo',
        'p funk',
        'p-funk',
        'funktronica',
        'funk rock',
        'funk soul',
        'psychedelic funk',
        'afro funk',
      ],
      family: funk,
    ),
    (
      tokens: [
        'soul',
        'motown',
        'memphis soul',
        'northern soul',
        'southern soul',
        'psychedelic soul',
        'blue eyed soul',
      ],
      family: soul,
    ),
    (
      tokens: [
        'blues',
        'delta blues',
        'chicago blues',
        'texas blues',
        'electric blues',
        'blues rock',
        'modern blues',
      ],
      family: blues,
    ),
    (
      tokens: [
        'folk',
        'indie folk',
        'singer songwriter',
        'singer-songwriter',
        'appalachian',
        'freak folk',
        'chamber folk',
        'modern folk',
        'folk rock',
        'folk pop',
        'forró',
        'forro',
      ],
      family: folk,
    ),
    (
      tokens: [
        'experimental',
        'idm',
        'glitch',
        'ambient',
        'industrial',
        'modular',
        'noise',
        'experimental electronic',
        'avant garde electronic',
        'breakcore',
        'witch house',
        'mahraganat',
        'electro shaabi',
        'shaabi',
      ],
      family: electronicExperimental,
    ),
  ];

  static final List<({String family, RegExp pattern})> _patterns =
      _buildPatterns();

  static List<({String family, RegExp pattern})> _buildPatterns() => [
        for (final (:tokens, :family) in _rules)
          (
            family: family,
            pattern: RegExp(
              tokens
                  .map(_normalize)
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .map(RegExp.escape)
                  .map(_tokenToPattern)
                  .join('|'),
              caseSensitive: false,
            ),
          ),
      ];

  static String _tokenToPattern(String token) {
    final words = token.split(RegExp(r'\s+'));
    return words.map((w) => r'\b' + w + r'\b').join(r'\s+');
  }

  /// Lowercase + fold accents so `forró` / `coupé` match ASCII word-boundary regexes.
  static String _normalize(String input) {
    final folded = _foldDiacritics(input.toLowerCase());
    return folded
        .replaceAll(RegExp(r'[-/&+]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _foldDiacritics(String input) {
    const pairs = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final unit in input.runes) {
      final ch = String.fromCharCode(unit);
      buffer.write(pairs[ch] ?? ch);
    }
    return buffer.toString();
  }

  static String? resolve(String blob) {
    final normalized = _normalize(blob);
    for (final (:family, :pattern) in _patterns) {
      if (pattern.hasMatch(normalized)) return family;
    }
    return null;
  }
}
