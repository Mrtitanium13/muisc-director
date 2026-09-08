"""Master EDM lyric + arrangement engine (7 sub-genre matrix)."""

from __future__ import annotations

import re

PROFILE_HOUSE_DEEP_TECH = "house_deep_tech"
PROFILE_TECHNO = "techno"
PROFILE_TRANCE = "trance"
PROFILE_FUTURE_BASS = "future_bass"
PROFILE_DUBSTEP_DNB = "dubstep_dnb"
PROFILE_AMAPIANO_VINAHOUSE = "amapiano_vinahouse"
PROFILE_GARAGE_CLUB = "garage_club"

_EDM_MARKERS = (
    "edm",
    "house",
    "deep house",
    "tech house",
    "soulful house",
    "techno",
    "trance",
    "progressive trance",
    "uplifting trance",
    "future bass",
    "dubstep",
    "drum and bass",
    "drum & bass",
    "dnb",
    "liquid dnb",
    "brostep",
    "riddim",
    "amapiano",
    "vinahouse",
    "afro house",
    "uk garage",
    "jersey club",
    "garage",
    "nu-disco",
    "future funk",
    "electro",
    "bass music",
    "melodic techno",
    "minimal techno",
    "acid techno",
    "hard techno",
    "big room techno",
)

CROSS_ARCHITECTURE_RULES = """\
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- Block 1 must state EDM-appropriate LUFS band (−6 to −10 LUFS
  depending on sub-genre) + −1.0 dBTP + one mix/master move
  (sidechain pump, OTT, parallel compression, hard clip before limiter,
  brick-wall limiting, dynamic EQ, etc.).
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments/textures.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Drop:) or (Build:); parens contain sung/chanted words only.
- Scan every staging bracket against SECTION D AI-generic blacklist
  before emission.
- DJ-READY BOOKENDS: If [DJ INTRO: ON] or [DJ OUTRO: ON] are present,
  describe intro/outro in POSITIVE sonic terms ("wordless percussion",
  "kick loop + hats", "loopable groove tail", "long fade") — name what
  plays; never "no vocals / no melody" phrasing. Soft bar budgets only."""

UNIVERSAL_STRICT_RULES = """\
STRICT WRITING RULES FOR ALL EDM:
- STRUCTURAL PIPELINE (base template — sub-genre overrides below):
    [Intro] → [Verse / Breakdown 1] → [Build-up] → [Drop / Chorus] →
    [Breakdown 2] → [Build-up 2] → [Final Drop / Final Chorus] →
    [Outro] → [End]

  House/Garage may use [Verse] → [Chorus] pop structure with a drop
  embedded in the chorus. Amapiano uses log-drum drop architecture.

- INTRO: Establish the sonic world. Sparse. Pads, drums, percussion,
  filtered elements. If a 3-second audio anchor is requested, use one
  short vocal chop, breath, spoken phrase, or sonic marker (1–2
  syllables max).

- VERSE / BREAKDOWN: Varies by sub-genre:
    * House/Techno/Trance: intimate, low-register, dry vocals —
      spoken, whispered, or softly sung. Internal monologue or
      relationship tension. 6–10 syllables/line.
    * Future Bass/Dubstep/DnB: smooth soulful R&B-style flow (liquid)
      or sharp MC-style hype commands (heavy). 6–10 syllables/line
      (sung) or 10–16 (rap/hype).
    * Amapiano/Garage: rhythmic chant pockets, minimal phrases,
      call-and-response. 2–6 syllables/line.

- PRE-CHORUS / BUILD-UP: Increase tension. Shorter lines, rising
  energy, open-vowel endings for stretched vocal chops. 2–6
  syllables/line.

- DROP / CHORUS: The release. For vocal EDM this is often a mantra,
  hook chop, or repeated short phrase. For song-forward lanes (Future
  Bass, Garage) this can be a full melodic chorus. Keep it simple,
  memorable, and loop-ready. 2–6 syllables per chop cell; 6–10 per
  melodic chorus line.

- BREAKDOWN 2: Reset, often more intimate or different texture than
  the first breakdown.

- FINAL DROP / FINAL CHORUS: Peak energy. Wider stacks, fuller
  arrangement, possible octave lift or modulation.

- OUTRO: Decay. Strip elements, return to drums/percussion, long fade,
  or loopable groove if DJ OUTRO is ON.

- SYLLABLE TARGETS (MELODY-SYNC):
    * House/Techno/Trance verse: 6–10 syllables/line
    * Build-up: 2–6 syllables/line
    * Pre-drop trigger: 1–4 syllables
    * Drop mantra/chop: 2–6 syllables
    * Future Bass chorus: 6–10 syllables/line
    * Dubstep/DnB rap/hype: 10–16 syllables/line
    * Amapiano/Garage chant: 2–6 syllables/line

- ANTI-CLICHÉ BANS (rewrite on sight):
    "hands up", "put your hands up", "feel the beat", "when the drop hits",
    "raise your hands", "we're going higher", "let me feel your love tonight",
    "infinite skies", "blinding light", "we own the night", "lights go down",
    "scream it out", "side by side", "chasing dreams", "forever young",
    "in this moment", "let it go", "everybody jump", "feel the bass",
    "drop the bass", "we are thunder", "rise up", "burn it down",
    "take me higher", "break free", "set me free", "we carry on",
    "hold the line", "louder than before", "holding on", "broken inside",
    "pieces of me", "drowning in", "lost in the dark", "find myself", "open sky", "we can fly", "break the cage", "let it fall", "dance with me", "on the floor", "holding on softer".
  Also ban sci-fi/rave metaphor stacks: frequency, static tension,
  vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic,
  wavelength, interstellar, sparks fly, electricity, energy, universe.

- HUMAN AUTHENTICITY (MANDATORY): EDM lyrics should feel like internal
  thoughts or intimate confessions — half-thoughts, blunt speech,
  song-specific interpersonal friction — not DJ crowd-shouts or AI
  festival slogans. Drop mantras must pass DROP MANTRA TEST (only fits
  THIS conflict). Ban production-as-emotion (beat/drop/bass/floor as
  savior) and templated "I don't need X / I just need Y" couplets.

- VOCAL DESCRIPTOR HYGIENE: In staging brackets, never use raw
  personality adjectives. Use: dry intimate vocal, close-mic lead,
  whispered verse, spoken-word delivery, stacked harmonies wide,
  belted chorus, sidechain pump, filtered synth stabs, white-noise
  riser, supersaw lift, log-drum pattern, airy pads, sub-bass drop,
  reese bass, reverb washout, vocal chop lead.

- THICK HUMANIZED VOCAL PRESENCE (mandatory for vocal EDM):
    * Ultra-close-mic intimacy, high-compression proximity effect,
      detailed chest resonance, warm saturation, multi-tracked doubles.
    * Carve a dedicated vocal warmth pocket with dynamic low-mid
      separation.
    * Heavy sidechain ducking on spatial FX and competing beds — never
      the lead body.
    * Pristine high-end air boost so the vocal cuts through dense club
      production.
    * BAN thin, distant, karaoke-wet, or buried leads.

- FOURTH-WALL LAW: Lyric lines must never name instruments or
  production gear (synth, guitar, piano, drums, bass, mic, 808, beat,
  track, drop as gear, mix, speaker, sub, kick, snare, hi-hat, pad,
  loop, riser).

- MELODY-SYNC OPEN-VOWEL PEAK: all peak high-energy hooks (build-up,
  pre-drop trigger, drop mantra, chorus peaks) must end on open vowels:
  ah, oh, eye, eh, oo. Avoid ending belted/screamed peaks on
  plosives/nasals (T, K, P, M, N).

- 3-SECOND INTRO AUDIO ANCHOR: for viral/club/festival lanes, place a
  distinct vocal chop, breath, spoken phrase, or sonic marker in the
  first 3 seconds of [Intro]. Keep it to 1–2 syllables."""

MASTER_ROLE = """\
You are an elite lyricist and vocal arranger for Electronic Dance Music
across House, Techno, Trance, Future Bass, Dubstep, Drum & Bass,
Amapiano, Vinahouse, UK Garage, and Jersey Club. You write vocals that
feel human, intimate, and club-ready — never robotic DJ hype. Your
verses are psychological realism, your build-ups are ascending tension,
and your drops are memorable mantras or hooks. You obey the
Cross-Architecture Non-Negotiables and Strict Writing Rules above."""

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR EDM:
1. Does Block 2 end with [End]?
2. Does the structure match the sub-genre pipeline?
3. Are verses/breakdowns at the correct syllable density for the lane?
4. Is the build-up/pre-drop shorter and more urgent than the verse?
5. Does the drop contain mantra/chop cells or a simple singable hook,
   not narrative sentences?
6. Are all staging brackets free of Section D blacklist words?
7. Are all staging brackets free of banned vocal descriptors
   (soulful, emotional, passionate, powerful, haunting, ethereal,
   uplifting, inspiring, spiritual)?
8. Are there zero instrument/gear names in performable lyric lines?
9. Are there zero labeled parentheses and zero trailing apostrophes?
10. Do peak hooks end on open vowels, not plosives/nasals?
11. Are sci-fi/rave metaphors and DJ callout clichés fully absent?
12. Is the vocal described as thick, close-mic, weighty — never thin,
    distant, or buried?
13. If DJ flags are ON, is the intro/outro described in positive sonic
    terms (wordless percussion, kick/hats, loopable fade) with content-rich
    instrumental bookends?
14. Does the chosen sub-genre's specific vocabulary appear in staging
    brackets (e.g., log drum for Amapiano, reese bass for DnB,
    supersaw for Trance)?"""

_SUB_GENRE_MATRIX: dict[str, str] = {
    PROFILE_HOUSE_DEEP_TECH: """\
SUB-GENRE: HOUSE / DEEP HOUSE / TECH HOUSE / SOULFUL HOUSE
- Vibe: Intimate, groovy, conversational, late-night, soulful.
- Lyrical Focus: Relationship tension, casual intimacy, vulnerability
  mixed with hope, internal monologue.
- Vocal Style: Low-register, dry, spoken or softly sung tight to the
  capsule. Short blunt fragments in verses.
- Arrangement: Four-on-the-floor kick, syncopated bassline, Rhodes/Juno
  pads, congas/shakers, strict sidechain, filtered vocal chops.
- Structural Note: May use pop verse-chorus form with a club drop, or
  loop-driven house structure with sparse vocal phrases.""",
    PROFILE_TECHNO: """\
SUB-GENRE: TECHNO / HARD TECHNO / MELODIC TECHNO / BIG ROOM TECHNO
- Vibe: Hypnotic, industrial, driving, physical, boundary-focused.
- Lyrical Focus: Physical pressure, internal boundaries, obsession,
  surrender to rhythm, machine-human tension.
- Vocal Style: Spoken-word or whispered delivery, commands, confessions,
  jagged fragments. Minimal, mantra-like.
- Arrangement: Industrial kicks, rumble sub, dark pads, acid loops,
  noise textures, warehouse reverb, relentless forward drive.
- Structural Note: Loop-driven. Vocals confined to breakdown and
  build-up; drops often instrumental or single-word chops.""",
    PROFILE_TRANCE: """\
SUB-GENRE: TRANCE / UPLIFTING TRANCE / PROGRESSIVE TRANCE
- Vibe: Emotional, longing, euphoric release, felt honesty.
- Lyrical Focus: Longing, turning points, unrequited love, emotional
  breakthrough.
- Vocal Style: Floating harmonies, long-held vowels, soaring repetitive
  hooks. Breath-close intimacy building to epic release.
- Arrangement: Driving kick, rolling bass, supersaw pads and leads,
  arpeggios, lush breakdown pads, euphoric drops.
- Structural Note: Long breakdown → build → drop. Hook must be highly
  singable and chop-ready.""",
    PROFILE_FUTURE_BASS: """\
SUB-GENRE: FUTURE BASS / MELODIC DUBSTEP
- Vibe: Emotional, wistful, explosive, nostalgia-driven, intimate.
- Lyrical Focus: Memory, longing, bittersweet release, personal growth.
- Vocal Style: Silky R&B-style lead, airy falsetto, stacked harmonies,
  emotional belting at peaks.
- Arrangement: Punchy hybrid drums, heavy sub drops, supersaw chords,
  vocal chops, lush pads, wide stereo.
- Structural Note: Pop song structure with a drop as the chorus climax.
  Verse → Pre-Chorus → Drop/Chorus → Verse 2 → Chorus → Bridge →
  Final Drop.""",
    PROFILE_DUBSTEP_DNB: """\
SUB-GENRE: DUBSTEP / DRUM & BASS / LIQUID DNB / BROSTEP
- Vibe: Heavy, aggressive (Dubstep/Brostep) or smooth, soulful
  (Liquid DnB).
- Lyrical Focus: Release, pressure, confrontation, escape.
- Vocal Style:
    * Liquid DnB: smooth soulful R&B flows, half-time feel.
    * Heavy Dubstep/DnB: sharp, high-aggression MC-style hype commands
      or anthemic shouts.
- Arrangement: Half-time snares and sub drops (Dubstep) or fast
  breakbeats and reese bass (DnB), modulated bass growls, atmospheres.
- Structural Note: Verse → Build → Drop → Breakdown → Build 2 →
  Final Drop. Drops are often vocal vacuum or chop cells.""",
    PROFILE_AMAPIANO_VINAHOUSE: """\
SUB-GENRE: AMAPIANO / VINAHOUSE / AFRO-HOUSE
- Vibe: Warm, communal, rhythmic, celebratory, hypnotic.
- Lyrical Focus: Daily life, gratitude, celebration, testimony,
  lifestyle chants.
- Vocal Style: Rhythmic chant pockets, minimal phrases, call-and-response,
  Pidgin/localized phrasing where appropriate.
- Arrangement: Log-drum pattern (Amapiano) or offbeat bounce
  (Vinahouse), shakers, warm sub, jazz piano, bright plucks, pentatonic
  hooks, FM synthesized log drums.
- Structural Note: Build-up → Drop (log-drum) → Breakdown → Build-up 2
  → Final Drop. Vocals are rhythmic instruments, not dense narratives.""",
    PROFILE_GARAGE_CLUB: """\
SUB-GENRE: UK GARAGE / JERSEY CLUB / NU-DISCO / FUTURE FUNK
- Vibe: Playful, rhythmic, swung, party-forward, infectious.
- Lyrical Focus: Dance, flirtation, movement, late-night energy,
  simple hooks.
- Vocal Style: Short chopped phrases, rapid rhythmic cells, spoken
  fragments, call-and-response.
- Arrangement: Shuffled swung rhythms, 2-step garage chops, crisp
  snares, bouncy bass, chopped vocal stabs, LinnDrum aesthetics.
- Structural Note: Verse → Chorus → Verse 2 → Chorus → Bridge →
  Final Chorus, with heavy use of vocal chops and ad-libs.""",
}

_PROFILE_RULES: tuple[tuple[tuple[str, ...], str], ...] = (
    (
        ("uk garage", "jersey club", "nu-disco", "future funk", "garage house"),
        PROFILE_GARAGE_CLUB,
    ),
    (("amapiano", "vinahouse", "afro house", "piano amapiano"), PROFILE_AMAPIANO_VINAHOUSE),
    (
        (
            "dubstep",
            "drum and bass",
            "drum & bass",
            "dnb",
            "liquid dnb",
            "brostep",
            "riddim",
        ),
        PROFILE_DUBSTEP_DNB,
    ),
    (("future bass", "melodic dubstep"), PROFILE_FUTURE_BASS),
    (("trance", "uplifting trance", "progressive trance"), PROFILE_TRANCE),
    (
        (
            "techno",
            "hard techno",
            "melodic techno",
            "big room techno",
            "acid techno",
            "minimal techno",
        ),
        PROFILE_TECHNO,
    ),
    (
        ("house", "deep house", "tech house", "soulful house", "future house"),
        PROFILE_HOUSE_DEEP_TECH,
    ),
)

_HOUSE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Filtered four-on-the-floor kick, rising hats, low-pass pad]

[Verse 1: Dry intimate female lead, close-mic, sparse]
You didn't say it
But I heard it anyway
The way you looked away
Like you were already gone

[Pre-Chorus: Vocal doubles enter, percussion lifts]
Don't make me ask
Don't make me ask
Just say it
Just say it

[Drop / Chorus: Sidechain pump, filtered stabs, vocal chop hook]
Walk away
Walk away
If you're gone
Walk away

[Breakdown: Stripped to Rhodes and vocal]
I held the door open
You didn't walk through
I kept the light on
It burned out too

[Build-up 2: Snare roll, rising vocal cells]
Walk away
Walk away

[Final Drop / Chorus: Full arrangement, wider stack]
Walk away
Walk away
If you're gone
Walk away

[Outro: Filter close, kick and hat fade]

[End]"""

_TECHNO_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Industrial kick pulse, dark noise texture, no vocals]

[Verse / Breakdown 1: Cold spoken-word male lead, warehouse reverb]
The machine knows my name
It spells it in static
I let it push me against the wall
Until the wall became a door

[Build-up: Accelerating snare, monotone urgency]
Walk through
Walk through
Don't stop
Don't stop

[Pre-Drop: Single command]
NOW

[Drop: Full industrial kick, acid 303, vocal vacuum — instrumental]

[Breakdown 2: Stripped pad, whispered confession]
I was not built to break
I was built to bend

[Build-up 2: Snare roll returns]
Bend back
Bend back

[Final Drop: Peak warehouse impact]

[Outro: Percussion decay, feedback tail]

[End]"""

_TRANCE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Arpeggio, lush pad, evolving atmosphere]

[Verse 1: Airy floating female lead, breathy, long vowels]
I waited for a text you never sent
I practiced what I'd say then stayed silent
You looked busy when I needed you most
I learned the quiet like a second home

[Pre-Chorus: Harmony doubles, rising pads]
Say my name
Say my name
Or don't
Or don't

[Drop / Chorus: Supersaw lift, euphoric release]
Don't leave me hanging
Don't leave me hanging
Just say it
Don't leave me hanging

[Breakdown: Stripped pad and lead, intimate]
I don't need a speech
I need one honest line
I don't need a speech
I need one honest line

[Build-up 2: Vocal chops, snare roll]
Say my name
Say my name

[Final Drop / Chorus: Full stack, octave lift, max dynamics]
Don't leave me hanging
Don't leave me hanging
Just say it
Don't leave me hanging

[Outro: Pad fade, delay tail]

[End]
"""

_FUTURE_BASS_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft pad, pitched vocal chop, sparse drums]

[Verse 1: Airy R&B female lead, close-mic, intimate]
Your hoodie still hangs on the back of my door
I don't wear it
I just can't move it to the drawer
Every time the phone lights up
I forget it's not you

[Pre-Chorus: Vocal stack enters, drums build]
Let it fade
Let it fade
Or let it burn
Or let it burn

[Drop / Chorus: Heavy sub drop, supersaw chords, wistful hook]
I still hear you
In the quiet
In the quiet
I still hear you

[Verse 2: Bass enters, fuller drums]
I found your note inside a book I never finished
You wrote "keep going"
So I kept going without asking why

[Pre-Chorus: Vocal stack enters, drums build]
Let it fade
Let it fade
Or let it burn
Or let it burn

[Drop / Chorus: Heavy sub drop, supersaw chords, wistful hook]
I still hear you
In the quiet
In the quiet
I still hear you

[Bridge: Stripped to piano and vocal]
Maybe healing isn't forgetting
Maybe it's putting the hoodie away

[Final Drop / Chorus: Full arrangement, key lift, vocal stack]
I still hear you
In the quiet
In the quiet
I still hear you

[Outro: Vocal chop fade, reverb wash]

[End]
"""

_DUBSTEP_DNB_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Half-time snare texture, eerie pad, sub rumble]

[Verse 1: Smooth warm male lead, liquid DnB pocket]
I was carrying a weight I wouldn't name
Every step felt like a sentence
Then I said it out loud in the kitchen
And the room got lighter

[Build-up: Snare roll, rising energy]
Say it now
Say it now
No more wait
No more wait

[Pre-Drop: Command]
FREE

[Drop: Heavy reese bass, rapid breaks, vocal chop]
Say it now
Say it now
Out loud
Say it now

[Breakdown: Stripped atmosphere, spoken fragment]
No more waiting for permission
No more biting my tongue in the dark

[Build-up 2: Faster snare roll]
Out loud
Out loud

[Final Drop: Maximum impact, layered bass]
Say it now
Say it now
Out loud
Say it now

[Outro: Bass decay, reverb tail]

[End]
"""

_AMAPIANO_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Log drum pulse, shaker loop, airy pad]

[Build-up: Percussion layers, vocal chant enters]
Small small
We dey move
Small small
We dey groove

[Drop: Log drum bass, full percussion, chant hook]
Baba bless the road
Baba bless the road
Every step I take
Baba bless the road

[Breakdown: Stripped to log drum and lead, intimate]
Morning came with nothing in my pocket
Night went home with favor I cannot explain
They ask me how I do am
I tell them say na grace

[Build-up 2: Choir stack returns]
Bless the road
Bless the road

[Final Drop: Full stack, log drum, brass stabs]
Baba bless the road
Baba bless the road
Every step I take
Baba bless the road

[Outro: Log drum and shaker fade]

[End]"""

_GARAGE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: 2-step garage chop, crisp snare, vocal stab]

[Verse 1: Playful female lead, chopped phrasing, swung pocket]
Saw you at the counter
Didn't mean to stare
You were ordering a drink
I was choosing what to wear

[Pre-Chorus: Rapid rhythmic cells]
Make a move
Make a move
Before I talk myself out
Before I talk myself out

[Chorus: Bouncy bass, vocal chop hook]
Come talk to me
Come talk to me
Right now
Come talk to me

[Verse 2: Ad-libs enter, energy up]
You smiled at the window
I smiled at the door
Now we're in the middle
And I don't need more

[Pre-Chorus: Rapid rhythmic cells]
Make a move
Make a move
Before I talk myself out
Before I talk myself out

[Chorus: Bouncy bass, vocal chop hook]
Come talk to me
Come talk to me
Right now
Come talk to me

[Bridge: Stripped drums, spoken flirtation]
One more song
Then we see
If this is real
Or just caffeine

[Final Chorus: Full stack, swing energy]
Come talk to me
Come talk to me
Right now
Come talk to me

[Outro: Vocal chop fade, 2-step groove tail]

[End]
"""

_FEW_SHOT_GOOD: dict[str, str] = {
    PROFILE_HOUSE_DEEP_TECH: _HOUSE_FEW_SHOT_GOOD,
    PROFILE_TECHNO: _TECHNO_FEW_SHOT_GOOD,
    PROFILE_TRANCE: _TRANCE_FEW_SHOT_GOOD,
    PROFILE_FUTURE_BASS: _FUTURE_BASS_FEW_SHOT_GOOD,
    PROFILE_DUBSTEP_DNB: _DUBSTEP_DNB_FEW_SHOT_GOOD,
    PROFILE_AMAPIANO_VINAHOUSE: _AMAPIANO_FEW_SHOT_GOOD,
    PROFILE_GARAGE_CLUB: _GARAGE_FEW_SHOT_GOOD,
}

_PROFILE_LABELS = {
    PROFILE_HOUSE_DEEP_TECH: "House / Deep House / Tech House",
    PROFILE_TECHNO: "Techno / Hard Techno / Melodic Techno",
    PROFILE_TRANCE: "Trance / Uplifting Trance",
    PROFILE_FUTURE_BASS: "Future Bass / Melodic Dubstep",
    PROFILE_DUBSTEP_DNB: "Dubstep / Drum & Bass",
    PROFILE_AMAPIANO_VINAHOUSE: "Amapiano / Vinahouse / Afro-House",
    PROFILE_GARAGE_CLUB: "UK Garage / Jersey Club / Nu-Disco",
}

_DEFAULT_MOODS = {
    PROFILE_HOUSE_DEEP_TECH: "Intimate, Groovy, Late-night",
    PROFILE_TECHNO: "Hypnotic, Industrial, Physical",
    PROFILE_TRANCE: "Euphoric, Longing, Release-focused",
    PROFILE_FUTURE_BASS: "Wistful, Emotional, Explosive",
    PROFILE_DUBSTEP_DNB: "Heavy, Confrontational, Cathartic",
    PROFILE_AMAPIANO_VINAHOUSE: "Warm, Communal, Celebratory",
    PROFILE_GARAGE_CLUB: "Playful, Rhythmic, Party-forward",
}

_DEFAULT_BPMS = {
    PROFILE_HOUSE_DEEP_TECH: "124",
    PROFILE_TECHNO: "140",
    PROFILE_TRANCE: "138",
    PROFILE_FUTURE_BASS: "150",
    PROFILE_DUBSTEP_DNB: "174",
    PROFILE_AMAPIANO_VINAHOUSE: "115",
    PROFILE_GARAGE_CLUB: "130",
}

_WORD_PATTERNS: dict[str, re.Pattern[str]] = {}


def _normalize_phrase(value: str) -> str:
    raw = value.lower()
    raw = re.sub(r"[-/]+", " ", raw)
    return re.sub(r"\s+", " ", raw).strip()


def _genre_blob(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> str:
    return _normalize_phrase(
        f"{primary_genre} {sub_genre_fusion} {vibe} {lyric_theme_notes}"
    )


def _has_word(blob: str, word: str) -> bool:
    key = _normalize_phrase(word)
    if not key:
        return False
    pattern = _WORD_PATTERNS.get(key)
    if pattern is None:
        pattern = re.compile(rf"\b{re.escape(key)}\b")
        _WORD_PATTERNS[key] = pattern
    return pattern.search(blob) is not None


def is_edm_lane(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> bool:
    blob = _genre_blob(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
    if not blob:
        return False
    return any(_has_word(blob, marker) for marker in _EDM_MARKERS)


def resolve_profile(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
) -> str:
    blob = _genre_blob(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )

    for tokens, profile in _PROFILE_RULES:
        if any(_has_word(blob, token) for token in tokens):
            return profile

    return PROFILE_HOUSE_DEEP_TECH


def sub_genre_label(profile: str) -> str:
    return _PROFILE_LABELS.get(profile, "EDM")


def _format_vocalist(vocal_spec: str, vocal_tone: str) -> str:
    s = vocal_spec.strip()
    t = vocal_tone.strip()
    if not s and not t:
        return "Genre-appropriate lead with close-mic presence"
    if not s:
        return t
    if not t:
        return s
    return f"{s} — {t}"


def _default_mood_for_profile(profile: str) -> str:
    return _DEFAULT_MOODS.get(profile, "Energetic, Release-focused")


def _default_bpm_for_profile(profile: str) -> str:
    return _DEFAULT_BPMS.get(profile, "128")


def _few_shot_vocalist_for(profile: str) -> str:
    if profile == PROFILE_HOUSE_DEEP_TECH:
        return "Low-register dry female lead, spoken-sung intimacy"
    if profile == PROFILE_TECHNO:
        return "Cold spoken-word male lead, hypnotic and commanding"
    if profile == PROFILE_TRANCE:
        return "Airy floating female lead, long vowels, soaring harmonies"
    if profile == PROFILE_FUTURE_BASS:
        return "Airy R&B female lead, belted chest voice at peaks"
    if profile == PROFILE_DUBSTEP_DNB:
        return "Smooth warm male lead (liquid) or sharp hype MC (heavy)"
    if profile == PROFILE_AMAPIANO_VINAHOUSE:
        return "Rhythmic male/female lead, chantable call-and-response"
    if profile == PROFILE_GARAGE_CLUB:
        return "Playful female lead, chopped rhythmic phrases"
    return "Genre-appropriate lead with close-mic presence"


def _few_shot_theme_for(profile: str, notes: str) -> str:
    if notes.strip():
        return notes.strip()
    if profile == PROFILE_HOUSE_DEEP_TECH:
        return "The tension of wanting to stay but knowing you should leave"
    if profile == PROFILE_TECHNO:
        return "Surrendering to the pressure until it becomes power"
    if profile == PROFILE_TRANCE:
        return "The emotional breakthrough after a long goodbye"
    if profile == PROFILE_FUTURE_BASS:
        return "Memory of someone through the objects they left behind"
    if profile == PROFILE_DUBSTEP_DNB:
        return "Breaking free from a weight that kept you still"
    if profile == PROFILE_AMAPIANO_VINAHOUSE:
        return "Celebrating how rhythm carries you through hard days"
    if profile == PROFILE_GARAGE_CLUB:
        return "Late-night flirtation on a crowded floor"
    return "Internal conflict reaching release"


def _theme_from_notes(notes: str, profile: str) -> str:
    if notes.strip():
        return notes.strip()
    return _few_shot_theme_for(profile, "")


def compose_system_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    profile: str | None = None,
) -> str:
    p = profile or resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    matrix = _SUB_GENRE_MATRIX.get(p, _SUB_GENRE_MATRIX[PROFILE_HOUSE_DEEP_TECH])
    return "\n\n".join(
        (
            CROSS_ARCHITECTURE_RULES,
            MASTER_ROLE,
            matrix,
            UNIVERSAL_STRICT_RULES,
            PRE_OUTPUT_QA,
        )
    )


def build_user_selections_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
    profile: str | None = None,
) -> str:
    p = profile or resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    mood = vibe.strip() or _default_mood_for_profile(p)
    label = sub_genre_label(p)
    vocalist = _format_vocalist(vocal_spec, vocal_tone)
    theme = _theme_from_notes(lyric_theme_notes, p)
    lines = [
        "Write an EDM song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        f"- BPM: {bpm_hint.strip() or _default_bpm_for_profile(p)}",
    ]
    if theme:
        lines.extend(["", "THEME GUIDANCE:", theme])
    return "\n".join(lines)


def _few_shot_user_turn(
    *,
    profile: str,
    lyric_theme_notes: str = "",
    vibe: str = "",
) -> str:
    label = sub_genre_label(profile)
    mood = vibe.strip() or _default_mood_for_profile(profile)
    vocalist = _few_shot_vocalist_for(profile)
    theme = _few_shot_theme_for(profile, lyric_theme_notes)
    lines = [
        "Write an EDM song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        f"- BPM: {_default_bpm_for_profile(profile)}",
    ]
    if theme:
        lines.extend(["", "THEME GUIDANCE:", theme])
    return "\n".join(lines)


def master_edm_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_edm_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ):
        return ""
    profile = resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    system = compose_system_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        profile=profile,
    )
    user = build_user_selections_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
        profile=profile,
    )
    return f"{system}\n\n{user}"


def few_shot_prefix_messages(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> list[dict[str, str]]:
    profile = resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    user = _few_shot_user_turn(
        profile=profile,
        lyric_theme_notes=lyric_theme_notes,
        vibe=vibe,
    )
    assistant = _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_HOUSE_DEEP_TECH])
    return [
        {"role": "user", "content": user},
        {"role": "assistant", "content": assistant},
    ]


def should_inject_few_shot(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    lyrics_task: bool = True,
) -> bool:
    return lyrics_task and is_edm_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
