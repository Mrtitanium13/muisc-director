"""Post-processing: theme consistency pass on Block 2 lyrics (runtime, silent)."""

from __future__ import annotations

import logging
from typing import Any

from app.llm_config import llm_provider, resolve_theme_consistency_fallback_model, resolve_theme_consistency_model
from app.post_process_common import (
    block2_output_valid,
    chat_simple,
    genre_context_block,
    load_tool_prompt,
    merge_block2_parts,
    sanitize_block2_output,
    split_block2_parts,
    truthy_env,
)
from app.suno_output_qa import unified_block2_missing

logger = logging.getLogger(__name__)

_THEME_PASS_MAX_TOKENS = 4096

_FALLBACK_SYSTEM = """POST-PROCESSING: THEME CONSISTENCY PASS — Block 2 lyrics only.
Identify primary theme, audit sections, remove theme drift, rewrite inconsistent lines.
Preserve syllables, groove, rhyme, cadence, all bracket headers/staging/tags, and [End].
Protect strong hooks. Match genre. No scores or commentary in output — revised Block 2 body only."""


def theme_consistency_enabled() -> bool:
    """On by default for V2 lyrics paths; opt out with THEME_CONSISTENCY_PASS=false."""
    return truthy_env("THEME_CONSISTENCY_PASS", default=True)


def _theme_consistency_user_message(
    *,
    block2_body: str,
    primary_genre: str,
    sub_genre_fusion: str,
    vibe: str,
    lyric_theme_notes: str,
    language: str,
    vocal_accent: str = "",
    dialect_style_id: str = "",
    dialect_variant_id: str = "",
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> str:
    ctx = genre_context_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        language=language,
        vocal_accent=vocal_accent,
        dialect_style_id=dialect_style_id,
        dialect_variant_id=dialect_variant_id,
        remix_original_song_title=remix_original_song_title,
        remix_original_artist=remix_original_artist,
        song_generation_type=song_generation_type,
    )
    return f"""{ctx}

BLOCK 2 LYRICS (revise for theme consistency — preserve structure):
---
{block2_body.strip()}
---

Return ONLY the revised Block 2 body (headers, staging, tags, lines, [End]). No Block 1. No commentary."""


def apply_theme_consistency_pass(
    client: Any,
    *,
    text: str,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    language: str = "English",
    vocal_accent: str = "",
    dialect_style_id: str = "",
    dialect_variant_id: str = "",
    provider: str | None = None,
    lightweight: bool = False,
    lyrics_task: bool = True,
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> tuple[str, str]:
    """
    Run theme consistency on Block 2. Returns (merged_full_text, pipeline_suffix).
    On failure or skip, returns (original text, "theme-skip").
    """
    if not theme_consistency_enabled() or not lyrics_task:
        return text, "theme-skip"
    if unified_block2_missing(text):
        return text, "theme-skip"

    parts = split_block2_parts(text)
    if parts is None:
        return text, "theme-skip"
    prefix, block2_body, suffix = parts
    if not block2_body.strip():
        return text, "theme-skip"

    system = load_tool_prompt("theme_consistency_pass.txt", fallback=_FALLBACK_SYSTEM)
    user_msg = _theme_consistency_user_message(
        block2_body=block2_body,
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        language=language,
        vocal_accent=vocal_accent,
        dialect_style_id=dialect_style_id,
        dialect_variant_id=dialect_variant_id,
        remix_original_song_title=remix_original_song_title,
        remix_original_artist=remix_original_artist,
        song_generation_type=song_generation_type,
    )
    model = resolve_theme_consistency_model(language=language, provider=provider)
    fallback = resolve_theme_consistency_fallback_model(provider=provider)

    revised = block2_body
    label = "theme-skip"
    max_passes = 2 if truthy_env("THEME_CONSISTENCY_DOUBLE_PASS", default=False) else 1
    for attempt in range(max_passes):
        active_model = model
        try:
            logger.info(
                "theme consistency pass model=%s attempt=%s", active_model, attempt + 1
            )
            out = chat_simple(
                client,
                model=active_model,
                system=system,
                user=user_msg,
                temperature=0.35 if attempt else 0.4,
                max_tokens=_THEME_PASS_MAX_TOKENS,
            )
        except Exception as exc:  # noqa: BLE001
            if active_model != fallback and llm_provider(provider) == "laozhang":
                logger.warning(
                    "theme consistency primary failed (%s); trying %s", exc, fallback
                )
                try:
                    out = chat_simple(
                        client,
                        model=fallback,
                        system=system,
                        user=user_msg,
                        temperature=0.35,
                        max_tokens=_THEME_PASS_MAX_TOKENS,
                    )
                    active_model = fallback
                except Exception as exc2:  # noqa: BLE001
                    logger.warning("theme consistency fallback failed: %s", exc2)
                    return text, "theme-fail"
            else:
                logger.warning("theme consistency pass failed: %s", exc)
                return text, "theme-fail"

        candidate = sanitize_block2_output(out)
        if not block2_output_valid(candidate):
            logger.warning("theme consistency invalid output; keeping prior")
            break
        revised = candidate
        label = f"theme-pass:{active_model}"
        user_msg = _theme_consistency_user_message(
            block2_body=revised,
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=(
                f"{lyric_theme_notes.strip()}; INTERNAL: tighten theme unity to 9+/10"
                if lyric_theme_notes.strip()
                else "INTERNAL: tighten theme unity to 9+/10"
            ),
            language=language,
        )

    if revised == block2_body:
        return text, label if label != "theme-skip" else "theme-unchanged"

    merged = merge_block2_parts(prefix, revised, suffix)
    if unified_block2_missing(merged):
        return text, "theme-fail"
    return merged, label
