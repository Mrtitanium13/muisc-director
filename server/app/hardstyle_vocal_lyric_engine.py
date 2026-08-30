"""Hardstyle / Rawstyle vocal lyricist — breakdown confession → build defiance → scream pre-drop."""

from __future__ import annotations

from app.big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine import (
    is_big_room_hardstyle_cinematic_hybrid_lane,
)

_HARDSTYLE_LANES = (
    "hardstyle",
    "rawstyle",
    "euphoric hardstyle",
    "hard bounce",
    "edm bounce",
)

_BOOTLEG_MARKERS = (
    "euro-dance bootleg",
    "euro dance bootleg",
    "hands up edm",
    "festival rave bootleg",
    "euro-dance festival",
)

MASTER_ROLE_PROMPT = (
    "You are a master lyricist for Hardstyle, Rawstyle, and Euphoric Hardstyle. "
    "Write vocals that move from raw human confession in the breakdown to cold defiant "
    "survival in the build-up, ending on a single screamed command before the kick impact."
)

BOOTLEG_ROLE_PROMPT = (
    "You are a master lyricist for Hardstyle / Euro-Dance Festival Bootleg crossovers. "
    "Write pitch-shift-ready commercial topline vocals that move from emotionally charged "
    "filtered verses through accelerating vocal chops in the build to anthem hook mantras "
    "in the drop — grounded in psychological honesty, not shallow rave filler."
)

UNIVERSAL_GUARDRAILS = """CRITICAL HARDSTYLE VOCAL GUARDRAILS:
1. DYNAMIC SHIFT: [Breakdown] = vulnerable, unpolished spoken-word confession or realization. [Build-up] = cold, defiant, aggressive survival or total release — demanding and determined.
2. ANTI-AI BAN: Never use melodramatic clichés (we own the night, ghosts pulling near, strobe light flash) or clinical phrasing (hollows out my chest cavity, destroy the grid, absolute power). Ban sci-fi/rave metaphors (frequency, neon, galaxies, seismic, vibrations, dissolving).
3. PSYCHOLOGICAL REALISM: Prioritize physical and emotional honesty — internal state over forced scene backdrops or clock times.
4. PRE-DROP TRIGGER: ONE short aggressive word — yelled or screamed — immediately before peak distortion kick (e.g. "BREATHE," "NEVER," "GO").
5. DROP SECTIONS: Stutter/chop cells and mantra loops only — no flowing poetic sentences in [Drop].
6. Structure: GENRE HUMANIZATION ENGINE § SECTION II.1 ELECTRONIC LOOP GRIDS. Syllables: MELODY-SYNC HARDSTYLE / HARD RAVES row. Honor user Key Phrase on build climax when provided."""

BOOTLEG_GUARDRAILS = """CRITICAL EURO-DANCE BOOTLEG VOCAL GUARDRAILS:
1. DYNAMIC SHIFT: [Verse]/[Breakdown] = emotionally charged dry filtered Euro-dance topline — short sung lines or intimate spoken phrases, internal conversational realism. [Build-up] = vocal repeats and chops accelerate — 2–4 word cells stacking, sidechain-pump friendly. [Drop] = pitch-shifted anthem hook chops and mantra loops only.
2. ANTI-AI BAN: Same hardstyle ban stack — no melodramatic clichés, clinical phrasing, or sci-fi/rave metaphors. Ban DJ-callout filler (hands up, feel the beat, we're going higher).
3. PRE-DROP TRIGGER: ONE yelled/screamed command word OR emotionally heavy 2–5 syllable phrase before distorted kick impact.
4. DROP: Chop-ready 2–6 word cells synced to supersaw hook — no narrative sentences.
5. Syllables: MELODY-SYNC HARDSTYLE / HARD RAVES row. Honor user Key Phrase on build climax and drop hook when provided."""

STYLISTIC_EXAMPLES = """STYLISTIC EXAMPLES (invent fresh lines — do not copy verbatim):
- Breakdown confession: "The room is spinning," "I'm not running away anymore."
- Build defiance: "Look me in the eyes," "We are staying right here."
- Pre-drop scream: "BREATHE" / "NEVER" / "GO" (single word only)."""

BOOTLEG_EXAMPLES = """BOOTLEG EXAMPLES (invent fresh lines — do not copy verbatim):
- Verse/breakdown: "I can't pretend," "Don't let go," "Say my name."
- Build chops: "Hold on — hold on — hold on," "All I — all I — wanted."
- Pre-drop: "GO" / "NOW" / "NEVER" (single word or 2–5 syllables).
- Drop mantra: "Never looking back," "Stay with me — stay with me."""


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def is_euro_dance_bootleg_profile(
    *, primary_genre: str = "", sub_genre_fusion: str = ""
) -> bool:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    return any(marker in blob for marker in _BOOTLEG_MARKERS)


def is_hardstyle_vocal_lane(*, primary_genre: str = "", sub_genre_fusion: str = "") -> bool:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    if not blob.strip():
        return False
    return any(kw in blob for kw in _HARDSTYLE_LANES)


def hardstyle_vocal_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    if not is_hardstyle_vocal_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return ""
    if is_big_room_hardstyle_cinematic_hybrid_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return ""
    if is_euro_dance_bootleg_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return "\n\n".join(
            part
            for part in (
                BOOTLEG_ROLE_PROMPT,
                BOOTLEG_GUARDRAILS,
                BOOTLEG_EXAMPLES,
                "Active Hardstyle vocal profile: euro_dance_bootleg",
            )
            if part
        )
    return "\n\n".join(
        part
        for part in (
            MASTER_ROLE_PROMPT,
            UNIVERSAL_GUARDRAILS,
            STYLISTIC_EXAMPLES,
        )
        if part
    )
