"""Master Country lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

PROFILE_MODERN_COUNTRY = "modern_country"
PROFILE_OUTLAW_AMERICANA = "outlaw_americana"
PROFILE_FOLK_SONGWRITER = "folk_songwriter"

_GENRE_MARKERS = [
    "country",
    "modern country",
    "outlaw country",
    "americana",
    "bluegrass",
    "folk",
    "indie folk",
    "folk-rock",
    "folk rock",
    "singer-songwriter",
    "singer songwriter",
    "nashville",
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
STRICT WRITING RULES FOR ALL COUNTRY/FOLK:
- Name places, objects, and relationships; avoid abstract emotion-only lines.
- Chorus sticky line ≤8 words; Verse 2 adds new story beat.
- Twang-friendly open vowels on peak hooks.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
"""

MASTER_ROLE_PROMPT = """\
You are a master country/folk lyricist. Write porch-true stories with place, people, and stakes — never interchangeable Nashville glitter or AI Hallmark.
"""

_SUB_GENRE_MATRIX = {
    PROFILE_MODERN_COUNTRY: """SUB-GENRE: MODERN COUNTRY
- Vibe: Story-first, place names, family/road detail, twang-friendly vowels.
- Ban: generic truck/beer checklist spam unless user theme needs it; avoid Hallmark.
- Arrangement: Verse-chorus with optional [Banjo/Steel] staging in brackets only.""",
    PROFILE_OUTLAW_AMERICANA: """SUB-GENRE: OUTLAW / AMERICANA
- Vibe: Weathered narrative, moral gray, concrete work and road detail.
- Prefer dusty specificity over radio-country glitter.""",
    PROFILE_FOLK_SONGWRITER: """SUB-GENRE: FOLK / SINGER-SONGWRITER
- Vibe: Intimate first-person, acoustic-room honesty, nature as setting not metaphor spam.
- Lines can breathe; imperfect rhyme welcome.""",
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
    _ProfileRule(tokens=["modern country", "nashville", "country pop"], profile=PROFILE_MODERN_COUNTRY),
    _ProfileRule(tokens=["outlaw", "americana", "alt-country", "alt country"], profile=PROFILE_OUTLAW_AMERICANA),
    _ProfileRule(tokens=["folk", "indie folk", "folk-rock", "folk rock", "singer-songwriter", "singer songwriter", "bluegrass"], profile=PROFILE_FOLK_SONGWRITER),
]

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR COUNTRY:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

_MODERN_COUNTRY_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Acoustic strum, soft steel]

[Verse 1: Warm close-mic]
Screen door still sticks in July
Mama said you'd call by Sunday
It's Wednesday and the coffee went cold
I left your chair pulled out anyway

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Verse 2]
Dust on the dash from the county road
I kept your postcard in the glove box
Folded wrong on purpose

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Bridge]
If you're gone, say you're gone
I can take the truth

[Final Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Outro]

[End]
"""
_OUTLAW_AMERICANA_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dry acoustic, room tone]

[Verse 1]
I fixed the fence you broke last spring
Didn't ask for thanks
You left a note under the sugar jar
Said "sorry" like it was enough

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Verse 2]
Midnight train don't stop for pride
I learned that the hard way twice

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Bridge]
I ain't holy
I ain't clean
I'm still here

[Final Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Outro]

[End]
"""
_FOLK_SONGWRITER_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Fingerpicked acoustic]

[Verse 1]
I walked the long way past your street
So I wouldn't have to wave
The porch light was on like always
I kept moving

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Verse 2]
Cold rain on the open plains
I talked to myself like you were listening

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Bridge]
Maybe that's growth
Maybe that's just tired

[Final Chorus]
I still know your window
I still know your window
I don't knock anymore

[Outro]

[End]
"""

_FEW_SHOT_GOOD = {
    PROFILE_MODERN_COUNTRY: _MODERN_COUNTRY_FEW_SHOT_GOOD,
    PROFILE_OUTLAW_AMERICANA: _OUTLAW_AMERICANA_FEW_SHOT_GOOD,
    PROFILE_FOLK_SONGWRITER: _FOLK_SONGWRITER_FEW_SHOT_GOOD,
}

_SUB_GENRE_LABELS = {
    PROFILE_MODERN_COUNTRY: "Modern Country / Nashville",
    PROFILE_OUTLAW_AMERICANA: "Outlaw / Americana",
    PROFILE_FOLK_SONGWRITER: "Folk / Singer-Songwriter",
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


def is_country_lane(
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
    return PROFILE_MODERN_COUNTRY


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "Country")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_MODERN_COUNTRY]
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
        "Write a song-specific conflict for this country lane."
    )
    return f"""USER SELECTIONS (COUNTRY MASTER):
- Primary genre: {primary_genre}
- Sub-genre / fusion: {(sub_genre_fusion or "").strip() or "(none)"}
- Resolved profile: {profile} ({sub_genre_label(profile)})
- Vibe: {(vibe or "").strip() or "(none)"}
- Theme / story: {theme}
- Vocalist: {_format_vocalist(vocal_spec, vocal_tone)}
- BPM hint: {(bpm_hint or "").strip() or "(none)"}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def master_country_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_country_lane(
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
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_MODERN_COUNTRY])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a Country song in the {sub_genre_label(profile)} lane. "
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
    return bool(lyrics_task) and is_country_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
