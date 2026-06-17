"""Musical Interpolation & Style-Flip Engine — user blocks and instrumental output hygiene."""

from __future__ import annotations

import re

_BLOCK2_MARKER = re.compile(
    r"BLOCK\s*2|PASTE\s+INTO\s+SUNO:\s*LYRICS",
    re.IGNORECASE,
)
_SECTION_HEADER = re.compile(
    r"^\[(Intro|Verse\s*\d*|Chorus|Final\s+Chorus|Bridge|Pre-Chorus|Drop|Build|Outro|Instrumental|End)\b",
    re.IGNORECASE,
)


def remix_engine_active(*, original_song_title: str = "", original_artist: str = "") -> bool:
    return bool(original_song_title.strip() and original_artist.strip())


def remix_style_flip_user_block_supplement(
    *,
    original_song_title: str,
    original_artist: str,
    target_genre: str,
    generation_type: str = "full_song",
) -> str:
    title = original_song_title.strip()
    artist = original_artist.strip()
    if not title or not artist:
        return ""

    genre = target_genre.strip() or "unspecified"
    mode = "INSTRUMENTAL-ONLY" if generation_type.strip().lower() == "instrumental" else "FULL-SONG"
    if mode == "INSTRUMENTAL-ONLY":
        mode_block = """
5. INSTRUMENTAL MODE: Purge ALL lyric lines, soft hums, vocal ad-libs, and singer cues from Block 2. Every [Verse], [Chorus], [Bridge], and [Outro] gets ONE dense instrumental-only staging bracket mandating instruments to mimic the original melody — e.g. [Lead synthesizer tracking the exact original vocal topline melody], [Rhythm section executing the original song's signature syncopated groove inside a jazz pocket]. No sung words in Block 2."""
    else:
        mode_block = """
5. FULL-SONG MODE: Preserve lyric sheets with phonetic/dialect tags in single comma-separated staging brackets; vocal delivery must mirror the original song's exact cadence and rhythm while lyrics stay theme-appropriate."""

    return f"""REMIX / MUSICAL INTERPOLATION ENGINE (LAYER 4.8 — ACTIVE)
Source reference (metadata only — NEVER print song title, artist name, or album brand in Block 1 or Block 2): "{title}" by "{artist}"
Target genre: {genre}
Generation mode: {mode}

MANDATORY INTERPOLATION & REMIX LAWS:
1. Deconstruct & lock foundational DNA: extract exact chord progression, topline melody intervals, core tempo, and syncopated vocal rhythm internally — do not name the source in output.
2. Harmonic skeleton (strict): do NOT change underlying harmonic structure. Target genre is an alternative instrumental layer over the original chord cadence and melody lines; keep melodic phrasing boundaries identical.
3. Override sonic textures only: strip original instrumentation; force rhythm section, instrument palette, and mix textures to match {genre} while new instruments play the original exact chords and hooks.
4. In [Intro], append melodic-continuity tracking codes (no brand names), e.g. [Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip].{mode_block}"""


def remix_post_process_compact_line(
    *,
    original_song_title: str = "",
    original_artist: str = "",
    generation_type: str = "full_song",
) -> str:
    title = original_song_title.strip()
    artist = original_artist.strip()
    if not title or not artist:
        return ""
    mode = generation_type.strip().lower() or "full_song"
    return f"RMX:src={title}|by={artist}|mode:{mode}|lock:melody+rhythm+chords"


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


def apply_instrumental_remix_output(text: str) -> str:
    """Strip lyric lines from Block 2; keep section headers + instrumental staging only."""
    lines = text.splitlines()
    out: list[str] = []
    in_block2 = False
    in_section = False
    has_staging = False
    current_header: str | None = None

    def flush_section() -> None:
        nonlocal in_section, has_staging, current_header
        if in_section and current_header and not has_staging:
            out.append(_default_instrumental_staging(current_header))
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

    flush_section()
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip()


def apply_remix_generation_type_output(
    text: str,
    *,
    original_song_title: str = "",
    original_artist: str = "",
    generation_type: str = "full_song",
) -> str:
    if not remix_engine_active(
        original_song_title=original_song_title,
        original_artist=original_artist,
    ):
        return text
    if generation_type.strip().lower() != "instrumental":
        return text
    return apply_instrumental_remix_output(text)
