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
    # EDM / electronic
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
    ("nu-disco", "edm"),
    ("future funk", "edm"),
    ("disco house", "edm"),
    ("uk garage", "edm"),
    ("soulful house", "edm"),
    ("hard techno", "techno"),
    ("melodic techno", "techno"),
    ("acid techno", "techno"),
    ("minimal techno", "techno"),
    ("big room techno", "techno"),
    ("techno", "techno"),
    ("drum and bass", "dnb"),
    ("drum & bass", "dnb"),
    ("liquid dnb", "dnb"),
    ("neurofunk", "dnb"),
    ("jungle", "dnb"),
    ("dnb", "dnb"),
    ("synthwave", "synthwave"),
    ("retrowave", "synthwave"),
    ("vaporwave", "synthwave"),
    ("new wave", "synthwave"),
    ("melodic dubstep", "dubstep"),
    ("riddim", "dubstep"),
    ("brostep", "dubstep"),
    ("dubstep", "dubstep"),
    ("dark ambient", "ambient"),
    ("ambient score", "ambient"),
    ("ambient", "ambient"),
    ("hyperpop", "pop"),
    ("digicore", "pop"),
    ("idm", "ambient"),
    ("glitch", "ambient"),
    ("industrial", "ambient"),
    ("ebm", "ambient"),
    ("breakcore", "ambient"),
    ("witch house", "ambient"),
    ("experimental", "ambient"),
    ("modular", "ambient"),
    ("electronic_experimental", "ambient"),
    # Hip-hop
    ("hip hop", "hiphop"),
    ("hip-hop", "hiphop"),
    ("boom bap", "boom_bap"),
    ("lo-fi hip hop", "hiphop"),
    ("conscious hip hop", "hiphop"),
    ("underground hip hop", "hiphop"),
    ("jazz rap", "boom_bap"),
    ("chillhop", "hiphop"),
    ("cloud rap", "hiphop"),
    ("afro rap", "hiphop"),
    ("drill", "trap"),
    ("uk drill", "trap"),
    ("ny drill", "trap"),
    ("melodic trap", "trap"),
    ("phonk", "trap"),
    ("trap", "trap"),
    ("rage", "hiphop"),
    ("jersey club", "hiphop"),
    ("memphis rap", "boom_bap"),
    # Pop
    ("mainstream pop", "pop"),
    ("electropop", "pop"),
    ("dance pop", "pop"),
    ("pop / max martin", "pop"),
    ("k-pop", "pop"),
    ("j-pop", "pop"),
    ("c-pop", "mandopop"),
    ("mandopop", "mandopop"),
    ("indie pop", "indie"),
    ("bedroom pop", "indie"),
    ("dream pop", "indie"),
    ("post-rock", "indie"),
    ("synth pop", "pop"),
    # R&B / soul / funk
    ("contemporary r&b", "rnb"),
    ("contemporary rnb", "rnb"),
    ("contemporary r and b", "rnb"),
    ("90s r&b", "rnb"),
    ("90s rnb", "rnb"),
    ("90s r and b", "rnb"),
    ("r&b", "rnb"),
    ("rnb", "rnb"),
    ("r and b", "rnb"),
    ("neo-soul", "rnb"),
    ("neo soul", "rnb"),
    ("soul", "rnb"),
    ("trap soul", "rnb"),
    ("quiet storm", "rnb"),
    ("new jack swing", "rnb"),
    ("funk", "rnb"),
    ("p-funk", "rnb"),
    ("gogo", "rnb"),
    ("motown", "rnb"),
    # Rock / metal
    ("indie rock", "rock"),
    ("alt rock", "rock"),
    ("alternative rock", "rock"),
    ("alternative", "rock"),
    ("classic rock", "rock"),
    ("hard rock", "rock"),
    ("punk", "rock"),
    ("pop punk", "rock"),
    ("emo", "rock"),
    ("grunge", "rock"),
    ("shoegaze", "indie"),
    ("britpop", "rock"),
    ("heavy metal", "metal"),
    ("death metal", "metal"),
    ("metalcore", "metal"),
    ("metal", "metal"),
    # Country / folk
    ("modern country", "country"),
    ("outlaw country", "country"),
    ("americana", "country"),
    ("bluegrass", "country"),
    ("sertanejo", "country"),
    ("country", "country"),
    ("singer-songwriter", "folk"),
    ("indie folk", "folk"),
    ("folk-rock", "folk"),
    ("folk rock", "folk"),
    ("folk", "folk"),
    # Afro / global
    ("amapiano", "amapiano"),
    ("amapiano-vinahouse", "amapiano"),
    ("afro house", "amapiano"),
    ("vinahouse", "amapiano"),
    ("gqom", "amapiano"),
    ("highlife", "afrobeats"),
    ("afrobeats", "afrobeats"),
    ("afro-swing", "afrobeats"),
    ("fuji", "afrobeats"),
    ("bongo flava", "afrobeats"),
    ("gengetone", "afrobeats"),
    ("azonto", "afrobeats"),
    # South Asian / MENA → world lane
    ("bollywood", "world"),
    ("filmi", "world"),
    ("punjabi", "world"),
    ("bhangra", "world"),
    ("middle eastern", "world"),
    ("city pop", "pop"),
    # Worship / gospel
    ("praise and worship", "worship"),
    ("praise/worship", "worship"),
    ("contemporary gospel", "worship"),
    ("traditional gospel", "worship"),
    ("urban gospel", "worship"),
    ("gospel", "worship"),
    ("modern worship", "worship"),
    ("worship ballad", "worship"),
    ("pop worship", "worship"),
    ("afro-gospel", "worship"),
    ("southern gospel", "worship"),
    ("country gospel", "worship"),
    ("ccm", "worship"),
    # Latin / Caribbean
    ("latin pop", "latin"),
    ("salsa", "latin"),
    ("bachata", "latin"),
    ("bossa nova", "latin"),
    ("cumbia", "latin"),
    ("dembow", "reggaeton"),
    ("reggaeton", "reggaeton"),
    ("latin trap", "reggaeton"),
    ("baile funk", "latin"),
    ("brazilian funk", "latin"),
    ("forró", "latin"),
    ("forro", "latin"),
    ("perreo", "latin"),
    ("guaracha", "latin"),
    ("champeta", "latin"),
    ("moombahton", "latin"),
    ("soca", "latin"),
    ("calypso", "latin"),
    ("merengue", "latin"),
    ("vallenato", "latin"),
    ("tango", "latin"),
    ("reggae", "latin"),
    ("roots reggae", "latin"),
    ("dub", "latin"),
    ("ska", "latin"),
    ("rocksteady", "latin"),
    ("dancehall", "reggaeton"),
    # Cinematic / jazz / experimental electronic
    ("film score", "cinematic"),
    ("orchestral", "cinematic"),
    ("trailer", "cinematic"),
    ("cinematic", "cinematic"),
    ("smooth jazz", "jazz"),
    ("bebop", "jazz"),
    ("vocal jazz", "jazz"),
    ("jazz fusion", "jazz"),
    ("fusion", "jazz"),
    ("nu-jazz", "jazz"),
    ("acid jazz", "jazz"),
    ("big band", "jazz"),
    ("jazz", "jazz"),
    ("latin jazz", "jazz"),
    # Blues → jazz lane (no dedicated blues matrix family)
    ("blues", "jazz"),
    ("delta blues", "jazz"),
    ("chicago blues", "jazz"),
    ("electric blues", "jazz"),
)

_MATRIX: dict[str, dict[str, dict[str, str]]] | None = None
_ANCHORS: dict[str, list[str]] | None = None
_DEFAULT_ANCHORS = ["[Chorus]"]
# Sibling fallbacks only when a first-class lane row is missing directives.
_ANCHOR_FALLBACKS: dict[str, str] = {
    "boom_bap": "hiphop",
    "amapiano": "afrobeats",
    "worship": "pop",
    "mandopop": "pop",
    "world": "afrobeats",
}


@dataclass(frozen=True)
class SunoPromptBuildResult:
    prompt: str
    lyrics: str
    matched_genre_key: str
    intensity: int


def _normalize_lane(levels: dict[str, Any]) -> dict[str, dict[str, str]]:
    if "style_prompts" in levels and "lyric_injections" in levels:
        style_prompts = levels["style_prompts"]
        lyric_injections = levels["lyric_injections"]
        return {
            tier: {
                "style": str(style_prompts[tier]),
                "lyrics": str(lyric_injections[tier]),
            }
            for tier in ("1", "2", "3")
        }
    return {
        tier: {
            "style": str(levels[tier].get("style", "")),
            "lyrics": str(levels[tier].get("lyrics", "")),
        }
        for tier in ("1", "2", "3")
        if tier in levels and isinstance(levels[tier], dict)
    }


def _load_raw() -> dict[str, Any]:
    return json.loads(_JSON_PATH.read_text(encoding="utf-8"))


def _load() -> dict[str, dict[str, dict[str, str]]]:
    global _MATRIX  # noqa: PLW0603
    if _MATRIX is not None:
        return _MATRIX
    raw = _load_raw()
    _MATRIX = {
        genre: _normalize_lane(levels)
        for genre, levels in raw.items()
        if not genre.startswith("_") and isinstance(levels, dict)
    }
    return _MATRIX


def _load_anchors() -> dict[str, list[str]]:
    global _ANCHORS  # noqa: PLW0603
    if _ANCHORS is not None:
        return _ANCHORS
    raw = _load_raw()
    out: dict[str, list[str]] = {}
    for genre, levels in raw.items():
        if genre.startswith("_") or not isinstance(levels, dict):
            continue
        anchors = levels.get("primary_anchors")
        if isinstance(anchors, list) and anchors:
            out[genre] = [str(item).strip() for item in anchors if str(item).strip()]
        else:
            out[genre] = list(_DEFAULT_ANCHORS)
    _ANCHORS = out
    return _ANCHORS


def get_anchors(lane: str) -> list[str]:
    key = (lane or "").strip().lower()
    anchors = _load_anchors()
    direct = anchors.get(key)
    if direct:
        return list(direct)
    fallback_key = _ANCHOR_FALLBACKS.get(key)
    if fallback_key:
        fallback = anchors.get(fallback_key)
        if fallback:
            return list(fallback)
    return list(_DEFAULT_ANCHORS)


def get_fx_lyrics(lane: str, tier: str) -> str:
    matrix = _load()
    key = (lane or "").strip().lower()
    profile = matrix.get(key)
    if not profile:
        fallback_key = _ANCHOR_FALLBACKS.get(key)
        if fallback_key:
            profile = matrix.get(fallback_key)
    if not profile:
        return ""
    row = profile.get(tier) or profile.get("2") or profile.get("1") or {}
    return str(row.get("lyrics") or "")


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
    anchors = get_anchors(lane)
    return f"{anchors[0]}\n"


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
    bands = {
        1: (
            "Low",
            "LOW (1): Subtle, almost invisible production.\n"
            "- Use sparse FX mentions: gentle reverb, soft compression, minimal layering.\n"
            "- Keep arrangement language restrained; prioritize vocal performance and song form.\n"
            "- Avoid hype build/drop language unless the genre absolutely requires it.",
        ),
        2: (
            "Medium",
            "MEDIUM (2): Balanced genre-appropriate production.\n"
            "- Use standard FX and arrangement tokens for the genre (sidechain, delay tails, vocal stacks, modulations).\n"
            "- Mention section energy changes (build, lift, breakdown) where they serve the song.\n"
            "- Keep FX in service of the lyric/melody, not overwhelming.",
        ),
        3: (
            "High",
            "HIGH (3): Maximum production spectacle and arrangement detail.\n"
            "- Dense FX vocabulary: filter sweeps, risers, impacts, sub drops, layered SFX, automation.\n"
            "- Explicit build/drop/contrast staging in every section where genre permits.\n"
            "- Treat Block 1 as a producer brief and Block 2 tags as a fully notated arrangement.",
        ),
    }
    label, instruction = bands.get(clamped, bands[2])
    return (
        f"PRODUCTION FX INTENSITY: {clamped}/3 ({label})\n\n"
        f"{instruction}\n\n"
        "Apply the GENRE FX MATRIX at this intensity level in both Block 1 prose "
        "and Block 2 section tags."
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
