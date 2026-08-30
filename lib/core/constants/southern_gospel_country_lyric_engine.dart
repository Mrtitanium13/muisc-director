import 'master_gospel_lyric_engine.dart';

/// Soulful Southern Gospel & Raw Country lyric architecture + few-shot calibration.
///
/// Injected when primary/fusion genre or vibe matches the southern gospel / raw
/// country lane. Works with [GenreLyricsDirectives] and chat few-shot turns.
/// Few-shot chat turns defer to [MasterGospelLyricEngine] when both lanes match.
class SouthernGospelCountryLyricEngine {
  SouthernGospelCountryLyricEngine._();

  static const _laneMarkers = [
    'southern gospel',
    'country gospel',
    'gospel country',
    'worship ballad',
    'outlaw country',
    'americana',
    'modern country',
    'raw country',
  ];

  static const _placeholderBan = [
    'cheap wine',
    'city lights',
    'neon',
    'empty bottle',
    'lost keys',
    'dirt road',
    'pickup truck',
    'whiskey in a glass',
    'porch swing',
    'small town',
  ];

  /// Quality overlay for raw country lanes — cliché ban only (theme rules are dynamic).
  static const String coreArchitecture = '''
SOULFUL SOUTHERN GOSPEL & RAW COUNTRY LYRIC ENGINE (mandatory for this lane)

You are an expert lyricist in Soulful Southern Gospel and Raw Country. Lyrics must feel deeply personal, spiritually heavy, and universally relatable — never template worship or stock country.

STRICT WRITING RULES:
1. BAN THE CLICHÉS: Never use generic physical placeholders for rebellion or emptiness (e.g. "cheap wine," "city lights," "neon," "empty bottle," "lost keys," dirt-road/pickup/porch stock). Replace with existential or psychological specificity ("crowded, lonely room," "monument of pride," "fleeting shadow").

BANNED PLACEHOLDER IMAGERY (rewrite if tempted): cheap wine, city lights, neon, empty bottle, lost keys, generic bar-on-Main-street vignettes without psychological specificity.''';

  /// Few-shot assistant turn — BAD vs GOOD transformation (Step 2).
  static const String fewShotAssistantTurn = '''
BAD (Avoid this style):
I hit the bar on Main street, drank until the dawn
Thinking about the good times and how they're all now gone
I lost my silver cross, I spent my final dime
Now I'm sitting in the dark, just wasting all my time.

GOOD (Write in this style):
I traded your inheritance for a crowded, lonely room
Chasing any fleeting shadow that could hide me from the truth
Woke up at 3 AM with a hunger in my heart
Realized the things I fought for only left me more oppressed.''';

  static const String fewShotUserTurn =
      'Write a verse about realizing you made a mistake and wanting to go back to God.';

  static bool isLane({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final blob =
        '${primaryGenre.trim()} ${subGenreFusion.trim()} ${vibe.trim()} ${lyricThemeNotes.trim()}'
            .toLowerCase();
    if (blob.trim().isEmpty) return false;
    if (_laneMarkers.any(blob.contains)) return true;
    if (blob.contains('gospel country lift')) return true;
    if (blob.contains('raw country')) return true;
    return false;
  }

  /// Map UI inputs → appended lyric directives (Step 3).
  static String uiDirectiveAppend({
    String? vocalSpec,
    String? vocalTone,
    String vibe = '',
    String melodyStyleId = '',
    String melodyCustomNotes = '',
  }) {
    final parts = <String>[];
    final spec = (vocalSpec ?? '').toLowerCase();
    final tone = (vocalTone ?? '').toLowerCase();
    final vibeL = vibe.toLowerCase();
    final melodyBlob =
        '${melodyStyleId.trim()} ${melodyCustomNotes.trim()}'.toLowerCase();

    final soulfulFemalePrayerful = (spec.contains('female') ||
            spec.contains('woman') ||
            spec.contains('soprano')) &&
        (tone.contains('prayerful') ||
            tone.contains('soulful') ||
            tone.contains('breathy') ||
            tone.contains('warm') ||
            vibeL.contains('prayerful'));

    if (soulfulFemalePrayerful ||
        vibeL.contains('soulful female') ||
        vibeL.contains('prayerful')) {
      parts.add(
        'VOCAL CADENCE DIRECTIVE: Write short, rhythmic lines with heavy vowel '
        'sounds (oh, ah) that allow a vocalist to bend notes and deliver a slow, '
        'bluesy, prayerful cadence.',
      );
    }

    if (vibeL.contains('gospel country lift') ||
        vibeL.contains('gospel choir') ||
        vibeL.contains('choir lift') ||
        melodyBlob.contains('call_response') ||
        melodyBlob.contains('anthemic') ||
        melodyBlob.contains('blues_gospel')) {
      parts.add(
        'CHORUS DIRECTIVE (Gospel Country Lift): Ensure the chorus uses simple, '
        'anthemic, easily harmonized declarations that a full gospel choir could '
        'instantly back up.',
      );
    }

    if (tone.contains('twang') || spec.contains('male lead')) {
      parts.add(
        'RAW COUNTRY DELIVERY: Conversational story-first phrasing; concrete '
        'geography over abstract grief; let testimony land in the chest voice.',
      );
    }

    return parts.join('\n');
  }

  /// OpenAI-style few-shot prefix inserted before the live user block.
  static List<Map<String, String>> fewShotPrefixMessages() => [
        {'role': 'user', 'content': fewShotUserTurn},
        {'role': 'assistant', 'content': fewShotAssistantTurn},
      ];

  static bool shouldInjectFewShot({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    bool lyricsTask = true,
  }) {
    if (!lyricsTask) return false;
    if (MasterGospelLyricEngine.shouldInjectFewShot(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
      lyricsTask: lyricsTask,
    )) {
      return false;
    }
    return isLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    );
  }

  static List<String> placeholderBanList() => List.unmodifiable(_placeholderBan);
}
