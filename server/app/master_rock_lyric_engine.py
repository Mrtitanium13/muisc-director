"""Master Rock lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

PROFILE_CLASSIC_ALT = "classic_alt"
PROFILE_POP_PUNK_EMO = "pop_punk_emo"
PROFILE_METAL_HEAVY = "metal_heavy"

_GENRE_MARKERS = [
    "rock",
    "classic rock",
    "hard rock",
    "alternative",
    "alt rock",
    "indie rock",
    "pop punk",
    "pop-punk",
    "punk",
    "emo",
    "metal",
    "metalcore",
    "heavy metal",
    "post-rock",
    "shoegaze",
]

CROSS_ARCHITECTURE_RULES = """\
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
"""

UNIVERSAL_STRICT_RULES = """\
STRICT WRITING RULES FOR ALL ROCK:
- Choruses anthemic but song-specific; verses carry concrete friction.
- Tag instrumental breaks as staging only; Fourth-Wall Law on sung lines.
- Verse 2 must escalate or complicate Verse 1.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
"""

MASTER_ROLE_PROMPT = """\
You are a master rock/metal lyricist. Write guitar-era grit with real interpersonal stakes — never neon-wild festival slogans.
"""

_SUB_GENRE_MATRIX = {
    PROFILE_CLASSIC_ALT: """SUB-GENRE: CLASSIC / ALT / INDIE ROCK
- Vibe: Guitar-driven grit, live-room honesty, stadium chorus when earned.
- Focus: Argument mid-sentence, cracked windshield detail, not neon wild slogans.
- Arrangement: [Intro] [Verse] [Chorus] [Verse] [Chorus] [Bridge/Solo tag] [Final Chorus] [Outro].
- Allow [Guitar Solo] staging; no gear names in sung lines.""",
    PROFILE_POP_PUNK_EMO: """SUB-GENRE: POP PUNK / EMO / PUNK
- Vibe: Fast, nasal, angst-fueled verses → explosive melodic choruses.
- Focus: Dead-end town specificity, parking-lot fights, apologies said wrong.
- Ban: teenage shadows, rise up, empty scream-for-scream slogans.""",
    PROFILE_METAL_HEAVY: """SUB-GENRE: METAL / METALCORE
- Vibe: Staccato verse aggression → soaring clean or guttural payoff.
- Focus: Concrete pressure and defiance — not fantasy-sword spam unless user asks.
- Ban: bubblegum romance, rise up / burn it down as empty mantras.
- Allow scream-ready syllables in breakdowns; clean legato in choruses when melodic.""",
}

@dataclass(frozen=True)
class _ProfileRule:
    tokens: list[str]
    profile: str

    def matches(self, blob: str) -> bool:
        for t in self.tokens:
            if _has_word(blob, t) or t in blob:
                return True
        return False


_PROFILE_RULES = [
    _ProfileRule(tokens=["classic rock", "hard rock", "alternative", "alt rock", "indie rock"], profile=PROFILE_CLASSIC_ALT),
    _ProfileRule(tokens=["pop punk", "pop-punk", "punk", "emo"], profile=PROFILE_POP_PUNK_EMO),
    _ProfileRule(tokens=["metal", "metalcore", "heavy metal", "death metal"], profile=PROFILE_METAL_HEAVY),
]

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR ROCK:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

_CLASSIC_ALT_FEW_SHOT_GOOD = """\
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
"""
_POP_PUNK_EMO_FEW_SHOT_GOOD = """\
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
"""
_METAL_HEAVY_FEW_SHOT_GOOD = """\
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
"""

_FEW_SHOT_GOOD = {
    PROFILE_CLASSIC_ALT: _CLASSIC_ALT_FEW_SHOT_GOOD,
    PROFILE_POP_PUNK_EMO: _POP_PUNK_EMO_FEW_SHOT_GOOD,
    PROFILE_METAL_HEAVY: _METAL_HEAVY_FEW_SHOT_GOOD,
}

_SUB_GENRE_LABELS = {
    PROFILE_CLASSIC_ALT: "Classic / Alt / Indie Rock",
    PROFILE_POP_PUNK_EMO: "Pop Punk / Emo / Punk",
    PROFILE_METAL_HEAVY: "Metal / Metalcore / Heavy",
}


def _normalize_phrase(raw: str) -> str:
    return re.sub(r"\s+", " ", (raw or "").lower()).strip()


def _has_word(blob: str, marker: str) -> bool:
    m = _normalize_phrase(marker)
    if not m:
        return False
    if " " not in m:
        return re.search(rf"\b{re.escape(m)}\b", blob) is not None
    return m in blob


def _genre_blob(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> str:
    return _normalize_phrase(
        " ".join(
            [
                primary_genre or "",
                sub_genre_fusion or "",
                vibe or "",
                lyric_theme_notes or "",
            ]
        )
    )


def is_rock_lane(
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
    return any(_has_word(blob, m) for m in _GENRE_MARKERS)


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
    for rule in _PROFILE_RULES:
        if rule.matches(blob):
            return rule.profile
    return PROFILE_CLASSIC_ALT


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "Rock")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_CLASSIC_ALT]
    return "\n\n".join(
        [
            CROSS_ARCHITECTURE_RULES.strip(),
            MASTER_ROLE_PROMPT.strip(),
            sub.strip(),
            UNIVERSAL_STRICT_RULES.strip(),
            PRE_OUTPUT_QA.strip(),
        ]
    ).strip()


def _format_vocalist(vocal_spec: str = "", vocal_tone: str = "") -> str:
    spec = (vocal_spec or "").strip()
    tone = (vocal_tone or "").strip()
    if not spec and not tone:
        return "Close-mic lead appropriate to lane"
    if not spec:
        return tone
    if not tone:
        return spec
    return f"{spec} · {tone}"


def _build_user_selections_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
    profile: str,
) -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "Write a song-specific conflict for this rock lane."
    )
    return f"""USER SELECTIONS (ROCK MASTER):
- Primary genre: {primary_genre}
- Sub-genre / fusion: {(sub_genre_fusion or "").strip() or "(none)"}
- Resolved profile: {profile} ({sub_genre_label(profile)})
- Vibe: {(vibe or "").strip() or "(none)"}
- Theme / story: {theme}
- Vocalist: {_format_vocalist(vocal_spec, vocal_tone)}
- BPM hint: {(bpm_hint or "").strip() or "(none)"}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def master_rock_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_rock_lane(
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
    selections = _build_user_selections_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
        profile=profile,
    )
    return f"{system}\n\n{selections}".strip()


def few_shot_assistant_turn(profile: str) -> str:
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_CLASSIC_ALT])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a Rock song in the {sub_genre_label(profile)} lane. "
        f"Theme: {theme}. Follow the master rules. End Block 2 with [End]."
    )


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
    return [
        {
            "role": "user",
            "content": few_shot_user_turn(
                profile=profile, lyric_theme_notes=lyric_theme_notes
            ),
        },
        {"role": "assistant", "content": few_shot_assistant_turn(profile)},
    ]


def should_inject_few_shot(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    lyrics_task: bool = False,
) -> bool:
    return bool(lyrics_task) and is_rock_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
