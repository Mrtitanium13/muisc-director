import 'genre_data.dart';

/// Dropdown presets for prompt form flow (mood, tone, era, language, BPM).
/// Optimized to align with Platinum Songwriting Engine v4.0.
class PromptFlowData {
  PromptFlowData._();

  static const String customOption = '__custom__';
  static const String customLabel = 'Custom';

  /// Part A — emotional tone (Block 1 mood lane).
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
    customLabel,
  ];

  /// Era / scene anchor (woven into vibe string for architectural style direction).
  static const List<String> eraScenes = [
    'Modern club/streaming',
    'Golden-era boom bap',
    '2010s Afrobeats wave',
    'Modern Amapiano lounge',
    'Afterlife Melodic Techno vibe',
    'Festival Hardstyle Mainstage',
    'Modern Praise & Worship',
    '2020s Saigon Pop',
    '90s Detroit techno',
    'Mid-2000s UK Funky',
    'Late-70s disco',
    'Early-80s boogie',
    '2000s Nashville',
    'Dark plugg mood',
    'Authentic Amapiano',
    'High-energy Vinahouse',
    'Urban Latin Pop',
    'Polished modern country',
    customLabel,
  ];

  /// Vocal timbre / delivery presets (Part A vocal character / processing mix).
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
    'Vocal Chants Only',
    'Twang-forward',
    'Unison Stacks',
    customLabel,
  ];

  /// Groove feels designed to match structural rhythmic quantization targets.
  static const List<String> grooveFeels = [
    'Four-on-the-floor',
    'Triplet rolling bass',
    'Syncopated log-drum',
    'Half-time feel',
    'Swung 16ths',
    'Shuffled hats',
    'Driving loops',
    'Hypnotic grid',
    'Pumping sidechain',
    'Sliding 808s',
    'Log drum bounce',
    'Offbeat bounce grooves',
    'Dem bow drum grid',
    'Acoustic strum pocket',
    customLabel,
  ];

  /// Supported languages including essential regional vernacular keys.
  static const List<String> languages = [
    'English',
    'Nigerian Pidgin-English',
    'Zulu / Xhosa',
    'Yoruba / Igbo',
    'Efik / Ibibio',
    'Spanish',
    'French',
    'Portuguese',
    'Korean',
    'Japanese',
    'Mandarin Chinese',
    'Vietnamese',
    'Hindi',
    'Arabic',
    'Swahili',
    'Zulu',
    'Xhosa',
    'Pidgin',
    'Instrumental (no lyrics)',
    customLabel,
  ];

  static const List<int> defaultBpmPresets = [
    72,
    76,
    85,
    88,
    94,
    95,
    102,
    108,
    110,
    112,
    115,
    118,
    124,
    128,
    132,
    138,
    140,
    150,
    160,
    174,
  ];

  /// Suggested BPM integers extracted from genre metadata.
  static List<int> bpmSuggestionsForGenre(String? genreLabel) {
    final hint = GenreData.bpmHintForLabel(genreLabel);
    if (hint == null || hint.isEmpty) {
      return defaultBpmPresets;
    }

    final nums = RegExp(r'\d{2,3}')
        .allMatches(hint)
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList();

    if (nums.isEmpty) return defaultBpmPresets;
    if (nums.length == 1) return [nums[0]];

    final lo = nums.reduce((a, b) => a < b ? a : b);
    final hi = nums.reduce((a, b) => a > b ? a : b);
    if (lo == hi) return [lo];

    final mid = ((lo + hi) / 2).round();
    return {lo, mid, hi}.toList()..sort();
  }

  static String? _matchInList(String value, List<String> options) {
    final lower = value.toLowerCase().trim();
    if (lower == customOption.toLowerCase() || lower == customLabel.toLowerCase()) {
      return customLabel;
    }
    for (final o in options) {
      if (o.toLowerCase().trim() == lower) return o;
    }
    return null;
  }

  /// Split a stored vibe into dropdown fields + fallback free text.
  static ({String? mood, String? era, String? groove, String detail})
      parseStoredVibe(String raw) {
    if (raw.trim().isEmpty) {
      return (mood: null, era: null, groove: null, detail: '');
    }

    final parts = raw
        .split(RegExp(r'\s*[·,;:\n]\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return (mood: null, era: null, groove: null, detail: raw.trim());
    }

    String? mood;
    String? era;
    String? groove;
    final leftovers = <String>[];

    for (final p in parts) {
      final m = _matchInList(p, moodTones);
      if (mood == null && m != null && m != customLabel) {
        mood = m;
        continue;
      }
      final e = _matchInList(p, eraScenes);
      if (era == null && e != null && e != customLabel) {
        era = e;
        continue;
      }
      final g = _matchInList(p, grooveFeels);
      if (groove == null && g != null && g != customLabel) {
        groove = g;
        continue;
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

  static String composeVibe({
    String? mood,
    String? era,
    String? groove,
    String detail = '',
  }) {
    final out = <String>[
      if (mood != null && mood.isNotEmpty && mood != customLabel) mood.trim(),
      if (era != null && era.isNotEmpty && era != customLabel) era.trim(),
      if (groove != null && groove.isNotEmpty && groove != customLabel) groove.trim(),
      if (detail.trim().isNotEmpty) detail.trim(),
    ];
    return out.join(' · ');
  }

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
    if (preset == null || preset.isEmpty || preset == customOption || preset == customLabel) {
      return customText.trim();
    }
    return preset;
  }

  static String languageForCommit({
    required String? preset,
    required String customText,
  }) {
    if (preset == null || preset.isEmpty || preset == customOption || preset == customLabel) {
      final t = customText.trim();
      return t.isEmpty ? 'English' : t;
    }
    return preset;
  }
}
