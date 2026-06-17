"""Human Authenticity Engine — user-block supplements for lyric quality."""

from __future__ import annotations

from app.audio_environment import is_live_performance_mode

_ELECTRONIC_LANES = (
    "uplifting trance",
    "trance",
    "big room",
    "festival edm",
    "progressive trance",
    "melodic techno",
    "progressive house",
    "big room techno",
    "techno",
    "edm",
    "house",
    "future bass",
    "electro",
)

_FESTIVAL_VOCAL_LANES = _ELECTRONIC_LANES + (
    "k-pop",
    "dance pop",
    "electropop",
)

_GOSPEL_LANES = (
    "gospel",
    "worship",
    "praise and worship",
    "praise & worship",
    "praise",
    "ccm",
    "christian",
    "southern gospel",
    "afro-gospel",
    "afro-praise",
    "contemporary christian",
)

_MANTRA_DOMINANT_LANES = (
    "hard techno",
    "industrial techno",
    "minimal techno",
    "schranz",
    "peak-time techno",
    "peak time techno",
    "acid techno",
    "big room",
    "festival edm",
    "tech house",
    "mainstage",
    "hardstyle",
    "phonk",
    "neurofunk",
    "dubstep",
)

_STORY_DOMINANT_LANES = (
    "hip hop",
    "hiphop",
    "boom bap",
    "lo-fi hip hop",
    "jazz rap",
    "trap",
    "drill",
    "country",
    "folk",
    "americana",
    "singer-songwriter",
    "singer songwriter",
    "indie folk",
    "outlaw country",
    "modern country",
    "bluegrass",
    "alt country",
    "afrobeat",
    "afrobeats",
    "afro-house",
    "afro house",
    "amapiano",
    "dancehall",
    "reggaeton",
    "commercial pop",
    "mainstream pop",
    "latin pop",
    "r&b",
    "rnb",
    "neo-soul",
    "neo soul",
    "soul",
    "contemporary r&b",
    "bedroom pop",
    "indie pop",
)

_PARTIAL_STORY_LANES = (
    "progressive house",
    "melodic techno",
    "melodic house",
    "uplifting trance",
    "progressive trance",
    "festival edm",
)


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def _blob_contains_any(blob: str, needles: tuple[str, ...]) -> bool:
    return any(kw in blob for kw in needles)


def is_electronic_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _ELECTRONIC_LANES)


def is_festival_vocal_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _FESTIVAL_VOCAL_LANES)


def is_gospel_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _GOSPEL_LANES)


def is_mantra_dominant_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _MANTRA_DOMINANT_LANES)


def is_situation_first_story_lane(primary: str, fusion: str = "") -> bool:
    if is_mantra_dominant_lane(primary, fusion):
        return False
    blob = _genre_blob(primary, fusion)
    return _blob_contains_any(blob, _STORY_DOMINANT_LANES) or is_gospel_lane(
        primary, fusion
    )


def is_partial_situation_story_lane(primary: str, fusion: str = "") -> bool:
    if is_mantra_dominant_lane(primary, fusion):
        return False
    if is_situation_first_story_lane(primary, fusion):
        return False
    return _blob_contains_any(_genre_blob(primary, fusion), _PARTIAL_STORY_LANES)


def human_authenticity_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    dj_outro: bool = False,
    audio_environment_mode: str = "",
) -> str:
    """Compact runtime reminder — full engine is in system prompt."""
    lines = [
        "HUMAN AUTHENTICITY ENGINE (Block 2 + polish — mandatory):",
        "- Replace generic emotion with concrete images (mug, kettle, keys, unread text).",
        "- Specificity pass: rewrite interchangeable lines (holding on, broken heart, lost in the dark).",
        "- Chorus: one hook + one emotional line; repeatable; no verbatim verse phrases.",
        "- NEVER output artist/producer/song names — translate to sonic character only.",
        "- Final internal QA: human authenticity, chorus memory, genre fit, Suno caps, zero names.",
    ]
    if is_mantra_dominant_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- §17 WAIVED (mantra/hook-dominant lane): no verse situation arcs — "
            "repetition, commands, physical sensation per §3A Level 1–2 only."
        )
    elif is_situation_first_story_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- §17 SITUATION-FIRST STORY (active): build verses from observable events "
            "and lived situations before naming emotions; Life-Moment Test before finalize."
        )
    elif is_partial_situation_story_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- §17 PARTIAL (progressive/melodic lane): situation triggers in breakdown/bridge "
            "only — chorus stays hook-first; no full verse story arcs."
        )
    if is_gospel_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- Critical Reconciliation Rule (final cleanse): no stacked acoustic+EDM tags; "
            "purge sidechain pump, drum loop, 16-bar DJ, mix-out groove from all brackets."
        )
        lines.append(
            "- Traditional Gospel Architecture: ban EDM/club staging in brackets "
            "(sidechain pump, filter sweep, DJ mix-out, supersaw, loop grids)."
        )
        if is_live_performance_mode(audio_environment_mode):
            lines.append(
                "- Live Performance Arena Mode: Intro = stadium crowd ambience, thunderous "
                "cheering, large outdoor stage reverb; Chorus = crowd singing along loudly; "
                "Bridge = audience handclaps; Outro = standing ovation and long applause."
            )
        else:
            lines.append(
                "- Studio-Isolation Directive: Intro/early tags ban Congregational, Live, "
                "Church, Sanctuary, Communal, SATB Choir Stack; mandate dead-room isolation "
                "and close-mic vocal tracking."
            )
            lines.append(
                "- Use studio-clean worship tokens: Isolated multi-tracked vocal doubles, Tight "
                "Double-Tracked Vocal Stacks, Hammond B3 swell, Analog VCA glue, trailing "
                "organ decay — never crowd/congregation ambience."
            )
        if dj_outro:
            if is_live_performance_mode(audio_environment_mode):
                lines.append(
                    "- Outro: sustained live band resolution, loud crowd screaming, "
                    "standing ovation, natural stadium decay — never DJ mix-out groove."
                )
            else:
                lines.append(
                    "- Outro: sustained studio band resolution, clean multi-track fade, "
                    "trailing organ decay — never DJ mix-out groove."
                )
    elif is_festival_vocal_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- Festival/melodic electronic: simple singable choruses; breakdown = intimate "
            "(whispered/double-track optional); hook repetition OK."
        )
        lines.append(
            "- Melodic impact allowed in Block 1: chorus lift, octave jump, sustained peak note."
        )
    elif is_electronic_lane(primary_genre, sub_genre_fusion):
        lines.append(
            "- Electronic: breakdown intimacy vs drop energy; optional whispered/stripped breakdown vocals."
        )
    if not is_gospel_lane(primary_genre, sub_genre_fusion) and (
        dj_outro or is_electronic_lane(primary_genre, sub_genre_fusion)
    ):
        lines.append(
            "- DJ-friendly: 16-bar outro, loopable groove, filtered mix-out, delay tails when outro flag or club lane."
        )
    lines.append(
        "- Block 1 near word cap: compress phrasing (shorthand bars/gear) without losing arrangement intent."
    )
    return "\n".join(lines)
