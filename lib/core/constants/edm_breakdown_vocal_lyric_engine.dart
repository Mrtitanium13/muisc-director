import 'big_room_fusion_progressive_vocal_lyric_engine.dart';
import 'big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine.dart';

/// EDM breakdown / build-up vocal lyricist — Techno, Trance, House, Festival EDM.

class EdmBreakdownVocalLyricEngine {

  EdmBreakdownVocalLyricEngine._();



  static const profilePeakTimeTechno = 'peak_time_techno';

  static const profileVocalTrance = 'vocal_trance';

  static const profileDeepMelodic = 'deep_melodic';



  static const _peakTimeMarkers = [

    'big room techno',

    'peak-time techno',

    'peak time techno',

    'hard techno',

    'minimal techno',

    'acid techno',

    'schranz',

    'industrial techno',

    'big room',

  ];



  static const _vocalTranceMarkers = [

    'uplifting trance',

    'progressive trance',

    'vocal trance',

    'trance',

    'festival edm',

    'big room edm',

    'mainstage',

    'mainstage dance',

  ];



  static const _deepMelodicMarkers = [

    'deep house',

    'soulful house',

    'melodic techno',

    'melodic house',

    'progressive house',

    'tech house',

    'disco house',

    'house',

  ];



  static const _edmLaneMarkers = [

    ..._peakTimeMarkers,

    ..._vocalTranceMarkers,

    ..._deepMelodicMarkers,

    'techno',

    'edm',

    'electronic dance',

  ];



  static const String masterRolePrompt = '''

You are a master lyricist specializing in Electronic Dance Music — Techno, Trance, House, and Festival EDM. Write breakdown and build-up vocals that feel deeply human, raw, and club-tested — grounded in psychological honesty. Keep vocals thick and humanized under dense club production: ultra-close-mic intimateness, high-compression proximity effect, detailed chest resonance, warm doubles, dedicated low-mid vocal warmth pocket, pristine high-end air boost; never thin, distant, karaoke-wet, or buried under the bed.''';



  static const String universalGuardrails = '''

CRITICAL EDM BREAKDOWN VOCAL GUARDRAILS:

1. BAN SCI-FI & RAVE METAPHORS: Never use frequency, static tension, vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic, wavelength, or interstellar framing.

2. INTERNAL CONVERSATIONAL REALISM: Write exactly how a real person thinks or speaks when they are vulnerable, hyper-focused, or experiencing intense emotion. Use short, blunt sentences, thought fragments, and jagged conversational phrasing (e.g. "Don't say anything," "If you touch me, it's over," "I can hear my heart") instead of poetic metaphors. Focus entirely on the character's immediate psychological state — adaptable to any user theme or time-of-day setting.

3. VOCAL PLACEMENT: Low-register, dry vocals — spoken or whispered tight against the microphone capsule with ultra-close-mic intimateness, high-compression proximity effect, and detailed chest resonance unless the sub-profile calls for floating sung hooks. Keep a dedicated low-mid vocal warmth pocket; never thin, distant, karaoke-wet, or buried under the club bed.

4. PRE-DROP TRIGGER: The 1–2 bars before the final drop must culminate in a sharp actionable command or one emotionally heavy phrase (e.g. "Run," "Now," "Just look at me").

5. LAYOUT: Keep lyrics strictly in [Breakdown], [Build-up]/[Build], and sparse [Outro] markers. Sparse text — leave breathing room for instruments.''';



  static const Map<String, String> _subGenreMatrix = {

    profilePeakTimeTechno: '''

SUB-PROFILE: BIG ROOM TECHNO / PEAK-TIME

- Focus: Internal monologues, physical boundaries, raw intimacy, sensory overload — psychological pressure over exposition.

- Arrangement: Spoken-word or whispered delivery; stark contrast against aggressive driving kicks.

- Syllables: MELODY-SYNC TECHNO / HOUSE / LOOP GRIDS row; Pre-Drop trigger 2–5 syllables.''',

    profileVocalTrance: '''

SUB-PROFILE: UPLIFTING / VOCAL TRANCE

- Focus: Longing, unrequited love, turning points, emotional release — felt honesty, not galaxy/neon poetry.

- Arrangement: Floating harmonies, long-held vowels, repetitive hooks chop-ready during build-up.

- Syllables: MELODY-SYNC FESTIVAL ANTHEMS row.''',

    profileDeepMelodic: '''

SUB-PROFILE: DEEP HOUSE / MELODIC TECHNO

- Focus: Conversational fragments, casual intimacy, relationship tension, cynicism mixed with hope.

- Arrangement: Low-register dry vocals — spoken or softly sung tight to the capsule.

- Syllables: MELODY-SYNC TECHNO / HOUSE / LOOP GRIDS + Build fragments 2–4 syllables.''',

  };



  static String _genreBlob(String primary, String fusion) =>

      '${primary.trim()} ${fusion.trim()}'.toLowerCase();



  static bool _containsAny(String blob, List<String> needles) =>

      needles.any(blob.contains);



  static bool isEdmBreakdownLane({

    required String primaryGenre,

    String subGenreFusion = '',

  }) {

    final blob = _genreBlob(primaryGenre, subGenreFusion);

    if (blob.trim().isEmpty) return false;

    if (BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return false;
    }

    if (BigRoomHardstyleCinematicHybridVocalLyricEngine.isHybridLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return false;
    }

    return _containsAny(blob, _edmLaneMarkers);

  }



  static String resolveProfile({

    required String primaryGenre,

    String subGenreFusion = '',

  }) {

    final blob = _genreBlob(primaryGenre, subGenreFusion);

    if (_containsAny(blob, _vocalTranceMarkers) ||

        (blob.contains('trance') && !blob.contains('melodic techno'))) {

      return profileVocalTrance;

    }

    if (_containsAny(blob, _deepMelodicMarkers)) {

      return profileDeepMelodic;

    }

    if (_containsAny(blob, _peakTimeMarkers) || blob.contains('techno')) {

      return profilePeakTimeTechno;

    }

    if (blob.contains('edm')) return profileVocalTrance;

    if (blob.contains('house')) return profileDeepMelodic;

    return profileDeepMelodic;

  }



  static String composeUserBlock({

    required String primaryGenre,

    String subGenreFusion = '',

  }) {

    if (!isEdmBreakdownLane(

      primaryGenre: primaryGenre,

      subGenreFusion: subGenreFusion,

    )) {

      return '';

    }

    final profile = resolveProfile(

      primaryGenre: primaryGenre,

      subGenreFusion: subGenreFusion,

    );

    final matrix = _subGenreMatrix[profile] ?? '';

    return [

      masterRolePrompt.trim(),

      universalGuardrails.trim(),

      matrix.trim(),

      'Active EDM breakdown profile: $profile',

    ].join('\n\n');

  }

}


