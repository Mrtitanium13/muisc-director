"""Privacy-safe remix observability — never logs raw title/artist."""

from __future__ import annotations

import logging
from typing import Any

from app.remix_engine import REMIX_BLOCK_VERSION, RemixMode, remix_source_fingerprint

logger = logging.getLogger("music_director.remix")


def emit_remix_event(**fields: Any) -> None:
    parts = [f"{k}={v}" for k, v in fields.items() if v is not None]
    logger.info("[remix] %s", " ".join(parts))


def log_remix_activation(
    *,
    mode: RemixMode,
    near_activation: bool,
    genre: str,
    song_generation_type: str,
    title: str = "",
    artist: str = "",
    block_injected: bool = False,
) -> None:
    fp = (
        remix_source_fingerprint(title, artist)
        if len(title.strip()) >= 2 and len(artist.strip()) >= 2
        else "none"
    )
    emit_remix_event(
        event="activation",
        mode=mode.value,
        near=near_activation,
        genre=(genre.strip() or "unset"),
        gen=song_generation_type,
        block_v=REMIX_BLOCK_VERSION,
        fp=fp,
        injected=block_injected,
    )


def log_remix_post_process(
    *,
    mode: RemixMode,
    song_generation_type: str,
    stripped_lyric_lines: int,
    staging_injected: int,
    leak_hit: bool,
    title: str = "",
    artist: str = "",
) -> None:
    fp = (
        remix_source_fingerprint(title, artist)
        if len(title.strip()) >= 2 and len(artist.strip()) >= 2
        else "none"
    )
    emit_remix_event(
        event="post_process",
        mode=mode.value,
        gen=song_generation_type,
        strip_n=stripped_lyric_lines,
        staging_n=staging_injected,
        leak=leak_hit,
        block_v=REMIX_BLOCK_VERSION,
        fp=fp,
    )
