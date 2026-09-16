"""Genre-specific Power Code & Temperament vocabulary — tools/code_translation_matrix.json."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Literal

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "code_translation_matrix.json"

GenreCategory = Literal[
    "edm", "hiphop", "rnb_soul", "rock_metal", "pop", "world_jazz_acoustic"
]
CodeType = Literal[
    "L99", "UDA", "BEASTMODE",
    "GRIT", "TENDER", "FURY", "HAZE", "SWAGGER", "HYMN", "WIRED",
]

_MATRIX: dict[str, dict[str, str]] | None = None
_CODE_RE = re.compile(
    r"/(L99|UDA|BEASTMODE|GRIT|TENDER|FURY|HAZE|SWAGGER|HYMN|WIRED)\b",
    re.IGNORECASE,
)


def _load() -> dict[str, dict[str, str]]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    _MATRIX = json.loads(_JSON_PATH.read_text(encoding="utf-8"))
    return _MATRIX


def get_genre_category(primary: str, fusion: str = "") -> GenreCategory:
    g = f"{primary} {fusion}".lower().replace("&", "and")
    if re.search(
        r"house|techno|trance|dubstep|hardstyle|bounce|edm|garage|jersey|amapiano|vinahouse|afro house",
        g,
    ):
        return "edm"
    if re.search(r"hip hop|hiphop|rap|trap|drill|phonk|boom bap|cloud rap", g):
        return "hiphop"
    if re.search(r"r&b|rnb|soul|gospel|worship|neo-soul|neo soul|praise", g):
        return "rnb_soul"
    if re.search(r"rock|metal|punk|grunge|shoegaze|hardcore", g):
        return "rock_metal"
    if re.search(r"pop|k-pop|kpop|j-pop|mandopop|hyperpop|synth-pop|synthpop", g):
        return "pop"
    return "world_jazz_acoustic"


def extract_active_codes(*blobs: str) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    for blob in blobs:
        for m in _CODE_RE.finditer(blob or ""):
            code = m.group(1).upper()
            if code not in seen:
                seen.add(code)
                found.append(code)
    return found


def _normalize_version(version: str | None) -> str:
    from app.suno_version import PREFERRED, density_key_for

    key = density_key_for(version or PREFERRED)
    if key == "v4.5":
        return "v4.5"
    if key == "v5.5":
        return "v5.5pro"
    return "v5"


def _trim_modifier(modifier: str, version: str) -> str:
    parts = [p.strip() for p in modifier.split(",") if p.strip()]
    if not parts:
        return modifier
    if version == "v4.5":
        return ", ".join(parts[:2])
    if version == "v5":
        half = max(1, (len(parts) + 1) // 2)
        return ", ".join(parts[:half]) + "."
    return modifier + "."


def apply_genre_specific_codes(
    genre: str,
    codes_blob: str,
    version: str | None = None,
    fusion: str = "",
    *,
    vibe: str = "",
) -> str:
    """C_final modifier string for Block 1 injection."""
    matrix = _load()
    category = get_genre_category(genre, fusion)
    v = _normalize_version(version)
    codes = extract_active_codes(codes_blob, vibe)
    if not codes:
        return ""

    modifiers = [
        _trim_modifier(matrix[code][category], v)
        for code in codes
        if code in matrix
    ]
    if not modifiers:
        return ""

    if v == "v4.5":
        return ", ".join(modifiers)
    if v == "v5":
        return " ".join(modifiers)
    return ", ".join(modifiers)


def code_translation_user_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    codes_blob: str = "",
    suno_version: str | None = None,
    vibe: str = "",
) -> str:
    codes = extract_active_codes(codes_blob, vibe)
    if not codes:
        return ""

    category = get_genre_category(primary_genre, sub_genre_fusion)
    v = _normalize_version(suno_version)
    matrix = _load()
    lines: list[str] = []
    for code in codes:
        row = matrix.get(code)
        if not row:
            continue
        phrase = row.get(category)
        if not phrase or not str(phrase).strip():
            continue
        prose = _trim_modifier(str(phrase), v)
        if not prose:
            continue
        lines.append(
            f"[CODE TRANSLATION: /{code} for {category}] "
            f"(Apply these specific sonic characteristics): {prose}"
        )
    return "\n".join(lines)
