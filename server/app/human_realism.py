"""Human Realism slider (0–100) — lyric authenticity vs polished AI writing."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

from app.elite_human_lyricist_directive import elite_human_lyricist_user_block

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "human_realism_config.json"


@lru_cache(maxsize=1)
def _load() -> dict:
    return json.loads(_JSON_PATH.read_text(encoding="utf-8"))


def _schema() -> dict:
    return _load()["_schema"]


DEFAULT_LEVEL = int(_schema().get("default_level", 75))
MIN_LEVEL = int(_schema().get("min_level", 0))
MAX_LEVEL = int(_schema().get("max_level", 100))


def clamp_level(value: int) -> int:
    return max(MIN_LEVEL, min(MAX_LEVEL, int(value)))


def _band_for(level: int) -> dict:
    v = clamp_level(level)
    for band in _load()["bands"]:
        if band["min"] <= v <= band["max"]:
            return band
    return _load()["bands"][2]


def band_label(value: int) -> str:
    return str(_band_for(clamp_level(value)).get("label", "Balanced"))


def _band_instructions(level: int) -> str:
    return str(_band_for(level).get("instructions", "")).strip()


def human_realism_user_block(
    value: int,
    dialect_style_id: str | None = None,
) -> str:
    cfg = _load()
    level = clamp_level(value)
    band = _band_instructions(level)
    lines = [
        elite_human_lyricist_user_block(dialect_style_id),
        "",
        str(cfg.get("user_block_header", "")).strip(),
        band,
        "",
        f"Human Realism Level: {level}/100",
        "Adjust lyric generation accordingly.",
        "Higher values: increase authenticity, specificity, conversational language, and imperfections; "
        "decrease metaphor density, poetic abstraction, and forced rhyming.",
        "Lower values: increase lyricism, poetic imagery, technical rhymes, and stylization.",
        "Maintain genre conventions while applying the realism level.",
    ]
    if level <= 40:
        lines.append(str(cfg.get("low_poetic_guardrail", "")).strip())
    return "\n".join(lines)
