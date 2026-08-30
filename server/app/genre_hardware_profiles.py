"""Part E v2.1 genre-specific hardware defaults — loaded from tools JSON."""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path

_JSON_PATH = (
    Path(__file__).resolve().parents[2] / "tools" / "genre_hardware_profiles_v2_1.json"
)


@dataclass(frozen=True)
class HardwareProfile:
    id: str
    genre: str
    cluster_id: str
    keywords: tuple[str, ...]
    style_descriptors: str
    lead_vocal: str
    vocal_chain: str
    drums: str
    bass: str
    keys_synths: str
    outboard: str
    monitoring: str
    room: str
    vibe: str


def _normalize_genre(genre: str) -> str:
    s = str(genre or "").replace("&amp;", "&").lower().strip()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[^\w\s&]+", " ", s, flags=re.UNICODE)
    return re.sub(r"\s+", " ", s).strip()


def _load_profiles() -> list[HardwareProfile]:
    raw = json.loads(_JSON_PATH.read_text(encoding="utf-8"))
    out: list[HardwareProfile] = []
    for row in raw:
        out.append(
            HardwareProfile(
                id=str(row["id"]),
                genre=str(row.get("genre", "")),
                cluster_id=str(row.get("cluster_id", "")),
                keywords=tuple(str(k).lower() for k in row.get("keywords", [])),
                style_descriptors=str(row.get("style_descriptors", "")),
                lead_vocal=str(row.get("lead_vocal", "")),
                vocal_chain=str(row.get("vocal_chain", "")),
                drums=str(row.get("drums", "")),
                bass=str(row.get("bass", "")),
                keys_synths=str(row.get("keys_synths", "")),
                outboard=str(row.get("outboard", "")),
                monitoring=str(row.get("monitoring", "")),
                room=str(row.get("room", "")),
                vibe=str(row.get("vibe", "")),
            )
        )
    return out


_PROFILES: list[HardwareProfile] | None = None
_BY_GENRE: dict[str, HardwareProfile] | None = None
_KEYWORD_INDEX: list[tuple[str, HardwareProfile]] | None = None


def all_profiles() -> list[HardwareProfile]:
    global _PROFILES  # noqa: PLW0603
    if _PROFILES is None:
        _PROFILES = _load_profiles()
    return _PROFILES


def _profile_by_genre() -> dict[str, HardwareProfile]:
    global _BY_GENRE  # noqa: PLW0603
    if _BY_GENRE is None:
        _BY_GENRE = {
            _normalize_genre(p.genre): p for p in all_profiles() if p.genre.strip()
        }
    return _BY_GENRE


def _keyword_index() -> list[tuple[str, HardwareProfile]]:
    """Longest-keyword-first index; built once for fusion fallback."""
    global _KEYWORD_INDEX  # noqa: PLW0603
    if _KEYWORD_INDEX is None:
        entries: list[tuple[str, HardwareProfile]] = []
        for profile in all_profiles():
            for kw in profile.keywords:
                key = str(kw).lower().strip()
                if key:
                    entries.append((key, profile))
        entries.sort(key=lambda item: (-len(item[0]), item[0]))
        _KEYWORD_INDEX = entries
    return _KEYWORD_INDEX


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary.strip()} {fusion.strip()}".lower()


def _default_profile() -> HardwareProfile:
    return HardwareProfile(
        id="DEFAULT",
        genre="",
        cluster_id="",
        keywords=(),
        style_descriptors=(
            "polished producer mix, genre-appropriate integrated loudness, "
            "named vocal chain, drum capture, bass, keys/synths, outboard bus glue"
        ),
        lead_vocal="Neumann U87 or SM7B matched to genre",
        vocal_chain="1073 pre -> 1176 -> LA-2A -> plate reverb",
        drums="genre-appropriate kit or drum machine with parallel compression",
        bass="DI + amp blend or sub synth as genre dictates",
        keys_synths="Rhodes, piano, or synth pads as genre dictates",
        outboard="SSL G bus glue, −1.0 dBTP ceiling",
        monitoring="Genelec + NS10 translation",
        room="controlled studio with optional live room on drums",
        vibe="release-ready, −9 to −11 LUFS depending on genre",
    )


def resolve_hardware_profile(primary: str, fusion: str = "") -> HardwareProfile:
    direct = _profile_by_genre().get(_normalize_genre(primary))
    if direct is not None:
        return direct

    blob = _genre_blob(primary, fusion)
    for kw, profile in _keyword_index():
        if kw in blob:
            return profile
    return _default_profile()


def resolve_profile_id(primary: str, fusion: str = "") -> str:
    return resolve_hardware_profile(primary, fusion).id


def has_profile(primary: str, fusion: str = "") -> bool:
    """True when a non-DEFAULT profile resolved (direct genre or keyword hit)."""
    return resolve_hardware_profile(primary, fusion).id != "DEFAULT"


def hardware_profile_user_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    dj_intro: bool = False,
    dj_outro: bool = False,
) -> str:
    p = resolve_hardware_profile(primary_genre, sub_genre_fusion)
    lines = [
        "GENRE HARDWARE DEFAULTS (Part E v2.1 — mandatory in Block 1 unless user overrides):",
        f"Profile: [{p.id}]",
        f"Style descriptors (weave naturally into Block 1 prose): {p.style_descriptors}",
        f"Lead vocal mic + chain: {p.lead_vocal} | Chain: {p.vocal_chain}",
        f"Drums: {p.drums}",
        f"Bass: {p.bass}",
        f"Keys / synths: {p.keys_synths}",
        f"Outboard / bus: {p.outboard}",
        f"Monitoring: {p.monitoring}",
        f"Room / tracking: {p.room}",
        f"Vibe / loudness: {p.vibe} (include −1.0 dBTP true-peak ceiling in Block 1).",
    ]
    if dj_intro and dj_outro:
        lines.append(
            "DJ phrasing (mandatory in Block 1): sixteen-bar filtered drum intro, sixteen-bar "
            "stripped percussion outro, beatmatch-clean sixteen-bar phrasing throughout."
        )
    elif dj_intro:
        lines.append(
            "DJ phrasing (mandatory in Block 1): sixteen-bar filtered drum intro, "
            "beatmatch-clean sixteen-bar phrasing, gradual filter opening before main groove."
        )
    elif dj_outro:
        lines.append(
            "DJ phrasing (mandatory in Block 1): sixteen-bar stripped percussion outro, "
            "beatmatch-clean sixteen-bar phrasing, long mix-out tail without a hard stop."
        )
    lines.append(
        "Do not omit hardware, LUFS intent, dBTP ceiling, mix moves, or style-descriptor "
        "language from Block 1 — Suno uses this for loudness, texture, and club/DJ polish."
    )
    return "\n".join(lines)
