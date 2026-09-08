"""Master Hardstyle / Hard Dance lyric + arrangement engine (5 sub-genre matrix)."""

from __future__ import annotations

import re

PROFILE_EUPHORIC = "euphoric_hardstyle"
PROFILE_RAWSTYLE = "rawstyle"
PROFILE_HARD_BOUNCE = "hard_bounce"
PROFILE_HARD_DANCE = "hard_dance"
PROFILE_EURO_BOOTLEG = "euro_dance_bootleg"

_HARDSTYLE_MARKERS = (
    "hardstyle",
    "rawstyle",
    "euphoric hardstyle",
    "hard bounce",
    "hard dance",
    "hardcore",
    "frenchcore",
    "raw hardstyle",
    "classic hardstyle",
)

CROSS_ARCHITECTURE_RULES = """\
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
  fade to silence."""

UNIVERSAL_STRICT_RULES = """\
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
    "let it go", "put your hands up", "feel the bass", "we're going higher",
    "rise up", "burn it down", "we are thunder", "take me higher",
    "bounce it back", "hit the floor", "shake it out", "lose the weight",
    "the bounce feels right".
  Also ban sci-fi/rave metaphor stacks: frequency, static tension,
  vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic,
  wavelength, interstellar, sparks fly, electricity, energy, universe.

- HUMAN AUTHENTICITY (MANDATORY): Breakdown must read like a real person
  confessing under pressure — unpolished, specific, song-unique. Build
  turns cold and commanding. Pre-drop is a single production trigger.
  Drop chops must pass DROP MANTRA TEST (human phrase for THIS conflict,
  not stock bounce/festival chants). Never name beat/drop/bass/floor as
  emotional salvation.

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
  (T, K, P, M, N)."""

MASTER_ROLE = """\
You are an elite lyricist, vocal arranger, and hard dance producer for
Hardstyle, Rawstyle, Euphoric Hardstyle, Hard Bounce, and Hard Dance.
You write raw, physically intense, emotionally honest hard dance vocals
that move from vulnerable breakdown confessions to fierce build-up
commands to anthemic drop mantras. You obey the Cross-Architecture
Non-Negotiables and Strict Writing Rules above."""

PRE_OUTPUT_QA = """\
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
    distant, or buried?"""

_SUB_GENRE_MATRIX: dict[str, str] = {
    PROFILE_EUPHORIC: """\
SUB-GENRE: EUPHORIC HARDSTYLE
- Vibe: Emotional, melodic, anthemic, festival mainstage, uplifting
  darkness-to-light arc.
- Lyrical Focus: Survival, inner battles, finding strength, defiance,
  not giving up.
- Vocal Style: Breakdown = vulnerable, half-sung confession; Build =
  cold determination; Pre-Drop = single screamed command; Drop =
  melodic anthem mantra.
- Arrangement: Distorted reverse-bass kicks, detuned supersaw leads,
  orchestral stabs, pitch-shifted vocal chops, massive reverb vacuum.""",
    PROFILE_RAWSTYLE: """\
SUB-GENRE: RAWSTYLE
- Vibe: Darker, harder, industrial, aggressive, psychological pressure.
- Lyrical Focus: Confrontation with inner demons, societal pressure,
  raw endurance, controlled fury.
- Vocal Style: Breakdown = spoken-word grit, paranoia, pressure; Build =
  defiant commands; Pre-Drop = harsh scream; Drop = distorted mantra
  chops.
- Arrangement: Heavily distorted raw kicks, screech synths, industrial
  noise textures, darker chord progressions, relentless forward drive.""",
    PROFILE_HARD_BOUNCE: """\
SUB-GENRE: HARD BOUNCE
- Vibe: Bouncy, playful, high-energy, party-forward, festival bounce.
- Lyrical Focus: Letting go, movement, crowd energy, simple hooks.
- Vocal Style: Breakdown = conversational party confession; Build =
  rhythmic chant fragments; Pre-Drop = short hype command; Drop =
  bouncy repetitive hook chops.
- Arrangement: Punchy offbeat bounce bass, hard kick, crisp clap-snare,
  festival lead stabs, air-horn/siren builds.""",
    PROFILE_HARD_DANCE: """\
SUB-GENRE: HARD DANCE (150 BPM MAINSTAGE)
- Vibe: Cinematic, euphoric, raw, mainstage-focused, extended DJ tool.
- Lyrical Focus: Journey, breakthrough, emotional climax, survival.
- Vocal Style: Breakdown = cinematic intimate confession; Build =
  soaring open-vowel urgency; Pre-Drop = one screamed word; Drop =
  massive anthem mantra.
- Arrangement: Rolling hardstyle kick-and-bass, mid-intro power section,
  cinematic breakdown with orchestral strings, climax drop with stacked
  screaming synths, 32-bar DJ bookends.""",
    PROFILE_EURO_BOOTLEG: """\
SUB-GENRE: EURO-DANCE BOOTLEG HARDSTYLE
- Vibe: Early-2000s Euro-dance nostalgia crossed with hardstyle impact.
- Lyrical Focus: Emotional melodrama, romantic defiance, dancefloor
  liberation.
- Vocal Style: Breakdown = dry filtered Euro-dance vocal, short sung
  lines or intimate spoken phrases; Build = accelerating vocal chops;
  Pre-Drop = yelled command or heavy phrase; Drop = pitch-shifted
  anthem hook chops.
- Arrangement: Hardstyle kick under Euro-dance chord stabs, supersaw
  hooks, pitch-shifted vocal chops, bounce-forward energy.""",
}

_PROFILE_RULES: tuple[tuple[tuple[str, ...], str], ...] = (
    (("rawstyle", "raw hardstyle", "rawstyle hard"), PROFILE_RAWSTYLE),
    (("hard bounce", "melbourne bounce", "bounce hardstyle"), PROFILE_HARD_BOUNCE),
    (("hard dance", "mainstage hardstyle", "150 bpm hard"), PROFILE_HARD_DANCE),
    (
        (
            "euro-dance bootleg",
            "euro dance bootleg",
            "hands up",
            "euro hardstyle",
        ),
        PROFILE_EURO_BOOTLEG,
    ),
    (("euphoric hardstyle", "euphoric", "melodic hardstyle"), PROFILE_EUPHORIC),
)

_EUPHORIC_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]
[Rolling hardstyle kick-and-bass pattern, sharp percussion, rising filter]

[Mid-Intro]
[Heavy instrumental power, distorted reverse-bass kicks, screech patterns, driving energy]

[Breakdown: Cinematic breakdown, kicks cut, lush pads, ultra-vulnerable close-mic lead]
I kept your voicemail just to hear you breathe
I played it twice then deleted everything
I said I was fine to everybody else
Then the quiet asked me questions I can't help

[Build-up: Accelerating snare rolls, open-vowel urgency, reverb washout expanding]
Still here
Still here
Look at me
Look at me

[Pre-Drop: Single screamed command, vacuum gap after]
BREATHE

[Drop: Full impact, distorted kicks, stacked supersaws, human mantra]
Don't call again
Don't call again
I already left
Don't call again

[Outro: Warehouse decay, lead synths cut, stripping to pure percussive kick]

[End]
"""

_RAWSTYLE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]
[Industrial kick rumble, metal percussion, dark noise texture]

[Mid-Intro]
[Raw distorted kicks, screech synth stabs, relentless forward drive]

[Breakdown: Kicks cut, cold spoken-word grit, paranoia, pressure]
They put my name on a wall I didn't build
Counted my breath like it was something to kill
Every shadow got a number, every number got a plan
I stopped answering the voice in my head, man

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
Not today
No surrender

[Outro: Industrial percussion decay, feedback ring]

[End]
"""

_HARD_BOUNCE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]
[Bouncy four-on-the-floor kick, offbeat stab, crisp clap]

[Mid-Intro]
[Hard bounce energy rising, festival stabs, snare builds]

[Breakdown: Percussion drops, conversational female lead, dry filtered]
I told my friends I'd stay home
Then I showed up anyway
Don't ask me why I'm smiling
I don't have a clean answer

[Build-up: Vocal chop fragments stacking, rhythmic urgency]
Closer
Closer
Don't speak
Don't speak

[Pre-Drop: Short command]
NOW

[Drop: Hard kick, offbeat bounce, pitch-shifted hook chops]
Don't touch me yet
Don't touch me yet
Wait for it
Don't touch me yet
Don't touch me yet
Wait for it

[Outro: Strip to kick and bounce stab, festival fade]

[End]"""

_HARD_DANCE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]
[Rolling hardstyle kick-and-bass pattern, 32-bar DJ tool layout]

[Mid-Intro]
[Heavy instrumental power, distorted raw kicks, screech layers, cinematic tension]

[Breakdown: Orchestral strings, kicks cut completely, ultra-vulnerable close-mic lead]
The phone went dark mid-sentence
I waited like a fool for three more rings
Every promise sounded like a bill
I finally stopped negotiating with silence

[Build-up: Snare rolls, pitch sweeps, rising open-vowel urgency into reverb vacuum]
Still here
Still here
Look at me
Look at me

[Pre-Drop: Single screamed command]
GO

[Climax Drop: Epic melodic chord progression, massive pitch-shifted kicks, stacked screaming synths, weighty human mantra]
Stop apologizing
Stop apologizing
I already left
Stop apologizing

[Second Breakdown: Stripped pad and breath vocal]
I don't want easy
I want honest

[Second Build-up: Accelerating snare rolls]
Look at me
Look at me

[Final Drop: Full stack, maximum dynamics]
Stop apologizing
Stop apologizing
I already left
Stop apologizing

[Outro: 32-bar DJ outro runway, lead synths cut, pure percussive fade to silence]

[End]"""

_EURO_BOOTLEG_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]
[Hardstyle kick under Euro-dance chord stab, bright synth hook teaser]

[Mid-Intro]
[Euphoric Euro lead builds, hard kick drops in, festival energy]

[Breakdown: Dry filtered Euro-dance vocal, short sung lines, intimate]
You said goodbye on a Monday
I showed up Friday anyway
I don't need your maybe
I need a clean answer

[Build-up: Vocal repeats and chops accelerate, 2–4 word cells]
Let me go
Let me go
Say it straight
Say it straight

[Pre-Drop: Yelled command or heavy phrase]
NOW

[Drop: Pitch-shifted anthem hook chops, hard kick, supersaw stabs]
I'm not yours
I'm not yours
Say it straight
I'm not yours

[Outro: Euro chord fade, kick and percussion tail]

[End]"""

_FEW_SHOT_GOOD: dict[str, str] = {
    PROFILE_EUPHORIC: _EUPHORIC_FEW_SHOT_GOOD,
    PROFILE_RAWSTYLE: _RAWSTYLE_FEW_SHOT_GOOD,
    PROFILE_HARD_BOUNCE: _HARD_BOUNCE_FEW_SHOT_GOOD,
    PROFILE_HARD_DANCE: _HARD_DANCE_FEW_SHOT_GOOD,
    PROFILE_EURO_BOOTLEG: _EURO_BOOTLEG_FEW_SHOT_GOOD,
}

_PROFILE_LABELS = {
    PROFILE_EUPHORIC: "Euphoric Hardstyle",
    PROFILE_RAWSTYLE: "Rawstyle",
    PROFILE_HARD_BOUNCE: "Hard Bounce",
    PROFILE_HARD_DANCE: "Hard Dance (150 BPM Mainstage)",
    PROFILE_EURO_BOOTLEG: "Euro-Dance Bootleg Hardstyle",
}

_DEFAULT_MOODS = {
    PROFILE_EUPHORIC: "Emotional, Anthemic, Survival-Focused",
    PROFILE_RAWSTYLE: "Dark, Aggressive, Industrial",
    PROFILE_HARD_BOUNCE: "Playful, Bouncy, Festival-Energy",
    PROFILE_HARD_DANCE: "Cinematic, Euphoric, Mainstage",
    PROFILE_EURO_BOOTLEG: "Nostalgic, Melodramatic, Dancefloor",
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


def is_hardstyle_lane(
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
    return any(_has_word(blob, marker) for marker in _HARDSTYLE_MARKERS)


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
    if _has_word(primary_norm, "rawstyle"):
        return PROFILE_RAWSTYLE
    if _has_word(primary_norm, "hard bounce") or _has_word(primary_norm, "bounce"):
        return PROFILE_HARD_BOUNCE
    if _has_word(primary_norm, "hard dance"):
        return PROFILE_HARD_DANCE
    if _has_word(primary_norm, "euro"):
        return PROFILE_EURO_BOOTLEG

    return PROFILE_EUPHORIC


def sub_genre_label(profile: str) -> str:
    return _PROFILE_LABELS.get(profile, "Hardstyle / Hard Dance")


def _format_vocalist(vocal_spec: str, vocal_tone: str) -> str:
    s = vocal_spec.strip()
    t = vocal_tone.strip()
    if not s and not t:
        return "Genre-appropriate gritty lead"
    if not s:
        return t
    if not t:
        return s
    return f"{s} — {t}"


def _default_mood_for_profile(profile: str) -> str:
    return _DEFAULT_MOODS.get(profile, "Intense, Cathartic, Driving")


def _few_shot_vocalist_for(profile: str) -> str:
    if profile == PROFILE_EUPHORIC:
        return (
            "Vulnerable male lead, gravelly close-mic, builds to distorted scream"
        )
    if profile == PROFILE_RAWSTYLE:
        return "Gritty spoken-word male lead, cold defiant delivery"
    if profile == PROFILE_HARD_BOUNCE:
        return "Bouncy female lead, conversational party energy"
    if profile == PROFILE_HARD_DANCE:
        return "Cinematic male lead, intimate breakdown to arena scream"
    if profile == PROFILE_EURO_BOOTLEG:
        return "Euro-dance female lead, dry filtered intimate tone"
    return "Gritty lead with chest-vibrating distortion"


def _few_shot_theme_for(profile: str, notes: str) -> str:
    if notes.strip():
        return notes.strip()
    if profile == PROFILE_EUPHORIC:
        return "Finding strength after hitting rock bottom"
    if profile == PROFILE_RAWSTYLE:
        return "Confronting the pressure that tries to break you"
    if profile == PROFILE_HARD_BOUNCE:
        return "Dropping the weight and losing yourself on the floor"
    if profile == PROFILE_HARD_DANCE:
        return "The journey from silence to a breakthrough scream"
    if profile == PROFILE_EURO_BOOTLEG:
        return "Romantic defiance and dancefloor liberation"
    return "Survival and cathartic release"


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
    matrix = _SUB_GENRE_MATRIX.get(p, _SUB_GENRE_MATRIX[PROFILE_EUPHORIC])
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
        "Write a Hardstyle song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        f"- BPM: {bpm_hint.strip() or '150'}",
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
        "Write a Hardstyle song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
        "- BPM: 150",
    ]
    if theme:
        lines.extend(["", "THEME GUIDANCE:", theme])
    return "\n".join(lines)


def master_hardstyle_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_hardstyle_lane(
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
    assistant = _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_EUPHORIC])
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
    return lyrics_task and is_hardstyle_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
