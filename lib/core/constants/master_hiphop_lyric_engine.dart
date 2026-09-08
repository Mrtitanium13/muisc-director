/// Master HipHop lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class MasterHipHopLyricEngine {
  MasterHipHopLyricEngine._();

  static const List<String> _genreMarkers = [
    'hiphop',
    'hip-hop',
    'hip hop',
    'rap',
    'boom bap',
    'boombap',
    'trap',
    'drill',
    'phonk',
    'grime',
    'uk drill',
  ];

  static const String profileBoomBap = 'boom_bap';
  static const String profileTrapDrill = 'trap_drill';
  static const String profileConscious = 'conscious';

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
STRICT WRITING RULES FOR ALL HIP-HOP:
- Internal rhyme and concrete detail preferred over abstract flex.
- Hook repeats with purpose; verses advance the scene.
- No beat/bass-as-savior metaphors.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
''';

  static const String masterRolePrompt = '''
You are a master hip-hop lyricist. Write punchy, picture-heavy bars and hooks with human stakes — never empty flex or AI motivator spam.
''';

  static const Map<String, String> _subGenreMatrix = {
    profileBoomBap: '''
SUB-GENRE: BOOM BAP / CLASSIC RAP
- Vibe: Internal rhyme, concrete street/detail imagery, sample-era authenticity.
- No empty flex filler; no motivational poster bars.
- Hook can be sung or chanted; verses carry pictures.
''',
    profileTrapDrill: '''
SUB-GENRE: TRAP / DRILL / PHONK
- Vibe: 808-pocket phrasing, cold mood, triplet-friendly counts, hook-first.
- Ban: soft pop-acoustic clichés; empty rise-up motivators.
- Keep bars tactical and specific — not cartoon violence unless user asks.
''',
    profileConscious: '''
SUB-GENRE: CONSCIOUS / STORY RAP
- Vibe: Narrative bars, social/personal stakes, vivid scenes.
- Still ban Hallmark and empty slogans; keep language human.
''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(tokens: ['boom bap', 'boombap', 'classic rap', 'jazz rap'], profile: profileBoomBap),
    _ProfileRule(tokens: ['trap', 'drill', 'uk drill', 'phonk'], profile: profileTrapDrill),
    _ProfileRule(tokens: ['conscious', 'story rap', 'lyrical rap'], profile: profileConscious),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR HIP-HOP:
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

  static bool isHipHopLane({
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
    return profileBoomBap;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileBoomBap => 'Boom Bap / Classic Rap',
        profileTrapDrill => 'Trap / Drill / Phonk',
        profileConscious => 'Conscious / Story Rap',
        _ => 'HipHop',
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
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileBoomBap]!;
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
    if (!isHipHopLane(
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
        ? 'Write a song-specific conflict for this hiphop lane.'
        : lyricThemeNotes.trim();
    return '''
USER SELECTIONS (HIPHOP MASTER):
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

  static const String _boomBapFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dusty drum break]

[Verse 1]
Receipts in my pocket, auntie on the line
Asking if I ate — I say I'm fine
Gate light buzzing like it knows my name
I walk past the corner where we used to claim

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Verse 2]
Vinyl in the crate, story in the scratch
I don't need a caption for the way I act

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Bridge]
No speech
Just proof

[Final Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Outro]

[End]
''';

  static const String _trapDrillFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: 808 pulse, sparse hats]

[Verse 1]
Phone face-down, I already know the tone
You want a favor dressed up like a bond
I learned the code: don't talk, just move
Cold steel quiet — nothing to prove

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Verse 2]
Tracking every almost — I delete the thread
Zero mercy for the story that you said

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Bridge]
Say it once
Then leave

[Final Chorus]
Don't text me late
Don't text me late
I ain't on call

[Outro]

[End]
''';

  static const String _consciousFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]

[Verse 1]
Mama praying soft while the kettle clicks
I count the rent in ones and little tricks
School fees staring from the kitchen table
I laugh it off — I'm not that able

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Verse 2]
WhatsApp group lighting up with bills and births
I type "I'll call" and mean the words

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Bridge]
Not a speech
A transfer

[Final Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Outro]

[End]
''';

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileBoomBap => _boomBapFewShotGood,
        profileTrapDrill => _trapDrillFewShotGood,
        profileConscious => _consciousFewShotGood,
        _ => _boomBapFewShotGood,
      };

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
  }) {
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a HipHop song in the ${subGenreLabel(profile)} lane. '
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
      isHipHopLane(
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
      tokens.any((t) => MasterHipHopLyricEngine._hasWord(blob, t) || blob.contains(t));
}
