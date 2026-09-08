"""Master HipHop lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

PROFILE_BOOM_BAP = "boom_bap"
PROFILE_TRAP_DRILL = "trap_drill"
PROFILE_CONSCIOUS = "conscious"

_GENRE_MARKERS = [
    "hiphop",
    "hip-hop",
    "hip hop",
    "rap",
    "boom bap",
    "boombap",
    "trap",
    "drill",
    "phonk",
    "grime",
    "uk drill",
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
STRICT WRITING RULES FOR ALL HIP-HOP:
- Internal rhyme and concrete detail preferred over abstract flex.
- Hook repeats with purpose; verses advance the scene.
- No beat/bass-as-savior metaphors.
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
"""

MASTER_ROLE_PROMPT = """\
You are a master hip-hop lyricist. Write punchy, picture-heavy bars and hooks with human stakes — never empty flex or AI motivator spam.
"""

_SUB_GENRE_MATRIX = {
    PROFILE_BOOM_BAP: """SUB-GENRE: BOOM BAP / CLASSIC RAP
- Vibe: Internal rhyme, concrete street/detail imagery, sample-era authenticity.
- No empty flex filler; no motivational poster bars.
- Hook can be sung or chanted; verses carry pictures.""",
    PROFILE_TRAP_DRILL: """SUB-GENRE: TRAP / DRILL / PHONK
- Vibe: 808-pocket phrasing, cold mood, triplet-friendly counts, hook-first.
- Ban: soft pop-acoustic clichés; empty rise-up motivators.
- Keep bars tactical and specific — not cartoon violence unless user asks.""",
    PROFILE_CONSCIOUS: """SUB-GENRE: CONSCIOUS / STORY RAP
- Vibe: Narrative bars, social/personal stakes, vivid scenes.
- Still ban Hallmark and empty slogans; keep language human.""",
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
    _ProfileRule(tokens=["boom bap", "boombap", "classic rap", "jazz rap"], profile=PROFILE_BOOM_BAP),
    _ProfileRule(tokens=["trap", "drill", "uk drill", "phonk"], profile=PROFILE_TRAP_DRILL),
    _ProfileRule(tokens=["conscious", "story rap", "lyrical rap"], profile=PROFILE_CONSCIOUS),
]

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR HIP-HOP:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

_BOOM_BAP_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dusty drum break]

[Verse 1]
Receipts in my pocket, auntie on the line
Asking if I ate — I say I'm fine
Gate light buzzing like it knows my name
I walk past the corner where we used to claim

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Verse 2]
Vinyl in the crate, story in the scratch
I don't need a caption for the way I act

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Bridge]
No speech
Just proof

[Final Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Outro]

[End]
"""
_TRAP_DRILL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: 808 pulse, sparse hats]

[Verse 1]
Phone face-down, I already know the tone
You want a favor dressed up like a bond
I learned the code: don't talk, just move
Cold steel quiet — nothing to prove

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Verse 2]
Tracking every almost — I delete the thread
Zero mercy for the story that you said

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Bridge]
Say it once
Then leave

[Final Chorus]
Don't text me late
Don't text me late
I ain't on call

[Outro]

[End]
"""
_CONSCIOUS_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]

[Verse 1]
Mama praying soft while the kettle clicks
I count the rent in ones and little tricks
School fees staring from the kitchen table
I laugh it off — I'm not that able

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Verse 2]
WhatsApp group lighting up with bills and births
I type "I'll call" and mean the words

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Bridge]
Not a speech
A transfer

[Final Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Outro]

[End]
"""

_FEW_SHOT_GOOD = {
    PROFILE_BOOM_BAP: _BOOM_BAP_FEW_SHOT_GOOD,
    PROFILE_TRAP_DRILL: _TRAP_DRILL_FEW_SHOT_GOOD,
    PROFILE_CONSCIOUS: _CONSCIOUS_FEW_SHOT_GOOD,
}

_SUB_GENRE_LABELS = {
    PROFILE_BOOM_BAP: "Boom Bap / Classic Rap",
    PROFILE_TRAP_DRILL: "Trap / Drill / Phonk",
    PROFILE_CONSCIOUS: "Conscious / Story Rap",
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


def is_hiphop_lane(
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
    return PROFILE_BOOM_BAP


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "HipHop")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_BOOM_BAP]
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
        "Write a song-specific conflict for this hiphop lane."
    )
    return f"""USER SELECTIONS (HIPHOP MASTER):
- Primary genre: {primary_genre}
- Sub-genre / fusion: {(sub_genre_fusion or "").strip() or "(none)"}
- Resolved profile: {profile} ({sub_genre_label(profile)})
- Vibe: {(vibe or "").strip() or "(none)"}
- Theme / story: {theme}
- Vocalist: {_format_vocalist(vocal_spec, vocal_tone)}
- BPM hint: {(bpm_hint or "").strip() or "(none)"}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def master_hiphop_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_hiphop_lane(
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
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_BOOM_BAP])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a HipHop song in the {sub_genre_label(profile)} lane. "
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
    return bool(lyrics_task) and is_hiphop_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
