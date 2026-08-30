"""Load genre lyric routing + FX lane fallback directives from tools/*.json."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_ROUTING_PATH = ROOT / "tools" / "genre_lyric_routing.json"
_FX_MATRIX_PATH = ROOT / "tools" / "genre_fx_matrix.json"


@lru_cache(maxsize=1)
def _routing() -> dict:
    return json.loads(_ROUTING_PATH.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def _fx_matrix() -> dict:
    return json.loads(_FX_MATRIX_PATH.read_text(encoding="utf-8"))


def global_guardrail() -> str:
    return str(_routing().get("global_guardrail", "")).strip()


def inline_directive(key: str) -> str:
    return str(_routing().get("inline_directives", {}).get(key, "")).strip()


def file_engine_body(key: str) -> str:
    rel = _routing().get("file_engines", {}).get(key)
    if not rel:
        return ""
    path = ROOT / str(rel)
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8").strip()


def lane_lyric_directive(lane: str) -> str:
    key = (lane or "").strip().lower()
    row = _fx_matrix().get(key)
    if isinstance(row, dict):
        text = str(row.get("lyric_engine_directives", "")).strip()
        if text:
            return text
    # Only used if the resolved lane exists but has empty lyric_engine_directives.
    fallbacks = {
        "boom_bap": "hiphop",
        "amapiano": "afrobeats",
        "worship": "pop",
        "mandopop": "pop",
    }
    fb = fallbacks.get(key)
    if fb:
        fb_row = _fx_matrix().get(fb, {})
        if isinstance(fb_row, dict):
            return str(fb_row.get("lyric_engine_directives", "")).strip()
    return ""


def format_engine(body: str) -> str:
    trimmed = body.strip()
    if not trimmed:
        return ""
    header = "[GENRE-SPECIFIC LYRIC ENGINE]"
    if trimmed.startswith(header):
        return trimmed
    return f"{header}:\n{trimmed}"
