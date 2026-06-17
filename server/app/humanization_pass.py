"""Post-processing: humanization pass on Block 2 (OpenRouter + LaoZhang)."""

from __future__ import annotations

import logging
from typing import Any

from app.llm_config import llm_provider, resolve_humanization_model
from app.payload_optimization import compact_payload_text
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

_FALLBACK = """HUMANIZATION PASS — Block 2 lyrics only.
Humanize, natural phrasing, remove AI artifacts, genre authenticity.
Preserve headers, staging, tags, syllables, hooks, [End]. Output Block 2 body only."""


def humanization_pass_enabled(*, provider: str | None = None) -> bool:
    if not truthy_env("HUMANIZATION_PASS", default=True):
        return False
    return llm_provider(provider) in ("openrouter", "laozhang")


def apply_humanization_pass(
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
    audio_environment_mode: str = "",
    provider: str | None = None,
    lyrics_task: bool = True,
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> tuple[str, str]:
    if not humanization_pass_enabled(provider=provider) or not lyrics_task:
        return text, "humanize-skip"
    if unified_block2_missing(text):
        return text, "humanize-skip"

    parts = split_block2_parts(text)
    if parts is None:
        return text, "humanize-skip"
    prefix, block2_body, suffix = parts
    if not block2_body.strip():
        return text, "humanize-skip"

    system = load_tool_prompt("humanization_pass.txt", fallback=_FALLBACK)
    ctx = genre_context_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        language=language,
        vocal_accent=vocal_accent,
        dialect_style_id=dialect_style_id,
        dialect_variant_id=dialect_variant_id,
        audio_environment_mode=audio_environment_mode,
        remix_original_song_title=remix_original_song_title,
        remix_original_artist=remix_original_artist,
        song_generation_type=song_generation_type,
    )
    body = compact_payload_text(block2_body)
    user_msg = (
        f"{ctx}\n\nBLOCK 2 (humanize; keep structure):\n---\n{body}\n---\n"
        "Return ONLY revised Block 2 through [End]. No Block 1. No commentary."
    )

    model = resolve_humanization_model(
        provider=provider,
        language=language,
        dialect_style_id=dialect_style_id,
    )
    try:
        logger.info("humanization pass model=%s", model)
        out = chat_simple(
            client,
            model=model,
            system=system,
            user=user_msg,
            temperature=0.45,
        )
        candidate = sanitize_block2_output(out)
        if not block2_output_valid(candidate):
            return text, "humanize-invalid"
        if candidate == block2_body:
            return text, "humanize-unchanged"
        merged = merge_block2_parts(prefix, candidate, suffix)
        if unified_block2_missing(merged):
            return text, "humanize-fail"
        return merged, f"humanize:{model}"
    except Exception as exc:  # noqa: BLE001
        logger.warning("humanization pass failed: %s", exc)
        return text, "humanize-fail"
