"""Master Pop lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

PROFILE_MAINSTREAM = "mainstream"
PROFILE_BEDROOM_INDIE = "bedroom_indie"
PROFILE_IDOL_POP = "idol_pop"

_GENRE_MARKERS = [
    "pop",
    "mainstream pop",
    "electropop",
    "electro pop",
    "dance pop",
    "synth pop",
    "synthpop",
    "bedroom pop",
    "indie pop",
    "k-pop",
    "kpop",
    "j-pop",
    "jpop",
    "c-pop",
    "cpop",
    "mandopop",
    "hyperpop",
    "latin pop",
    "max martin",
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
STRICT WRITING RULES FOR ALL POP:
- Chorus must contain one ≤6-word sticky line grounded in THIS conflict.
- Verse 2 must add new detail, not restate Verse 1.
- Prefer AABB/ABAB when it serves the hook; imperfect rhyme OK in indie lanes.
- No production-as-emotion (beat/drop/bass as savior).
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.
"""

MASTER_ROLE_PROMPT = """\
You are a master pop lyricist. Write hyper-singable, commercially precise lyrics with human interpersonal friction — never motivational-poster or neon-slogan filler.
"""

_SUB_GENRE_MATRIX = {
    PROFILE_MAINSTREAM: """SUB-GENRE: MAINSTREAM POP / DANCE-ELECTROPOP
- Vibe: Immediate hooks, symmetrical lines, commercial earworms.
- Focus: One clear interpersonal conflict; chorus = ≤6-word sticky line.
- Arrangement: [Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Pre-Chorus]
  [Chorus] [Bridge] [Final Chorus] [Outro] [End].
- Syllables: Verse 8–12 · Pre 6–10 · Chorus 4–8 · Post 2–6.""",
    PROFILE_BEDROOM_INDIE: """SUB-GENRE: BEDROOM / INDIE POP
- Vibe: Soft, unpolished, close-mic home-studio honesty.
- Focus: Small domestic details over arena slogans.
- Arrangement: Sparse verse → gentle chorus lift → quiet bridge.
- Syllables: Verse 6–12 · Chorus 4–8. Imperfect rhyme welcome.""",
    PROFILE_IDOL_POP: """SUB-GENRE: IDOL / MULTI-MEMBER / LATIN POP
- Vibe: Group stacks, dramatic pre-chorus, bilingual hooks when language allows.
- Focus: Camera-ready specificity — missed cue, last take, say my name once.
- Ban: starlight eyes, synchronized heart, dream chase, neon rain as empty glitter.
- Arrangement: Verse → Pre → Chorus → Dance break / Bridge → Final Chorus.""",
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
    _ProfileRule(tokens=["mainstream", "max martin", "dance pop", "electropop", "synth pop", "synthpop", "hyperpop"], profile=PROFILE_MAINSTREAM),
    _ProfileRule(tokens=["bedroom", "indie pop"], profile=PROFILE_BEDROOM_INDIE),
    _ProfileRule(tokens=["k-pop", "kpop", "j-pop", "jpop", "c-pop", "cpop", "mandopop", "latin pop"], profile=PROFILE_IDOL_POP),
]

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR POP:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

_MAINSTREAM_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft synth pulse, dry close-mic]

[Verse 1: Dry intimate female lead]
You left your jacket on my chair again
I almost texted then I didn't
You said "busy" like it meant something soft
It didn't

[Pre-Chorus: Doubles enter]
Say it straight
Say it straight
Don't dress it up

[Chorus: Wide stack, punchy hook]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Verse 2]
I practiced calm in the bathroom mirror
Then you walked in laughing at your phone
I kept my voice down for the neighbors
Not for you

[Pre-Chorus]
Say it straight
Say it straight
Don't dress it up

[Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Bridge: Stripped]
One more night then I'm gone
I meant every word

[Final Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Outro: Soft fade]

[End]
"""
_BEDROOM_INDIE_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Lo-fi keys, tape hiss light]

[Verse 1: Soft close-mic]
Cold tea on the desk again
Paper on the wall peeling at the corner
I said I'd clean it Sunday
It's Thursday and I still haven't

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Verse 2]
Your hoodie still smells like rain
I don't wear it
I just leave it on the chair

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Bridge]
Messy room
Quiet mind
Same problem

[Final Chorus]
I almost called
I almost called
Then I put the phone face-down

[Outro]

[End]
"""
_IDOL_POP_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Bright pluck, group breath]

[Verse 1: Lead + light stack]
Camera flash and I miss my mark
You mouth "again" from the side
I laugh like it doesn't sting
It does

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Verse 2]
We trade lines like we trade glances
I keep the soft one for the bridge
You keep the loud one for the drop

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Bridge]
Last chance in the hallway light
Then we walk back in

[Final Chorus]
One take left
One take left
Don't look away

[Outro]

[End]
"""

_FEW_SHOT_GOOD = {
    PROFILE_MAINSTREAM: _MAINSTREAM_FEW_SHOT_GOOD,
    PROFILE_BEDROOM_INDIE: _BEDROOM_INDIE_FEW_SHOT_GOOD,
    PROFILE_IDOL_POP: _IDOL_POP_FEW_SHOT_GOOD,
}

_SUB_GENRE_LABELS = {
    PROFILE_MAINSTREAM: "Mainstream Pop / Max Martin / Dance Pop",
    PROFILE_BEDROOM_INDIE: "Bedroom Pop / Indie Pop",
    PROFILE_IDOL_POP: "K-Pop / J-Pop / C-Pop / Mandopop",
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


def is_pop_lane(
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
    return PROFILE_MAINSTREAM


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "Pop")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_MAINSTREAM]
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
        "Write a song-specific conflict for this pop lane."
    )
    return f"""USER SELECTIONS (POP MASTER):
- Primary genre: {primary_genre}
- Sub-genre / fusion: {(sub_genre_fusion or "").strip() or "(none)"}
- Resolved profile: {profile} ({sub_genre_label(profile)})
- Vibe: {(vibe or "").strip() or "(none)"}
- Theme / story: {theme}
- Vocalist: {_format_vocalist(vocal_spec, vocal_tone)}
- BPM hint: {(bpm_hint or "").strip() or "(none)"}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def master_pop_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_pop_lane(
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
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_MAINSTREAM])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a Pop song in the {sub_genre_label(profile)} lane. "
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
    return bool(lyrics_task) and is_pop_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
