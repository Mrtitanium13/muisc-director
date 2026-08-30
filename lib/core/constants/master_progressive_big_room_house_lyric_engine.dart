/// Master Progressive House / Big Room Fusion / Festival Anthem
/// lyric + arrangement engine.
///
/// Runs inside the Suno V4 Master Production Architecture.
/// Enforces SECTION 0 (caps), SECTION D (AI-generic blacklist),
/// MELODY-SYNC syllable laws, the Fourth-Wall Law, and the
/// Progressive/Big-Room structural pipeline:
/// Intro → Verse → Pre-Chorus/Build-up → Drop/Chorus → Breakdown →
/// Build-up 2 → Final Drop/Chorus → Outro.
abstract final class MasterProgressiveBigRoomHouseLyricEngine {
  MasterProgressiveBigRoomHouseLyricEngine._();

  // ────────────────────────── Constants ──────────────────────────

  static const List<String> _progressiveBigRoomMarkers = [
    'progressive house',
    'big room',
    'bigroom',
    'festival anthem',
    'festival house',
    'festival edm',
    'mainstage',
    'festival progressive',
    'prog house',
    'big room fusion',
    'progressive big room',
  ];

  static const String profileProgressiveVocal = 'progressive_vocal';
  static const String profileBigRoomFusion = 'big_room_fusion';
  static const String profileFestivalAnthem = 'festival_anthem';
  static const String profileMelodicProg = 'melodic_progressive';
  static const String profileStadiumBallad = 'stadium_ballad';

  /// Cross-architecture rules that govern how this engine interacts with
  /// the main Suno system prompt.
  static const String crossArchitectureRules = '''
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- Block 1 must state EDM/Progressive House-appropriate LUFS band
  (−6 to −8 LUFS) + −1.0 dBTP + one mix/master move
  (sidechain pump, OTT, parallel compression, hard clip before limiter,
   etc.).
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments/textures.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Build:) or (Drop:); parens contain sung/chanted words only.
- Scan every staging bracket against SECTION D AI-generic blacklist
  before emission.
- DJ-READY BOOKENDS: If [DJ INTRO: ON] or [DJ OUTRO: ON] are present,
  describe intro/outro in POSITIVE sonic terms ("wordless percussion",
  "kick loop + hats", "loopable groove tail", "long fade") — name what
  plays; never "no vocals / no melody" phrasing. Soft bar budgets only.''';

  static const String universalStrictRules = '''
STRICT WRITING RULES FOR ALL PROGRESSIVE / BIG ROOM HOUSE:
- STRUCTURAL PIPELINE (mandatory order):
    [Intro] → [Verse 1] → [Pre-Chorus / Build-up] → [Drop / Chorus] →
    [Breakdown] → [Build-up 2] → [Final Drop / Final Chorus] →
    [Outro] → [End]

  Optional additions: [Post-Chorus] after first Drop, [Second Verse]
  before second Build-up.

- INTRO: Sparse, atmospheric. Pads, plucks, filtered drums. No full
  vocal unless a 3-second audio anchor is requested; if so, keep it to
  1–2 syllables max.

- VERSE: Intimate, low-register, conversational. Short blunt fragments.
  Max 4–7 syllables per line. Heavy pauses. Close-mic intimacy.
  The verse must establish an internal psychological conflict, not a
  scene description.

- PRE-CHORUS / BUILD-UP: Exponentially increasing rhythmic urgency.
  Shift to 2–4 word cells. Lines must end on open, long-held vowels
  (A, E, O) so they stretch naturally across the rising chord
  progression. Expanding wet hall washout into a vacuum gap is allowed
  before the drop.

- DROP / CHORUS: Aggressive syncopated metric mantra loop. Maximum
  2 distinct lines, repeated rhythmically. Written for vocal chopping
  and sampling. Dry, weighty, pocketed above the supersaw wall.

- BREAKDOWN: More personal/intimate than the drop. Stripped
  instrumentation. Whispered or double-tracked vocals. Reflective
  storytelling allowed here, but keep it sparse.

- FINAL DROP / FINAL CHORUS: Same hook mantra, but wider, fuller, with
  added vocal stack or octave lift. Must feel like a peak.

- OUTRO: Strip melody and leads. Long delay tails, filtered pad fade,
  or loopable groove if DJ OUTRO is ON.

- SYLLABLE TARGETS (MELODY-SYNC):
    * Verse: 4–7 syllables/line
    * Pre-Chorus/Build-up: 2–4 syllables/line
    * Pre-Drop Trigger: 1–4 syllables
    * Drop/Chorus: 2–6 syllables per chop cell
    * Breakdown: 6–10 syllables/line, sparse

- ANTI-CLICHÉ BANS (rewrite on sight):
    "hands up", "put your hands up", "feel the beat", "when the drop hits",
    "raise your hands", "we're going higher", "let me feel your love tonight",
    "infinite skies", "blinding light", "we own the night", "lights go down",
    "scream it out", "side by side", "chasing dreams", "forever young",
    "in this moment", "let it go".
  Also ban sci-fi/rave metaphors: frequency, static tension, vibrations,
  dissolving, galaxies, starlight, seismic, neon, cosmic, wavelength,
  interstellar, sparks fly, electricity, energy, universe.

- HUMAN REALISM: Build lyrics around an internal psychological conflict:
  a sudden shift in trust, an unspoken realization, the exact moment a
  relationship fractures, a choice from which there is no return. Focus
  on raw friction between two people or within one person, not exterior
  scene-setting.

- VOCAL DESCRIPTOR HYGIENE: In staging brackets, never use raw
  personality adjectives. Use: close-mic intimacy, breathy verse vocal,
  belted chest voice, stacked harmonies wide, glossy doubles, dry
  intimate vocal, wet hall washout, sidechain pump, filtered synth stabs,
  supersaw lift, white-noise riser.

- THICK HUMANIZED VOCAL PRESENCE (mandatory for vocal progressive house):
    * Ultra-close-mic intimacy, high-compression proximity effect,
      detailed chest resonance, warm saturation, multi-tracked doubles.
    * Carve a dedicated vocal warmth pocket with dynamic low-mid
      separation.
    * Heavy sidechain ducking on spatial FX and competing beds — never
      the lead body.
    * Pristine high-end air boost so the vocal cuts through dense
      supersaw walls.
    * Build-up may use expanding wet hall washout into a sudden silence/
      vacuum gap before the drop — then slam the drop mantra dry and
      present.
    * BAN thin, distant, karaoke-wet, or buried leads.

- FOURTH-WALL LAW: Lyric lines must never name instruments or
  production gear (synth, guitar, piano, drums, bass, mic, 808, beat,
  track, drop as gear, mix, speaker, stage, lights as gear terms).

- MELODY-SYNC OPEN-VOWEL PEAK: all peak high-energy hooks (build-up,
  pre-drop trigger, drop mantra, final chorus) must end on open vowels:
  ah, oh, eye, eh, oo. Avoid ending belted peaks on plosives/nasals
  (T, K, P, M, N).''';

  static const String masterRolePrompt = '''
You are an elite lyricist and vocal arranger for Progressive House,
Big Room Fusion, and Festival Anthem productions. You write raw,
commercial, emotionally honest male/female-led vocals designed to cut through
dense supersaw walls. Your verses are intimate internal monologues, your
build-ups are ascending open-vowel urgency, and your drops are
syncopated, chop-ready mantras. You obey the Cross-Architecture
Non-Negotiables and Strict Writing Rules above.''';

  static const Map<String, String> _subGenreMatrix = {
    profileProgressiveVocal: '''
SUB-GENRE: PROGRESSIVE HOUSE (VOCAL)
- Vibe: Emotional, longing, cinematic, building, euphoric release.
- Lyrical Focus: Unspoken feelings, turning points, emotional surrender,
  unrequited or complicated love.
- Vocal Style: Verse = breathy close-mic intimacy; Build = soaring
  repetitive hook fragments; Drop = melodic anthem mantra.
- Arrangement: Evolving arpeggios, lush pads, rolling bass, supersaw
  chord progressions, long breakdowns, euphoric drops.''',
    profileBigRoomFusion: '''
SUB-GENRE: BIG ROOM FUSION / PROGRESSIVE BIG ROOM
- Vibe: Festival-scale, anthemic, larger-than-life, communal release.
- Lyrical Focus: Defiance, breaking free, collective emotional peak,
  personal revolution.
- Vocal Style: Verse = intimate confessional; Build = crowd-ready chant
  fragments; Drop = massive simple mantra.
- Arrangement: Big room kicks, supersaw walls, snare rolls, white-noise
  risers, wide stereo, hard-limited drops.''',
    profileFestivalAnthem: '''
SUB-GENRE: FESTIVAL ANTHEM
- Vibe: Mainstage euphoria, collective singing, massive hooks.
- Lyrical Focus: Shared release, unity, not giving up, surviving
  together.
- Vocal Style: Verse = personal whisper; Build = ascending chant; Drop =
  2-line anthem loop designed for 10,000 voices.
- Arrangement: Festival-sized drums, supersaw leads, piano-house chords,
  huge reverb throws, audience-friendly dynamics.''',
    profileMelodicProg: '''
SUB-GENRE: MELODIC PROGRESSIVE / MELODIC HOUSE
- Vibe: Dreamy, emotional, warm, nostalgic, sunset-driven.
- Lyrical Focus: Memory, longing, bittersweet release, intimate moments.
- Vocal Style: Verse = soft, breathy, close; Build = floating harmonies;
  Drop = emotional melodic hook.
- Arrangement: Warm analog pads, melodic basslines, arpeggios, softer
  drums, rich harmonic progressions, less aggressive than big room.''',
    profileStadiumBallad: '''
SUB-GENRE: STADIUM BALLAD PROGRESSIVE
- Vibe: Epic, emotional, slow-build, cinematic, tear-jerking.
- Lyrical Focus: Regret, hope, final chances, emotional confession.
- Vocal Style: Verse = fragile close-mic; Pre-Chorus = rising lift;
  Chorus = full belted anthem; Drop = instrumental swell or vocal chop.
- Arrangement: Piano-led, orchestral strings, massive drums entering at
  chorus, supersaw lift at peak.''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(
      tokens: ['festival anthem', 'mainstage anthem', 'festival house'],
      profile: profileFestivalAnthem,
    ),
    _ProfileRule(
      tokens: [
        'big room fusion',
        'bigroom fusion',
        'big room house',
        'bigroom house',
        'progressive big room',
      ],
      profile: profileBigRoomFusion,
    ),
    _ProfileRule(
      tokens: ['stadium ballad', 'epic ballad', 'cinematic progressive'],
      profile: profileStadiumBallad,
    ),
    _ProfileRule(
      tokens: ['melodic progressive', 'melodic house', 'sunset progressive'],
      profile: profileMelodicProg,
    ),
    _ProfileRule(
      tokens: ['progressive house', 'progressive vocal', 'vocal progressive'],
      profile: profileProgressiveVocal,
    ),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR PROGRESSIVE / BIG ROOM HOUSE:
1. Does Block 2 end with [End]?
2. Does the structure follow the pipeline:
   Intro → Verse → Pre-Chorus/Build-up → Drop/Chorus → Breakdown →
   Build-up 2 → Final Drop/Chorus → Outro?
3. Is the Verse 4–7 syllables/line, intimate, internal monologue?
4. Is the Pre-Chorus/Build-up 2–4 syllables/line, ending on open vowels?
5. Is the Pre-Drop Trigger 1–4 syllables, high-impact?
6. Does the Drop/Chorus contain only 2–6 syllable mantra/chop cells,
   maximum 2 distinct repeated lines?
7. Are all staging brackets free of Section D blacklist words?
8. Are all staging brackets free of banned vocal descriptors
   (soulful, emotional, passionate, powerful, haunting, ethereal,
   uplifting, inspiring, spiritual)?
9. Are there zero instrument/gear names in performable lyric lines?
10. Are there zero labeled parentheses and zero trailing apostrophes?
11. Do peak hooks end on open vowels, not plosives/nasals?
12. Are sci-fi/rave metaphors and DJ callout clichés fully absent?
13. Is the vocal described as thick, close-mic, weighty — never thin,
    distant, or buried under supersaws?
14. If DJ flags are ON, is the intro/outro described in positive sonic
    terms (wordless percussion, kick/hats, loopable fade) with content-
    rich instrumental bookends, not just bar counts?''';

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

  static bool isProgressiveBigRoomLane({
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
    return _progressiveBigRoomMarkers.any((marker) => _hasWord(blob, marker));
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

    final primaryNorm = _normalizePhrase(primaryGenre);
    if (_hasWord(primaryNorm, 'festival') ||
        _hasWord(primaryNorm, 'anthem') ||
        _hasWord(primaryNorm, 'mainstage')) {
      return profileFestivalAnthem;
    }
    if (_hasWord(primaryNorm, 'big room') || _hasWord(primaryNorm, 'bigroom')) {
      return profileBigRoomFusion;
    }
    if (_hasWord(primaryNorm, 'stadium') ||
        _hasWord(primaryNorm, 'ballad') ||
        _hasWord(primaryNorm, 'epic')) {
      return profileStadiumBallad;
    }
    if (_hasWord(primaryNorm, 'melodic')) return profileMelodicProg;

    return profileProgressiveVocal;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileProgressiveVocal => 'Progressive House (Vocal)',
        profileBigRoomFusion => 'Big Room Fusion',
        profileFestivalAnthem => 'Festival Anthem',
        profileMelodicProg => 'Melodic Progressive / Melodic House',
        profileStadiumBallad => 'Stadium Ballad Progressive',
        _ => 'Progressive / Big Room House',
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
    final subGenre =
        _subGenreMatrix[p] ?? _subGenreMatrix[profileProgressiveVocal]!;
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
    if (!isProgressiveBigRoomLane(
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
      ..writeln(
        'Write a Progressive/Big Room House song based on the following user selections:',
      )
      ..writeln('- SUB-GENRE: ${subGenreLabel(p)}')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist');

    if (bpmHint != null && bpmHint.trim().isNotEmpty) {
      buffer.writeln('- BPM: ${bpmHint.trim()}');
    } else {
      buffer.writeln('- BPM: 128');
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
      ..writeln(
        'Write a Progressive/Big Room House song based on the following user selections:',
      )
      ..writeln('- SUB-GENRE: $label')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist')
      ..writeln('- BPM: 128');

    if (theme.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('THEME GUIDANCE:')
        ..writeln(theme);
    }

    return buffer.toString().trim();
  }

  static String _fewShotVocalistFor(String profile) => switch (profile) {
        profileProgressiveVocal =>
          'Breathy close-mic female lead, building to belted anthem',
        profileBigRoomFusion =>
          'Intimate confessional female lead, soaring at the drop',
        profileFestivalAnthem =>
          'Female lead with festival crowd-sing energy',
        profileMelodicProg => 'Soft breathy female lead, warm and nostalgic',
        profileStadiumBallad =>
          'Fragile verse female lead, epic belted chorus',
        _ => 'Female lead with thick close-mic presence',
      };

  static String _fewShotThemeFor(String profile, String notes) {
    if (notes.isNotEmpty) return notes;
    return switch (profile) {
      profileProgressiveVocal =>
        'The moment you realize a relationship has crossed a line',
      profileBigRoomFusion => 'Personal defiance and collective release',
      profileFestivalAnthem =>
        'Surviving something hard together with thousands of people',
      profileMelodicProg =>
        'Bittersweet memory of a summer that ended too soon',
      profileStadiumBallad => 'A final confession before everything changes',
      _ => 'Internal conflict reaching emotional release',
    };
  }

  static String _themeFromNotes(String notes, String profile) {
    if (notes.isNotEmpty) return notes;
    return _fewShotThemeFor(profile, '');
  }

  static String _defaultMoodForProfile(String profile) => switch (profile) {
        profileProgressiveVocal => 'Emotional, Longing, Euphoric',
        profileBigRoomFusion => 'Festival-Scale, Defiant, Anthemic',
        profileFestivalAnthem => 'Communal, Bright, Mainstage',
        profileMelodicProg => 'Dreamy, Nostalgic, Warm',
        profileStadiumBallad => 'Epic, Cinematic, Tear-Jerking',
        _ => 'Emotional, Building, Release-Focused',
      };

  static String _formatVocalist(String? spec, String? tone) {
    final s = (spec ?? '').trim();
    final t = (tone ?? '').trim();
    if (s.isEmpty && t.isEmpty) {
      return 'Genre-appropriate female lead';
    }
    if (s.isEmpty) return t;
    if (t.isEmpty) return s;
    return '$s — $t';
  }

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileProgressiveVocal => _progressiveVocalFewShotGood,
        profileBigRoomFusion => _bigRoomFusionFewShotGood,
        profileFestivalAnthem => _festivalAnthemFewShotGood,
        profileMelodicProg => _melodicProgFewShotGood,
        profileStadiumBallad => _stadiumBalladFewShotGood,
        _ => _progressiveVocalFewShotGood,
      };

  static const String _progressiveVocalFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Evolving arpeggio, wide stereo pad, sparse drums]

[Verse 1: Close-mic female lead, dry intimate, minimal verb]
You didn't mean it
I see the change now
We hit the limit
Too quiet

[Pre-Chorus: Vocal doubles enter, tension build, rising pads]
Before I break
Before I break
Don't look
Don't look

[Drop / Chorus: Supersaw lift, sidechain pump, anthemic mantra]
Let it fall
Let it fall
Nothing left
Let it fall

[Breakdown: Stripped to pad and breath vocal, intimate]
I gave you the key
You kept a secret
We crossed the border
No warning

[Build-up 2: Snare rolls, open-vowel urgency, reverb washout]
I can't stay
I can't stay
It's gone
It's gone

[Pre-Drop: Sharp command]
Tell me

[Final Drop / Chorus: Full stack, wider, octave lift, max dynamics]
Let it fall
Let it fall
Nothing left
Let it fall

[Outro: Delay tails, filtered pad fade]

[End]''';

  static const String _bigRoomFusionFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Festival kick, filtered synth stab, rising white noise]

[Verse 1: Dry intimate female lead, close-mic, sparse]
I was standing still while the world moved on
Holding every door for a love already gone
You said "be careful" like I was made of glass
I walked through the fire just to prove I could pass

[Pre-Chorus: Building chant fragments, percussion lifts]
Not backing down
Not backing down
Hear me now
Hear me now

[Drop / Chorus: Big room supersaws, hard kick, crowd mantra]
We are thunder
We are thunder
Louder
We are thunder

[Breakdown: Stripped drums and vocal, more personal]
I don't need the crown
I just need the truth
I don't need the noise
I just need the proof

[Build-up 2: Snare roll, rising vocals]
Rise up
Rise up
Burn it down
Burn it down

[Pre-Drop: Command]
Now

[Final Drop / Chorus: Full festival stack, key lift, max width]
We are thunder
We are thunder
Louder
We are thunder

[Outro: Kick and synth stab tail, long fade]

[End]''';

  static const String _festivalAnthemFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Crowd texture if live mode, piano-house chord, kick build]

[Verse 1: Whispered female lead, close-mic, intimate]
We were lost in the same storm
Holding onto different ropes
I saw you drowning in the crowd
And I let go of all my hope

[Pre-Chorus: Group vocal stack enters, anthem lift]
Hold on
Hold on
Hold the line
Stay with me

[Drop / Chorus: Full festival arrangement, supersaw anthem]
We carry on
We carry on
Through the night
We carry on

[Breakdown: Acoustic guitar or piano only, lead vulnerable]
Every scar we earned
Every bridge we burned
Brought us to this light
Brought us to this light

[Build-up 2: Drum roll, crowd chant texture]
We carry on
We carry on

[Pre-Drop: Command]
Rise

[Final Drop / Chorus: Maximum dynamics, crowd sing-along stack]
We carry on
We carry on
Through the night
We carry on

[Outro: Piano chord fade, crowd reverb tail if live mode]

[End]''';

  static const String _melodicProgFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Warm analog pad, soft arpeggio, ambient texture]

[Verse 1: Breath female lead, close-mic, warm plate reverb]
You left your coffee on the counter
I left my heart in the summer
We were a song that ended too soon
Now every sunset sounds like you

[Pre-Chorus: Harmony doubles, bass enters]
Don't fade
Don't fade
Stay here
Stay here

[Drop / Chorus: Melodic supersaw chord, anthem hook]
Golden hour
Golden hour
Hold me now
Golden hour

[Breakdown: Stripped to pad and solo vocal]
I still drive the long way home
Past the corner where we used to go
The radio plays the song we never finished
And I keep driving

[Build-up 2: Percussion returns, rising vocals]
Golden hour
Golden hour

[Pre-Drop: Breath]
Please

[Final Drop / Chorus: Full warm arrangement, vocal stack]
Golden hour
Golden hour
Hold me now
Golden hour

[Outro: Analog pad fade, soft reverb tail]

[End]''';

  static const String _stadiumBalladFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Solo piano, sparse, cinematic]

[Verse 1: Fragile female lead, close-mic, dry]
I never said the things I should have said
I let the moment pass like it was nothing
Now you're packing boxes by the bed
And I'm still learning how to use my voice

[Pre-Chorus: Strings enter, vocal lifts]
Wait
Wait
Don't go
Don't go

[Chorus: Full band, belted chest voice, orchestral drums]
If I could take it back
I would say it loud
I would say your name
Above the crowd
If I could take it back
I'd tear down every wall
I'd tell you everything
Or nothing at all

[Breakdown: Piano and vocal only, vulnerable peak]
I practiced the words
In every mirror in this house
But courage never showed
The night you walked out

[Build-up 2: Drums and strings swell]
Say it now
Say it now

[Drop / Climax: Instrumental swell with vocal chop, full orchestra]
If I could take it back
I would say it loud
I would say your name
Above the crowd

[Final Chorus: Key change, maximum dynamics]
If I could take it back
I would say it loud
I would say your name
Above the crowd
If I could take it back
I'd tear down every wall
I'd tell you everything
Or nothing at all

[Outro: Piano fade, string decay]

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
      isProgressiveBigRoomLane(
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
