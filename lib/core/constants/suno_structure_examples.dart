/// Canonical Suno STRUCTURE bracket examples, version-aware.
///
/// Use [exampleForVersion] to pick the right example for the user's target
/// Suno version. Each example is self-contained and compliant with the
/// Suno Syntax Law (see Dynamic Structural Engine).
// ignore_for_file: constant_identifier_names
import 'suno_version.dart';

class SunoStructureExamples {
  SunoStructureExamples._();

  static const String v55_generic = '''[Intro: sparse atmospheric fade-in]
[Verse 1: intimate close-mic vocal, minimalist instrumentation]
[Chorus: full belt, wide layered harmonies, lift dynamics]
[Verse 2: added percussion, narrative escalation]
[Chorus: wider arrangement, counter-melody enters]
[Bridge: drop to half-time, single instrument, breath vocal]
[Final Chorus: gospel-level intensity, ad-lib counter-melody, max dynamics]
[Outro: 4-bar fade, room tone only]
[End]''';

  static const String v55_pop = '''[Intro: radio-bright hook tease, 4 Bars]
[Verse 1: percussive vocal, sparse pocket groove]
[Pre-Chorus: rising tension, added pads]
[Chorus: euphoric lift, stacked harmonies, wide stereo]
[Verse 2: new lyrical angle, rhythmic variation]
[Pre-Chorus: same as before, doubled energy]
[Chorus: bigger arrangement, octave-double vocal]
[Bridge: stripped-down piano + vocal]
[Final Chorus: full arrangement, key-change lift, ad-libs]
[Outro: hook reprise fade]
[End]''';

  static const String v55_edm = '''[Intro: filtered low-pass sweep, 16 Bars]
[Build-up: rising white noise, snare rolls, pitch-bending leads]
[Drop: hypnotic bass groove, tight kick, signature riff]
[Breakdown: stripped to pads + vocal, atmospheric space]
[Build-up: second rise, bigger sweep]
[Drop: full arrangement, counter-melody layer]
[Outro: DJ-friendly 8-bar loop-out]
[End]''';

  static const String v55_hiphop = '''[Intro: producer tag, beat tease]
[Verse 1: vocal-forward, tight pocket delivery]
[Hook: melodic refrain, doubled vocal, 808 emphasis]
[Verse 2: new angle, flow switch]
[Hook: wider arrangement, ad-lib layers]
[Bridge: beat-switch, half-time feel]
[Hook: climactic repeat, ad-libs counter-melody]
[Outro: beat fade, vocal echo]
[End]''';

  static const String v55_worship = '''[Intro: ambient pad swell, call to worship]
[Verse 1: intimate prayerful vocal, fingerpicked acoustic]
[Chorus: congregational lift, SATB harmonies rising]
[Verse 2: narrative build, full band enters]
[Chorus: wider harmonies, tambourine pulse]
[Bridge: dynamic plateau, prayerful pause]
[Vamp: call-and-response, repeating refrain]
[Spontaneous Flow: ad-lib worship, spoken word optional]
[Final Chorus: full anthem, cathedral reverberation, full choir]
[Outro: soft prayer hum fade]
[End]''';

  static const String v55_amapiano = '''[Intro: shaker pulse, log-drum tease]
[Verse 1: breathy intimate vocal, sparse piano stabs]
[Chorus: log-drum bounce drops in, group chant accents]
[Verse 2: sax phrase motif enters, rhythmic variation]
[Chorus: wider percussion layer]
[Breakdown: perc-only, conga solo]
[Chorus: full groove, layered claps]
[Outro: log-drum fade]
[End]''';

  static const String v55_cinematic = '''[Intro: isolated motif, sparse texture]
[Theme A: orchestral exposition, establishing mood]
[Development: variation, counter-theme, rising dynamics]
[Climax: full orchestra, tutti, emotional peak]
[Coda: sparse recall of motif, fade to silence]
[End]''';

  static const String v55_mandopop = '''[Intro: piano ballad foundation, melodic tease]
[Verse 1: breathy intimate vocal, minimal accompaniment]
[Pre-Chorus: erhu counter-melodic phrase enters]
[Chorus: emotional lift, guzheng arpeggios, full strings]
[Verse 2: narrative escalation, drums join]
[Pre-Chorus: same lift, doubled vocal]
[Chorus: wider orchestration, key change]
[Bridge: piano + vocal only, vulnerable moment]
[Final Chorus: full anthem, mandopop-style climactic belt]
[Outro: piano motif resolve]
[End]''';

  static const String v55_jazz = '''[A Section: head melody, straight-time]
[A Section: melody restated, light variation]
[B Section: contrasting bridge, new harmonic color]
[A Section: head return, walking bass, solo comping]
[Instrumental Solo: extended improvisation over AABA]
[Head Out: final melody statement]
[End]''';

  static const String v5_generic = '''[Intro]
[Verse 1]
[Chorus: full harmonies]
[Verse 2]
[Chorus: wider arrangement]
[Bridge: stripped down]
[Final Chorus: climactic]
[Outro]
[End]''';

  static const String v5_edm = '''[Intro]
[Build-up]
[Drop: signature riff]
[Breakdown]
[Build-up]
[Drop: full arrangement]
[Outro]
[End]''';

  static const String v5_hiphop = '''[Intro]
[Verse 1]
[Hook: doubled vocal]
[Verse 2]
[Hook: wider arrangement]
[Bridge: beat switch]
[Hook: climactic]
[Outro]
[End]''';

  static const String v45_generic = '''[Intro]
[Verse 1]
[Chorus]
[Verse 2]
[Chorus]
[Bridge]
[Final Chorus]
[Outro]
[End]''';

  static const String v45_edm = '''[Intro]
[Build]
[Drop]
[Breakdown]
[Build]
[Drop]
[Outro]
[End]''';

  static const Map<String, Map<String, String>> _versionTable = {
    'v4.5': {
      'generic': v45_generic,
      'edm': v45_edm,
    },
    'v5': {
      'generic': v5_generic,
      'edm': v5_edm,
      'hiphop': v5_hiphop,
    },
    'v5.5': {
      'generic': v55_generic,
      'pop': v55_pop,
      'edm': v55_edm,
      'hiphop': v55_hiphop,
      'worship': v55_worship,
      'amapiano': v55_amapiano,
      'cinematic': v55_cinematic,
      'mandopop': v55_mandopop,
      'jazz': v55_jazz,
    },
  };

  /// Normalize UI/API version strings to table keys (density alias).
  static String normalizeVersion(String raw) {
    final key = SunoVersion.densityKeyFor(raw);
    if (key == 'v5.0') return 'v5';
    return key;
  }

  static String exampleForVersion({
    required String version,
    String familyKey = 'generic',
  }) {
    final key = normalizeVersion(version);
    final family = _versionTable[key];
    if (family == null) return v45_generic;
    return family[familyKey] ?? family['generic'] ?? v45_generic;
  }

  static String familyForGenre(String? genre) {
    if (genre == null || genre.isEmpty) return 'generic';
    final g = genre.toLowerCase();
    if (g.contains('worship') || g.contains('gospel')) return 'worship';
    if (g.contains('amapiano')) return 'amapiano';
    if (g.contains('mandopop') || g.contains('c-pop')) return 'mandopop';
    if (g.contains('jazz')) return 'jazz';
    if (g.contains('cinematic') ||
        g.contains('ambient') ||
        g.contains('orchestral') ||
        g.contains('film')) {
      return 'cinematic';
    }
    if (g.contains('hip hop') ||
        g.contains('trap') ||
        g.contains('drill') ||
        g.contains('boom bap') ||
        g.contains('phonk') ||
        g.contains('rap')) {
      return 'hiphop';
    }
    if (g.contains('edm') ||
        g.contains('house') ||
        g.contains('techno') ||
        g.contains('trance') ||
        g.contains('dubstep') ||
        g.contains('dnb') ||
        g.contains('bass') ||
        g.contains('hardstyle')) {
      return 'edm';
    }
    if (g.contains('pop') || g.contains('k-pop') || g.contains('j-pop')) {
      return 'pop';
    }
    return 'generic';
  }

  /// Version- and genre-aware bracket syntax preamble for the LLM user block.
  static String buildStructurePreamble({
    required String sunoVersion,
    String? selectedGenre,
    String? subGenreFusion,
  }) {
    final genre = (selectedGenre ?? '').trim().isNotEmpty
        ? selectedGenre
        : subGenreFusion;
    final family = familyForGenre(genre);
    final example = exampleForVersion(
      version: sunoVersion,
      familyKey: family,
    );
    return '''Canonical bracket layout example (follow this syntax; content is genre-specific):

$example

Render your SUNO STRUCTURE using these exact bracket forms. Replace the staging
notes with content specific to this track — do not copy the example's staging
literally. Every section must be a bracketed line. Always terminate with [End].''';
  }

  /// All shipped examples grouped by version tier (for validation/tests).
  static Map<String, List<String>> get allExamplesByVersion => {
        'v4.5': [v45_generic, v45_edm],
        'v5': [v5_generic, v5_edm, v5_hiphop],
        'v5.5': [
          v55_generic,
          v55_pop,
          v55_edm,
          v55_hiphop,
          v55_worship,
          v55_amapiano,
          v55_cinematic,
          v55_mandopop,
          v55_jazz,
        ],
      };
}
