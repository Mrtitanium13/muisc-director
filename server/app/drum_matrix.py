"""Genre drum profiles for Block 2 staging — tools/drum_matrix.json."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "drum_matrix.json"
_DEFAULT_KEY = "pop"


@dataclass(frozen=True)
class DrumProfile:
    kit: str
    pattern: str
    mix: str
    negative: str


_MATRIX: dict[str, DrumProfile] | None = None


from app.genre_key_resolver import resolve_genre_key


def _load() -> dict[str, DrumProfile]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    raw: dict[str, Any] = json.loads(_JSON_PATH.read_text(encoding="utf-8"))
    _MATRIX = {
        key: DrumProfile(
            kit=str(val.get("kit", "")),
            pattern=str(val.get("pattern", "")),
            mix=str(val.get("mix", "")),
            negative=str(val.get("negative", "")),
        )
        for key, val in raw.items()
    }
    return _MATRIX


def resolve_drum_profile(primary: str, fusion: str = "") -> tuple[str, DrumProfile]:
    matrix = _load()
    resolved = resolve_genre_key(
        matrix.keys(),
        primary,
        fusion,
        default=_DEFAULT_KEY,
    )
    return resolved, matrix[resolved]


def build_drum_staging_line(profile: DrumProfile, max_len: int = 120) -> str:
    line = f"{profile.kit}, {profile.pattern}, {profile.mix}"
    if len(line) <= max_len:
        return line
    return line[: max_len - 1] + "…"


def drum_matrix_user_block(primary: str, fusion: str = "", suno_version: str | None = None) -> str:
    from app.suno_version import PREFERRED, density_key_for

    key, profile = resolve_drum_profile(primary, fusion)
    staging = build_drum_staging_line(profile)
    v = density_key_for(suno_version or PREFERRED)
    if v == "v4.5":
        style_hint = f"{profile.kit}, {profile.pattern}, {profile.mix}"[:120]
    elif v == "v5.5":
        style_hint = (
            f"{profile.kit} driving a {profile.pattern}, featuring {profile.mix}. "
            f"Strictly avoid: {profile.negative}."
        )
    else:
        style_hint = (
            f"{profile.kit} playing {profile.pattern}. {profile.mix}. "
            f"Avoid: {profile.negative}."
        )[:150]

    return "\n".join(
        [
            "DRUM MATRIX (Block 2 staging + drum character — ARRANGEMENT STAGING FORMAT):",
            f"Matched profile: [{key}]",
            f"Kit: {profile.kit}",
            f"Pattern: {profile.pattern}",
            f"Mix: {profile.mix}",
            f"Avoid: {profile.negative}",
            f"Staging seed (≤120 chars, invent fresh per section): {staging}",
            f"Version drum phrasing hint ({v}): {style_hint}",
            "Evolve staging on repeated sections — never copy-paste identical drum cues.",
        ]
    )
