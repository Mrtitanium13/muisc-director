/// Master Pop lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class MasterPopLyricEngine {
  MasterPopLyricEngine._();

  static const List<String> _genreMarkers = [
    'pop',
    'mainstream pop',
    'electropop',
    'electro pop',
    'dance pop',
    'synth pop',
    'synthpop',
    'bedroom pop',
    'indie pop',
    'k-pop',
    'kpop',
    'j-pop',
    'jpop',
    'c-pop',
    'cpop',
    'mandopop',
    'hyperpop',
    'latin pop',
    'max martin',
  ];

  static const String profileMainstream = 'mainstream';
  static const String profileBedroomIndie = 'bedroom_indie';
  static const String profileIdolPop = 'idol_pop';

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
STRICT WRITING RULES FOR ALL POP:
- Chorus must contain one ≤6-word sticky line grounded in THIS conflict.
- Verse 2 must add new detail, not restate Verse 1.
- Prefer AABB/ABAB when it serves the hook; imperfect rhyme OK in indie lanes.
- No production-as-emotion (beat/drop/bass as savior).
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
''';

  static const String masterRolePrompt = '''
You are a master pop lyricist. Write hyper-singable, commercially precise lyrics with human interpersonal friction — never motivational-poster or neon-slogan filler.
''';

  static const Map<String, String> _subGenreMatrix = {
    profileMainstream: '''
SUB-GENRE: MAINSTREAM POP / DANCE-ELECTROPOP
- Vibe: Immediate hooks, symmetrical lines, commercial earworms.
- Focus: One clear interpersonal conflict; chorus = ≤6-word sticky line.
- Arrangement: [Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Pre-Chorus]
  [Chorus] [Bridge] [Final Chorus] [Outro] [End].
- Syllables: Verse 8–12 · Pre 6–10 · Chorus 4–8 · Post 2–6.
''',
    profileBedroomIndie: '''
SUB-GENRE: BEDROOM / INDIE POP
- Vibe: Soft, unpolished, close-mic home-studio honesty.
- Focus: Small domestic details over arena slogans.
- Arrangement: Sparse verse → gentle chorus lift → quiet bridge.
- Syllables: Verse 6–12 · Chorus 4–8. Imperfect rhyme welcome.
''',
    profileIdolPop: '''
SUB-GENRE: IDOL / MULTI-MEMBER / LATIN POP
- Vibe: Group stacks, dramatic pre-chorus, bilingual hooks when language allows.
- Focus: Camera-ready specificity — missed cue, last take, say my name once.
- Ban: starlight eyes, synchronized heart, dream chase, neon rain as empty glitter.
- Arrangement: Verse → Pre → Chorus → Dance break / Bridge → Final Chorus.
''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(tokens: ['mainstream', 'max martin', 'dance pop', 'electropop', 'synth pop', 'synthpop', 'hyperpop'], profile: profileMainstream),
    _ProfileRule(tokens: ['bedroom', 'indie pop'], profile: profileBedroomIndie),
    _ProfileRule(tokens: ['k-pop', 'kpop', 'j-pop', 'jpop', 'c-pop', 'cpop', 'mandopop', 'latin pop'], profile: profileIdolPop),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR POP:
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

  static bool isPopLane({
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
    return profileMainstream;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileMainstream => 'Mainstream Pop / Max Martin / Dance Pop',
        profileBedroomIndie => 'Bedroom Pop / Indie Pop',
        profileIdolPop => 'K-Pop / J-Pop / C-Pop / Mandopop',
        _ => 'Pop',
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
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileMainstream]!;
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
    if (!isPopLane(
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
        ? 'Write a song-specific conflict for this pop lane.'
        : lyricThemeNotes.trim();
    return '''
USER SELECTIONS (POP MASTER):
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

  static const String _mainstreamFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft synth pulse, dry close-mic]

[Verse 1: Dry intimate female lead]
You left your jacket on my chair again
I almost texted then I didn't
You said "busy" like it meant something soft
It didn't

[Pre-Chorus: Doubles enter]
Say it straight
Say it straight
Don't dress it up

[Chorus: Wide stack, punchy hook]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Verse 2]
I practiced calm in the bathroom mirror
Then you walked in laughing at your phone
I kept my voice down for the neighbors
Not for you

[Pre-Chorus]
Say it straight
Say it straight
Don't dress it up

[Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Bridge: Stripped]
One more night then I'm gone
I meant every word

[Final Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Outro: Soft fade]

[End]
''';

  static const String _bedroomIndieFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Lo-fi keys, tape hiss light]

[Verse 1: Soft close-mic]
Cold tea on the desk again
Paper on the wall peeling at the corner
I said I'd clean it Sunday
It's Thursday and I still haven't

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Verse 2]
Your hoodie still smells like rain
I don't wear it
I just leave it on the chair

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Bridge]
Messy room
Quiet mind
Same problem

[Final Chorus]
I almost called
I almost called
Then I put the phone face-down

[Outro]

[End]
''';

  static const String _idolPopFewShotGood = '''
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Bright pluck, group breath]

[Verse 1: Lead + light stack]
Camera flash and I miss my mark
You mouth "again" from the side
I laugh like it doesn't sting
It does

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Verse 2]
We trade lines like we trade glances
I keep the soft one for the bridge
You keep the loud one for the drop

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Bridge]
Last chance in the hallway light
Then we walk back in

[Final Chorus]
One take left
One take left
Don't look away

[Outro]

[End]
''';

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileMainstream => _mainstreamFewShotGood,
        profileBedroomIndie => _bedroomIndieFewShotGood,
        profileIdolPop => _idolPopFewShotGood,
        _ => _mainstreamFewShotGood,
      };

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
  }) {
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a Pop song in the ${subGenreLabel(profile)} lane. '
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
      isPopLane(
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
      tokens.any((t) => MasterPopLyricEngine._hasWord(blob, t) || blob.contains(t));
}
