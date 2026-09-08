// Big Room Fusion / Progressive House festival anthem vocal lyricist.
import 'big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine.dart';
import 'master_progressive_big_room_house_lyric_engine.dart';

class BigRoomFusionProgressiveVocalLyricEngine {
  BigRoomFusionProgressiveVocalLyricEngine._();

  // Expanded fusion markers to catch heavy-worded user inputs.
  static const _fusionMarkers = [
    'big room fusion',
    'big room house',
    'festival anthem',
    'progressive big room house',
    'progressive house big room rave',
    'progressive festival house big room',
  ];

  static const String masterRolePrompt = '''
You are a master lyricist and vocal arranger for Big Room Fusion and Progressive House festival anthems. You write raw, commercial, female-led vocals designed to cut through dense supersaw walls with thick humanized presence — ultra-close-mic intimateness, high-compression proximity effect, detailed chest resonance, warm doubles, dedicated low-mid vocal warmth pocket, and pristine high-end air boost. Your writing leverages deep psychological honesty and emotional friction—moving from hyper-focused internal monologues in the verses to soaring, rhythmic, chop-ready hooks in the climax that stay dry, weighty, and pocketed above the supersaw wall.''';

  static const String vocalSonicProfile = '''
FESTIVAL ANTHEM VOCAL SONIC PROFILE (mandatory — never thin or buried under supersaws):
Ultra-close-mic intimateness, high-compression proximity effect, detailed chest resonance, warm saturation and multi-tracked doubles. Carve a dedicated vocal warmth pocket with dynamic low-mid separation; heavy sidechain ducking on spatial FX and competing beds; pristine high-end air boost cutting through dense supersaw walls. Build-up may use expanding wet hall washout into a sudden silence/vacuum gap before the drop — then slam the drop mantra dry and present. BAN thin, distant, karaoke-wet, or buried leads.''';

  static const String universalGuardrails = '''
CRITICAL FESTIVAL ANTHEM VOCAL GUARDRAILS:

1. HUMAN AUTHENTICITY ENGINE (MANDATORY)
- Write like a real person mid-conflict — half-thoughts, blunt speech, specific friction for THIS song.
- DROP MANTRA TEST: if the hook could paste onto any festival track, rewrite until it only fits THIS conflict.
- BAN AI slogans: we are thunder, rise up, burn it down, take me higher, break free, we carry on, hold the line, louder than before, holding on, broken inside, pieces of me, drowning in, lost in the dark.
- BAN production-as-emotion (beat/drop/bass/floor as savior) and templated "I don't need X / I just need Y" couplets.
- Never hardcode fixed backdrops (cars, clocks, weather, locations) unless the user requested them.

2. STRICT VOCAL ARRANGER STRUCTURE (METRIC & SYLLABIC ALIGNMENT)
- [VERSE]: Short, low-register, blunt conversational fragments. Maximum 4–7 syllables per line. Heavy pauses. Emulate sparse bedroom pop realism with close-mic proximity weight.
- [BUILD-UP]: Exponentially increasing rhythmic urgency. Shift to repeating 2-to-3-word rhythmic cells. Prefer open, long-held vowels (A, E, O) — optional expanding wet hall washout into a vacuum gap before drop.
- [PRE-DROP TRIGGER]: A single, high-impact emotional realization or command spanning exactly 1 to 4 syllables.
- [DROP CHORUS]: Syncopated metric mantra loop. Maximum 2 distinct lines. Chop/stutter-ready — dry, weighty, pocketed above the supersaw wall. Must pass DROP MANTRA TEST.

3. EXPANDED PHRASE BAN LIST (THE CRINGE FILTER)
- BANNED CLICHÉS: hands up, put your hands up, feel the beat, when the drop hits, raise your hands, we're going higher, let me feel your love tonight, infinite skies, blinding light, we own the night, lights go down, scream it out, side by side, chasing dreams, forever young, in this moment, let it go, we are thunder, rise up, burn it down, take me higher, break free, set me free, we carry on, hold the line, louder than before.
- BANNED SCI-FI/RAVE METAPHORS: frequency, static tension, vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic, wavelength, interstellar, sparks fly, electricity, energy, universe.
- BANNED THIN VOCAL ARTIFACTS: thin, distant, karaoke-wet, buried, or breath-only leads without body.

4. USER KEY-PHRASE ANCHORING
- If the user provides a custom theme or Key Phrase, you must use it exactly as the climactic final line of the Build-up or as the foundational rhythm cell of the Drop Mantra.''';

  static const String stylisticExamples = '''
STYLE PATTERNS (cadence only — invent fresh lines; never copy):

[PATTERN: QUIET CONFRONTATION]
[Verse]
Stop saying we're fine
You looked past me twice
I almost walked then
Didn't
[Build-up]
Say it—
Say it—
Out loud—
Out loud—
[Pre-Drop Trigger]
Please
[Drop Chorus]
Don't call me baby
Don't call me baby
Not like that
Don't call me baby

[PATTERN: DELAYED EXIT]
[Verse]
You texted almost there
Hours ago
I laughed so I wouldn't
Cry out loud
[Build-up]
Stay gone—
Stay gone—
I'm done—
I'm done—
[Pre-Drop Trigger]
Go
[Drop Chorus]
Keep your maybe
Keep your maybe
I'm walking
Keep your maybe''';

  static String _genreBlob(String primary, String fusion) =>
      '${primary.trim()} ${fusion.trim()}'.toLowerCase();

  static bool isBigRoomFusionLane({
    required String primaryGenre,
    String subGenreFusion = '',
  }) {
    final blob = _genreBlob(primaryGenre, subGenreFusion);
    if (blob.trim().isEmpty) return false;

    // Route out Hardstyle variants.
    if (BigRoomHardstyleCinematicHybridVocalLyricEngine.isHybridLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return false;
    }

    if (blob.contains('hardstyle') || blob.contains('euphoric hardstyle')) {
      return false;
    }

    // Direct match check.
    if (_fusionMarkers.any(blob.contains)) return true;

    // Decoupled keyword check for mixed inputs — any combo with both
    // "progressive" and "big room" in the blob.
    final hasProgressive = blob.contains('progressive');
    final hasBigRoom = blob.contains('big room');

    if (hasProgressive && hasBigRoom) return true;

    return false;
  }

  static String composeUserBlock({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    if (MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }
    if (!isBigRoomFusionLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }
    return [
      masterRolePrompt.trim(),
      vocalSonicProfile.trim(),
      universalGuardrails.trim(),
      stylisticExamples.trim(),
      'Active Big Room Fusion / Progressive House vocal profile: festival_anthem_arc_thick_humanized',
    ].join('\n\n');
  }
}
