"""Live instrument matrix — tools/live_instrument_matrix.json."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from app.payload_optimization import (
    process_dynamic_vocal_and_instrument_payload,
    vocal_option_from_audio_environment,
)

from app.genre_key_resolver import resolve_genre_key

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "live_instrument_matrix.json"
_DEFAULT_KEY = "pop"


@dataclass(frozen=True)
class LiveInstrument:
    id: str
    name: str
    category: str
    default_articulation: str
    mix_role: str


_MATRIX: dict[str, list[LiveInstrument]] | None = None


def _raw_json() -> dict[str, Any]:
    return json.loads(_JSON_PATH.read_text(encoding="utf-8"))


def _row_to_instrument(row: dict[str, Any]) -> LiveInstrument:
    return LiveInstrument(
        id=str(row["id"]),
        name=str(row["name"]),
        category=str(row.get("category", "")),
        default_articulation=str(row.get("defaultArticulation", "")),
        mix_role=str(row.get("mixRole", "")),
    )


def _load() -> dict[str, list[LiveInstrument]]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    raw = _raw_json()
    out: dict[str, list[LiveInstrument]] = {}
    for genre, rows in raw.items():
        out[genre] = [_row_to_instrument(dict(row)) for row in rows]
    _MATRIX = out
    return out


def invalidate_matrix_cache() -> None:
    """Clear cached matrix after JSON regeneration."""
    global _MATRIX  # noqa: PLW0603
    _MATRIX = None


def resolve_genre_instrument_key(primary: str, fusion: str = "") -> str:
    matrix = _load()
    return resolve_genre_key(
        matrix.keys(),
        primary,
        fusion,
        default=_DEFAULT_KEY,
    )


def instruments_for_genre(
    primary: str,
    fusion: str = "",
    *,
    vocal_option_ui: str = "close-mic",
) -> list[LiveInstrument]:
    key = resolve_genre_instrument_key(primary, fusion)
    raw_rows = [dict(r) for r in _raw_json().get(key, _raw_json()[_DEFAULT_KEY])]
    patched = process_dynamic_vocal_and_instrument_payload(raw_rows, vocal_option_ui)
    return [_row_to_instrument(row) for row in patched]


def parse_instrument_selection(raw: str) -> list[str]:
    return [t.strip() for t in raw.split(",") if t.strip()]


def _power_codes_active(power_codes: str) -> bool:
    return "/L99" in (power_codes or "").upper()


def _gear_modifier(inst: LiveInstrument, l99: bool) -> str:
    if not l99:
        return ""
    if inst.category == "guitar":
        return " (vintage Fender amp, tube warmth)"
    if inst.category == "keys":
        return " (Neve 1073 preamp, analog warmth)"
    if inst.category in ("horns", "strings"):
        return " (Neumann U47 close-mic'd, dry room)"
    return ""


def _match_selected(
    available: list[LiveInstrument], tokens: list[str]
) -> list[LiveInstrument]:
    out: list[LiveInstrument] = []
    seen: set[str] = set()

    def norm(s: str) -> str:
        return re.sub(r"\s+", " ", s.lower().strip())

    for token in tokens:
        t = norm(token)
        hit: LiveInstrument | None = None
        for inst in available:
            if norm(inst.id) == t or norm(inst.name) == t:
                hit = inst
                break
        if hit is None:
            for inst in available:
                n = norm(inst.name)
                if t in n or n in t:
                    hit = inst
                    break
        if hit and hit.id not in seen:
            seen.add(hit.id)
            out.append(hit)
    return out


def _normalize_version(version: str) -> str:
    v = (version or "v5.0").strip().lower()
    if v == "v4.5":
        return "v4.5"
    if v.startswith("v5.5"):
        return "v5.5pro"
    return "v5"


def generate_live_instrument_prompt(
    genre: str,
    selection_raw: str,
    version: str = "v5.0",
    power_codes: str = "",
    fusion: str = "",
    *,
    vocal_option_ui: str = "close-mic",
) -> tuple[str, str]:
    """Returns (style_injection, meta_tag_injection)."""
    tokens = parse_instrument_selection(selection_raw)
    if not tokens:
        return "", ""

    key = resolve_genre_instrument_key(genre, fusion)
    available = instruments_for_genre(genre, fusion, vocal_option_ui=vocal_option_ui)
    selected = _match_selected(available, tokens)
    if not selected:
        return "", ""

    v = _normalize_version(version)
    l99 = _power_codes_active(power_codes)

    descriptions: list[str] = []
    for inst in selected:
        mod = _gear_modifier(inst, l99)
        if v == "v4.5":
            descriptions.append(
                f"{inst.name}, {inst.default_articulation}, {inst.mix_role}{mod}"
            )
        elif v == "v5":
            descriptions.append(
                f"featuring {inst.default_articulation} {inst.name} "
                f"sitting in the {inst.mix_role}{mod}"
            )
        else:
            descriptions.append(
                f"driven by a {inst.default_articulation} {inst.name}{mod}, "
                f"perfectly seated in the {inst.mix_role}"
            )

    if v == "v4.5":
        style = f", {', '.join(descriptions)}"
        meta = f"[{selected[0].name} Feature]"
    elif v == "v5":
        style = f". {', '.join(descriptions)}."
        meta = f"[Instrumental: {' and '.join(s.name for s in selected)} interplay]"
    else:
        style = f". The arrangement is elevated by {', and '.join(descriptions)}."
        primary = selected[0]
        meta = (
            f"[Instrumental Break: Feature {primary.default_articulation} "
            f"{primary.name}, {primary.mix_role}, dynamic lift, subtle tape saturation]"
        )
        if len(selected) > 1:
            secondary = selected[1]
            meta += (
                f"\n[Bridge: Intimate interplay between {secondary.name} "
                f"and vocals, {secondary.mix_role}]"
            )

    return style, meta


def live_instrument_user_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    selection_raw: str,
    suno_version: str = "v5.0",
    power_codes: str = "",
    audio_environment_mode: str = "studio_isolated",
) -> str:
    raw = (selection_raw or "").strip()
    if not raw:
        return ""

    vocal_option = vocal_option_from_audio_environment(audio_environment_mode)
    key = resolve_genre_instrument_key(primary_genre, sub_genre_fusion)
    style_inj, meta_inj = generate_live_instrument_prompt(
        primary_genre,
        raw,
        version=suno_version,
        power_codes=power_codes,
        fusion=sub_genre_fusion,
        vocal_option_ui=vocal_option,
    )
    matched = _match_selected(
        instruments_for_genre(
            primary_genre,
            sub_genre_fusion,
            vocal_option_ui=vocal_option,
        ),
        parse_instrument_selection(raw),
    )

    lines = [
        "LIVE INSTRUMENT ACCOMPANIMENT (LIVE INSTRUMENT PROTOCOL — Block 1 prose + Block 2 meta-tags):",
        f"Matched genre profile: [{key}]",
        f"Vocal backing patch: [{vocal_option}] (from audio_environment_mode={audio_environment_mode or 'studio_isolated'})",
        f"User selection: {raw}",
    ]
    if matched:
        for inst in matched:
            lines.append(
                f"• {inst.name}: {inst.default_articulation} | mix: {inst.mix_role}"
            )
    else:
        lines.append(
            "• Free-text instruments — describe articulation + mix placement per protocol; "
            "frame atypical pairings as intentional fusion."
        )
    if style_inj:
        lines.append(f"Block 1 styleInjection (weave into producer prose): {style_inj}")
    if meta_inj:
        lines.append(f"Block 2 metaTagInjection (place in timeline): {meta_inj}")
    lines.append(
        "Never list bare instrument names. No artist names. Honor version-aware injection from LIVE INSTRUMENT PROTOCOL."
    )
    return "\n".join(lines)
