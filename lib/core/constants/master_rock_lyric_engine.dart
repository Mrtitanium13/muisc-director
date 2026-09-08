/// Master Rock lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class MasterRockLyricEngine {
  MasterRockLyricEngine._();

  static const List<String> _genreMarkers = [
    'rock',
    'classic rock',
    'hard rock',
    'alternative',
    'alt rock',
    'indie rock',
    'pop punk',
    'pop-punk',
    'punk',
    'emo',
    'metal',
    'metalcore',
    'heavy metal',
    'post-rock',
    'shoegaze',
  ];

  static const String profileClassicAlt = 'classic_alt';
  static const String profilePopPunkEmo = 'pop_punk_emo';
  static const String profileMetalHeavy = 'metal_heavy';

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
STRICT WRITING RULES FOR ALL ROCK:
- Choruses anthemic but song-specific; verses carry concrete friction.
- Tag instrumental breaks as staging only; Fourth-Wall Law on sung lines.
- Verse 2 must escalate or complicate Verse 1.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
''';

  static const String masterRolePrompt = '''
You are a master rock/metal lyricist. Write guitar-era grit with real interpersonal stakes — never neon-wild festival slogans.
''';

  static const Map<String, String> _subGenreMatrix = {
    profileClassicAlt: '''
SUB-GENRE: CLASSIC / ALT / INDIE ROCK
- Vibe: Guitar-driven grit, live-room honesty, stadium chorus when earned.
- Focus: Argument mid-sentence, cracked windshield detail, not neon wild slogans.
- Arrangement: [Intro] [Verse] [Chorus] [Verse] [Chorus] [Bridge/Solo tag] [Final Chorus] [Outro].
- Allow [Guitar Solo] staging; no gear names in sung lines.
''',
    profilePopPunkEmo: '''
SUB-GENRE: POP PUNK / EMO / PUNK
- Vibe: Fast, nasal, angst-fueled verses → explosive melodic choruses.
- Focus: Dead-end town specificity, parking-lot fights, apologies said wrong.
- Ban: teenage shadows, rise up, empty scream-for-scream slogans.
''',
    profileMetalHeavy: '''
SUB-GENRE: METAL / METALCORE
- Vibe: Staccato verse aggression → soaring clean or guttural payoff.
- Focus: Concrete pressure and defiance — not fantasy-sword spam unless user asks.
- Ban: bubblegum romance, rise up / burn it down as empty mantras.
- Allow scream-ready syllables in breakdowns; clean legato in choruses when melodic.
''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(tokens: ['classic rock', 'hard rock', 'alternative', 'alt rock', 'indie rock'], profile: profileClassicAlt),
    _ProfileRule(tokens: ['pop punk', 'pop-punk', 'punk', 'emo'], profile: profilePopPunkEmo),
    _ProfileRule(tokens: ['metal', 'metalcore', 'heavy metal', 'death metal'], profile: profileMetalHeavy),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR ROCK:
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

  static bool isRockLane({
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
    return profileClassicAlt;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileClassicAlt => 'Classic / Alt / Indie Rock',
        profilePopPunkEmo => 'Pop Punk / Emo / Punk',
        profileMetalHeavy => 'Metal / Metalcore / Heavy',
        _ => 'Rock',
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
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileClassicAlt]!;
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
    if (!isRockLane(
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
        ? 'Write a song-specific conflict for this rock lane.'
        : lyricThemeNotes.trim();
    return '''
USER SELECTIONS (ROCK MASTER):
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

  static const String _classicAltFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Distorted guitar figure, dry room]

[Verse 1: Gritty close-mic male lead]
Engine ticking cool in the lot
You said it mid-sentence then walked
I stood there with the door half open
Like an idiot with a cracked windshield

[Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Verse 2]
I kept the volume up so I wouldn't think
You kept the keys so I'd have to ask
We both pretended that was normal

[Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Bridge: Guitar break staging]
I said it too loud
I meant it anyway

[Final Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Outro]

[End]
''';

  static const String _popPunkEmoFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Fast downstrokes]

[Verse 1: Punchy nasal lead]
Dead-end town and a parking-lot fight
I meant the apology
You heard the volume
Same old mess in a new jacket

[Chorus]
Don't call my mom
Don't call my mom
I already left

[Verse 2]
We screamed loud then went quiet
Like we practiced being strangers

[Chorus]
Don't call my mom
Don't call my mom
I already left

[Bridge]
I wrote it down then tore it up
Still true

[Final Chorus]
Don't call my mom
Don't call my mom
I already left

[Outro]

[End]
''';

  static const String _metalHeavyFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Palm-mute chug]

[Verse 1: Tight staccato]
They put a number on my name
Counted my breath like inventory
I stopped answering
I started pushing back

[Chorus: Clean belted]
Not today
Not today
Get back

[Breakdown: Harsh]
NEVER

[Chorus]
Not today
Not today
Get back

[Bridge]
No clean apology
No soft landing

[Final Chorus]
Not today
Not today
Get back

[Outro]

[End]
''';

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileClassicAlt => _classicAltFewShotGood,
        profilePopPunkEmo => _popPunkEmoFewShotGood,
        profileMetalHeavy => _metalHeavyFewShotGood,
        _ => _classicAltFewShotGood,
      };

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
  }) {
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a Rock song in the ${subGenreLabel(profile)} lane. '
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
      isRockLane(
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
      tokens.any((t) => MasterRockLyricEngine._hasWord(blob, t) || blob.contains(t));
}
