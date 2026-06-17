"""Suno Prompt Builder — genre-specific production FX by intensity (tools/genre_fx_matrix.json)."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from app.genre_key_resolver import resolve_genre_key

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "genre_fx_matrix.json"
_DEFAULT_KEY = "pop"

_GENRE_FX_ALIASES: tuple[tuple[str, str], ...] = (
    ("big room", "edm"),
    ("festival edm", "edm"),
    ("future bass", "edm"),
    ("future house", "edm"),
    ("rawstyle", "hardstyle"),
    ("euphoric hardstyle", "hardstyle"),
    ("hard bounce", "hardstyle"),
    ("hardstyle", "hardstyle"),
    ("house", "edm"),
    ("deep house", "edm"),
    ("tech house", "edm"),
    ("progressive house", "edm"),
    ("melodic house", "edm"),
    ("trance", "edm"),
    ("uplifting trance", "edm"),
    ("electro", "edm"),
    ("edm bounce", "edm"),
    ("hard techno", "techno"),
    ("melodic techno", "techno"),
    ("acid techno", "techno"),
    ("minimal techno", "techno"),
    ("big room techno", "techno"),
    ("drum and bass", "dnb"),
    ("liquid dnb", "dnb"),
    ("neurofunk", "dnb"),
    ("jungle", "dnb"),
    ("synthwave", "synthwave"),
    ("retrowave", "synthwave"),
    ("vaporwave", "synthwave"),
    ("melodic dubstep", "dubstep"),
    ("riddim", "dubstep"),
    ("brostep", "dubstep"),
    ("dark ambient", "ambient"),
    ("ambient score", "ambient"),
    ("hip hop", "hiphop"),
    ("boom bap", "hiphop"),
    ("lo-fi hip hop", "hiphop"),
    ("conscious hip hop", "hiphop"),
    ("drill", "trap"),
    ("uk drill", "trap"),
    ("melodic trap", "trap"),
    ("phonk", "trap"),
    ("mainstream pop", "pop"),
    ("electropop", "pop"),
    ("dance pop", "pop"),
    ("k-pop", "pop"),
    ("j-pop", "pop"),
    ("contemporary r&b", "rnb"),
    ("neo-soul", "rnb"),
    ("soul", "rnb"),
    ("trap soul", "rnb"),
    ("dembow", "reggaeton"),
    ("indie rock", "rock"),
    ("alt rock", "rock"),
    ("alternative rock", "rock"),
    ("hard rock", "rock"),
    ("punk", "rock"),
    ("heavy metal", "metal"),
    ("metalcore", "metal"),
    ("indie pop", "indie"),
    ("bedroom pop", "indie"),
    ("shoegaze", "indie"),
    ("dream pop", "indie"),
    ("post-rock", "indie"),
    ("modern country", "country"),
    ("americana", "country"),
    ("bluegrass", "country"),
    ("singer-songwriter", "folk"),
    ("indie folk", "folk"),
    ("amapiano", "afrobeats"),
    ("afro house", "afrobeats"),
    ("highlife", "afrobeats"),
    ("vinahouse", "afrobeats"),
    ("latin pop", "latin"),
    ("salsa", "latin"),
    ("bachata", "latin"),
    ("bossa nova", "latin"),
    ("cumbia", "latin"),
    ("film score", "cinematic"),
    ("orchestral", "cinematic"),
    ("trailer", "cinematic"),
    ("smooth jazz", "jazz"),
    ("bebop", "jazz"),
    ("vocal jazz", "jazz"),
    ("jazz rap", "hiphop"),
)

_MATRIX: dict[str, dict[str, dict[str, str]]] | None = None


@dataclass(frozen=True)
class SunoPromptBuildResult:
    prompt: str
    lyrics: str
    matched_genre_key: str
    intensity: int


def _load() -> dict[str, dict[str, dict[str, str]]]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    raw: dict[str, Any] = json.loads(_JSON_PATH.read_text(encoding="utf-8"))
    _MATRIX = {
        genre: {
            level: {
                "style": str(val.get("style", "")),
                "lyrics": str(val.get("lyrics", "")),
            }
            for level, val in levels.items()
        }
        for genre, levels in raw.items()
    }
    return _MATRIX


def resolve_genre_fx_key(primary: str, fusion: str = "") -> str:
    matrix = _load()
    return resolve_genre_key(
        matrix.keys(),
        primary,
        fusion,
        default=_DEFAULT_KEY,
        extra_replacements=_GENRE_FX_ALIASES,
        apply_default_aliases=False,
    )


def _is_instrumental(lyrics: str) -> bool:
    t = lyrics.strip()
    if not t:
        return True
    return t.lower() == "[instrumental]"


def strip_fx_layout(lyrics: str) -> str:
    """Remove genre-FX arrangement prefixes so re-applying lane/intensity is idempotent."""
    out = lyrics
    changed = True
    matrix = _load()
    while changed:
        changed = False
        for profile in matrix.values():
            for level in ("1", "2", "3"):
                fx = (profile.get(level, {}).get("lyrics") or "").strip()
                if fx and out.startswith(fx):
                    out = out[len(fx) :].lstrip()
                    changed = True
    return out


def fx_lyrics_anchor(lane: str) -> str:
    key = (lane or "").strip().lower()
    if key == "hardstyle":
        return "[Monologue]\n"
    return "[Chorus]\n"


def build_suno_prompt(
    base_style: str,
    base_lyrics: str,
    primary_genre: str,
    *,
    fusion_genre: str = "",
    intensity: int = 2,
) -> SunoPromptBuildResult:
    final_style = (base_style or "").strip()
    final_lyrics = (base_lyrics or "").strip()
    instrumental = _is_instrumental(final_lyrics)
    target_intensity = max(1, min(3, int(intensity or 2)))
    genre_key = resolve_genre_fx_key(primary_genre, fusion_genre)
    matrix = _load()
    profile = matrix.get(genre_key)
    if not profile:
        return SunoPromptBuildResult(
            prompt=final_style,
            lyrics="[Instrumental]" if instrumental else final_lyrics,
            matched_genre_key=genre_key,
            intensity=target_intensity,
        )
    fx = profile.get(str(target_intensity), {})
    fx_style = (fx.get("style") or "").strip()
    fx_lyrics = fx.get("lyrics") or ""
    if fx_style:
        final_style = fx_style if not final_style else f"{final_style}, {fx_style}"
    if fx_lyrics.strip():
        if instrumental:
            final_lyrics = f"{fx_lyrics.strip()}\n[Instrumental]"
        elif "[Drop]" in final_lyrics:
            final_lyrics = final_lyrics.replace(
                "[Drop]",
                f"{fx_lyrics.strip()}\n[Drop]",
                1,
            )
        elif "[Monologue]" in final_lyrics:
            final_lyrics = final_lyrics.replace(
                "[Monologue]",
                f"{fx_lyrics.strip()}\n[Monologue]",
                1,
            )
        elif "[Chorus]" in final_lyrics:
            final_lyrics = final_lyrics.replace(
                "[Chorus]",
                f"{fx_lyrics.strip()}\n[Chorus]",
                1,
            )
        else:
            final_lyrics = f"{fx_lyrics.strip()}{final_lyrics}"
    elif instrumental:
        final_lyrics = "[Instrumental]"
    return SunoPromptBuildResult(
        prompt=final_style,
        lyrics=final_lyrics,
        matched_genre_key=genre_key,
        intensity=target_intensity,
    )


def production_intensity_user_block(value: int) -> str:
    clamped = max(1, min(3, int(value or 2)))
    label = {1: "Low", 2: "Medium", 3: "High"}.get(clamped, "Medium")
    return (
        f"PRODUCTION FX INTENSITY: {clamped} ({label}) — "
        "apply GENRE FX MATRIX lane below."
    )


def genre_fx_user_block(
    primary_genre: str,
    *,
    fusion: str = "",
    intensity: int = 2,
    base_style: str = "",
    base_lyrics: str = "",
) -> str:
    clamped = max(1, min(3, int(intensity or 2)))
    label = {1: "Low", 2: "Medium", 3: "High"}.get(clamped, "Medium")
    built = build_suno_prompt(
        base_style,
        base_lyrics,
        primary_genre,
        fusion_genre=fusion,
        intensity=clamped,
    )
    lines = [
        "GENRE FX MATRIX (Suno Prompt Builder — production FX by intensity):",
        f"Intensity: {clamped} ({label}) · Matched lane: [{built.matched_genre_key}]",
    ]
    if built.prompt:
        lines.append(
            "Block 1 — weave these production FX clauses into producer prose "
            f"(comma-linked, within SECTION 0 caps): {built.prompt}"
        )
    if built.lyrics.strip():
        lines.append(
            "Block 2 — insert these arrangement section tags at the first [Drop] or "
            "[Chorus] anchor (or before main hook sections); evolve staging per "
            "ARRANGEMENT STAGING FORMAT:"
        )
        lines.append(built.lyrics.strip())
    else:
        lines.append(
            f"Block 2 — intensity {clamped}: no extra FX section tags for this lane; "
            "keep genre-native structure."
        )
    lines.append(
        "Do not paste this matrix header into user-visible output — apply silently "
        "inside BLOCK 1 + BLOCK 2."
    )
    return "\n".join(lines)
