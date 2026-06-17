"""Suno post-generation lyrics normalizer — audio-engine-safe tag translation."""

from __future__ import annotations

import re

from app.post_process_common import merge_block2_parts, split_block2_parts

_DJ_INTRO_RE = re.compile(r"\[\d+-bar\s+DJ\s+intro[^\]]*\]", re.I)
_DJ_OUTRO_RE = re.compile(r"\[\d+-bar\s+DJ\s+outro[^\]]*\]", re.I)
_DEAD_ROOM_RE = re.compile(r"\[Dead-room[^\]]*\]", re.I)
_MALE_INTIMATE_RE = re.compile(r"\[Male\s+Vocal,\s*Intimate[^\]]*\]", re.I)
_MALE_WHISPERED_RE = re.compile(r"\[Male\s+Vocal,\s*Whispered[^\]]*\]", re.I)
_MALE_BUILDING_RE = re.compile(
    r"\[Male\s+Vocal,\s*Building\s+Intensity[^\]]*\]", re.I
)
_SECTION_HEADER_RE = re.compile(r"^\[([^\]]+)\]\s*$")
_PAREN_ONLY_LINE_RE = re.compile(r"^\([^)]+\)\s*$")
_EXACT_DROP_TONIGHT_RE = re.compile(
    r"\[Drop\]\n\(Tonight\.\.\.\)\n\(Tonight\.\.\.\)", re.I
)
_EXACT_FINAL_DROP_RE = re.compile(
    r"\[Final Drop\]\n\(Tonight\.\.\.\)\n\(We're infinite\.\.\.\)", re.I
)


def _shout_from_paren_line(line: str) -> str | None:
    m = re.match(r"^\(([^)]+)\)\s*$", line.strip())
    if not m:
        return None
    text = m.group(1).strip()
    if not text:
        return None
    text = re.sub(r"\.{2,}$", "!", text)
    if not re.search(r"[!.?]$", text):
        text = f"{text}!"
    return text


def _is_drop_header(header: str) -> bool:
    h = header.strip().lower()
    return h in {"drop", "final drop"}


def _fix_paren_only_drop_sections(text: str) -> str:
    lines = text.split("\n")
    out: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i]
        header_match = _SECTION_HEADER_RE.match(line.strip())
        if header_match and _is_drop_header(header_match.group(1)):
            header = header_match.group(1).strip()
            body: list[str] = []
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if _SECTION_HEADER_RE.match(nxt.strip()):
                    break
                if nxt.strip():
                    body.append(nxt)
                i += 1

            only_parens = body and all(
                _PAREN_ONLY_LINE_RE.match(row.strip()) for row in body
            )
            if only_parens:
                shout = _shout_from_paren_line(body[-1])
                if shout:
                    out.extend(["[Pre-Drop]", shout, ""])
                out.append(f"[{header}]")
                tag = (
                    "[Maximum Energy Instrumental Drop]"
                    if "final" in header.lower()
                    else "[Instrumental Drop]"
                )
                out.append(tag)
                continue

            out.append(line)
            out.extend(body)
            continue

        out.append(line)
        i += 1

    return "\n".join(out)


def normalize_lyrics_for_audio_engine(llm_lyrics: str) -> str:
    """Translate dense LLM lyrics into streamlined, audio-safe AI tags."""
    if not llm_lyrics:
        return ""

    out = _DJ_INTRO_RE.sub("[Intro]\n[Atmospheric Synth Intro]", llm_lyrics)
    out = _DJ_OUTRO_RE.sub("[Outro]\n[Minimal Outro]", out)
    out = _DEAD_ROOM_RE.sub("[Intimate Male Vocal]", out)
    out = _MALE_INTIMATE_RE.sub("[Intimate Male Vocal]", out)
    out = _MALE_WHISPERED_RE.sub("[Whispered Male Vocal]", out)
    out = _MALE_BUILDING_RE.sub(
        "[Building Intensity]\n[Accelerating Snare Roll]", out
    )
    out = re.sub(r"Prophet-5", "Synth", out, flags=re.I)
    out = re.sub(r"TR-909", "Drums", out, flags=re.I)
    out = re.sub(r"TR-808", "Drums", out, flags=re.I)
    out = _EXACT_DROP_TONIGHT_RE.sub(
        "[Pre-Drop]\nTonight!\n\n[Drop]\n[Instrumental Drop]", out
    )
    out = _EXACT_FINAL_DROP_RE.sub(
        "[Pre-Drop]\nWe are infinite!\n\n[Final Drop]\n[Maximum Energy Instrumental Drop]",
        out,
    )
    out = _fix_paren_only_drop_sections(out)
    out = re.sub(r"\n{3,}", "\n\n", out).strip()
    return out


def apply_audio_engine_normalization_to_suno_output(full_text: str) -> str:
    """Apply normalization to Block 2 lyrics only when a unified banner is present."""
    parts = split_block2_parts(full_text)
    if parts is None:
        return full_text

    prefix, body, suffix = parts
    normalized = normalize_lyrics_for_audio_engine(body)
    if normalized == body:
        return full_text
    return merge_block2_parts(prefix, normalized, suffix)
