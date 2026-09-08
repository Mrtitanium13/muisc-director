"""EDM breakdown / build-up vocal lyricist — Techno, Trance, House, Festival EDM."""

from __future__ import annotations

from app.big_room_fusion_progressive_vocal_lyric_engine import is_big_room_fusion_lane
from app.big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine import (
    is_big_room_hardstyle_cinematic_hybrid_lane,
)

PROFILE_PEAK_TIME_TECHNO = "peak_time_techno"
PROFILE_VOCAL_TRANCE = "vocal_trance"
PROFILE_DEEP_MELODIC = "deep_melodic"

_PEAK_TIME_MARKERS = (
    "big room techno",
    "peak-time techno",
    "peak time techno",
    "hard techno",
    "minimal techno",
    "acid techno",
    "schranz",
    "industrial techno",
    "big room",
)

_VOCAL_TRANCE_MARKERS = (
    "uplifting trance",
    "progressive trance",
    "vocal trance",
    "trance",
    "festival edm",
    "big room edm",
    "mainstage",
    "mainstage dance",
)

_DEEP_MELODIC_MARKERS = (
    "deep house",
    "soulful house",
    "melodic techno",
    "melodic house",
    "progressive house",
    "tech house",
    "disco house",
    "house",
)

_EDM_LANE_MARKERS = (
    *_PEAK_TIME_MARKERS,
    *_VOCAL_TRANCE_MARKERS,
    *_DEEP_MELODIC_MARKERS,
    "techno",
    "edm",
    "electronic dance",
)

MASTER_ROLE_PROMPT = (
    "You are a master lyricist specializing in Electronic Dance Music — "
    "Techno, Trance, House, and Festival EDM. Write breakdown and build-up vocals "
    "that feel deeply human, raw, and club-tested — grounded in psychological honesty. "
    "Keep vocals thick and humanized under dense club production: ultra-close-mic "
    "intimateness, high-compression proximity effect, detailed chest resonance, warm "
    "doubles, dedicated low-mid vocal warmth pocket, pristine high-end air boost; "
    "never thin, distant, karaoke-wet, or buried under the bed."
)

UNIVERSAL_GUARDRAILS = """CRITICAL EDM BREAKDOWN VOCAL GUARDRAILS:
1. BAN SCI-FI & RAVE METAPHORS: Never use frequency, static tension, vibrations, dissolving, galaxies, starlight, seismic, neon, cosmic, wavelength, or interstellar framing.
2. HUMAN AUTHENTICITY (MANDATORY): Write exactly how a real person thinks or speaks when vulnerable, hyper-focused, or flooded — short blunt sentences, thought fragments, jagged conversational phrasing (e.g. "Don't say anything," "If you touch me, it's over"). Invent conflict for THIS song; never paste festival slogans.
3. BAN AI FESTIVAL / HALLMARK FILLS: we are thunder, rise up, burn it down, take me higher, break free, set me free, we carry on, hold the line, louder than before, holding on, broken inside, pieces of me, drowning in, lost in the dark, find myself, this is real, in this moment, forever young, chasing dreams, feel the beat, hands up. If a line could sit on any EDM track, rewrite.
4. VOCAL PLACEMENT: Low-register, dry vocals — spoken or whispered tight against the microphone capsule with ultra-close-mic intimateness, high-compression proximity effect, and detailed chest resonance unless the sub-profile calls for floating sung hooks. Keep a dedicated low-mid vocal warmth pocket; never thin, distant, karaoke-wet, or buried under the club bed. Keep vocals thick and humanized under dense club production (warm doubles, pristine high-end air boost).
5. PRE-DROP TRIGGER: The 1–2 bars before the final drop must culminate in a sharp actionable command or one emotionally heavy phrase — production trigger point (e.g. "Run," "Now," "Just look at me").
6. LAYOUT INTEGRATION: Sparse text only in breakdown/build-up/outro markers. Leave air for kicks, subs, and filter sweeps.
7. NO PRODUCTION-AS-EMOTION: Never name beat, drop, bass, floor, or lights as the thing that saves or heals the singer.
3. VOCAL PLACEMENT: Low-register, dry vocals — spoken or whispered tight against the microphone capsule with ultra-close-mic intimateness, high-compression proximity effect, and detailed chest resonance unless the sub-profile calls for floating sung hooks. Keep a dedicated low-mid vocal warmth pocket; never thin, distant, karaoke-wet, or buried under the club bed.
4. PRE-DROP TRIGGER: The 1–2 bars before the final drop must culminate in a sharp actionable command or one emotionally heavy phrase (e.g. "Run," "Now," "Just look at me").
5. LAYOUT: Keep lyrics strictly in [Breakdown], [Build-up]/[Build], and sparse [Outro] markers. Sparse text — leave breathing room for instruments."""

_SUB_GENRE_MATRIX: dict[str, str] = {
    PROFILE_PEAK_TIME_TECHNO: """SUB-PROFILE: BIG ROOM TECHNO / PEAK-TIME
- Focus: Internal monologues, physical boundaries, raw intimacy, sensory overload — psychological pressure over exposition.
- Arrangement: Spoken-word or whispered delivery; stark contrast against aggressive driving kicks.
- Syllables: MELODY-SYNC TECHNO / HOUSE / LOOP GRIDS row; Pre-Drop trigger 2–5 syllables.""",
    PROFILE_VOCAL_TRANCE: """SUB-PROFILE: UPLIFTING / VOCAL TRANCE
- Focus: Longing, unrequited love, turning points, emotional release — felt honesty, not galaxy/neon poetry.
- Arrangement: Floating harmonies, long-held vowels, repetitive hooks chop-ready during build-up.
- Syllables: MELODY-SYNC FESTIVAL ANTHEMS row.""",
    PROFILE_DEEP_MELODIC: """SUB-PROFILE: DEEP HOUSE / MELODIC TECHNO
- Focus: Conversational fragments, casual intimacy, relationship tension, cynicism mixed with hope.
- Arrangement: Low-register dry vocals — spoken or softly sung tight to the capsule.
- Syllables: MELODY-SYNC TECHNO / HOUSE / LOOP GRIDS + Build fragments 2–4 syllables.""",
}


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def _contains_any(blob: str, needles: tuple[str, ...]) -> bool:
    return any(kw in blob for kw in needles)


def is_edm_breakdown_lane(*, primary_genre: str = "", sub_genre_fusion: str = "") -> bool:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    if not blob.strip():
        return False
    if is_big_room_fusion_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return False
    if is_big_room_hardstyle_cinematic_hybrid_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return False
    return _contains_any(blob, _EDM_LANE_MARKERS)


def resolve_profile(*, primary_genre: str = "", sub_genre_fusion: str = "") -> str:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    if _contains_any(blob, _VOCAL_TRANCE_MARKERS) or (
        "trance" in blob and "melodic techno" not in blob
    ):
        return PROFILE_VOCAL_TRANCE
    if _contains_any(blob, _DEEP_MELODIC_MARKERS):
        return PROFILE_DEEP_MELODIC
    if _contains_any(blob, _PEAK_TIME_MARKERS) or "techno" in blob:
        return PROFILE_PEAK_TIME_TECHNO
    if "edm" in blob:
        return PROFILE_VOCAL_TRANCE
    if "house" in blob:
        return PROFILE_DEEP_MELODIC
    return PROFILE_DEEP_MELODIC


def edm_breakdown_vocal_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    if not is_edm_breakdown_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return ""
    profile = resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    matrix = _SUB_GENRE_MATRIX.get(profile, "")
    return "\n\n".join(
        part
        for part in (
            MASTER_ROLE_PROMPT,
            UNIVERSAL_GUARDRAILS,
            matrix,
            f"Active EDM breakdown profile: {profile}",
        )
        if part
    )
