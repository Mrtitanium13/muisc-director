"""Anti-scream and token translation filter — post-generation lyric safeguard."""

from __future__ import annotations

import re

from app.advanced_thematic_variator import is_hardstyle_lane
from app.post_process_common import merge_block2_parts, split_block2_parts

_SECTION_HEADER_RE = re.compile(r"^\[([^\]]+)\]\s*$")
_DROP_HEADER_RE = re.compile(r"^drop$|^final drop$", re.I)

_VOCAL_TAG_REPLACEMENTS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\[Maximum Aggression\]", re.I), "[Heavy Produced Mix]"),
    (re.compile(r"\[Aggressive Hype\]", re.I), "[Heavy Produced Mix]"),
    (re.compile(r"\[Vocal Belt\]", re.I), "[Sustained Clean Melodic Vocals]"),
    (re.compile(r"\[Shouted Vocal\]", re.I), "[Sustained Clean Melodic Vocals]"),
)

_MONOLOGUE_DELIVERY_TAGS = (
    "[Deep Pitch-Down Male Voiceover]",
    "[Calm Controlled Spoken Word]",
)


def _scrub_exclamations(text: str) -> str:
    return text.replace("!", ".")


def _translate_vocal_tags(text: str) -> str:
    out = text
    for pattern, replacement in _VOCAL_TAG_REPLACEMENTS:
        out = pattern.sub(replacement, out)
    return out


def _is_drop_header(header: str) -> bool:
    return bool(_DROP_HEADER_RE.match(header.strip()))


def _is_lyric_line(line: str) -> bool:
    t = line.strip()
    if not t:
        return False
    if _SECTION_HEADER_RE.match(t):
        return False
    return True


def _punchy_phrase(lines: list[str], max_words: int = 4) -> str:
    words: list[str] = []
    for line in reversed(lines):
        for word in line.strip().split():
            if word:
                words.insert(0, word)
            if len(words) >= max_words:
                break
        if len(words) >= max_words:
            break
    return " ".join(words[:max_words])


def _collapse_pre_drop_cues(text: str) -> str:
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        header_match = _SECTION_HEADER_RE.match(line.strip())
        if header_match and _is_drop_header(header_match.group(1)):
            cue_lines: list[str] = []
            while out and _is_lyric_line(out[-1]):
                cue_lines.insert(0, out.pop())
            if len(cue_lines) > 1 or any(
                len(row.split()) > 4 for row in cue_lines
            ):
                out.append(_punchy_phrase(cue_lines))
            else:
                out.extend(cue_lines)
            out.append(line)
            i += 1
            continue
        out.append(line)
        i += 1
    return "\n".join(out)


def _apply_hardstyle_monologue_tags(text: str) -> str:
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        header_match = _SECTION_HEADER_RE.match(line.strip())
        if header_match and header_match.group(1).strip().lower() == "monologue":
            out.append(line)
            i += 1
            block = "\n".join(lines[i:]).lower()
            for tag in _MONOLOGUE_DELIVERY_TAGS:
                if tag.lower() not in block:
                    out.append(tag)
            continue
        out.append(line)
        i += 1
    return "\n".join(out)


def apply_anti_scream_to_lyrics(
    lyrics: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    if not lyrics.strip():
        return lyrics
    out = _scrub_exclamations(lyrics)
    out = _translate_vocal_tags(out)
    if is_hardstyle_lane(primary_genre, sub_genre_fusion):
        out = _apply_hardstyle_monologue_tags(out)
    out = _collapse_pre_drop_cues(out)
    return out


def apply_anti_scream_filter(
    full_text: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    """Apply anti-scream rules to Block 2 lyrics when unified output is present."""
    parts = split_block2_parts(full_text)
    if parts is None:
        return apply_anti_scream_to_lyrics(
            full_text,
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
        )
    prefix, body, suffix = parts
    cleaned = apply_anti_scream_to_lyrics(
        body,
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    if cleaned == body:
        return full_text
    return merge_block2_parts(prefix, cleaned, suffix)
