"""Master RnB lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

PROFILE_TRAP_SOUL = "trap_soul"
PROFILE_NEO_SOUL = "neo_soul"
PROFILE_CONTEMPORARY = "contemporary"

_GENRE_MARKERS = [
    "rnb",
    "r&b",
    "r and b",
    "contemporary r&b",
    "contemporary rnb",
    "neo-soul",
    "neo soul",
    "trap soul",
    "quiet storm",
    "new jack",
    "soul",
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
STRICT WRITING RULES FOR ALL R&B:
- Verses conversational; choruses stacked and sticky.
- Ad-libs belong in parens as sung words only.
- Concrete relationship detail over abstract longing labels.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
"""

MASTER_ROLE_PROMPT = """\
You are a master R&B/soul lyricist. Write intimate, melismatic-ready lines with real relationship friction — never neon-shadow Hallmark.
"""

_SUB_GENRE_MATRIX = {
    PROFILE_TRAP_SOUL: """SUB-GENRE: TRAP SOUL
- Vibe: Dark, moody, relationship-centered vulnerability over 808 pocket.
- Short confessional lines; hook hypnotic and specific.""",
    PROFILE_NEO_SOUL: """SUB-GENRE: NEO-SOUL / QUIET STORM
- Vibe: Organic chest-voice warmth, late-night intimacy, socially aware when theme fits.
- Prefer lived detail over velvet-skies abstractions.""",
    PROFILE_CONTEMPORARY: """SUB-GENRE: CONTEMPORARY R&B
- Vibe: Silky melisma room, conversational ad-libs, stacked chorus harmonies.
- Focus: Relationship specificity — hoodie on chair, phone face-down, I meant what I said.
- Ban: neon shadows, pieces of me, drowning in you.""",
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
    _ProfileRule(tokens=["trap soul"], profile=PROFILE_TRAP_SOUL),
    _ProfileRule(tokens=["neo-soul", "neo soul", "quiet storm"], profile=PROFILE_NEO_SOUL),
    _ProfileRule(tokens=["contemporary r&b", "contemporary rnb", "contemporary"], profile=PROFILE_CONTEMPORARY),
]

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR R&B:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

_TRAP_SOUL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dark pad, 808]

[Verse 1]
I keep replaying what you didn't say
Kitchen light buzzing like a warning
You want soft
I want straight

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Verse 2]
I bit my tongue till it tasted like staying
I'm done with that flavor

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Bridge]
One honest line
That's all

[Final Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Outro]

[End]
"""
_NEO_SOUL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Warm Rhodes]

[Verse 1]
Late ride home with the window cracked
City humming like it knows my secrets
I told you I'd be better by spring
Spring came quiet

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Verse 2]
Your laugh still sits in the passenger seat
I don't move it

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Bridge]
Sweet healing ain't a slogan
It's putting the fight down

[Final Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Outro]

[End]
"""
_CONTEMPORARY_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft keys, intimate]

[Verse 1: Smooth close-mic]
Your hoodie on my chair again
Phone face-down like I'm not tempted
I almost called then I laughed it off
I meant what I said last week

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Verse 2]
You talk soft when you want a door open
I learned that tone the hard way

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Bridge]
Say it to my face
Or don't say it

[Final Chorus]
I almost called
I almost called
Then I left it alone

[Outro]

[End]
"""

_FEW_SHOT_GOOD = {
    PROFILE_TRAP_SOUL: _TRAP_SOUL_FEW_SHOT_GOOD,
    PROFILE_NEO_SOUL: _NEO_SOUL_FEW_SHOT_GOOD,
    PROFILE_CONTEMPORARY: _CONTEMPORARY_FEW_SHOT_GOOD,
}

_SUB_GENRE_LABELS = {
    PROFILE_TRAP_SOUL: "Trap Soul",
    PROFILE_NEO_SOUL: "Neo-Soul / Quiet Storm",
    PROFILE_CONTEMPORARY: "Contemporary R&B",
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


def is_rnb_lane(
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
    return PROFILE_CONTEMPORARY


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "RnB")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_CONTEMPORARY]
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
        "Write a song-specific conflict for this rnb lane."
    )
    return f"""USER SELECTIONS (RNB MASTER):
- Primary genre: {primary_genre}
- Sub-genre / fusion: {(sub_genre_fusion or "").strip() or "(none)"}
- Resolved profile: {profile} ({sub_genre_label(profile)})
- Vibe: {(vibe or "").strip() or "(none)"}
- Theme / story: {theme}
- Vocalist: {_format_vocalist(vocal_spec, vocal_tone)}
- BPM hint: {(bpm_hint or "").strip() or "(none)"}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def master_rnb_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_rnb_lane(
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
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_CONTEMPORARY])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a RnB song in the {sub_genre_label(profile)} lane. "
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
    return bool(lyrics_task) and is_rnb_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
