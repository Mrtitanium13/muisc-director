"""Suno v6 version helpers — density aliases for retired pre-v6 models.

UI chips: v6 (flagship), v6-wild (exploratory), v6-mini (lean / free tier).
Engines that still branch on v4.5 / v5.0 / v5.5 should call density_key_for().
"""

from __future__ import annotations

PREFERRED = "v6"
UI_VALUES = ("v6", "v6-wild", "v6-mini")


def _norm(raw: str | None) -> str:
    return (raw or "").strip().lower()


def density_profile_for(raw: str | None) -> str:
    """Return 'minimal' | 'hybrid' | 'rich'."""
    v = _norm(raw)
    if v == "v4.5":
        return "minimal"
    if v in ("v6-mini", "v6mini", "v5.0", "v5", "suno_v5"):
        return "hybrid"
    return "rich"


def density_key_for(raw: str | None) -> str:
    """Legacy density key: v4.5 | v5.0 | v5.5."""
    profile = density_profile_for(raw)
    if profile == "minimal":
        return "v4.5"
    if profile == "hybrid":
        return "v5.0"
    return "v5.5"


def is_rich_density(raw: str | None) -> bool:
    return density_profile_for(raw) == "rich"


def is_minimal_density(raw: str | None) -> bool:
    return density_profile_for(raw) == "minimal"


def is_wild_intent(raw: str | None) -> bool:
    v = _norm(raw)
    return v in ("v6-wild", "v6wild")


def migrate_to_ui_value(raw: str | None) -> str:
    v = _norm(raw)
    if not v:
        return PREFERRED
    if v == "v6":
        return "v6"
    if v in ("v6-wild", "v6wild"):
        return "v6-wild"
    if v in ("v6-mini", "v6mini"):
        return "v6-mini"
    return PREFERRED


def model_intent_directive(raw: str | None) -> str:
    v = _norm(raw)
    if v in ("v6-wild", "v6wild"):
        return (
            "SUNO MODEL INTENT (v6-wild): Exploratory / textured. Prefer unexpected "
            "but musical arrangement turns within valid metatags; keep structure coherent. "
            "Invite variance without junk tags — user may refine later on flagship v6."
        )
    if v in ("v6-mini", "v6mini"):
        return (
            "SUNO MODEL INTENT (v6-mini): Lean hybrid staging. Prioritize clear section "
            "structure over dense director essays; keep Block 1 concise within the fixed cap."
        )
    if v == "v6" or density_profile_for(raw) == "rich":
        return (
            "SUNO MODEL INTENT (v6): Precise and polished. Strong Style adherence, "
            "genre-accurate rich director notes, clean Full-arc structure."
        )
    if density_profile_for(raw) == "hybrid":
        return (
            "SUNO MODEL INTENT (hybrid density): One primary staging descriptor per "
            "bracket; balanced lyric/structure depth."
        )
    if density_profile_for(raw) == "minimal":
        return (
            "SUNO MODEL INTENT (minimal density): Section-name brackets only; put "
            "production cues in Block 1 prose."
        )
    return ""
