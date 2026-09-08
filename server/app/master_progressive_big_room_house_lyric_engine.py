"""Master Progressive House / Big Room Fusion / Festival Anthem lyric engine."""

from __future__ import annotations

import re

PROFILE_PROGRESSIVE_VOCAL = "progressive_vocal"
PROFILE_BIG_ROOM_FUSION = "big_room_fusion"
PROFILE_FESTIVAL_ANTHEM = "festival_anthem"
PROFILE_MELODIC_PROG = "melodic_progressive"
PROFILE_STADIUM_BALLAD = "stadium_ballad"

_PROGRESSIVE_BIG_ROOM_MARKERS = (
    "progressive house",
    "big room",
    "bigroom",
    "festival anthem",
    "festival house",
    "festival edm",
    "mainstage",
    "festival progressive",
    "prog house",
    "big room fusion",
    "progressive big room",
)

CROSS_ARCHITECTURE_RULES = """\
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
  plays; never "no vocals / no melody" phrasing. Soft bar budgets only."""

UNIVERSAL_STRICT_RULES = """\
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
    "in this moment", "let it go", "we are thunder", "rise up", "burn it down",
    "take me higher", "break free", "set me free", "we carry on", "hold the line",
    "louder than before", "holding on", "broken inside", "pieces of me",
    "drowning in", "lost in the dark", "find myself", "this is real".
  Also ban sci-fi/rave metaphors: frequency, static tension, vibrations,
  dissolving, galaxies, starlight, seismic, neon, cosmic, wavelength,
  interstellar, sparks fly, electricity, energy, universe.

- HUMAN AUTHENTICITY (MANDATORY): Write like a real person mid-conflict —
  half-thoughts, blunt speech, specific interpersonal friction for THIS
  song. Plain words over poetic synonyms. Drop/chorus must be a sticky
  human phrase that only fits THIS conflict (DROP MANTRA TEST). Ban
  templated "I don't need X / I just need Y" couplets and production-
  as-emotion (beat/drop/bass/floor as savior). Never paste festival
  slogans.

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
  (T, K, P, M, N)."""

MASTER_ROLE = """\
You are an elite lyricist and vocal arranger for Progressive House,
Big Room Fusion, and Festival Anthem productions. You write raw,
commercial, emotionally honest male/female-led vocals designed to cut through
dense supersaw walls. Your verses are intimate internal monologues, your
build-ups are ascending open-vowel urgency, and your drops are
syncopated, chop-ready mantras. You obey the Cross-Architecture
Non-Negotiables and Strict Writing Rules above."""

PRE_OUTPUT_QA = """\
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
14. If DJ flags are ON, is the intro/outro described in sonic terms
    (wordless percussion, kick/hats, loopable fade) with content-rich
    instrumental bookends, not just bar counts?"""

_SUB_GENRE_MATRIX: dict[str, str] = {
    PROFILE_PROGRESSIVE_VOCAL: """\
SUB-GENRE: PROGRESSIVE HOUSE (VOCAL)
- Vibe: Emotional, longing, cinematic, building, euphoric release.
- Lyrical Focus: Unspoken feelings, turning points, emotional surrender,
  unrequited or complicated love.
- Vocal Style: Verse = breathy close-mic intimacy; Build = soaring
  repetitive hook fragments; Drop = melodic anthem mantra.
- Arrangement: Evolving arpeggios, lush pads, rolling bass, supersaw
  chord progressions, long breakdowns, euphoric drops.""",
    PROFILE_BIG_ROOM_FUSION: """\
SUB-GENRE: BIG ROOM FUSION / PROGRESSIVE BIG ROOM
- Vibe: Festival-scale, anthemic, larger-than-life, communal release.
- Lyrical Focus: Defiance, breaking free, collective emotional peak,
  personal revolution.
- Vocal Style: Verse = intimate confessional; Build = crowd-ready chant
  fragments; Drop = massive simple mantra.
- Arrangement: Big room kicks, supersaw walls, snare rolls, white-noise
  risers, wide stereo, hard-limited drops.""",
    PROFILE_FESTIVAL_ANTHEM: """\
SUB-GENRE: FESTIVAL ANTHEM
- Vibe: Mainstage euphoria, collective singing, massive hooks.
- Lyrical Focus: Shared release, unity, not giving up, surviving
  together.
- Vocal Style: Verse = personal whisper; Build = ascending chant; Drop =
  2-line anthem loop designed for 10,000 voices.
- Arrangement: Festival-sized drums, supersaw leads, piano-house chords,
  huge reverb throws, audience-friendly dynamics.""",
    PROFILE_MELODIC_PROG: """\
SUB-GENRE: MELODIC PROGRESSIVE / MELODIC HOUSE
- Vibe: Dreamy, emotional, warm, nostalgic, sunset-driven.
- Lyrical Focus: Memory, longing, bittersweet release, intimate moments.
- Vocal Style: Verse = soft, breathy, close; Build = floating harmonies;
  Drop = emotional melodic hook.
- Arrangement: Warm analog pads, melodic basslines, arpeggios, softer
  drums, rich harmonic progressions, less aggressive than big room.""",
    PROFILE_STADIUM_BALLAD: """\
SUB-GENRE: STADIUM BALLAD PROGRESSIVE
- Vibe: Epic, emotional, slow-build, cinematic, tear-jerking.
- Lyrical Focus: Regret, hope, final chances, emotional confession.
- Vocal Style: Verse = fragile close-mic; Pre-Chorus = rising lift;
  Chorus = full belted anthem; Drop = instrumental swell or vocal chop.
- Arrangement: Piano-led, orchestral strings, massive drums entering at
  chorus, supersaw lift at peak.""",
}

_PROFILE_RULES: tuple[tuple[tuple[str, ...], str], ...] = (
    (("festival anthem", "mainstage anthem", "festival house"), PROFILE_FESTIVAL_ANTHEM),
    (
        (
            "big room fusion",
            "bigroom fusion",
            "big room house",
            "bigroom house",
            "progressive big room",
        ),
        PROFILE_BIG_ROOM_FUSION,
    ),
    (("stadium ballad", "epic ballad", "cinematic progressive"), PROFILE_STADIUM_BALLAD),
    (("melodic progressive", "melodic house", "sunset progressive"), PROFILE_MELODIC_PROG),
    (("progressive house", "progressive vocal", "vocal progressive"), PROFILE_PROGRESSIVE_VOCAL),
)

_PROGRESSIVE_VOCAL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Evolving arpeggio, wide stereo pad, sparse drums]

[Verse 1: Close-mic female lead, dry intimate, minimal verb]
Stop saying we're fine
You looked past me twice
I almost walked then
Didn't

[Pre-Chorus: Vocal doubles enter, tension build, rising pads]
Say it
Say it
Out loud
Out loud

[Drop / Chorus: Supersaw lift, sidechain pump, human mantra]
Don't call me baby
Don't call me baby
Not like that
Don't call me baby

[Breakdown: Stripped to pad and breath vocal, intimate]
You texted almost there
Hours ago
I laughed so I wouldn't
Cry out loud

[Build-up 2: Snare rolls, open-vowel urgency, reverb washout]
Stay gone
Stay gone
I'm done
I'm done

[Pre-Drop: Sharp command]
Go

[Final Drop / Chorus: Full stack, wider, octave lift, max dynamics]
Keep your maybe
Keep your maybe
I'm walking
Keep your maybe

[Outro: Delay tails, filtered pad fade]

[End]"""

_BIG_ROOM_FUSION_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Festival kick, filtered synth stab, rising white noise]

[Verse 1: Dry intimate female lead, close-mic, sparse]
I kept your jacket by the door
You never asked for it back
I still check the hallway when
Someone laughs like you

[Pre-Chorus: Building chant fragments, percussion lifts]
Don't stay
Don't stay
Not tonight
Not tonight

[Drop / Chorus: Big room supersaws, hard kick, human mantra]
Leave your jacket
Leave your jacket
I'm done waiting
Leave your jacket

[Breakdown: Stripped drums and vocal, more personal]
I practiced what I'd say
Then you walked in smiling
All the words went quiet
I just nodded once

[Build-up 2: Snare roll, rising vocals]
Say less
Say less
Walk out
Walk out

[Pre-Drop: Command]
Now

[Final Drop / Chorus: Full festival stack, key lift, max width]
Leave your jacket
Leave your jacket
I'm done waiting
Leave your jacket

[Outro: Kick and synth stab tail, long fade]

[End]"""

_FESTIVAL_ANTHEM_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Crowd texture if live mode, piano-house chord, kick build]

[Verse 1: Whispered female lead, close-mic, intimate]
We shared the same ride home
You talked about next year
I stared at my hands and
Didn't correct you

[Pre-Chorus: Group vocal stack enters, lift]
Stay quiet
Stay quiet
Don't promise
Don't promise

[Drop / Chorus: Full festival arrangement, human mantra]
Don't promise next year
Don't promise next year
Not tonight
Don't promise next year

[Breakdown: Sparse keys only, lead vulnerable]
I wanted to believe you
That was the problem
I wanted to believe you
That was the problem

[Build-up 2: Drum roll]
Don't promise
Don't promise

[Pre-Drop: Command]
Stop

[Final Drop / Chorus: Maximum dynamics, sing-along stack]
Don't promise next year
Don't promise next year
Not tonight
Don't promise next year

[Outro: Piano chord fade, crowd reverb tail if live mode]

[End]"""

_MELODIC_PROG_FEW_SHOT_GOOD = """\
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

[End]"""

_STADIUM_BALLAD_FEW_SHOT_GOOD = """\
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

[End]"""

_FEW_SHOT_GOOD: dict[str, str] = {
    PROFILE_PROGRESSIVE_VOCAL: _PROGRESSIVE_VOCAL_FEW_SHOT_GOOD,
    PROFILE_BIG_ROOM_FUSION: _BIG_ROOM_FUSION_FEW_SHOT_GOOD,
    PROFILE_FESTIVAL_ANTHEM: _FESTIVAL_ANTHEM_FEW_SHOT_GOOD,
    PROFILE_MELODIC_PROG: _MELODIC_PROG_FEW_SHOT_GOOD,
    PROFILE_STADIUM_BALLAD: _STADIUM_BALLAD_FEW_SHOT_GOOD,
}

_PROFILE_LABELS = {
    PROFILE_PROGRESSIVE_VOCAL: "Progressive House (Vocal)",
    PROFILE_BIG_ROOM_FUSION: "Big Room Fusion",
    PROFILE_FESTIVAL_ANTHEM: "Festival Anthem",
    PROFILE_MELODIC_PROG: "Melodic Progressive / Melodic House",
    PROFILE_STADIUM_BALLAD: "Stadium Ballad Progressive",
}

_DEFAULT_MOODS = {
    PROFILE_PROGRESSIVE_VOCAL: "Emotional, Longing, Euphoric",
    PROFILE_BIG_ROOM_FUSION: "Festival-Scale, Defiant, Anthemic",
    PROFILE_FESTIVAL_ANTHEM: "Communal, Bright, Mainstage",
    PROFILE_MELODIC_PROG: "Dreamy, Nostalgic, Warm",
    PROFILE_STADIUM_BALLAD: "Epic, Cinematic, Tear-Jerking",
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


def is_progressive_big_room_lane(
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
    return any(_has_word(blob, marker) for marker in _PROGRESSIVE_BIG_ROOM_MARKERS)


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

    primary_norm = _normalize_phrase(primary_genre)
    if (
        _has_word(primary_norm, "festival")
        or _has_word(primary_norm, "anthem")
        or _has_word(primary_norm, "mainstage")
    ):
        return PROFILE_FESTIVAL_ANTHEM
    if _has_word(primary_norm, "big room") or _has_word(primary_norm, "bigroom"):
        return PROFILE_BIG_ROOM_FUSION
    if (
        _has_word(primary_norm, "stadium")
        or _has_word(primary_norm, "ballad")
        or _has_word(primary_norm, "epic")
    ):
        return PROFILE_STADIUM_BALLAD
    if _has_word(primary_norm, "melodic"):
        return PROFILE_MELODIC_PROG

    return PROFILE_PROGRESSIVE_VOCAL


def sub_genre_label(profile: str) -> str:
    return _PROFILE_LABELS.get(profile, "Progressive / Big Room House")


def _format_vocalist(vocal_spec: str, vocal_tone: str) -> str:
    s = vocal_spec.strip()
    t = vocal_tone.strip()
    if not s and not t:
        return "Genre-appropriate female lead"
    if not s:
        return t
    if not t:
        return s
    return f"{s} — {t}"


def _default_mood_for_profile(profile: str) -> str:
    return _DEFAULT_MOODS.get(profile, "Emotional, Building, Release-Focused")


def _few_shot_vocalist_for(profile: str) -> str:
    if profile == PROFILE_PROGRESSIVE_VOCAL:
        return "Breathy close-mic female lead, building to belted anthem"
    if profile == PROFILE_BIG_ROOM_FUSION:
        return "Intimate confessional female lead, soaring at the drop"
    if profile == PROFILE_FESTIVAL_ANTHEM:
        return "Female lead with festival crowd-sing energy"
    if profile == PROFILE_MELODIC_PROG:
        return "Soft breathy female lead, warm and nostalgic"
    if profile == PROFILE_STADIUM_BALLAD:
        return "Fragile verse female lead, epic belted chorus"
    return "Female lead with thick close-mic presence"


def _few_shot_theme_for(profile: str, notes: str) -> str:
    if notes.strip():
        return notes.strip()
    if profile == PROFILE_PROGRESSIVE_VOCAL:
        return "The moment you realize a relationship has crossed a line"
    if profile == PROFILE_BIG_ROOM_FUSION:
        return "Personal defiance and collective release"
    if profile == PROFILE_FESTIVAL_ANTHEM:
        return "Surviving something hard together with thousands of people"
    if profile == PROFILE_MELODIC_PROG:
        return "Bittersweet memory of a summer that ended too soon"
    if profile == PROFILE_STADIUM_BALLAD:
        return "A final confession before everything changes"
    return "Internal conflict reaching emotional release"


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
    matrix = _SUB_GENRE_MATRIX.get(p, _SUB_GENRE_MATRIX[PROFILE_PROGRESSIVE_VOCAL])
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
        "Write a Progressive/Big Room House song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        f"- BPM: {bpm_hint.strip() or '128'}",
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
        "Write a Progressive/Big Room House song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        "- BPM: 128",
    ]
    if theme:
        lines.extend(["", "THEME GUIDANCE:", theme])
    return "\n".join(lines)


def master_progressive_big_room_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_progressive_big_room_lane(
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
    assistant = _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_PROGRESSIVE_VOCAL])
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
    return lyrics_task and is_progressive_big_room_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
