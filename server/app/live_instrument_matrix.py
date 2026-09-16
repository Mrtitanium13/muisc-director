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

_JSON_PATH = Path(__file__).resolve().parents[2] / "tools" / "live_instrument_matrix.json"
_DEFAULT_KEY = "default"
_LEGACY_ALIASES: dict[str, str] = {}


@dataclass(frozen=True)
class LiveInstrument:
    id: str
    name: str
    category: str
    default_articulation: str
    mix_role: str
    prompt_text: str = ""
    alias_hints: tuple[str, ...] = ()

    @property
    def prompt_label(self) -> str:
        p = (self.prompt_text or "").strip()
        return p if p else self.name


_LIVE_AMBIENCE_STUDIO = (
    "dead-room isolation",
    "close-mic studio capture",
    "dry acoustic room",
)


_MATRIX: dict[str, list[LiveInstrument]] | None = None
_SCHEMA: dict[str, Any] | None = None


def _parse_json() -> dict[str, Any]:
    raw = json.loads(_JSON_PATH.read_text(encoding="utf-8"))
    if "genres" in raw:
        return {
            "schema_version": str(raw.get("schemaVersion", "1.1.0")),
            "category_taxonomy": dict(raw.get("categoryTaxonomy", {})),
            "category_classification_rules": list(
                raw.get("categoryClassificationRules", [])
            ),
            "genre_preset_alias": dict(raw.get("genrePresetAlias", {})),
            "genres": dict(raw["genres"]),
        }
    return {
        "schema_version": "1.0.0",
        "category_taxonomy": {},
        "category_classification_rules": [],
        "genre_preset_alias": {},
        "genres": raw,
    }


def _raw_json() -> dict[str, Any]:
    global _SCHEMA  # noqa: PLW0603
    if _SCHEMA is None:
        _SCHEMA = _parse_json()
    return _SCHEMA


def _row_to_instrument(row: dict[str, Any]) -> LiveInstrument:
    alias_raw = row.get("aliases") or row.get("aliasHints") or []
    if isinstance(alias_raw, str):
        aliases = tuple(a.strip() for a in alias_raw.split("|") if a.strip())
    else:
        aliases = tuple(str(a).strip() for a in alias_raw if str(a).strip())
    return LiveInstrument(
        id=str(row["id"]),
        name=str(row["name"]),
        category=str(row.get("category", "")),
        default_articulation=str(row.get("defaultArticulation", "")),
        mix_role=str(row.get("mixRole", "")),
        prompt_text=str(row.get("promptText") or ""),
        alias_hints=aliases,
    )


def selection_implies_live_ambience(real_instrumentals: str) -> bool:
    return "live" in str(real_instrumentals or "").lower()


def augment_avoid_clause(*, avoid: str, real_instrumentals: str) -> str:
    if not selection_implies_live_ambience(real_instrumentals):
        return str(avoid or "").strip()
    seen: set[str] = set()
    out: list[str] = []
    for clause in [*( [avoid.strip()] if avoid and avoid.strip() else []), *_LIVE_AMBIENCE_STUDIO]:
        key = clause.lower()
        if key not in seen:
            seen.add(key)
            out.append(clause)
    return ", ".join(out)


def _all_instruments_union() -> list[LiveInstrument]:
    seen: set[str] = set()
    out: list[LiveInstrument] = []
    for rows in _raw_json()["genres"].values():
        for row in rows:
            inst = _row_to_instrument(dict(row))
            if inst.id not in seen:
                seen.add(inst.id)
                out.append(inst)
    return out


def _load() -> dict[str, list[LiveInstrument]]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    schema = _raw_json()
    out: dict[str, list[LiveInstrument]] = {}
    for genre, rows in schema["genres"].items():
        out[genre] = [_row_to_instrument(dict(row)) for row in rows]
    _MATRIX = out
    return out


def invalidate_matrix_cache() -> None:
    """Clear cached matrix after JSON regeneration."""
    global _MATRIX, _SCHEMA  # noqa: PLW0603
    _MATRIX = None
    _SCHEMA = None


def bundle_key_for_genre(genre: str | None) -> str | None:
    """Exact alias match (case-insensitive), then longest substring match."""
    trimmed = (genre or "").strip()
    if not trimmed:
        return None
    aliases = _raw_json().get("genre_preset_alias", {})
    keys = set(_load().keys())
    for alias, target in aliases.items():
        if alias.lower() == trimmed.lower() and target in keys:
            return str(target)
    best = ""
    lower = trimmed.lower()
    for alias, target in aliases.items():
        alias_lower = alias.lower()
        if alias_lower in lower and target in keys and len(alias_lower) > len(best):
            best = str(target)
    return best or None


def voices_for_genre(genre: str | None) -> list[dict[str, Any]]:
    key = bundle_key_for_genre(genre)
    if not key:
        return []
    return [dict(row) for row in _raw_json()["genres"].get(key, [])]


def _bundle_for_label(label: str) -> str | None:
    return bundle_key_for_genre(label)


def _legacy_hit(text: str, keys: set[str]) -> str | None:
    lower = text.lower()
    for alias, target in _LEGACY_ALIASES.items():
        if alias in lower and target in keys:
            return target
    return None


def resolve_genre_instrument_key(primary: str, fusion: str = "") -> str:
    matrix = _load()
    keys = set(matrix.keys())
    blob = f"{primary} {fusion}".lower().strip()

    if fusion.strip():
        primary_hit = _bundle_for_label(primary) or _legacy_hit(primary, keys)
        if primary_hit and primary_hit in keys:
            return primary_hit

    for label in (primary, fusion):
        hit = _bundle_for_label(label)
        if hit and hit in keys:
            return hit

    legacy = _legacy_hit(blob, keys)
    if legacy and legacy in keys:
        return legacy

    partial = bundle_key_for_genre(blob)
    if partial and partial in keys:
        return partial

    return _best_genre_key_from_blob(blob, keys) or _DEFAULT_KEY


def _best_genre_key_from_blob(blob: str, keys: set[str]) -> str:
    best = ""
    for key in keys:
        phrase = key.replace("_", " ")
        if phrase in blob and len(phrase) > len(best):
            best = key
    return best


def instruments_for_genre(
    primary: str,
    fusion: str = "",
    *,
    vocal_option_ui: str = "close-mic",
) -> list[LiveInstrument]:
    key = resolve_genre_instrument_key(primary, fusion)
    genres = _raw_json()["genres"]
    raw_rows = [dict(r) for r in genres.get(key, genres[_DEFAULT_KEY])]
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
    if inst.category in ("horns", "strings", "saxophones", "trumpets", "winds"):
        return " (Neumann U47 close-mic'd, dry room)"
    if inst.category in ("bass", "melodic_bass"):
        return " (Ampeg SVT warmth, tight DI blend)"
    return ""


def _token_matches_instrument(token: str, inst: LiveInstrument) -> bool:
    t = re.sub(r"\s+", " ", token.lower().strip())
    if not t:
        return False
    if inst.id.lower() == t or inst.name.lower() == t:
        return True
    label = inst.prompt_label.lower()
    if label == t or t in label or label in t:
        return True
    for alias in inst.alias_hints:
        a = alias.lower()
        if a == t or t in a or a in t:
            return True
    return False


def _match_selected(
    available: list[LiveInstrument],
    tokens: list[str],
    *,
    fallback_catalog: list[LiveInstrument] | None = None,
) -> list[LiveInstrument]:
    out: list[LiveInstrument] = []
    seen: set[str] = set()
    catalog = fallback_catalog if fallback_catalog is not None else available

    for token in tokens:
        hit: LiveInstrument | None = None
        for inst in available:
            if _token_matches_instrument(token, inst):
                hit = inst
                break
        if hit is None:
            for inst in catalog:
                if _token_matches_instrument(token, inst):
                    hit = inst
                    break
        if hit and hit.id not in seen:
            seen.add(hit.id)
            out.append(hit)
    return out


def _normalize_version(version: str | None) -> str:
    from app.suno_version import PREFERRED, density_key_for

    key = density_key_for(version or PREFERRED)
    if key == "v4.5":
        return "v4.5"
    if key == "v5.5":
        return "v5.5pro"
    return "v5"


def generate_live_instrument_prompt(
    genre: str,
    selection_raw: str,
    version: str | None = None,
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
    catalog = _all_instruments_union()
    selected = _match_selected(available, tokens, fallback_catalog=catalog)
    if not selected:
        return "", ""

    v = _normalize_version(version)
    l99 = _power_codes_active(power_codes)

    descriptions: list[str] = []
    for inst in selected:
        label = inst.prompt_label
        mod = _gear_modifier(inst, l99)
        use_prompt_only = bool((inst.prompt_text or "").strip())
        if v == "v4.5":
            if use_prompt_only:
                descriptions.append(f"{label}, {inst.mix_role}{mod}")
            else:
                descriptions.append(
                    f"{label}, {inst.default_articulation}, {inst.mix_role}{mod}"
                )
        elif v == "v5":
            if use_prompt_only:
                descriptions.append(
                    f"featuring {label} sitting in the {inst.mix_role}{mod}"
                )
            else:
                descriptions.append(
                    f"featuring {inst.default_articulation} {label} "
                    f"sitting in the {inst.mix_role}{mod}"
                )
        else:
            if use_prompt_only:
                descriptions.append(
                    f"driven by {label}{mod}, perfectly seated in the {inst.mix_role}"
                )
            else:
                descriptions.append(
                    f"driven by a {inst.default_articulation} {label}{mod}, "
                    f"perfectly seated in the {inst.mix_role}"
                )

    if v == "v4.5":
        style = f", {', '.join(descriptions)}"
        meta = f"[{selected[0].prompt_label} Feature]"
    elif v == "v5":
        style = f". {', '.join(descriptions)}."
        meta = f"[Instrumental: {' and '.join(s.prompt_label for s in selected)} interplay]"
    else:
        style = f". The arrangement is elevated by {', and '.join(descriptions)}."
        primary = selected[0]
        meta = (
            f"[Instrumental Break: Feature {primary.default_articulation} "
            f"{primary.prompt_label}, {primary.mix_role}, dynamic lift, subtle tape saturation]"
        )
        if len(selected) > 1:
            secondary = selected[1]
            meta += (
                f"\n[Bridge: Intimate interplay between {secondary.prompt_label} "
                f"and vocals, {secondary.mix_role}]"
            )

    return style, meta


def live_instrument_user_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    selection_raw: str,
    suno_version: str | None = None,
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
        fallback_catalog=_all_instruments_union(),
    )

    lines = [
        f"Matrix schema: {_raw_json().get('schema_version', '1.0.0')}",
        f"Matched genre profile: [{key}]",
        f"Vocal backing patch: [{vocal_option}] (from audio_environment_mode={audio_environment_mode or 'studio_isolated'})",
        f"User selection: {raw}",
    ]
    if matched:
        for inst in matched:
            lines.append(
                f"• {inst.prompt_label} ({inst.name}): {inst.default_articulation} | mix: {inst.mix_role}"
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
        "Never list bare instrument names. No artist names. Honor version-aware injection from REAL INSTRUMENT PROTOCOL."
    )
    body = "\n".join(lines)
    return (
        "[REAL INSTRUMENT ACCOMPANIMENT] (MANDATORY: Feature the following "
        "instruments prominently. Emphasize their natural, acoustic character and "
        "the specified articulations. This is a production requirement, not a "
        f"suggestion.):\n{body}"
    )
