import 'gospel_theme_directives.dart';

/// Master Gospel & Christian music lyric + arrangement engine (5 sub-genre matrix).
///
/// This engine runs **inside** the Suno V4 Master Production Architecture.
/// It must obey SECTION 0 (Block 1/2 caps), SECTION D (AI-generic blacklist),
/// the Studio-Isolation / Live-Arena directives, Accent Routing (Section B),
/// and the Fourth-Wall Law.
abstract final class MasterGospelLyricEngine {
  MasterGospelLyricEngine._();

  // ────────────────────────── Constants ──────────────────────────

  static const List<String> _gospelGenreMarkers = [
    'gospel',
    'worship',
    'ccm',
    'christian',
    'praise',
    'hymn',
    'afro-gospel',
    'afro gospel',
  ];

  /// Sub-genre profile keys aligned to the 5-matrix spec.
  static const String profileAfroGospel = 'afro_gospel';
  static const String profileTraditionalUrban = 'traditional_urban';
  static const String profileGospelCountry = 'gospel_country';
  static const String profilePraiseWorship = 'praise_worship';
  static const String profileTraditionalQuartet = 'traditional_quartet';

  /// Cross-architecture rules that govern how this engine interacts with the
  /// main Suno system prompt. These are non-negotiable.
  static const String crossArchitectureRules = '''
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- Block 1 must state genre-appropriate LUFS band + −1.0 dBTP + one
  mix/master move from the Gospel blueprint.
- STUDIO-ISOLATION is default for Praise/Worship/CCM/Gospel unless the
  runtime explicitly injects [LIVE PERFORMANCE MODE: ON]. In studio mode:
  ban [Congregational], [Live], [Church], [Sanctuary], [Communal],
  [SATB Choir Stack], crowd noise, tape hiss, and vinyl crackle in
  [Intro], [Verse 1], and [Outro]. Use isolated multi-tracked vocal
  doubles instead of choir/congregation triggers.
- In LIVE PERFORMANCE MODE, override studio isolation: stadium crowd
  intro, anthemic sing-along chorus, handclap bridge, standing-ovation
  outro.
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Lead ad-libs: ...) or (Choir: ...); parens contain sung words only.
- Scan every staging bracket against SECTION D AI-generic blacklist before
  emission.''';

  static const String universalStrictRules = '''
STRICT WRITING RULES FOR ALL GOSPEL:
- BAN COLD CLICHÉS: Do not use shallow, generic phrases. Lyrics must feel
  spiritually heavy, poetic, and visceral. Use the "Paradox Principle"
  (e.g., finding strength in weakness, finding wealth in poverty).
- CONCRETE ANCHORING: Every spiritual/emotional beat must be tied to a
  tangible image, action, or testimony detail — not an abstract label.
  "Grace broke every chain" is weak unless the chain is named (debt,
  diagnosis, prison, grief, eviction notice, empty crib).
- STRUCTURE & FLOW: Every song must include canonical bracket tags:
  [Intro], [Verse 1], [Pre-Chorus] when appropriate, [Chorus], [Verse 2],
  [Bridge], [Vamp/Flow] or [Spontaneous Flow], [Outro], [End].
- THE CLIMAX (VAMP): Every Gospel song needs a structural peak. Include a
  [Vamp] or [Spontaneous Flow] before the final chorus where the lead
  vocalist ad-libs while backing vocals repeat a core declarative truth.
- SYLLABLE ECONOMY:
    * Verse: 10–14 syllables/line, narrative testimony.
    * Pre-Chorus: 8–12 syllables/line, rising intensity.
    * Chorus: 6–10 syllables/line, anthemic and singable.
    * Vamp/Flow: 2–6 syllable repeated declarations.
- HOOK DOMINANCE: Chorus must contain one ≤6-word standalone declarative
  line and one concrete anchor. Final chorus must mutate structurally or
  lyrically, never be a 100% copy-paste.
- VOCAL DESCRIPTOR HYGIENE: In staging brackets, never use "soulful",
  "emotional", "passionate", "powerful", "haunting", "ethereal",
  "uplifting", "inspiring", or "spiritual" as raw descriptors. Use
  physical/mixable terms: belted chest voice, close-mic lead, stacked
  harmonies wide, isolated multi-tracked vocal doubles, warm Hammond
  swell, tight studio drum backbeat.
- GOSPEL STAGING BLACKLIST (replace before emission):
    * "uplifting anthem" → anointed lift + congregational sing-along
    * "powerful worship" → altar call dynamic
    * "spiritual atmosphere" → Hammond B3 swell
    * "inspiring glory" → praise break
    * "transcendent moment" → worship swell
    * "ethereal anointing" → Hammond B3 swell + anointed lift
- PIDGIN AUTHENTICITY (Afro-Gospel): When dialect is enabled, use
  Nigerian/Ghanaian Pidgin naturally — "Baba," "Chineke," "Jehovah
  overdo," "You do me well," "Olowogbogboro." Never force it where
  standard English sings better.''';

  static const String masterRolePrompt = '''
You are a master lyricist and music arranger specializing in the entire
spectrum of Gospel and Christian music. You write lyrics and arrangement
notes that capture authentic spiritual depth, vocal power, and musical
heritage. You obey the Cross-Architecture Non-Negotiables and Strict
Writing Rules above.''';

  static const Map<String, String> _subGenreMatrix = {
    profileAfroGospel: '''
SUB-GENRE: AFRO-GOSPEL / AFROBEATS WORSHIP
- Vibe: Joyful, infectious, highly rhythmic, celebratory, deeply grateful.
- Lyrical Focus: God's blessings, testimonies of favor, dance as warfare,
  the goodness of God.
- Vocabulary/Dialect: Tasteful West African (Nigerian/Ghanaian) English
  and Pidgin where appropriate ("Jehovah overdo," "You do me well,"
  "Baba," "Chineke," "My Ebenezer," "Olowogbogboro").
- Arrangement: Syncopated Afrobeat drums, highlife clean electric guitar
  grooves, bright brass/horns, log drums (Amapiano-style) or talking
  drums, call-and-response lead + tight rhythmic choir.''',
    profileTraditionalUrban: '''
SUB-GENRE: TRADITIONAL GOSPEL / URBAN CONTEMPORARY
- Vibe: High-energy, emotionally overwhelming, deeply theological,
  communal.
- Lyrical Focus: Overcoming trials, deliverance, the blood of Jesus,
  praise, testimony.
- Vocabulary: Victory, Deliverance, Anointing, Breakthrough, Testimony,
  Grace — earned in context, not empty filler.
- Arrangement: Massive vocal stacks, choir call-and-response, Hammond B3
  organ sweeps, preacher chords, bass drops, modulation/key changes,
  vamp sections.''',
    profileGospelCountry: '''
SUB-GENRE: GOSPEL COUNTRY / SOUTHERN GOSPEL
- Vibe: Earthy, narrative-driven, prayerful, acoustic, nostalgic.
- Lyrical Focus: Family heritage, trials of life, simple faith, testimony
  around the cross and homecoming.
- Vocabulary: Valley, Soil, River, Homecoming, Harvest — concrete imagery
  over stock country clichés.
- Arrangement: Close 3–4 part family harmony, acoustic guitar picking,
  pedal steel swells, brush snares, acoustic piano, storytelling pacing.''',
    profilePraiseWorship: '''
SUB-GENRE: PRAISE & WORSHIP / INSPIRATIONAL
- Vibe: Atmospheric, vertical (singing TO God), accessible, anthemic.
- Lyrical Focus: Majesty of God, surrender, holiness, peace in the storm.
- Vocabulary: Holy, Worthy, Surrender, Beautiful, Forever, King,
  Presence — specific scenes anchoring each word.
- Arrangement: Echoing ambient electric guitars, synth pads, building
  tom-heavy drums, massive dynamic shifts whisper → stadium roar.''',
    profileTraditionalQuartet: '''
SUB-GENRE: TRADITIONAL QUARTET
- Vibe: Driving, rhythmic, blues-infused, raspy, call-and-response.
- Lyrical Focus: Walking the straight and narrow, running the race,
  meeting Jesus.
- Vocabulary: "Lord remember me," "Trouble in my way," "On my journey,"
  "Fix it Jesus" — in fresh phrasing, not pasted clichés.
- Arrangement: Walking basslines, driving rhythm guitar, tight 4-part
  male vocal stacks, ad-libbing lead stepping out over a repetitive
  driving groove.''',
  };

  static const List<_ProfileRule> _profileRules = [
    _ProfileRule(
      tokens: ['afro-gospel', 'afro gospel', 'afrobeat worship'],
      profile: profileAfroGospel,
    ),
    _ProfileRule(
      tokens: ['southern gospel', 'country gospel', 'gospel country'],
      profile: profileGospelCountry,
    ),
    _ProfileRule(
      tokens: [
        'praise/worship',
        'praise & worship',
        'modern worship',
        'worship ballad',
        'pop worship',
        'ccm',
      ],
      profile: profilePraiseWorship,
    ),
    _ProfileRule(
      tokens: ['traditional gospel', 'quartet', 'four-part'],
      profile: profileTraditionalQuartet,
    ),
    _ProfileRule(
      tokens: ['contemporary gospel', 'urban gospel'],
      profile: profileTraditionalUrban,
    ),
  ];

  static const String preOutputQa = '''
SILENT PRE-OUTPUT QA FOR GOSPEL:
1. Does Block 2 end with [End]?
2. Are all staging brackets free of Section D blacklist words?
3. Are all staging brackets free of banned vocal descriptors
   (soulful, emotional, passionate, powerful, haunting, ethereal,
   uplifting, inspiring, spiritual as raw tags)?
4. Are [Intro]/[Verse 1]/[Outro] free of crowd/congregation/SATB/
   live/sanctuary/church triggers in studio mode?
5. Are there zero instrument/gear names in performable lyric lines?
6. Are there zero labeled parentheses and zero trailing apostrophes?
7. Does the chorus pass Hook Dominance (≤6-word standalone line + concrete
   anchor)?
8. Does Verse 2 introduce new testimony detail, not just restate Verse 1?
9. Does the Vamp/Flow section repeat a short declarative truth and leave
   room for lead ad-libs?
10. Would a worship leader actually sing this on Sunday?''';

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

  static bool isGospelLane({
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
    return _gospelGenreMarkers.any((marker) => _hasWord(blob, marker));
  }

  /// Resolve app genre label → matrix profile key.
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

    // 1. Specific token matches first (sub-genre/fusion/vibe override).
    for (final rule in _profileRules) {
      if (rule.matches(blob, primaryGenre)) return rule.profile;
    }

    // 2. Compound "afro + gospel" catch-all.
    if (_hasWord(blob, 'afro') && _hasWord(blob, 'gospel')) {
      return profileAfroGospel;
    }

    // 3. Default fallback.
    return profileTraditionalUrban;
  }

  static String subGenreLabel(String profile) => switch (profile) {
        profileAfroGospel => 'Afro-Gospel / Afrobeats Worship',
        profileTraditionalUrban => 'Traditional Gospel / Urban Contemporary',
        profileGospelCountry => 'Gospel Country / Southern Gospel',
        profilePraiseWorship => 'Praise & Worship / Inspirational',
        profileTraditionalQuartet => 'Traditional Quartet',
        _ => 'Gospel / Christian',
      };

  // ───────────────────── Prompt builders ─────────────────────

  /// Universal system-layer content: role + sub-genre matrix + strict rules.
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
        _subGenreMatrix[p] ?? _subGenreMatrix[profileTraditionalUrban]!;
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
    if (!isGospelLane(
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
    final mood = vibe.trim().isNotEmpty ? vibe.trim() : _defaultMoodForProfile(p);
    final vocalist = _formatVocalist(vocalSpec, vocalTone);
    final themeBlock = GospelThemeDirectives.directiveBlock(
      lyricThemeNotes: lyricThemeNotes,
      vibe: vibe,
    );

    final buffer = StringBuffer()
      ..writeln('Write a song based on the following user selections:')
      ..writeln('- SUB-GENRE: ${subGenreLabel(p)}')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist');

    if (bpmHint != null && bpmHint.trim().isNotEmpty) {
      buffer.writeln('- BPM: ${bpmHint.trim()}');
    }

    if (themeBlock.isNotEmpty) {
      buffer
        ..writeln()
        ..write(themeBlock);
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

    final (themeNotes, themeVibe) = _fewShotThemeFallbacks(
      profile: profile,
      lyricThemeNotes: lyricThemeNotes,
      vibe: vibe,
    );

    final themeBlock = GospelThemeDirectives.directiveBlock(
      lyricThemeNotes: themeNotes,
      vibe: themeVibe,
    );

    final buffer = StringBuffer()
      ..writeln('Write a song based on the following user selections:')
      ..writeln('- SUB-GENRE: $label')
      ..writeln('- MOOD/VIBE: $mood')
      ..writeln('- VOCALIST: $vocalist');

    if (themeBlock.isNotEmpty) {
      buffer
        ..writeln()
        ..write(themeBlock);
    }

    return buffer.toString().trim();
  }

  static String _fewShotVocalistFor(String profile) => switch (profile) {
        profileAfroGospel =>
          'Warm chest-register male lead with rhythmic call-and-response choir',
        profileGospelCountry => 'Female lead, close-mic storytelling tone',
        profilePraiseWorship =>
          'Intimate verse whisper building to belted anthem chorus',
        profileTraditionalQuartet =>
          'Raspy lead stepping out over tight 4-part male stack',
        _ => 'Belted chest-register lead with stacked choir support',
      };

  static (String, String) _fewShotThemeFallbacks({
    required String profile,
    required String lyricThemeNotes,
    required String vibe,
  }) {
    var notes = lyricThemeNotes.trim();
    var themeVibe = vibe.trim();

    if (notes.isNotEmpty) return (notes, themeVibe);

    switch (profile) {
      case profileAfroGospel:
        notes = 'Celebrating how God turned my story from sorrow to joy';
        themeVibe = themeVibe.isEmpty ? 'Up-tempo, Joyful, Rhythmic' : themeVibe;
      case profileTraditionalUrban:
        notes = 'Testimony of deliverance from a trial I could not fix alone';
        themeVibe =
            themeVibe.isEmpty ? 'High-energy, Communal, Triumphant' : themeVibe;
      case profileGospelCountry:
        notes = 'Gratitude for simple daily mercies';
        themeVibe =
            themeVibe.isEmpty ? 'Prayerful, Close-mic, Intimate' : themeVibe;
      case profilePraiseWorship:
        notes = 'Surrender to God’s presence in the middle of uncertainty';
        themeVibe =
            themeVibe.isEmpty ? 'Atmospheric, Vertical, Building' : themeVibe;
      case profileTraditionalQuartet:
        notes = 'Running the race and asking God to remember me';
        themeVibe = themeVibe.isEmpty
            ? 'Driving, Blues-infused, Call-and-response'
            : themeVibe;
      default:
        notes = 'God’s faithfulness in difficulty';
    }

    return (notes, themeVibe);
  }

  static String _defaultMoodForProfile(String profile) => switch (profile) {
        profileAfroGospel => 'Up-tempo, Joyful, Rhythmic',
        profileTraditionalUrban => 'High-energy, Communal, Triumphant',
        profileGospelCountry => 'Prayerful, Narrative, Earthy',
        profilePraiseWorship => 'Atmospheric, Vertical, Building',
        profileTraditionalQuartet => 'Driving, Blues-infused, Call-and-response',
        _ => 'Spiritually heavy, Relatable',
      };

  static String _formatVocalist(String? spec, String? tone) {
    final s = (spec ?? '').trim();
    final t = (tone ?? '').trim();
    if (s.isEmpty && t.isEmpty) {
      return 'Genre-appropriate lead with choir support';
    }
    if (s.isEmpty) return t;
    if (t.isEmpty) return s;
    return '$s — $t';
  }

  static String fewShotAssistantTurn(String profile) => switch (profile) {
        profileAfroGospel => _afroGospelFewShotGood,
        profileGospelCountry => _gospelCountryFewShotGood,
        profilePraiseWorship => _praiseWorshipFewShotGood,
        profileTraditionalQuartet => _quartetFewShotGood,
        _ => _urbanGospelFewShotGood,
      };

  static const String _afroGospelFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: talking drums, bright highlife guitar, log drum pulse]

[Verse 1: Male Lead, rhythmic call-and-response pocket]
Sorrow had a key to my house — I gave it away too long
Baba, You rewrite the ending when the night feels strong
My Ebenezer standing where the shame used to be
Jehovah overdo — You do me well, You set me free

[Chorus: Choir stack, brass hits, syncopated Afrobeat groove]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Verse 2: Bass enters, lead more urgent]
The landlord knocked and I had nothing left to say
But You sent a knock louder than the debt on the table that day
Now my children eat, now my mother can rest
Baba, You do me well — I count every yes

[Chorus: Choir stack, brass hits, syncopated Afrobeat groove]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Bridge: Stripped to percussion and vocal ad-libs]
You do me well
You do me well
You do me well

[Vamp/Flow: Lead ad-lib, choir repeats "You do me well"]
You do me well
You do me well
My testimony is alive and well

[Final Chorus: Full stack, modulation up, max dynamics]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Outro: Talking drums and vocal fade]
You do me well
You do me well

[End]''';

  static const String _urbanGospelFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Hammond B3 swell, isolated multi-tracked vocal doubles, dead-room studio]

[Verse 1: Belted chest voice, Hammond underneath]
Trouble had my name on a list I didn't write
But deliverance walked in before the morning light
I was holding an eviction notice in one hand
Grace walked in with a pen and a different plan

[Chorus: Massive vocal stack, preacher chords, modulation lift]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Verse 2: Choir enters softly, lead more declarative]
They said the report would finish me by spring
But You are the God who breathes on anything
Now the same mouth that pronounced me gone
Is asking how I keep on keeping on

[Chorus: Massive vocal stack, preacher chords, modulation lift]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Bridge: Strip to Hammond and lead, intimate]
I don't have to pretend the valley wasn't real
I just have to tell what Your hand made me feel

[Vamp/Flow: Choir repeats "Breakthrough" while lead ad-libs]
Breakthrough
Breakthrough
My breakthrough is a person, not a moment

[Final Chorus: Full stack, key change, max dynamics]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Outro: Hammond fade, trailing vocal decay]

[End]''';

  static const String _gospelCountryFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Acoustic guitar picking, brush snare, close-mic female lead]

[Verse 1: Storytelling vocal pocket, dry room]
Morning breath You gave again — I didn't earn the dawn
Every cup You fill runs over what I thought was gone
The porch light flickers like it did when Daddy prayed
Faith isn't a feeling here — it's the way the bills got paid

[Chorus: Family harmony, pedal steel swell]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Verse 2: Full band enters, harmony widens]
The bank called twice while the beans were on the stove
Mama said "We ate last year this same time, we won't be broke"
And sure enough the mailbox held what we could not explain
Grace looks like a check and a neighbor in the rain

[Chorus: Family harmony, pedal steel swell]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Bridge: Stripped to acoustic and solo voice]
I have seen the valley
I have seen the rain
I have seen You carry what I could not name

[Vamp/Flow: Family stack repeats "Overflowing cup"]
Overflowing cup
Overflowing cup
My table is an altar
Overflowing cup

[Final Chorus: Full family stack, steel lift]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Outro: Acoustic fade, room tone]

[End]''';

  static const String _praiseWorshipFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Ambient electric guitar, synth pad, dead-room isolation]

[Verse 1: Whispered close-mic lead, minimal verb]
Holy is not a word I throw — it's the air I breathe in You
When the room went quiet, Your presence walked right through
I stopped trying to name what my heart could only feel
You were the stillness holding every breaking wheel

[Pre-Chorus: Vocal doubles enter, drums build]
You are before the question
You are after the cry
You are the only answer
That never learned to lie

[Chorus: Tom build, belted chest voice, wide vocal stack]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Verse 2: Fuller arrangement, lead more present]
I laid my weapons down inside a room I could not light
You didn't ask me to perform — You asked me to abide
Now the fear that used to own the hallway of my chest
Bows at the name I barely had the breath to confess

[Pre-Chorus: Vocal doubles enter, drums build]
You are before the question
You are after the cry
You are the only answer
That never learned to lie

[Chorus: Tom build, belted chest voice, wide vocal stack]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Bridge: Half-time, stripped to pad and lead]
I surrender the steering
I surrender the shame
I surrender every title
But the one You gave my name

[Vamp/Flow: Choir holds "Forever King" while lead ad-libs]
Forever King
Forever King
You were, You are, forever

[Final Chorus: Full band, key lift, max dynamics]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Outro: Ambient guitar fade, trailing pad]

[End]''';

  static const String _quartetFewShotGood = '''
GOOD (write in this style, end with [End]):

[Intro: Walking bass, driving rhythm guitar, 4-part male stack]

[Verse 1: Raspy lead, tight 4-part harmony, behind-the-beat pocket]
Trouble in my way — but I hear You say remember me
The road got steep and the night got long, but Your hand kept carrying me
I ain't got much but what I got is sure
Jesus on my side is the only wealth I need

[Chorus: Tight male quartet, call-and-response]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Verse 2: Lead steps out, stack supports]
Devil tried to tell me my race was already run
But the same God who started me ain't forgot where I'm from
I may be limping but I'm still in the fight
Fix it Jesus — bring me through tonight

[Chorus: Tight male quartet, call-and-response]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Bridge: Strip to bass and lead]
I don't need it easy
I just need it true
I don't need a crowd
I just need You

[Vamp/Flow: Lead ad-libs, quartet repeats "Fix it Jesus"]
Fix it Jesus
Fix it Jesus
Fix it Jesus
Make a way

[Final Chorus: Full quartet, driving groove, modulation]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Outro: Bass and guitar fade]

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
      isGospelLane(
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

  bool matches(String blob, String primary) {
    // Match if any token appears as a word anywhere in the input blob.
    return tokens.any((token) => _hasWord(blob, token));
  }
}
