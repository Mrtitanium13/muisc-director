/// Master Country lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class MasterCountryLyricEngine {
  MasterCountryLyricEngine._();

  static const List<String> _genreMarkers = [
    'country',
    'modern country',
    'outlaw country',
    'americana',
    'bluegrass',
    'folk',
    'indie folk',
    'folk-rock',
    'folk rock',
    'singer-songwriter',
    'singer songwriter',
    'nashville',
  ];

  static const String profileModernCountry = 'modern_country';
  static const String profileOutlawAmericana = 'outlaw_americana';
  static const String profileFolkSongwriter = 'folk_songwriter';

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
STRICT WRITING RULES FOR ALL COUNTRY/FOLK:
- Name places, objects, and relationships; avoid abstract emotion-only lines.
- Chorus sticky line ≤8 words; Verse 2 adds new story beat.
- Twang-friendly open vowels on peak hooks.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
''';

  static const String masterRolePrompt = '''
You are a master country/folk lyricist. Write porch-true stories with place, people, and stakes — never interchangeable Nashville glitter or AI Hallmark.
''';

  static const Map<String, String> _subGenreMatrix = {
    profileModernCountry: '''
SUB-GENRE: MODERN COUNTRY
- Vibe: Story-first, place names, family/road detail, twang-friendly vowels.
- Ban: generic truck/beer checklist spam unless user theme needs it; avoid Hallmark.
- Arrangement: Verse-chorus with optional [Banjo/Steel] staging in brackets only.
''',
    profileOutlawAmericana: '''
SUB-GENRE: OUTLAW / AMERICANA
- Vibe: Weathered narrative, moral gray, concrete work and road detail.
- Prefer dusty specificity over radio-country glitter.
''',
    profileFolkSongwriter: '''
SUB-GENRE: FOLK / SINGER-SONGWRITER
- Vibe: Intimate first-person, acoustic-room honesty, nature as setting not metaphor spam.
- Lines can breathe; imperfect rhyme welcome.
''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(tokens: ['modern country', 'nashville', 'country pop'], profile: profileModernCountry),
    _ProfileRule(tokens: ['outlaw', 'americana', 'alt-country', 'alt country'], profile: profileOutlawAmericana),
    _ProfileRule(tokens: ['folk', 'indie folk', 'folk-rock', 'folk rock', 'singer-songwriter', 'singer songwriter', 'bluegrass'], profile: profileFolkSongwriter),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR COUNTRY:
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

  static bool isCountryLane({
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
    return profileModernCountry;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileModernCountry => 'Modern Country / Nashville',
        profileOutlawAmericana => 'Outlaw / Americana',
        profileFolkSongwriter => 'Folk / Singer-Songwriter',
        _ => 'Country',
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
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileModernCountry]!;
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
    if (!isCountryLane(
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
        ? 'Write a song-specific conflict for this country lane.'
        : lyricThemeNotes.trim();
    return '''
USER SELECTIONS (COUNTRY MASTER):
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

  static const String _modernCountryFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Acoustic strum, soft steel]

[Verse 1: Warm close-mic]
Screen door still sticks in July
Mama said you'd call by Sunday
It's Wednesday and the coffee went cold
I left your chair pulled out anyway

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Verse 2]
Dust on the dash from the county road
I kept your postcard in the glove box
Folded wrong on purpose

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Bridge]
If you're gone, say you're gone
I can take the truth

[Final Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Outro]

[End]
''';

  static const String _outlawAmericanaFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dry acoustic, room tone]

[Verse 1]
I fixed the fence you broke last spring
Didn't ask for thanks
You left a note under the sugar jar
Said "sorry" like it was enough

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Verse 2]
Midnight train don't stop for pride
I learned that the hard way twice

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Bridge]
I ain't holy
I ain't clean
I'm still here

[Final Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Outro]

[End]
''';

  static const String _folkSongwriterFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Fingerpicked acoustic]

[Verse 1]
I walked the long way past your street
So I wouldn't have to wave
The porch light was on like always
I kept moving

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Verse 2]
Cold rain on the open plains
I talked to myself like you were listening

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Bridge]
Maybe that's growth
Maybe that's just tired

[Final Chorus]
I still know your window
I still know your window
I don't knock anymore

[Outro]

[End]
''';

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileModernCountry => _modernCountryFewShotGood,
        profileOutlawAmericana => _outlawAmericanaFewShotGood,
        profileFolkSongwriter => _folkSongwriterFewShotGood,
        _ => _modernCountryFewShotGood,
      };

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
  }) {
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a Country song in the ${subGenreLabel(profile)} lane. '
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
      isCountryLane(
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
      tokens.any((t) => MasterCountryLyricEngine._hasWord(blob, t) || blob.contains(t));
}
