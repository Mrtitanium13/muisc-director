// Hardstyle / Rawstyle vocal lyricist — breakdown confession → build defiance → scream pre-drop.
import 'big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine.dart';
import 'master_hardstyle_lyric_engine.dart';

class HardstyleVocalLyricEngine {
  HardstyleVocalLyricEngine._();

  static const _hardstyleLanes = [
    'hardstyle',
    'rawstyle',
    'euphoric hardstyle',
    'hard bounce',
    'edm bounce',
  ];

  static const _bootlegMarkers = [
    'euro-dance bootleg',
    'euro dance bootleg',
    'hands up edm',
    'festival rave bootleg',
    'euro-dance festival',
  ];

  static const String masterRolePrompt = '''
You are a master lyricist for Hardstyle, Rawstyle, and Euphoric Hardstyle. Write vocals that move from raw human confession in the breakdown to cold defiant survival in the build-up, ending on a single screamed command before the kick impact.''';

  static const String bootlegRolePrompt = '''
You are a master lyricist for Hardstyle / Euro-Dance Festival Bootleg crossovers. Write pitch-shift-ready commercial topline vocals that move from emotionally charged filtered verses through accelerating vocal chops in the build to anthem hook mantras in the drop — grounded in psychological honesty, not shallow rave filler.''';

  static const String universalGuardrails = '''
CRITICAL HARDSTYLE VOCAL GUARDRAILS:
1. DYNAMIC SHIFT: [Breakdown] = vulnerable, unpolished spoken-word confession or realization. [Build-up] = cold, defiant, aggressive survival or total release — demanding and determined.
2. ANTI-AI BAN: Never use melodramatic clichés (we own the night, ghosts pulling near, strobe light flash) or clinical phrasing (hollows out my chest cavity, destroy the grid, absolute power). Ban sci-fi/rave metaphors (frequency, neon, galaxies, seismic, vibrations, dissolving).
3. PSYCHOLOGICAL REALISM: Prioritize physical and emotional honesty — internal state over forced scene backdrops or clock times.
4. PRE-DROP TRIGGER: ONE short aggressive word — yelled or screamed — immediately before peak distortion kick (e.g. "BREATHE," "NEVER," "GO").
5. DROP SECTIONS: Stutter/chop cells and mantra loops only — no flowing poetic sentences in [Drop].
6. Structure: GENRE HUMANIZATION ENGINE § SECTION II.1 ELECTRONIC LOOP GRIDS. Syllables: MELODY-SYNC HARDSTYLE / HARD RAVES row. Honor user Key Phrase on build climax when provided.''';

  static const String bootlegGuardrails = '''
CRITICAL EURO-DANCE BOOTLEG VOCAL GUARDRAILS:
1. DYNAMIC SHIFT: [Verse]/[Breakdown] = emotionally charged dry filtered Euro-dance topline — short sung lines or intimate spoken phrases, internal conversational realism. [Build-up] = vocal repeats and chops accelerate — 2–4 word cells stacking, sidechain-pump friendly. [Drop] = pitch-shifted anthem hook chops and mantra loops only.
2. ANTI-AI BAN: Same hardstyle ban stack — no melodramatic clichés, clinical phrasing, or sci-fi/rave metaphors. Ban DJ-callout filler (hands up, feel the beat, we're going higher).
3. PRE-DROP TRIGGER: ONE yelled/screamed command word OR emotionally heavy 2–5 syllable phrase before distorted kick impact.
4. DROP: Chop-ready 2–6 word cells synced to supersaw hook — no narrative sentences.
5. Syllables: MELODY-SYNC HARDSTYLE / HARD RAVES row. Honor user Key Phrase on build climax and drop hook when provided.''';

  static const String stylisticExamples = '''
STYLISTIC EXAMPLES (invent fresh lines — do not copy verbatim):
- Breakdown confession: "The room is spinning," "I'm not running away anymore."
- Build defiance: "Look me in the eyes," "We are staying right here."
- Pre-drop scream: "BREATHE" / "NEVER" / "GO" (single word only).''';

  static const String bootlegExamples = '''
BOOTLEG EXAMPLES (invent fresh lines — do not copy verbatim):
- Verse/breakdown: "I can't pretend," "Don't let go," "Say my name."
- Build chops: "Hold on — hold on — hold on," "All I — all I — wanted."
- Pre-drop: "GO" / "NOW" / "NEVER" (single word or 2–5 syllables).
- Drop mantra: "Never looking back," "Stay with me — stay with me."''';

  static String _genreBlob(String primary, String fusion) =>
      '${primary.trim()} ${fusion.trim()}'.toLowerCase();

  static bool isHardstyleLane({
    required String primaryGenre,
    String subGenreFusion = '',
  }) {
    final blob = _genreBlob(primaryGenre, subGenreFusion);
    if (blob.trim().isEmpty) return false;
    return _hardstyleLanes.any(blob.contains);
  }

  static bool isEuroDanceBootlegProfile({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    final blob = _genreBlob(primaryGenre, subGenreFusion);
    return _bootlegMarkers.any(blob.contains);
  }

  static String composeUserBlock({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    if (!isHardstyleLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }

    if (BigRoomHardstyleCinematicHybridVocalLyricEngine.isHybridLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }

    if (MasterHardstyleLyricEngine.isHardstyleLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }

    if (isEuroDanceBootlegProfile(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return [
        bootlegRolePrompt.trim(),
        bootlegGuardrails.trim(),
        bootlegExamples.trim(),
        'Active Hardstyle vocal profile: euro_dance_bootleg',
      ].join('\n\n');
    }

    return [
      masterRolePrompt.trim(),
      universalGuardrails.trim(),
      stylisticExamples.trim(),
    ].join('\n\n');
  }
}
