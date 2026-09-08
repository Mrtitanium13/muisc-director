"""Shared helpers for runtime post-processing passes."""

from __future__ import annotations

import os
import re
from pathlib import Path
from typing import Any

from app.payload_optimization import compact_payload_text
from app.suno_output_qa import (
    _line_is_block2_lyrics_header,
    unified_block2_missing,
)

_POST_MAX_TOKENS = 8192


def truthy_env(name: str, *, default: bool = True) -> bool:
    raw = os.getenv(name, "").strip().lower()
    if raw in ("0", "false", "no", "off"):
        return False
    if raw in ("1", "true", "yes", "on"):
        return True
    return default


def load_tool_prompt(filename: str, *, fallback: str) -> str:
    path = Path(__file__).resolve().parents[2] / "tools" / filename
    if path.is_file():
        return path.read_text(encoding="utf-8").strip()
    return fallback


def split_block2_parts(raw: str) -> tuple[str, str, str] | None:
    lines = raw.replace("\r\n", "\n").split("\n")
    i_block2 = -1
    for i, line in enumerate(lines):
        if _line_is_block2_lyrics_header(line):
            i_block2 = i
            break
    if i_block2 < 0:
        return None

    prefix = "\n".join(lines[: i_block2 + 1])
    rest = "\n".join(lines[i_block2 + 1 :])
    if not rest.strip():
        return None

    end_match = re.search(r"^(\s*\[End\]\s*)$", rest, flags=re.MULTILINE | re.IGNORECASE)
    if end_match:
        body = rest[: end_match.start()].rstrip("\n")
        body = f"{body}\n{rest[end_match.start():end_match.end()]}".strip("\n")
        suffix = rest[end_match.end() :].lstrip("\n")
        return prefix, body, suffix

    return prefix, rest.strip("\n"), ""


def merge_block2_parts(prefix: str, block2_body: str, suffix: str) -> str:
    parts = [prefix.rstrip(), block2_body.strip()]
    if suffix.strip():
        parts.append(suffix.strip("\n"))
    return "\n\n".join(parts)


def pin_user_lyrics_to_block2(output: str, user_lyrics: str) -> str:
    """Path A: force Block 2 sung lines to the lyrics-box paste."""
    user = str(user_lyrics or "").strip()
    if not user:
        return output
    parts = split_block2_parts(output)
    if parts is None:
        return output
    prefix, _body, suffix = parts
    body = user
    if not re.search(r"\[End\]", body, flags=re.IGNORECASE):
        body = f"{body}\n\n[End]"
    return merge_block2_parts(prefix, body, suffix)



def sanitize_block2_output(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = re.sub(r"^```[\w]*\n?", "", t)
        t = re.sub(r"\n?```\s*$", "", t).strip()
    lines = t.split("\n")
    if lines and _line_is_block2_lyrics_header(lines[0]):
        t = "\n".join(lines[1:]).strip()
    return t


def block2_output_valid(body: str) -> bool:
    if len(body.strip()) < 12:
        return False
    if "[end]" not in body.lower():
        return False
    if re.search(r"\[(intro|verse|chorus|hook|drop|outro)(\s|\])", body, re.I):
        return True
    return len(body.split()) >= 8


def sanitize_full_output(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = re.sub(r"^```[\w]*\n?", "", t)
        t = re.sub(r"\n?```\s*$", "", t).strip()
    return compact_payload_text(t)


def full_output_valid(raw: str) -> bool:
    if unified_block2_missing(raw):
        return False
    upper = raw.upper()
    return "BLOCK 1" in upper and "STYLE" in upper and "BLOCK 2" in upper and "LYRICS" in upper


def chat_simple(
    client: Any,
    *,
    model: str,
    system: str,
    user: str,
    temperature: float,
    max_tokens: int = _POST_MAX_TOKENS,
) -> str:
    from app.llm_config import completion_token_kwargs

    kwargs: dict[str, Any] = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": compact_payload_text(user)},
        ],
        "temperature": temperature,
        **completion_token_kwargs(model, max_tokens),
    }
    resp = client.chat.completions.create(**kwargs)
    text = (resp.choices[0].message.content or "").strip()
    if not text:
        raise ValueError("Empty post-process response")
    return text


def genre_context_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str,
    vibe: str,
    lyric_theme_notes: str,
    language: str,
    vocal_accent: str = "",
    dialect_style_id: str = "",
    dialect_variant_id: str = "",
    audio_environment_mode: str = "",
    remix_original_song_title: str = "",
    remix_original_artist: str = "",
    song_generation_type: str = "full_song",
) -> str:
    from app.audio_environment import audio_environment_post_process_compact_line
    from app.dialect_style import dialect_post_process_compact_line
    from app.payload_optimization import compact_genre_context_block
    from app.remix_engine import remix_post_process_compact_line
    from app.vocal_accent import (
        accent_vs_dialect_compact_line,
        regional_tag_deduplication_compact_line,
        vocal_accent_post_process_compact_line,
    )

    extras: list[str] = []
    accent_line = vocal_accent_post_process_compact_line(
        vocal_accent, dialect_style_id=dialect_style_id
    )
    if accent_line:
        extras.append(accent_line)
    dialect_line = dialect_post_process_compact_line(
        dialect_style_id, dialect_variant_id=dialect_variant_id
    )
    if dialect_line:
        extras.append(dialect_line)
    accent_rule = accent_vs_dialect_compact_line(
        vocal_accent=vocal_accent, dialect_style_id=dialect_style_id
    )
    if accent_rule:
        extras.append(accent_rule)
    dedup_rule = regional_tag_deduplication_compact_line(
        vocal_accent=vocal_accent, dialect_style_id=dialect_style_id
    )
    if dedup_rule:
        extras.append(dedup_rule)
    env_line = audio_environment_post_process_compact_line(audio_environment_mode)
    if env_line:
        extras.append(env_line)
    remix_line = remix_post_process_compact_line(
        original_song_title=remix_original_song_title,
        original_artist=remix_original_artist,
        generation_type=song_generation_type,
    )
    if remix_line:
        extras.append(remix_line)
    return compact_genre_context_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        language=language,
        extra_lines=tuple(extras),
    )
