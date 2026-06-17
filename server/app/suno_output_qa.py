"""Lightweight QA for unified two-block Suno output (server-side retry)."""

from __future__ import annotations

import re

BLOCK1_WORD_MIN = 130
BLOCK1_INCOMPLETE_WORD_THRESHOLD = 80


def _line_is_block1_style_header(line: str) -> bool:
    t = line.strip()
    if not t:
        return False
    u = t.upper()
    if "PASTE INTO SUNO:" in u and "STYLE" in u and "LYRICS" not in u:
        return True
    if "BLOCK" not in u:
        return False
    if not re.search(r"BLOCK\s*1", u):
        return False
    return "STYLE" in u


def _line_is_block2_lyrics_header(line: str) -> bool:
    u = line.strip().upper()
    if "PASTE INTO SUNO:" in u and "LYRICS" in u:
        return True
    if "BLOCK" not in u:
        return False
    if not re.search(r"BLOCK\s*2", u):
        return False
    return "LYRICS" in u


def _strip_decorative_lines(text: str) -> str:
    out: list[str] = []
    sep = "━═─▔▁‐-–—"
    for line in text.split("\n"):
        t = line.strip()
        if not t:
            continue
        if re.match(r"^[\-=]{3,}$", t):
            continue
        banner_only = True
        for ch in t:
            if ch.isspace() or ch in sep or ch in "📋⚡🎛️":
                continue
            banner_only = False
            break
        if banner_only:
            continue
        out.append(line)
    return "\n".join(out)


def _block1_body_word_count(raw: str) -> int:
    lines = raw.replace("\r\n", "\n").split("\n")
    i_block1 = -1
    i_block2 = -1
    for i, line in enumerate(lines):
        if _line_is_block2_lyrics_header(line) and i_block2 < 0:
            i_block2 = i
        elif _line_is_block1_style_header(line) and i_block1 < 0:
            i_block1 = i
    if i_block1 < 0:
        return 0
    end = i_block2 if i_block2 >= 0 else len(lines)
    if i_block1 + 1 >= end:
        return 0
    body = _strip_decorative_lines("\n".join(lines[i_block1 + 1 : end])).strip()
    if not body:
        return 0
    return len(re.findall(r"\S+", body))


def unified_block2_missing(raw: str) -> bool:
    """True when V2 Block 1 banner exists but Block 2 lyrics body is absent."""
    lines = raw.replace("\r\n", "\n").split("\n")
    i_block1 = -1
    i_block2 = -1
    for i, line in enumerate(lines):
        if _line_is_block2_lyrics_header(line) and i_block2 < 0:
            i_block2 = i
        elif _line_is_block1_style_header(line) and i_block1 < 0:
            i_block1 = i
    if i_block1 < 0:
        return False
    if i_block2 < 0:
        return True
    lyric_raw = "\n".join(lines[i_block2 + 1 :]).strip()
    lyric = _strip_decorative_lines(lyric_raw).strip()
    if not lyric:
        return True
    before_end = lyric.split("[End]", 1)[0].strip() if "[End]" in lyric else lyric
    return len(before_end) < 8


def block1_probably_truncated(raw: str) -> bool:
    wc = _block1_body_word_count(raw)
    return 0 < wc < BLOCK1_INCOMPLETE_WORD_THRESHOLD


def prompt_qa_snapshot(raw: str, *, use_v2: bool, block2_opt_out: bool) -> dict:
    """Debug/metrics snapshot for generation QA (no secrets)."""
    return {
        "text_len": len(raw or ""),
        "block1_words": _block1_body_word_count(raw or ""),
        "block2_missing": unified_block2_missing(raw or ""),
        "block1_short": block1_probably_truncated(raw or ""),
        "should_format_retry": should_format_retry(
            raw or "", use_v2=use_v2, block2_opt_out=block2_opt_out
        ),
    }


def should_format_retry(
    raw: str,
    *,
    use_v2: bool,
    block2_opt_out: bool,
) -> bool:
    if not use_v2 or block2_opt_out:
        return False
    if unified_block2_missing(raw):
        return True
    wc = _block1_body_word_count(raw)
    return 0 < wc < BLOCK1_INCOMPLETE_WORD_THRESHOLD


def build_format_retry_suffix(*, block2_missing: bool, block1_short: bool) -> str:
    lines = [
        "STRICT COMPLIANCE — Output the **complete** two-block reply again. Fix:",
    ]
    if block1_short:
        lines.append(
            f"- Block 1 producer prose must be **{BLOCK1_WORD_MIN}–150 words** "
            "(full sentences — do not stop mid-paragraph)."
        )
    if block2_missing:
        lines.append(
            "- Include **BLOCK 2 — PASTE INTO SUNO: LYRICS** with section metatags "
            "through **[End]** on its own line."
        )
    lines.append("- No markdown fences. No meta-commentary before the banners.")
    lines.append(
        "- Apply Human Authenticity Engine: concrete imagery in verses; memorable concise chorus; "
        "no artist names; compress Block 1 if over caps."
    )
    return "\n".join(lines)
