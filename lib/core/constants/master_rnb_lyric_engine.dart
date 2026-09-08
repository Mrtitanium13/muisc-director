/// Master RnB lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class MasterRnbLyricEngine {
  MasterRnbLyricEngine._();

  static const List<String> _genreMarkers = [
    'rnb',
    'r&b',
    'r and b',
    'contemporary r&b',
    'contemporary rnb',
    'neo-soul',
    'neo soul',
    'trap soul',
    'quiet storm',
    'new jack',
    'soul',
  ];

  static const String profileTrapSoul = 'trap_soul';
  static const String profileNeoSoul = 'neo_soul';
  static const String profileContemporary = 'contemporary';

  static const String crossArchitectureRules = '''
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Lead ad-libs: ...); parens contain sung words only.
- Scan every staging bracket against SECTION D AI-generic blacklist before
  emission.
- HUMAN AUTHENTICITY (MANDATORY): conversational speech, song-specific
  interpersonal friction, plain words. HOOK TEST: if the chorus could paste
  onto any song unchanged, rewrite.
- BAN AI slogans/Hallmark: holding on, broken inside, pieces of me, drowning in, lost in the dark, find myself, chasing dreams, forever young, in this moment, this is real, take me higher, break free, we are thunder, rise up, burn it down, open sky, we can fly, dance with me, on the floor, break the cage, let it fall, high voltage, neon lightning, target lock, neon wild, starlight eyes.
''';

  static const String universalStrictRules = '''
STRICT WRITING RULES FOR ALL R&B:
- Verses conversational; choruses stacked and sticky.
- Ad-libs belong in parens as sung words only.
- Concrete relationship detail over abstract longing labels.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
''';

  static const String masterRolePrompt = '''
You are a master R&B/soul lyricist. Write intimate, melismatic-ready lines with real relationship friction — never neon-shadow Hallmark.
''';

  static const Map<String, String> _subGenreMatrix = {
    profileTrapSoul: '''
SUB-GENRE: TRAP SOUL
- Vibe: Dark, moody, relationship-centered vulnerability over 808 pocket.
- Short confessional lines; hook hypnotic and specific.
''',
    profileNeoSoul: '''
SUB-GENRE: NEO-SOUL / QUIET STORM
- Vibe: Organic chest-voice warmth, late-night intimacy, socially aware when theme fits.
- Prefer lived detail over velvet-skies abstractions.
''',
    profileContemporary: '''
SUB-GENRE: CONTEMPORARY R&B
- Vibe: Silky melisma room, conversational ad-libs, stacked chorus harmonies.
- Focus: Relationship specificity — hoodie on chair, phone face-down, I meant what I said.
- Ban: neon shadows, pieces of me, drowning in you.
''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(tokens: ['trap soul'], profile: profileTrapSoul),
    _ProfileRule(tokens: ['neo-soul', 'neo soul', 'quiet storm'], profile: profileNeoSoul),
    _ProfileRule(tokens: ['contemporary r&b', 'contemporary rnb', 'contemporary'], profile: profileContemporary),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR R&B:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?''';

  static String _genreBlob({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final parts = [
      primaryGenre.trim(),
      subGenreFusion.trim(),
      vibe.trim(),
      lyricThemeNotes.trim(),
    ];
    return _normalizePhrase(parts.join(' '));
  }

  static bool isRnbLane({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final blob = _genreBlob(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    );
    if (blob.isEmpty) return false;
    return _genreMarkers.any((marker) => _hasWord(blob, marker));
  }

  static String resolveProfile({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
  }) {
    final blob = _genreBlob(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    for (final rule in _profileRules) {
      if (rule.matches(blob)) return rule.profile;
    }
    return profileContemporary;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileTrapSoul => 'Trap Soul',
        profileNeoSoul => 'Neo-Soul / Quiet Storm',
        profileContemporary => 'Contemporary R&B',
        _ => 'RnB',
      };

  static String composeSystemBlock({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String? profile,
  }) {
    final p = profile ??
        resolveProfile(
          primaryGenre: primaryGenre,
          subGenreFusion: subGenreFusion,
          vibe: vibe,
        );
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileContemporary]!;
    return '''
$crossArchitectureRules

$masterRolePrompt

$subGenre

$universalStrictRules

$preOutputQa'''
        .trim();
  }

  static String composeUserBlock({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
  }) {
    if (!isRnbLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      return '';
    }
    final profile = resolveProfile(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    return '''
${composeSystemBlock(
  primaryGenre: primaryGenre,
  subGenreFusion: subGenreFusion,
  vibe: vibe,
  profile: profile,
)}

${_buildUserSelectionsBlock(
  primaryGenre: primaryGenre,
  subGenreFusion: subGenreFusion,
  vibe: vibe,
  lyricThemeNotes: lyricThemeNotes,
  vocalSpec: vocalSpec,
  vocalTone: vocalTone,
  bpmHint: bpmHint,
  profile: profile,
)}'''
        .trim();
  }

  static String _buildUserSelectionsBlock({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
    required String profile,
  }) {
    final vocalist = _formatVocalist(vocalSpec, vocalTone);
    final bpm = (bpmHint ?? '').trim();
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'Write a song-specific conflict for this rnb lane.'
        : lyricThemeNotes.trim();
    return '''
USER SELECTIONS (RNB MASTER):
- Primary genre: $primaryGenre
- Sub-genre / fusion: ${subGenreFusion.trim().isEmpty ? '(none)' : subGenreFusion.trim()}
- Resolved profile: $profile (${subGenreLabel(profile)})
- Vibe: ${vibe.trim().isEmpty ? '(none)' : vibe.trim()}
- Theme / story: $theme
- Vocalist: $vocalist
- BPM hint: ${bpm.isEmpty ? '(none)' : bpm}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots.'''
        .trim();
  }

  static String _formatVocalist(String? vocalSpec, String? vocalTone) {
    final spec = (vocalSpec ?? '').trim();
    final tone = (vocalTone ?? '').trim();
    if (spec.isEmpty && tone.isEmpty) return 'Close-mic lead appropriate to lane';
    if (spec.isEmpty) return tone;
    if (tone.isEmpty) return spec;
    return '$spec · $tone';
  }

  static const String _trapSoulFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dark pad, 808]

[Verse 1]
I keep replaying what you didn't say
Kitchen light buzzing like a warning
You want soft
I want straight

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Verse 2]
I bit my tongue till it tasted like staying
I'm done with that flavor

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Bridge]
One honest line
That's all

[Final Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Outro]

[End]
''';

  static const String _neoSoulFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Warm Rhodes]

[Verse 1]
Late ride home with the window cracked
City humming like it knows my secrets
I told you I'd be better by spring
Spring came quiet

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Verse 2]
Your laugh still sits in the passenger seat
I don't move it

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Bridge]
Sweet healing ain't a slogan
It's putting the fight down

[Final Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Outro]

[End]
''';

  static const String _contemporaryFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft keys, intimate]

[Verse 1: Smooth close-mic]
Your hoodie on my chair again
Phone face-down like I'm not tempted
I almost called then I laughed it off
I meant what I said last week

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Verse 2]
You talk soft when you want a door open
I learned that tone the hard way

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Bridge]
Say it to my face
Or don't say it

[Final Chorus]
I almost called
I almost called
Then I left it alone

[Outro]

[End]
''';

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileTrapSoul => _trapSoulFewShotGood,
        profileNeoSoul => _neoSoulFewShotGood,
        profileContemporary => _contemporaryFewShotGood,
        _ => _contemporaryFewShotGood,
      };

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
  }) {
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a RnB song in the ${subGenreLabel(profile)} lane. '
        'Theme: $theme. Follow the master rules. End Block 2 with [End].';
  }

  static List<Map<String, String>> fewShotPrefixMessages({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final profile = resolveProfile(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    return [
      {
        'role': 'user',
        'content': fewShotUserTurn(
          profile: profile,
          lyricThemeNotes: lyricThemeNotes,
        ),
      },
      {
        'role': 'assistant',
        'content': fewShotAssistantTurn(profile),
      },
    ];
  }

  static bool shouldInjectFewShot({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    required bool lyricsTask,
  }) =>
      lyricsTask &&
      isRnbLane(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
      );

  static String _normalizePhrase(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _hasWord(String blob, String marker) {
    final m = _normalizePhrase(marker);
    if (m.isEmpty) return false;
    if (!m.contains(' ')) {
      return RegExp(r'\b' + RegExp.escape(m) + r'\b').hasMatch(blob);
    }
    return blob.contains(m);
  }
}

class _ProfileRule {
  const _ProfileRule({required this.tokens, required this.profile});
  final List<String> tokens;
  final String profile;
  bool matches(String blob) =>
      tokens.any((t) => MasterRnbLyricEngine._hasWord(blob, t) || blob.contains(t));
}
