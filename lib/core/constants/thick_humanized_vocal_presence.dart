import 'vocal_spec_tone_data.dart';

/// Resolved vocal presence family.
enum VocalFamily {
  edmDense('EDM Dense / Festival / Hard Dance'),
  hipHop('Hip-Hop / Trap / Boom Bap'),
  gospel('Gospel / Worship'),
  afro('Afro / Amapiano'),
  asianPop('Asian Pop'),
  rnb('R&B / Soul / Neo-Soul'),
  acoustic('Acoustic / Folk / Singer-Songwriter'),
  rock('Rock / Alternative'),
  latin('Latin / Reggaeton'),
  pop('Pop'),
  unknown('Unknown');

  final String displayName;
  const VocalFamily(this.displayName);
}

class _FamilyRule {
  final VocalFamily family;
  final String overlay;
  final List<String> keywords;

  const _FamilyRule(this.family, this.overlay, this.keywords);
}

/// Cross-genre thick / humanized vocal presence for Suno Block 1 + Block 2.
///
/// Stops thin, distant, washed-out leads buried under dense production.
/// Hardstyle hybrid may add denser local sonic profiles on top of this base.
///
/// Examples:
///   detectFamily('Hardstyle', '')                -> VocalFamily.edmDense
///   detectFamilies('Afro House', 'R&B Fusion')   -> [afro, rnb]
///   familyOverlay(vocalSpec: 'Rap Vocal Space')  -> hip-hop overlay
class ThickHumanizedVocalPresence {
  ThickHumanizedVocalPresence._();

  // ---------------------------------------------------------------------------
  // Core directive (always injected when vocals exist)
  // ---------------------------------------------------------------------------

  static const String globalCore = '''
THICK HUMANIZED VOCAL PRESENCE (mandatory — never thin, distant, or buried):
1. PROXIMITY & WEIGHT: Ultra-close-mic intimateness, high-compression proximity effect, detailed chest resonance, audible human breathing dynamics and mouth texture. Lead must read as physically near the capsule — weighty and human, never thin or washed-out.
2. THICKENING: Warm vocal saturation, multi-tracked doubles / formant-aware backing where genre-appropriate, chest-vibrating fundamental body in the low-mids. Prefer organic pitch consistency over glassy robotic thinness.
3. POCKETING & DETACHMENT: Dynamic low-mid separation with a dedicated vocal warmth pocket (~200–300 Hz body). Heavy sidechain ducking on spatial FX and competing beds (not the lead body). Sharp transient isolation. Pristine high-end air boost so the vocal cuts through dense production without becoming harsh.
4. BAN THIN VOCAL ARTIFACTS: Never imply thin, distant, karaoke-wet, buried, or breath-only leads without body. Reject reverb floods that erase proximity. Dense instruments duck around the vocal — never the reverse.
5. BLOCK 1 WEAVE: Embed these descriptors into vocal production prose whenever vocals exist. BLOCK 2: Reflect presence in staging tags (close-mic, doubles, dry pocket, air boost) — do not paste this block as a lyric theme.''';

  // ---------------------------------------------------------------------------
  // Family overlays
  // ---------------------------------------------------------------------------

  static const String edmDenseOverlay = '''
FAMILY OVERLAY — EDM DENSE / FESTIVAL / HARD DANCE:
Cut through supersaw walls, distorted kicks, and hypersaw stacks. Dry, weighty climax/drop mantras in a carved pocket, reinforced with stacked drop-mantra doubles for festival scale. Optional hyper-expanding wet hall washout into a sudden silence/vacuum gap before drop impact — then slam the hook dry and present.''';

  static const String hipHopOverlay = '''
FAMILY OVERLAY — HIP-HOP / TRAP / BOOM BAP:
Forward booth presence, compressed intelligibility over 808s and sample beds. Dry center lead with stacked hook doubles; ad-libs may widen — never drown the lead in distant room.''';

  static const String gospelOverlay = '''
FAMILY OVERLAY — GOSPEL / WORSHIP:
Thick multi-tracked doubles and choir power without losing lead clarity. Close-mic lead tracking; stacks support, never bury.''';

  static const String acousticOverlay = '''
FAMILY OVERLAY — ACOUSTIC / FOLK / SINGER-SONGWRITER:
Intimate near-capsule body and chest warmth without festival vacuum automation. Short natural room only — never distant wash that thins the lead. Optional tasteful chorus doubles for lift.''';

  static const String asianPopOverlay = '''
FAMILY OVERLAY — ASIAN POP (K/J/C/MANDO):
Hyper-polished air and stack density with weighty lead body — never breath-only thinness. Doubles and air sheen must add thickness, not erase proximity.''';

  static const String afroOverlay = '''
FAMILY OVERLAY — AFRO / AMAPIANO:
Mid-forward rhythmic vocal pocket over log-drum and percussion beds. Dry intimate lead with stacked chant layers widening behind the topline; sidechain beds under the vocal — never bury the topline under kick/log-drum.''';

  static const String rnbOverlay = '''
FAMILY OVERLAY — R&B / SOUL / NEO-SOUL:
Velvet chest weight, stacked harmonies that thicken without distance. Warm saturation and close-mic intimacy; plate/short room only — avoid washed-out karaoke reverb.''';

  static const String rockOverlay = '''
FAMILY OVERLAY — ROCK / ALTERNATIVE:
Raw SM7B-style bite and chest grit that sits above distorted guitars. Forward compressed lead, double-tracked for chorus weight; guitars duck slightly on vocal phrases.''';

  static const String latinOverlay = '''
FAMILY OVERLAY — LATIN / REGGAETON / URBANO:
Warm, mid-forward vocal with rhythmic phrase-pocketing over dembow and percussion beds. Crisp consonants and close-mic intimacy; doubles and ad-libs stay dry and present. Never drown the lead in hall reverb — keep vocal body above tropical percussion and brass stabs.''';

  static const String popOverlay = '''
FAMILY OVERLAY — POP / DANCE-POP:
Modern pop vocal chain: weighty lead body, polished air sheen, crisp transient detail. Tuned doubles and stacks add thickness without distance. Short plate/room only; never washed-out or karaoke-thin.''';

  // ---------------------------------------------------------------------------
  // Matching table (order is the default priority for single-family detection)
  // ---------------------------------------------------------------------------

  static const List<_FamilyRule> _rules = [
    _FamilyRule(
      VocalFamily.edmDense,
      edmDenseOverlay,
      [
        'hardstyle',
        'rawstyle',
        'hard dance',
        'eurodance',
        'big room',
        'festival anthem',
        'progressive house',
        'future house',
        'electro house',
        'bass house',
        'trance',
        'techno',
        'edm',
        'dubstep',
        'melodic dubstep',
        'riddim',
        'drum and bass',
        'drum & bass',
        'drum n bass',
        'dnb',
        'synthwave',
        'retrowave',
        'jump up',
        'neurofunk',
        'hardcore',
        'frenchcore',
        'uptempo',
        'tek',
        'melbourne bounce',
        'bounce',
        'electro',
      ],
    ),
    _FamilyRule(
      VocalFamily.hipHop,
      hipHopOverlay,
      [
        'hip hop',
        'hiphop',
        'hip-hop',
        'trap',
        'boom bap',
        'boombap',
        'boom-bap',
        'rap',
        'drill',
        'grime',
        'phonk',
        'cloud rap',
        'trap soul',
        'melodic rap',
      ],
    ),
    _FamilyRule(
      VocalFamily.gospel,
      gospelOverlay,
      [
        'gospel',
        'worship',
        'christian',
        'praise',
        'contemporary christian',
        'choir',
        'cinematic',
        'film score',
        'trailer',
        'orchestral',
      ],
    ),
    _FamilyRule(
      VocalFamily.afro,
      afroOverlay,
      [
        'amapiano',
        'yanos',
        'afro',
        'afro house',
        'afrohouse',
        'afro-house',
        'afrobeat',
        'afrobeats',
        'afro pop',
        'afropop',
        'afro fusion',
        'afrofusion',
        'gqom',
      ],
    ),
    _FamilyRule(
      VocalFamily.asianPop,
      asianPopOverlay,
      [
        'k-pop',
        'kpop',
        'j-pop',
        'jpop',
        'c-pop',
        'cpop',
        'mandopop',
        'mandarin pop',
        'cantopop',
        'cantonese pop',
        'city pop',
        'anime',
        'anisong',
        't-pop',
        'thai pop',
        'p-pop',
        'pinoy pop',
      ],
    ),
    _FamilyRule(
      VocalFamily.rnb,
      rnbOverlay,
      [
        'r&b',
        'rnb',
        'rhythm and blues',
        'contemporary rnb',
        'alt rnb',
        'alternative rnb',
        'pbrnb',
        'neo-soul',
        'neo soul',
        'soul',
        'quiet storm',
      ],
    ),
    _FamilyRule(
      VocalFamily.latin,
      latinOverlay,
      [
        'latin',
        'latino',
        'latina',
        'reggaeton',
        'regueton',
        'urbano',
        'música urbana',
        'bachata',
        'salsa',
        'merengue',
        'cumbia',
        'dembow',
        'mambo',
        'tango',
        'bossa nova',
        'latin pop',
        'latin house',
      ],
    ),
    _FamilyRule(
      VocalFamily.acoustic,
      acousticOverlay,
      [
        'folk',
        'indie folk',
        'singer-songwriter',
        'singer songwriter',
        'acoustic',
        'unplugged',
        'live lounge',
        'coffeehouse',
        'americana',
        'country',
        'bluegrass',
        'jazz',
        'classic swing',
        'swing',
        'blues',
        'ambient',
        'soundscape',
        'reggae',
        'dub',
      ],
    ),
    _FamilyRule(
      VocalFamily.rock,
      rockOverlay,
      [
        'rock',
        'hard rock',
        'classic rock',
        'pop rock',
        'indie rock',
        'alternative',
        'alt rock',
        'punk',
        'post-punk',
        'metal',
        'grunge',
        'emo',
      ],
    ),
    _FamilyRule(
      VocalFamily.pop,
      popOverlay,
      [
        'pop',
        'dance pop',
        'dance-pop',
        'electropop',
        'electro-pop',
        'synth pop',
        'synth-pop',
        'indie pop',
        'indie-pop',
        'hyperpop',
        'dream pop',
        'dream-pop',
        'power pop',
        'power-pop',
        'teen pop',
        'bubblegum pop',
        'art pop',
        'bedroom pop',
        'world',
        'bollywood',
        'mena',
        'middle eastern',
        'bhangra',
        'filmi',
        'punjabi',
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Precomputed lookups
  // ---------------------------------------------------------------------------

  static final Map<VocalFamily, List<String>> _normalizedKeywords = {
    for (final rule in _rules)
      rule.family: rule.keywords.map(_normalizeGenre).toList(),
  };

  static final Map<VocalFamily, String> _overlayByFamily = {
    for (final rule in _rules) rule.family: rule.overlay,
  };

  /// Known families excluding [VocalFamily.unknown] (UI / debug).
  static List<VocalFamily> get knownFamilies => VocalFamily.values
      .where((f) => f != VocalFamily.unknown)
      .toList(growable: false);

  // ---------------------------------------------------------------------------
  // Public predicates / resolvers
  // ---------------------------------------------------------------------------

  /// True unless the user explicitly chose instrumental-only.
  static bool shouldInject(String? vocalSpec) =>
      !VocalSpecToneData.isInstrumentalOnly(vocalSpec);

  /// Returns every family that matches the genre blob, in `_rules` order.
  /// Useful for fusions like "Afro House + R&B".
  static List<VocalFamily> detectFamilies(
    String primaryGenre,
    String subGenreFusion,
  ) {
    final blob = _normalizeGenre('$primaryGenre $subGenreFusion');
    if (blob.isEmpty) return const [];

    final found = <VocalFamily>[];
    for (final rule in _rules) {
      if (_containsAny(blob, _normalizedKeywords[rule.family]!)) {
        found.add(rule.family);
      }
    }
    return List.unmodifiable(found);
  }

  /// First matching family, or [VocalFamily.unknown].
  static VocalFamily detectFamily(String primaryGenre, String subGenreFusion) {
    final families = detectFamilies(primaryGenre, subGenreFusion);
    return families.isEmpty ? VocalFamily.unknown : families.first;
  }

  /// Trimmed overlay for a resolved family, or `null` for unknown.
  static String? overlayFor(VocalFamily family) {
    if (family == VocalFamily.unknown) return null;
    return _overlayByFamily[family]?.trim();
  }

  /// Returns the family overlay(s).
  ///
  /// When [includeAllMatches] is `true`, every matching family overlay is
  /// included (good for genre fusions). When `false` (default), only the first
  /// match is used to keep prompt length down.
  ///
  /// Falls back to a family implied by [vocalSpec] when no genre matches.
  static String? familyOverlay({
    String primaryGenre = '',
    String subGenreFusion = '',
    String? vocalSpec,
    bool includeAllMatches = false,
  }) {
    final families = detectFamilies(primaryGenre, subGenreFusion);

    if (families.isNotEmpty) {
      final selected = includeAllMatches ? families : families.take(1);
      final overlays = selected.map(overlayFor).whereType<String>();
      return overlays.isEmpty ? null : overlays.join('\n\n');
    }

    final specFamily = _familyFromSpec(vocalSpec);
    return specFamily != null ? overlayFor(specFamily) : null;
  }

  // ---------------------------------------------------------------------------
  // Composition
  // ---------------------------------------------------------------------------

  /// User-block for all vocal generations (empty when instrumental-only).
  ///
  /// Keep [includeAllFamilyMatches] false by default so Block 1 stays short;
  /// set true only when a fusion path wants every matching overlay.
  static String composeUserBlock({
    String primaryGenre = '',
    String subGenreFusion = '',
    String? vocalSpec,
    bool includeAllFamilyMatches = false,
  }) {
    if (!shouldInject(vocalSpec)) return '';

    final parts = <String>[globalCore.trim()];

    final overlay = familyOverlay(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vocalSpec: vocalSpec,
      includeAllMatches: includeAllFamilyMatches,
    );
    if (overlay != null && overlay.isNotEmpty) {
      parts.add(overlay);
    }

    return parts.join('\n\n');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Strips punctuation, lowercases, and collapses whitespace so inputs like
  /// "Hardstyle / Rawstyle Fusion" and "K-Pop" match their keywords.
  static String _normalizeGenre(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s&]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Word-boundary match. Prevents "afro" from matching "afternoon" or "pop"
  /// from matching inside "kpop" (use dedicated `kpop` / `k-pop` keywords).
  static bool _containsAny(String blob, List<String> phrases) =>
      phrases.any((phrase) {
        if (phrase.isEmpty) return false;
        final escaped = RegExp.escape(phrase);
        return RegExp('\\b$escaped\\b').hasMatch(blob);
      });

  /// Maps a vocal spec to a sensible family when no genre is available.
  static VocalFamily? _familyFromSpec(String? spec) {
    final normalized = VocalSpecToneData.coerceSpec(spec);
    if (normalized == null) return null;

    if (normalized == VocalSpecToneData.rapVocalSpaceSpec) {
      return VocalFamily.hipHop;
    }
    if (VocalSpecToneData.isChoir(normalized)) {
      return VocalFamily.gospel;
    }
    return null;
  }
}
