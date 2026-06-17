"""OpenRouter runtime pipeline: Qwen theme → Mistral humanize → Qwen compress."""

from __future__ import annotations

import logging
from typing import Any

from app.humanization_pass import apply_humanization_pass, humanization_pass_enabled
from app.llm_config import llm_provider
from app.post_process_common import truthy_env
from app.suno_compression_pass import apply_suno_compression_pass, suno_compression_pass_enabled
from app.theme_consistency import apply_theme_consistency_pass, theme_consistency_enabled

logger = logging.getLogger(__name__)


def openrouter_post_process_enabled(*, provider: str | None = None) -> bool:
    if llm_provider(provider) != "openrouter":
        return False
    return truthy_env("OPENROUTER_POST_PROCESS", default=True)


def run_openrouter_post_process(
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
    lightweight: bool = False,
    lyrics_task: bool = True,
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> tuple[str, str]:
    """
    Qwen 3.7 theme → Mistral humanize → Qwen compress.
    Returns (text, colon-separated pipeline suffix).
    """
    if not openrouter_post_process_enabled(provider=provider):
        return text, ""

    labels: list[str] = []
    current = text

    if lyrics_task and theme_consistency_enabled():
        current, label = apply_theme_consistency_pass(
            client,
            text=current,
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            language=language,
            vocal_accent=vocal_accent,
            dialect_style_id=dialect_style_id,
            dialect_variant_id=dialect_variant_id,
            provider=provider,
            lightweight=lightweight,
            lyrics_task=lyrics_task,
            remix_original_song_title=remix_original_song_title,
            remix_original_artist=remix_original_artist,
            song_generation_type=song_generation_type,
        )
        if label not in ("theme-skip", "theme-unchanged", "theme-fail"):
            labels.append(label)

    if lyrics_task and humanization_pass_enabled(provider=provider):
        current, label = apply_humanization_pass(
            client,
            text=current,
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            language=language,
            vocal_accent=vocal_accent,
            dialect_style_id=dialect_style_id,
            dialect_variant_id=dialect_variant_id,
            audio_environment_mode=audio_environment_mode,
            provider=provider,
            lyrics_task=lyrics_task,
            remix_original_song_title=remix_original_song_title,
            remix_original_artist=remix_original_artist,
            song_generation_type=song_generation_type,
        )
        if label not in ("humanize-skip", "humanize-unchanged", "humanize-fail"):
            labels.append(label)

    if suno_compression_pass_enabled(provider=provider):
        current, label = apply_suno_compression_pass(
            client,
            text=current,
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            language=language,
            vocal_accent=vocal_accent,
            dialect_style_id=dialect_style_id,
            dialect_variant_id=dialect_variant_id,
            audio_environment_mode=audio_environment_mode,
            field_mode=field_mode,
            provider=provider,
            lyrics_task=lyrics_task,
            remix_original_song_title=remix_original_song_title,
            remix_original_artist=remix_original_artist,
            song_generation_type=song_generation_type,
        )
        if label not in ("compress-skip", "compress-unchanged", "compress-fail"):
            labels.append(label)

    suffix = ":".join(labels)
    if suffix:
        logger.info("openrouter post-process chain: %s", suffix)
    return current, suffix
