"""Macro vs micro structure reconciliation for Suno user blocks."""

from __future__ import annotations

from app.suno_prompt_builder import get_fx_lyrics, resolve_genre_fx_key


FLEXIBLE_ID = "flexible"
CUSTOM_ID = "custom"

_DIRECTIVE = (
    "[STRUCTURAL HIERARCHY] (MANDATORY INSTRUCTION: You will receive two forms of "
    "structural guidance. "
    "1. A high-level STRUCTURE_LOCK or a full section-by-section roadmap. This is the "
    "primary authority for the song's overall flow and sequence. "
    "2. Bracketed production tags [like this] inside the lyrics. These are micro-level events. "
    "YOUR TASK: Place the micro-level production tags within their logical parent section "
    "from the high-level roadmap. The roadmap's sequence is non-negotiable.)"
)


def _effective_lane(genre_fx_lane: str, primary_genre: str, fusion: str) -> str:
    manual = str(genre_fx_lane or "").strip().lower()
    if manual:
        return manual
    return resolve_genre_fx_key(primary_genre, fusion)


def has_macro_structure(preset_id: str, custom_notes: str) -> bool:
    pid = str(preset_id or "").strip()
    if pid == CUSTOM_ID:
        return bool(str(custom_notes or "").strip())
    return bool(pid) and pid != FLEXIBLE_ID


def has_micro_structure(
    *,
    genre_fx_lane: str,
    primary_genre: str,
    fusion: str,
    production_intensity: int,
) -> bool:
    intensity = max(1, min(3, int(production_intensity or 2)))
    if intensity <= 1:
        return False
    lane = _effective_lane(genre_fx_lane, primary_genre, fusion)
    return bool(get_fx_lyrics(lane, str(intensity)).strip())


def structural_hierarchy_user_block(
    *,
    preset_id: str,
    custom_notes: str,
    genre_fx_lane: str,
    primary_genre: str,
    fusion: str,
    production_intensity: int,
) -> str:
    if not has_macro_structure(preset_id, custom_notes):
        return ""
    if not has_micro_structure(
        genre_fx_lane=genre_fx_lane,
        primary_genre=primary_genre,
        fusion=fusion,
        production_intensity=production_intensity,
    ):
        return ""
    return _DIRECTIVE
