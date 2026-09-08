"""Lyric craft directive precedence for complex lyric generation paths."""

from __future__ import annotations

_PATH_A_DIRECTIVE = (
    "[LYRIC CRAFT HIERARCHY] PATH A — USER LYRICS are primary authority. "
    "Copy the provided sung lines into BLOCK 2 verbatim. Do not rewrite, "
    "paraphrase, or replace them. Genre / humanism / temperament may inform "
    "Block 1 production prose and arrangement staging tags only."
)

_DIRECTIVE = (
    "[LYRIC CRAFT HIERARCHY] (MANDATORY INSTRUCTION: Apply directives in this "
    "strict order of authority: "
    "1. PRIMARY AUTHORITY: The [SOURCE TEXT FOR LYRICS] if present. This is the "
    "foundational story/theme. "
    "2. USER OVERRIDE: The user's explicit [LYRIC THEME NOTES] act as a lens to "
    "interpret the source text. "
    "3. GENRE LENS: The [GENRE-SPECIFIC LYRIC ENGINE] defines genre conventions. "
    "4. HUMANISM STYLE: The [HUMAN REALISM] setting dictates the final performance "
    "style. "
    "5. EMOTIONAL MODIFIER: The [LYRIC TEMPERAMENT] codes add the final emotional "
    "color.)"
)


def is_complex_lyric_path(
    *,
    generate_lyrics: bool,
    optional_lyrics: str,
    use_vibe_as_lyric_source: bool = False,
) -> bool:
    return (
        bool(generate_lyrics)
        or bool(use_vibe_as_lyric_source)
        or bool(str(optional_lyrics or "").strip())
    )


def lyric_craft_hierarchy_user_block(
    *,
    generate_lyrics: bool,
    optional_lyrics: str,
    use_vibe_as_lyric_source: bool = False,
) -> str:
    if not is_complex_lyric_path(
        generate_lyrics=generate_lyrics,
        optional_lyrics=optional_lyrics,
        use_vibe_as_lyric_source=use_vibe_as_lyric_source,
    ):
        return ""
    if str(optional_lyrics or "").strip():
        return _PATH_A_DIRECTIVE
    return _DIRECTIVE
