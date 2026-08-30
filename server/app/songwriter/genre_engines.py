"""Bridge songwriter stages 5–7 to existing genre lyric masters.

Uses the same runtime resolvers as Suno Path C (`genre_lyrics_user_block`),
so masters stay in one place. Truncates for multi-stage token budget.
Heavy lanes (gospel / EDM / hardstyle / amapiano) get a higher default budget
so master craft is not cut mid-rule.
"""

from __future__ import annotations

import os
from typing import Any

# Stages that receive the full genre lyric engine (chorus-first drafting).
GENRE_ENGINE_STAGES = frozenset({"chorus", "verses", "bridge"})

# Default budgets (chars). Override globally with SONGWRITER_GENRE_ENGINE_MAX_CHARS.
_DEFAULT_MAX = 6000
# Amapiano lanes compose the EDM master block + dedicated amapiano directive
# (~11.5k chars); 12k keeps heavy-lane master craft from being cut mid-rule.
_HEAVY_LANE_MAX = 12000

_HEAVY_LANES = frozenset({"amapiano", "gospel", "hardstyle", "edm"})


def genre_engine_max_chars(lane: str | None = None) -> int:
    raw = os.getenv("SONGWRITER_GENRE_ENGINE_MAX_CHARS", "").strip()
    if raw:
        try:
            return max(1500, min(int(raw), 20000))
        except ValueError:
            pass
    if (lane or "").lower() in _HEAVY_LANES:
        heavy = os.getenv("SONGWRITER_GENRE_ENGINE_HEAVY_MAX_CHARS", "").strip()
        if heavy:
            try:
                return max(1500, min(int(heavy), 20000))
            except ValueError:
                pass
        return _HEAVY_LANE_MAX
    return _DEFAULT_MAX


def detect_master_lane(
    *,
    genre: str,
    subgenre: str = "",
    mood: str = "",
    theme: str = "",
) -> str:
    """Best-effort lane id for truncation / telemetry (mirrors Path C priority)."""
    try:
        from app.genre_lyrics_directives import is_amapiano_lane
        from app.master_edm_lyric_engine import is_edm_lane
        from app.master_gospel_lyric_engine import is_gospel_lane
        from app.master_hardstyle_lyric_engine import is_hardstyle_lane
        from app.southern_gospel_country_lyric_engine import (
            is_southern_gospel_country_lane,
        )
    except Exception:
        return "generic"

    if is_gospel_lane(
        primary_genre=genre,
        sub_genre_fusion=subgenre,
        vibe=mood,
        lyric_theme_notes=theme,
    ):
        return "gospel"
    try:
        if is_southern_gospel_country_lane(
            primary_genre=genre,
            sub_genre_fusion=subgenre,
            vibe=mood,
            lyric_theme_notes=theme,
        ):
            return "gospel"
    except Exception:
        pass
    if is_hardstyle_lane(
        primary_genre=genre,
        sub_genre_fusion=subgenre,
        vibe=mood,
        lyric_theme_notes=theme,
    ):
        return "hardstyle"
    if is_amapiano_lane(genre, subgenre):
        return "amapiano"
    if is_edm_lane(
        primary_genre=genre,
        sub_genre_fusion=subgenre,
        vibe=mood,
        lyric_theme_notes=theme,
    ):
        return "edm"
    return "generic"


def resolve_genre_lyric_engine(
    *,
    genre: str,
    subgenre: str = "",
    mood: str = "",
    theme: str = "",
    story: str = "",
    vocal_style: str = "",
    bpm: str = "",
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Return {text, truncated, char_count, source, master_lane} for stage context."""
    extra = extra or {}
    vibe = mood or str(extra.get("vibe") or "")
    lyric_theme = " ".join(
        x for x in (theme, story, str(extra.get("lyric_theme_notes") or "")) if x
    ).strip()
    vocal_spec = vocal_style or str(extra.get("vocal_spec") or "")
    vocal_tone = str(extra.get("vocal_tone") or "")
    bpm_hint = bpm or str(extra.get("bpm") or "")
    genre_fx_lane = str(extra.get("genre_fx_lane") or extra.get("genreFxLaneId") or "")

    master_lane = detect_master_lane(
        genre=genre, subgenre=subgenre, mood=vibe, theme=lyric_theme
    )

    try:
        from app.genre_lyrics_directives import genre_lyrics_user_block

        text = genre_lyrics_user_block(
            primary_genre=genre,
            sub_genre_fusion=subgenre,
            vibe=vibe,
            lyric_theme_notes=lyric_theme,
            vocal_spec=vocal_spec,
            vocal_tone=vocal_tone,
            bpm_hint=bpm_hint,
            genre_fx_lane=genre_fx_lane,
        ).strip()
    except Exception as e:  # noqa: BLE001
        return {
            "text": "",
            "truncated": False,
            "char_count": 0,
            "source": "genre_lyrics_user_block",
            "master_lane": master_lane,
            "raw_char_count": 0,
            "error": str(e),
        }

    raw_len = len(text)
    max_chars = genre_engine_max_chars(master_lane)
    truncated = False
    if raw_len > max_chars:
        truncated = True
        text = (
            text[:max_chars].rstrip()
            + "\n\n[…genre lyric engine truncated for songwriter token budget…]"
        )

    return {
        "text": text,
        "truncated": truncated,
        "char_count": len(text),
        "raw_char_count": raw_len,
        "source": "genre_lyrics_user_block",
        "master_lane": master_lane,
        "max_chars": max_chars,
    }


def stage_user_context(
    base_context: dict[str, Any],
    *,
    stage_id: str,
    genre_engine: dict[str, Any] | None,
) -> dict[str, Any]:
    """Copy context and attach genre_lyric_engine only for drafting stages."""
    ctx = dict(base_context)
    if stage_id in GENRE_ENGINE_STAGES and genre_engine and genre_engine.get("text"):
        ctx["genre_lyric_engine"] = genre_engine["text"]
        ctx["genre_lyric_engine_meta"] = {
            "truncated": genre_engine.get("truncated"),
            "char_count": genre_engine.get("char_count"),
            "raw_char_count": genre_engine.get("raw_char_count"),
            "master_lane": genre_engine.get("master_lane"),
            "source": genre_engine.get("source"),
            "instruction": (
                "Follow genre_lyric_engine for diction, cadence, structure, and "
                "genre-authentic imagery. genre_rules (pack) is secondary. "
                "Do not copy sample lyrics; write 100% original lines."
            ),
        }
    else:
        ctx.pop("genre_lyric_engine", None)
        ctx.pop("genre_lyric_engine_meta", None)
    return ctx
