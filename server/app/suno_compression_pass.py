"""Post-processing: Suno compression pass (OpenRouter: Qwen · LaoZhang: Claude)."""

from __future__ import annotations

import logging
from typing import Any

from app.llm_config import llm_provider, resolve_compression_model
from app.payload_optimization import compact_payload_text
from app.post_process_common import (
    chat_simple,
    full_output_valid,
    genre_context_block,
    load_tool_prompt,
    sanitize_full_output,
    truthy_env,
)
from app.suno_output_qa import unified_block2_missing

logger = logging.getLogger(__name__)

_FALLBACK = """STAGE 5 SYNTAX COMPRESSION LAW (MANDATORY):
1. NO MULTI-BRACKET STACKING — collapse [A] [B] [C] into [A, B, C].
2. NO VERB PHRASES in brackets — noun textures only.
3. Remove trailing apostrophes from rhythm words.
4. ZERO REGIONAL TAG DUPLICATION — accent/delivery once per section bracket.
Block 1: 130-150 words / ≤1000 chars. Block 2: ≤2500 chars through [End].
Output complete two-block reply only."""


def suno_compression_pass_enabled(*, provider: str | None = None) -> bool:
    if not truthy_env("SUNO_COMPRESSION_PASS", default=True):
        return False
    return llm_provider(provider) in ("openrouter", "laozhang")


def apply_suno_compression_pass(
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
    field_mode: str = "custom",
    provider: str | None = None,
    lyrics_task: bool = True,
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> tuple[str, str]:
    if not suno_compression_pass_enabled(provider=provider):
        return text, "compress-skip"
    if lyrics_task and unified_block2_missing(text):
        return text, "compress-skip"

    system = load_tool_prompt("suno_compression_pass.txt", fallback=_FALLBACK)
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
    mode = (field_mode or "custom").strip().lower()
    payload = compact_payload_text(text)
    user_msg = (
        f"{ctx}\nFIELD:{mode}\n\nFULL OUTPUT (Stage 5 compress; preserve intent):\n"
        f"---\n{payload}\n---\n"
        "Return complete two-block reply only. No commentary."
    )

    model = resolve_compression_model(provider=provider)
    try:
        logger.info("suno compression pass model=%s", model)
        out = chat_simple(
            client,
            model=model,
            system=system,
            user=user_msg,
            temperature=0.35,
        )
        candidate = sanitize_full_output(out)
        if not full_output_valid(candidate):
            return text, "compress-invalid"
        if candidate.strip() == text.strip():
            return text, "compress-unchanged"
        return candidate, f"compress:{model}"
    except Exception as exc:  # noqa: BLE001
        logger.warning("suno compression pass failed: %s", exc)
        return text, "compress-fail"
