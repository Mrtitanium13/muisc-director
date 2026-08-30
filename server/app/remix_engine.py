"""Musical Interpolation & Style-Flip Engine — Layer 4.8 (block v1.2).

Canonical laws: tools/remix/layer_4_8_remix_laws.txt
Parity: fixtures/remix/*.json + Dart remix_payload_compiler.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass
from enum import Enum

REMIX_BLOCK_VERSION = "1.3"
REMIX_BLOCK_MARKER = "REMIX / MUSICAL INTERPOLATION ENGINE"
REMIX_ANALYZER_BLOCK_MARKER = "REMIX / GENRE-FLIP"

_BLOCK2_MARKER = re.compile(
    r"BLOCK\s*2|PASTE\s+INTO\s+SUNO:\s*LYRICS",
    re.IGNORECASE,
)
_SECTION_HEADER = re.compile(
    r"^\[(Intro|Verse\s*\d*|Chorus|Final\s+Chorus|Bridge|Pre-Chorus|Drop|Build|Outro|Instrumental|End)\b",
    re.IGNORECASE,
)
_FEAT_SPLIT = re.compile(r"\s*(?:feat\.?|ft\.?|,|&)\s*", re.IGNORECASE)


class RemixMode(str, Enum):
    NONE = "none"
    INTERPOLATION = "interpolation"
    ANALYZER_GENRE_FLIP = "analyzer_genre_flip"


@dataclass(frozen=True)
class RemixResolution:
    mode: RemixMode
    near_activation: bool = False

    @property
    def is_active(self) -> bool:
        return self.mode != RemixMode.NONE


def resolve_remix_mode(
    *,
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    remix_from_analyzer: bool = False,
) -> RemixResolution:
    title = (remix_original_song_title or "").strip()
    artist = (remix_original_artist or "").strip()
    has_title = len(title) >= 2
    has_artist = len(artist) >= 2
    near = has_title != has_artist

    if remix_from_analyzer:
        return RemixResolution(RemixMode.ANALYZER_GENRE_FLIP, near_activation=near)
    if has_title and has_artist:
        return RemixResolution(RemixMode.INTERPOLATION)
    return RemixResolution(RemixMode.NONE, near_activation=near)


def remix_engine_active(*, original_song_title: str = "", original_artist: str = "") -> bool:
    """Legacy helper — interpolation only (ignores analyzer flag). Prefer resolve_remix_mode."""
    return resolve_remix_mode(
        remix_original_song_title=original_song_title,
        remix_original_artist=original_artist,
        remix_from_analyzer=False,
    ).mode == RemixMode.INTERPOLATION


def _fnv1a32(text: str) -> str:
    h = 0x811C9DC5
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def remix_source_fingerprint(title: str, artist: str) -> str:
    raw = f"{title.strip().lower()}|{artist.strip().lower()}"
    if len(raw) < 3:
        return "none"
    return _fnv1a32(raw)


def resolve_remix_descriptors(
    *,
    title: str,
    artist: str,
    target_genre: str,
    bpm: str = "",
    key_root: str = "",
    scale: str = "",
    vibe: str = "",
) -> dict[str, str]:
    """Neutral DNA only — never includes catalog title/artist strings."""
    genre = target_genre.strip() or "unspecified"
    bpm_t = bpm.strip()
    key = " ".join(x for x in (key_root.strip(), scale.strip()) if x)
    vibe_t = " ".join((vibe or "").split())
    if len(vibe_t) > 160:
        vibe_t = vibe_t[:157].rstrip() + "…"
    return {
        "target_genre": genre,
        "tempo_feel": (
            f"Anchor near {bpm_t} BPM while preserving the locked reference groove feel."
            if bpm_t
            else "Match the locked reference pulse and pocket; do not invent a conflicting tempo story."
        ),
        "tonal_center": (
            f"Prefer {key} as the working center while preserving the locked reference cadence logic."
            if key
            else "Preserve the locked reference tonal center and cadence destinations."
        ),
        "harmonic_character": (
            "Lock the reference chord progression and phrase boundaries; "
            "do not substitute a new harmonic story."
        ),
        "melodic_contour": (
            f"Preserve topline interval contour and hook shape; re-voice with {genre} instruments/leads."
        ),
        "rhythmic_character": (
            f"Preserve syncopated lead/vocal rhythm mapped into a {genre} pocket."
        ),
        "texture_brief": (
            f"Override drums, bass role, pads/leads, and mix aesthetic to idiomatic {genre} textures only."
        ),
        "emotional_lane": (
            f"Emotional lane (operator vibe, name-free): {vibe_t}"
            if vibe_t
            else "Keep the emotional arc of the locked reference without naming it."
        ),
        "source_fingerprint": remix_source_fingerprint(title, artist),
    }


def descriptors_to_user_block_dna(d: dict[str, str]) -> str:
    return f"""REFERENCE DNA (descriptor-only — no catalog titles or artist names in context):
- Target genre textures: {d['target_genre']}
- Tempo / pulse: {d['tempo_feel']}
- Tonal center: {d['tonal_center']}
- Harmonic brief: {d['harmonic_character']}
- Melodic brief: {d['melodic_contour']}
- Rhythmic brief: {d['rhythmic_character']}
- Texture brief: {d['texture_brief']}
- Emotional lane: {d['emotional_lane']}
- Source lock id (opaque): {d['source_fingerprint']}
Operator lock: a specific catalog reference is held client-side only. Reproduce its chord cadence, topline contour, and lead rhythm as session-musician DNA — never invent, print, or hint at a song title or artist."""


def remix_style_flip_user_block_supplement(
    *,
    original_song_title: str,
    original_artist: str,
    target_genre: str,
    generation_type: str = "full_song",
    bpm: str = "",
    key_root: str = "",
    scale: str = "",
    vibe: str = "",
    existing_user_block: str | None = None,
) -> str:
    if existing_user_block and REMIX_BLOCK_MARKER in existing_user_block:
        return ""
    title = original_song_title.strip()
    artist = original_artist.strip()
    if len(title) < 2 or len(artist) < 2:
        return ""

    d = resolve_remix_descriptors(
        title=title,
        artist=artist,
        target_genre=target_genre,
        bpm=bpm,
        key_root=key_root,
        scale=scale,
        vibe=vibe,
    )
    genre = d["target_genre"]
    instrumental = generation_type.strip().lower() == "instrumental"
    mode = "INSTRUMENTAL-ONLY" if instrumental else "FULL-SONG"
    if instrumental:
        mode_block = """
6. INSTRUMENTAL MODE (compose directly — do NOT draft sung lyrics then delete them):
   Emit Block 2 as section headers + ONE dense instrumental staging bracket per section only.
   Never generate lyric lines, soft hums, vocal ad-libs, or singer cues.
   Staging must mandate instruments tracking the locked topline melody and syncopated groove."""
    else:
        mode_block = """
6. FULL-SONG MODE: Preserve lyric sheets with phonetic/dialect tags in single comma-separated staging brackets; vocal delivery must mirror the locked reference cadence and rhythm while lyrics stay theme-appropriate."""

    return f"""{REMIX_BLOCK_MARKER} (LAYER 4.8 · v{REMIX_BLOCK_VERSION} — ACTIVE · DESCRIPTOR-ONLY)
Generation mode: {mode}
{descriptors_to_user_block_dna(d)}

MANDATORY INTERPOLATION & REMIX LAWS:
1. Treat REFERENCE DNA as the locked melodic/harmonic brief. Do not invent a catalog title or artist.
2. Harmonic skeleton (strict): do NOT change underlying harmonic structure. Target genre ({genre}) is an alternative instrumental layer over the locked chord cadence and melody lines; keep melodic phrasing boundaries identical.
3. Override sonic textures only: strip prior instrumentation; force rhythm section, instrument palette, and mix textures to match {genre} while new instruments play the locked chords and hooks.
4. In [Intro], append melodic-continuity tracking codes (no brand names), e.g. [Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip].
5. Never print song titles, artist names, album brands, or “in the style of …” imitation language.{mode_block}"""


def remix_post_process_compact_line(
    *,
    original_song_title: str = "",
    original_artist: str = "",
    generation_type: str = "full_song",
) -> str:
    """Out-of-band compact token — NO source title/artist (leak-safe)."""
    title = original_song_title.strip()
    artist = original_artist.strip()
    if len(title) < 2 or len(artist) < 2:
        return ""
    mode = generation_type.strip().lower() or "full_song"
    fp = remix_source_fingerprint(title, artist)
    return f"RMX:mode:{mode}|lock:melody+rhythm+chords|v={REMIX_BLOCK_VERSION}|fp={fp}"


def _norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9 ]", "", s.lower())


def source_leak_guard(output: str, title: str, artist: str) -> tuple[str, bool]:
    """Fail-closed: redact source identity if it leaked into Style/Lyrics."""
    variants: set[str] = {title.strip(), artist.strip()}
    variants |= {p.strip() for p in _FEAT_SPLIT.split(artist) if p.strip()}
    variants = {v for v in variants if len(v) >= 3}
    if not variants:
        return output, False
    hay = _norm(output)
    hits = [v for v in variants if len(_norm(v)) >= 3 and _norm(v) in hay]
    if not hits:
        return output, False
    cleaned = output
    for h in hits:
        cleaned = re.sub(re.escape(h), "[redacted]", cleaned, flags=re.IGNORECASE)
    return cleaned, True


def _is_staging_bracket_line(trimmed: str) -> bool:
    if not trimmed.startswith("[") or not trimmed.endswith("]"):
        return False
    return _SECTION_HEADER.match(trimmed) is None


def _default_instrumental_staging(header: str) -> str:
    h = header.lower()
    if h.startswith("[intro"):
        return "[Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip]"
    if "chorus" in h:
        return "[Lead synthesizer tracking the exact original vocal topline melody, Full ensemble hook lift over locked harmonic skeleton]"
    if "bridge" in h:
        return "[Harmonic pivot on original chord cadence, Expressive solo tracking original topline intervals]"
    if "outro" in h:
        return "[Gradual arrangement decay on original progression, Trailing motif fade preserving melodic contour]"
    if "verse" in h:
        return "[Melodic lead tracking exact original topline, Rhythm section executing signature syncopated groove in target genre pocket]"
    return "[Instrumental progression locked to original chord and melody skeleton]"


def apply_instrumental_remix_output_detailed(
    text: str,
) -> tuple[str, int, int]:
    """Safety net: strip lyric lines from Block 2; keep section headers + staging.

    Returns (text, stripped_lyric_lines, staging_injected).
    """
    lines = text.splitlines()
    out: list[str] = []
    in_block2 = False
    in_section = False
    has_staging = False
    current_header: str | None = None
    stripped_lyric_lines = 0
    staging_injected = 0

    def flush_section() -> None:
        nonlocal in_section, has_staging, current_header, staging_injected
        if in_section and current_header and not has_staging:
            out.append(_default_instrumental_staging(current_header))
            staging_injected += 1
        in_section = False
        has_staging = False
        current_header = None

    for line in lines:
        trimmed = line.strip()
        if _BLOCK2_MARKER.search(trimmed):
            in_block2 = True
            out.append(line)
            continue
        if not in_block2:
            out.append(line)
            continue
        if not trimmed:
            flush_section()
            out.append(line)
            continue
        if _SECTION_HEADER.match(trimmed):
            flush_section()
            out.append(line)
            in_section = True
            current_header = trimmed
            continue
        if trimmed.startswith("[") and trimmed.endswith("]") and _is_staging_bracket_line(trimmed):
            out.append(trimmed)
            has_staging = True
            continue
        stripped_lyric_lines += 1

    flush_section()
    cleaned = re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip()
    return cleaned, stripped_lyric_lines, staging_injected


def apply_instrumental_remix_output(text: str) -> str:
    """Safety net: strip lyric lines from Block 2; keep section headers + staging."""
    cleaned, _, _ = apply_instrumental_remix_output_detailed(text)
    return cleaned


def apply_remix_generation_type_output(
    text: str,
    *,
    original_song_title: str = "",
    original_artist: str = "",
    generation_type: str = "full_song",
    remix_from_analyzer: bool = False,
) -> str:
    from app.remix_telemetry import log_remix_post_process

    resolution = resolve_remix_mode(
        remix_original_song_title=original_song_title,
        remix_original_artist=original_artist,
        remix_from_analyzer=remix_from_analyzer,
    )
    out = text
    stripped = 0
    staging = 0
    leak_hit = False
    if (
        resolution.mode == RemixMode.INTERPOLATION
        and generation_type.strip().lower() == "instrumental"
    ):
        out, stripped, staging = apply_instrumental_remix_output_detailed(out)
    if resolution.mode == RemixMode.INTERPOLATION:
        out, leak_hit = source_leak_guard(out, original_song_title, original_artist)
    if resolution.is_active or resolution.near_activation:
        log_remix_post_process(
            mode=resolution.mode,
            song_generation_type=generation_type.strip().lower() or "full_song",
            stripped_lyric_lines=stripped,
            staging_injected=staging,
            leak_hit=leak_hit,
            title=original_song_title,
            artist=original_artist,
        )
    return out
