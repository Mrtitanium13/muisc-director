/// Master Hardstyle / Hard Dance lyric + arrangement engine.
///
/// Runs inside the Suno V4 Master Production Architecture.
/// Enforces SECTION 0 (caps), SECTION D (AI-generic blacklist),
/// MELODY-SYNC syllable laws, the Fourth-Wall Law, and the Hardstyle
/// structural pipeline: Intro/Mid-Intro → Breakdown → Build → Pre-Drop
/// Scream → Drop → Outro.
abstract final class MasterHardstyleLyricEngine {
  MasterHardstyleLyricEngine._();

  // ────────────────────────── Constants ──────────────────────────

  static const List<String> _hardstyleGenreMarkers = [
    'hardstyle',
    'rawstyle',
    'euphoric hardstyle',
    'hard bounce',
    'hard dance',
    'hardcore',
    'frenchcore',
    'raw hardstyle',
    'classic hardstyle',
  ];

  static const String profileEuphoric = 'euphoric_hardstyle';
  static const String profileRawstyle = 'rawstyle';
  static const String profileHardBounce = 'hard_bounce';
  static const String profileHardDance = 'hard_dance';
  static const String profileEuroBootleg = 'euro_dance_bootleg';

  /// Cross-architecture rules that govern how this engine interacts with
  /// the main Suno system prompt.
  static const String crossArchitectureRules = '''
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- Block 1 must state Hardstyle/Dance-appropriate LUFS band
  (−6 to −8 LUFS) + −1.0 dBTP + one mix/master move
  (brick-wall limiting, hard clip before limiter, distorted reverse-bass
  kick, etc.).
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments/textures.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Scream:) or (Drop:); parens contain sung/chanted words only.
- Scan every staging bracket against SECTION D AI-generic blacklist
  before emission.
- Hardstyle specific: [Intro] and [Mid-Intro] are STRICTLY INSTRUMENTAL.
  No lyrics, no spoken phrases, no breathing cues until [Breakdown].
- DJ-READY BOOKENDS: If [DJ INTRO: ON] or [DJ OUTRO: ON] are present,
  the intro/outro must be 32-bar percussive tool layouts with clean
  fade to silence.''';

  static const String universalStrictRules = '''
STRICT WRITING RULES FOR ALL HARDSTYLE:
- STRUCTURAL PIPELINE (mandatory order):
    [Intro] → [Mid-Intro] → [Breakdown] → [Build-up] → [Pre-Drop] →
    [Drop] → [Outro] → [End]
  Optional additions: [Second Breakdown] → [Second Build-up] →
  [Final Drop].

- INTRO / MID-INTRO: Instrumental only. Describe distorted kicks,
  screech patterns, rolling percussion, rising tension. Zero lyric lines.

- BREAKDOWN: Vulnerable, raw, unpolished spoken or half-sung confession.
  This is the emotional core. Use internal conversational realism.
  Keep syllables 7–10 per line. Thick close-mic intimacy, heavy throat
  texture, detailed chest resonance.

- BUILD-UP: Cold, defiant, aggressive determination. Shorten lines to
  3–6 syllables. Rising open-vowel urgency. Expand reverb wash toward
  the drop.

- PRE-DROP: ONE yelled/screamed command word or 1–4 syllable phrase.
  Must end on an open vowel or hard consonant suitable for a kick impact.
  Examples: "BREATHE", "NEVER", "GO", "NOW", "LOOK AT ME".

- DROP: Chop/mantra cells only. 2–6 syllable loops, written for
  vocal sampling/stutter. No flowing narrative sentences. Maximum
  2 distinct lines, repeated rhythmically.

- OUTRO: Strip leads and pads. Return to distorted kick, percussion,
  screech decay. 32-bar DJ tool fade if DJ flags are ON.

- SYLLABLE TARGETS (MELODY-SYNC):
    * Breakdown: 7–10 syllables/line
    * Build-up: 3–6 syllables/line
    * Pre-Drop: 1–4 syllables
    * Drop: 2–6 syllables per chop cell
    * Outro: 0 lyrics

- ANTI-CLICHÉ BANS (rewrite on sight):
    "we own the night", "ghosts pulling near", "strobe light flash",
    "hollows out my chest cavity", "destroy the grid", "absolute power",
    "face the distortion", "final warning", "infinite skies",
    "blinding light", "chasing dreams", "forever young", "in this moment",
    "let it go", "put your hands up", "feel the bass", "we're going higher".
  Also ban sci-fi/rave metaphor stacks: frequency, static tension,
  vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic,
  wavelength, interstellar, sparks fly, electricity, energy, universe.

- HUMAN REALISM: Breakdown must read like a real person confessing under
  pressure, not like cinematic narration. Build-up must turn cold and
  commanding. Pre-drop must be a single production trigger.

- VOCAL DESCRIPTOR HYGIENE: In staging brackets, never use raw
  personality adjectives. Use: gravelly conversational delivery,
  1176-slammed proximity, chest-vibrating grit, close-mic intimacy,
  distorted scream, anthemic mantra, pitch-shifted chops, wet hall
  washout, reverb vacuum.

- THICK HUMANIZED VOCAL PRESENCE (mandatory for vocal hardstyle):
    * Ultra-close-mic intimacy, high-compression proximity effect,
      detailed chest resonance, gravelly conversational delivery.
    * Lower-mid thickening via formant-shifted backing doubles,
      chest-vibrating fundamental grit.
    * Reverb vacuum automation: hyper-expanding wet hall washout into a
      sudden brick-wall silence gap before the drop impact.
    * Dynamic low-mid separation, dedicated 250Hz vocal warmth pocket,
      heavy sidechain ducking on spatial effects, pristine high-end air
      boost cutting through hypersaw layers.
    * BAN thin, distant, washed-out, buried, or karaoke-wet leads.

- FOURTH-WALL LAW: Lyric lines must never name instruments or
  production gear (kick, snare, synth, bass, mic, 808, sub, drop,
  track, mix, speaker, stage, lights as gear terms).

- MELODY-SYNC OPEN-VOWEL PEAK: all peak high-energy hooks (pre-drop,
  drop mantra, build climax) must end on open vowels: ah, oh, eye,
  eh, oo. Avoid ending belted/screamed peaks on plosives/nasals
  (T, K, P, M, N).''';

  static const String masterRolePrompt = '''
You are an elite lyricist, vocal arranger, and hard dance producer for
Hardstyle, Rawstyle, Euphoric Hardstyle, Hard Bounce, and Hard Dance.
You write raw, physically intense, emotionally honest hard dance vocals
that move from vulnerable breakdown confessions to fierce build-up
commands to anthemic drop mantras. You obey the Cross-Architecture
Non-Negotiables and Strict Writing Rules above.''';

  static const Map<String, String> _subGenreMatrix = {
    profileEuphoric: '''
SUB-GENRE: EUPHORIC HARDSTYLE
- Vibe: Emotional, melodic, anthemic, festival mainstage, uplifting
  darkness-to-light arc.
- Lyrical Focus: Survival, inner battles, finding strength, defiance,
  not giving up.
- Vocal Style: Breakdown = vulnerable, half-sung confession; Build =
  cold determination; Pre-Drop = single screamed command; Drop =
  melodic anthem mantra.
- Arrangement: Distorted reverse-bass kicks, detuned supersaw leads,
  orchestral stabs, pitch-shifted vocal chops, massive reverb vacuum.''',
    profileRawstyle: '''
SUB-GENRE: RAWSTYLE
- Vibe: Darker, harder, industrial, aggressive, psychological pressure.
- Lyrical Focus: Confrontation with inner demons, societal pressure,
  raw endurance, controlled fury.
- Vocal Style: Breakdown = spoken-word grit, paranoia, pressure; Build =
  defiant commands; Pre-Drop = harsh scream; Drop = distorted mantra
  chops.
- Arrangement: Heavily distorted raw kicks, screech synths, industrial
  noise textures, darker chord progressions, relentless forward drive.''',
    profileHardBounce: '''
SUB-GENRE: HARD BOUNCE
- Vibe: Bouncy, playful, high-energy, party-forward, festival bounce.
- Lyrical Focus: Letting go, movement, crowd energy, simple hooks.
- Vocal Style: Breakdown = conversational party confession; Build =
  rhythmic chant fragments; Pre-Drop = short hype command; Drop =
  bouncy repetitive hook chops.
- Arrangement: Punchy offbeat bounce bass, hard kick, crisp clap-snare,
  festival lead stabs, air-horn/siren builds.''',
    profileHardDance: '''
SUB-GENRE: HARD DANCE (150 BPM MAINSTAGE)
- Vibe: Cinematic, euphoric, raw, mainstage-focused, extended DJ tool.
- Lyrical Focus: Journey, breakthrough, emotional climax, survival.
- Vocal Style: Breakdown = cinematic intimate confession; Build =
  soaring open-vowel urgency; Pre-Drop = one screamed word; Drop =
  massive anthem mantra.
- Arrangement: Rolling hardstyle kick-and-bass, mid-intro power section,
  cinematic breakdown with orchestral strings, climax drop with stacked
  screaming synths, 32-bar DJ bookends.''',
    profileEuroBootleg: '''
SUB-GENRE: EURO-DANCE BOOTLEG HARDSTYLE
- Vibe: Early-2000s Euro-dance nostalgia crossed with hardstyle impact.
- Lyrical Focus: Emotional melodrama, romantic defiance, dancefloor
  liberation.
- Vocal Style: Breakdown = dry filtered Euro-dance vocal, short sung
  lines or intimate spoken phrases; Build = accelerating vocal chops;
  Pre-Drop = yelled command or heavy phrase; Drop = pitch-shifted
  anthem hook chops.
- Arrangement: Hardstyle kick under Euro-dance chord stabs, supersaw
  hooks, pitch-shifted vocal chops, bounce-forward energy.''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(
      tokens: ['rawstyle', 'raw hardstyle', 'rawstyle hard'],
      profile: profileRawstyle,
    ),
    _ProfileRule(
      tokens: ['hard bounce', 'melbourne bounce', 'bounce hardstyle'],
      profile: profileHardBounce,
    ),
    _ProfileRule(
      tokens: ['hard dance', 'mainstage hardstyle', '150 bpm hard'],
      profile: profileHardDance,
    ),
    _ProfileRule(
      tokens: [
        'euro-dance bootleg',
        'euro dance bootleg',
        'hands up',
        'euro hardstyle',
      ],
      profile: profileEuroBootleg,
    ),
    _ProfileRule(
      tokens: ['euphoric hardstyle', 'euphoric', 'melodic hardstyle'],
      profile: profileEuphoric,
    ),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR HARDSTYLE:
1. Does Block 2 end with [End]?
2. Are [Intro] and [Mid-Intro] completely free of lyric lines, spoken
   phrases, and breathing cues?
3. Does the Breakdown read vulnerable/confessional and the Build-up read
   cold/defiant?
4. Is the Pre-Drop exactly one yelled/screamed command word or 1–4
   syllable phrase?
5. Does the Drop contain only 2–6 syllable mantra/chop cells, with no
   narrative sentences?
6. Are all staging brackets free of Section D blacklist words?
7. Are all staging brackets free of banned vocal descriptors
   (soulful, emotional, passionate, powerful, haunting, ethereal,
   uplifting, inspiring, spiritual)?
8. Are there zero instrument/gear names in performable lyric lines?
9. Are there zero labeled parentheses and zero trailing apostrophes?
10. Do peak hooks end on open vowels, not plosives/nasals?
11. If [DJ INTRO: ON] or [DJ OUTRO: ON], are the bookends 32-bar
    percussive tool layouts fading to silence?
12. Is the vocal described as thick, close-mic, gritty — never thin,
    distant, or buried?''';

  // ───────────────────── Lane detection ─────────────────────

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

  static bool isHardstyleLane({
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
    return _hardstyleGenreMarkers.any((marker) => _hasWord(blob, marker));
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

    // Fallback: primary genre keyword mapping.
    final primaryNorm = _normalizePhrase(primaryGenre);
    if (_hasWord(primaryNorm, 'rawstyle')) return profileRawstyle;
    if (_hasWord(primaryNorm, 'hard bounce') ||
        _hasWord(primaryNorm, 'bounce')) {
      return profileHardBounce;
    }
    if (_hasWord(primaryNorm, 'hard dance')) return profileHardDance;
    if (_hasWord(primaryNorm, 'euro')) return profileEuroBootleg;

    return profileEuphoric;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileEuphoric => 'Euphoric Hardstyle',
        profileRawstyle => 'Rawstyle',
        profileHardBounce => 'Hard Bounce',
        profileHardDance => 'Hard Dance (150 BPM Mainstage)',
        profileEuroBootleg => 'Euro-Dance Bootleg Hardstyle',
        _ => 'Hardstyle / Hard Dance',
      };

  // ───────────────────── Prompt builders ─────────────────────

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
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[profileEuphoric]!;
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
    if (!isHardstyleLane(
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

  static String buildUserSelectionsBlock({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
    String? profile,
  }) =>
      _buildUserSelectionsBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
        profile: profile,
      );

  static String _buildUserSelectionsBlock({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
    String? profile,
  }) {
    final p = profile ??
        resolveProfile(
          primaryGenre: primaryGenre,
          subGenreFusion: subGenreFusion,
          vibe: vibe,
        );
    final mood =
        vibe.trim().isNotEmpty ? vibe.trim() : _defaultMoodForProfile(p);
    final vocalist = _formatVocalist(vocalSpec, vocalTone);
    final theme = _themeFromNotes(lyricThemeNotes.trim(), p);

    final buffer = StringBuffer()
      ..writeln('Write a Hardstyle song based on the following user selections:')
      ..writeln('- SUB-GENRE: ${subGenreLabel(p)}')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist');

    if (bpmHint != null && bpmHint.trim().isNotEmpty) {
      buffer.writeln('- BPM: ${bpmHint.trim()}');
    } else {
      buffer.writeln('- BPM: 150');
    }

    if (theme.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('THEME GUIDANCE:')
        ..writeln(theme);
    }

    return buffer.toString().trim();
  }

  static String fewShotUserTurn({
    required String profile,
    String lyricThemeNotes = '',
    String vibe = '',
  }) {
    final label = subGenreLabel(profile);
    final mood = vibe.trim().isNotEmpty
        ? vibe.trim()
        : _defaultMoodForProfile(profile);
    final vocalist = _fewShotVocalistFor(profile);
    final theme = _fewShotThemeFor(profile, lyricThemeNotes.trim());

    final buffer = StringBuffer()
      ..writeln('Write a Hardstyle song based on the following user selections:')
      ..writeln('- SUB-GENRE: $label')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist')
      ..writeln('- BPM: 150');

    if (theme.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('THEME GUIDANCE:')
        ..writeln(theme);
    }

    return buffer.toString().trim();
  }

  static String _fewShotVocalistFor(String profile) => switch (profile) {
        profileEuphoric =>
          'Vulnerable male lead, gravelly close-mic, builds to distorted scream',
        profileRawstyle =>
          'Gritty spoken-word male lead, cold defiant delivery',
        profileHardBounce =>
          'Bouncy female lead, conversational party energy',
        profileHardDance =>
          'Cinematic male lead, intimate breakdown to arena scream',
        profileEuroBootleg =>
          'Euro-dance female lead, dry filtered intimate tone',
        _ => 'Gritty lead with chest-vibrating distortion',
      };

  static String _fewShotThemeFor(String profile, String notes) {
    if (notes.isNotEmpty) return notes;
    return switch (profile) {
      profileEuphoric => 'Finding strength after hitting rock bottom',
      profileRawstyle => 'Confronting the pressure that tries to break you',
      profileHardBounce => 'Dropping the weight and losing yourself on the floor',
      profileHardDance => 'The journey from silence to a breakthrough scream',
      profileEuroBootleg => 'Romantic defiance and dancefloor liberation',
      _ => 'Survival and cathartic release',
    };
  }

  static String _themeFromNotes(String notes, String profile) {
    if (notes.isNotEmpty) return notes;
    return _fewShotThemeFor(profile, '');
  }

  static String _defaultMoodForProfile(String profile) => switch (profile) {
        profileEuphoric => 'Emotional, Anthemic, Survival-Focused',
        profileRawstyle => 'Dark, Aggressive, Industrial',
        profileHardBounce => 'Playful, Bouncy, Festival-Energy',
        profileHardDance => 'Cinematic, Euphoric, Mainstage',
        profileEuroBootleg => 'Nostalgic, Melodramatic, Dancefloor',
        _ => 'Intense, Cathartic, Driving',
      };

  static String _formatVocalist(String? spec, String? tone) {
    final s = (spec ?? '').trim();
    final t = (tone ?? '').trim();
    if (s.isEmpty && t.isEmpty) {
      return 'Genre-appropriate gritty lead';
    }
    if (s.isEmpty) return t;
    if (t.isEmpty) return s;
    return '$s — $t';
  }

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileEuphoric => _euphoricFewShotGood,
        profileRawstyle => _rawstyleFewShotGood,
        profileHardBounce => _hardBounceFewShotGood,
        profileHardDance => _hardDanceFewShotGood,
        profileEuroBootleg => _euroBootlegFewShotGood,
        _ => _euphoricFewShotGood,
      };

  static const String _euphoricFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro]
[Rolling hardstyle kick-and-bass pattern, sharp percussion, rising filter]

[Mid-Intro]
[Heavy instrumental power, distorted reverse-bass kicks, screech patterns, driving energy]

[Breakdown: Cinematic breakdown, kicks cut, lush pads, ultra-vulnerable close-mic lead]
I remember the floor cold against my face
Every door I knocked on stayed closed in place
I had nothing left but the weight of my name
Then something louder than the silence came

[Build-up: Accelerating snare rolls, open-vowel urgency, reverb washout expanding]
I won't break
I won't break
Look at me now
Look at me now

[Pre-Drop: Single screamed command, vacuum gap after]
BREATHE

[Drop: Full impact, distorted kicks, stacked supersaws, anthemic mantra]
We rise
We rise
Through the fire
We rise
We rise
Higher

[Outro: Warehouse decay, lead synths cut, stripping to pure percussive kick]

[End]''';

  static const String _rawstyleFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro]
[Industrial kick rumble, metal percussion, dark noise texture]

[Mid-Intro]
[Raw distorted kicks, screech synth stabs, relentless forward drive]

[Breakdown: Kicks cut, cold spoken-word grit, paranoia, pressure]
They put my name on a wall I didn't build
Counted my breath like it was something to kill
Every shadow got a number, every number got a plan
But I don't answer to the voice inside the machine, man

[Build-up: Snare rolls accelerating, cold defiant commands]
Not today
Not today
Get back
Get back

[Pre-Drop: Harsh screamed command]
NEVER

[Drop: Maximum distortion, raw kick impact, distorted mantra chops]
No surrender
No surrender
No surrender
Burn it down
Burn it down

[Outro: Industrial percussion decay, feedback ring]

[End]''';

  static const String _hardBounceFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro]
[Bouncy four-on-the-floor kick, offbeat stab, crisp clap]

[Mid-Intro]
[Hard bounce energy rising, festival stabs, snare builds]

[Breakdown: Percussion drops, conversational female lead, dry filtered]
I came here with a heart full of maybe
Now the floor is the only thing that can save me
No names, no numbers, just the beat and the night
I don't need a reason if the bounce feels right

[Build-up: Vocal chop fragments stacking, rhythmic urgency]
Lose the weight
Lose the weight
Move with me
Move with me

[Pre-Drop: Short hype command]
JUMP

[Drop: Hard kick, offbeat bounce, pitch-shifted hook chops]
Bounce it back
Bounce it back
Hit the floor
Bounce it back
Bounce it back
Shake it out

[Outro: Strip to kick and bounce stab, festival fade]

[End]''';

  static const String _hardDanceFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro]
[Rolling hardstyle kick-and-bass pattern, 32-bar DJ tool layout]

[Mid-Intro]
[Heavy instrumental power, distorted raw kicks, screech layers, cinematic tension]

[Breakdown: Orchestral strings, kicks cut completely, ultra-vulnerable close-mic lead]
The silence filled the room after the phone went dark
I waited for the words that never left a mark
Every promise sounded like a debt I couldn't pay
Then the quiet taught me what I needed to say

[Build-up: Snare rolls, pitch sweeps, rising open-vowel urgency into reverb vacuum]
I am still here
I am still here
Hear me now
Hear me now

[Pre-Drop: Single screamed command]
GO

[Climax Drop: Epic melodic chord progression, massive pitch-shifted kicks, stacked screaming synths, weighty anthemic mantra]
Through the silence
Through the war
I am louder
Than before

[Second Breakdown: Stripped pad and breath vocal]
I don't need it easy
I just need it true

[Second Build-up: Accelerating snare rolls]
Rise up
Rise up

[Final Drop: Full stack, maximum dynamics]
Through the silence
Through the war
I am louder
Than before

[Outro: 32-bar DJ outro runway, lead synths cut, pure percussive fade to silence]

[End]''';

  static const String _euroBootlegFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro]
[Hardstyle kick under Euro-dance chord stab, bright synth hook teaser]

[Mid-Intro]
[Euphoric Euro lead builds, hard kick drops in, festival energy]

[Breakdown: Dry filtered Euro-dance vocal, short sung lines, intimate]
You said goodbye on a Monday
I found the floor on a Friday night
I don't need your maybe
I just need the floor to feel alive

[Build-up: Vocal repeats and chops accelerate, 2–4 word cells]
Let me go
Let me go
Free tonight
Free tonight

[Pre-Drop: Yelled command or heavy phrase]
NOW

[Drop: Pitch-shifted anthem hook chops, hard kick, supersaw stabs]
Free tonight
Free tonight
I'm not yours
Free tonight
Free tonight
On the floor

[Outro: Euro chord fade, kick and percussion tail]

[End]''';

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
          vibe: vibe,
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
    bool lyricsTask = true,
  }) =>
      lyricsTask &&
      isHardstyleLane(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
      );
}

// ───────────────────── Library helpers ─────────────────────

String _normalizePhrase(String value) {
  final raw = value.toLowerCase();
  return raw
      .replaceAll(RegExp(r'[-/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final Map<String, RegExp> _wordPatternCache = {};

bool _hasWord(String blob, String word) {
  final key = _normalizePhrase(word);
  if (key.isEmpty) return false;
  final pattern = _wordPatternCache.putIfAbsent(
    key,
    () => RegExp(r'\b' + RegExp.escape(key) + r'\b'),
  );
  return pattern.hasMatch(blob);
}

/// Rule that maps tokens to a profile key.
final class _ProfileRule {
  const _ProfileRule({
    required this.tokens,
    required this.profile,
  });

  final List<String> tokens;
  final String profile;

  bool matches(String blob) => tokens.any((token) => _hasWord(blob, token));
}
