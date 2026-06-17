"""Token-efficient payload shaping for LLM requests (continuation + post-process)."""

from __future__ import annotations

import os
import re
from typing import Any

_DEFAULT_CONTINUATION_MAX = 6000
_DEFAULT_CONTINUATION_HEAD = 1400
_DEFAULT_CONTINUATION_TAIL = 4200

_MULTI_NL = re.compile(r"\n{3,}")
_TRAILING_WS_LINE = re.compile(r"[ \t]+\n")


def continuation_max_chars() -> int:
    raw = os.getenv("CONTINUATION_PRIOR_MAX_CHARS", "").strip()
    if raw.isdigit():
        return max(500, int(raw))
    return _DEFAULT_CONTINUATION_MAX


def truncate_continuation_prior(text: str, *, max_chars: int | None = None) -> str:
    """Rolling window: keep Block 1 head + Block 2 tail; drop middle when over budget."""
    t = compact_payload_text(text)
    if not t:
        return t
    limit = max_chars if max_chars is not None else continuation_max_chars()
    if len(t) <= limit:
        return t

    head_budget = min(_DEFAULT_CONTINUATION_HEAD, max(400, limit // 4))
    tail_budget = min(_DEFAULT_CONTINUATION_TAIL, limit - head_budget - 48)
    if tail_budget < 800:
        tail_budget = max(800, limit - head_budget - 48)

    marker = "\n...[prior output truncated for token budget]...\n"
    if head_budget + tail_budget + len(marker) >= len(t):
        return t[:limit]

    return f"{t[:head_budget].rstrip()}{marker}{t[-tail_budget:].lstrip()}"


def compact_payload_text(text: str) -> str:
    """Strip trailing whitespace, collapse excessive blank lines, trim ends."""
    if not text:
        return text
    out = text.replace("\r\n", "\n").replace("\r", "\n")
    out = _TRAILING_WS_LINE.sub("\n", out)
    out = _MULTI_NL.sub("\n\n", out)
    return out.strip()


LAOZHANG_ARCHITECTURE_BOUNDARY = """[LAOZHANG ARCHITECTURE BOUNDARY]
You are the GPT-5.5 multilingual prompt-generation pass (LaoZhang). Claude follows to refine lyrics and artistic expression.
- Multilingual understanding: honor the user Language field, African languages, and Nigerian Pidgin (`dialect_style_id=nigerian_pidgin`) — never flatten Pidgin or African lyric intent to textbook English.
- Generate the complete Suno two-block reply (Block 1 STYLE + Block 2 LYRICS when applicable).
- Wrap all music instructions for a single section inside a single, comma-separated bracket.
- If the track environment is Studio, use cold engineering tokens: "Dead-room isolation, Zero audience noise".
- Keep lyric lines instrument-free; Claude will elevate hooks, storytelling, vocal personality, and poetic expression in the polish pass."""

_STACKED_BRACKETS = re.compile(r"(?:\[[^\]]+\]\s*){2,}")


def append_laozhang_system_prompt_boundary(system_prompt: str) -> str:
    """Append LaoZhang single-pass constraints (no Mistral humanizer on this branch)."""
    return f"{system_prompt.rstrip()}\n\n{LAOZHANG_ARCHITECTURE_BOUNDARY}"


def _collapse_stacked_brackets(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        tags = [t.strip() for t in re.findall(r"\[(.*?)\]", match.group(0)) if t.strip()]
        return f"[{', '.join(tags)}]" if tags else match.group(0)

    return "\n".join(_STACKED_BRACKETS.sub(repl, line) for line in text.splitlines())


def enforce_laozhang_syntax_hygiene(raw_prompt: str) -> str:
    """
    Inline Stage-5 compression filter for LaoZhang routes — bracket glitches and
    ambient crowd anchors when OpenRouter post-process is not in play.
    """
    text = run_global_prompt_hygiene(raw_prompt)
    text = (
        text.replace("SATB Choir", "Isolated multi-tracked vocal doubles")
        .replace("SATB Studio Choir", "Isolated multi-tracked vocal doubles")
        .replace("Studio Harmonic Backing", "Isolated multi-tracked vocal doubles")
        .replace("Harmonic Backing", "Isolated multi-tracked vocal doubles")
        .replace("Live Drum Kit", "Studio drum backbeat")
        .replace("Congregational Mix", "Wide stereo vocal mix")
        .replace("Congregational", "Multi-tracked vocal doubles")
    )
    return text.strip()


def process_dynamic_vocal_and_instrument_payload(
    genre_matrix_list: list[dict[str, Any]],
    vocal_option_ui: str,
) -> list[dict[str, Any]]:
    """
    Patch backing vocal rows based on client audio-environment selection.
    vocal_option_ui tokens: close-mic | live | ambient
    """
    acoustics = {
        "close-mic": {
            "articulation": (
                "thick double-tracked vocal stacks, crisp unison presence tracking"
            ),
            "mix_role": (
                "bold studio presence vocal, dry close-mic isolation, "
                "heavy proximity compression, zero ambient room bleed"
            ),
        },
        "live": {
            "articulation": (
                "authentic group backing echoes, natural spacious unison scaling"
            ),
            "mix_role": (
                "stadium depth arena footprint, open room microphone reflections, "
                "wide stereo field bleed"
            ),
        },
        "ambient": {
            "articulation": (
                "soft lush atmospheric backing layers, evolving choral pads"
            ),
            "mix_role": (
                "enveloping soundscape, deep cathedral reverb wash, "
                "wet hall decay tail, ethereal space"
            ),
        },
    }
    selected = acoustics.get(vocal_option_ui.lower(), acoustics["close-mic"])
    optimized: list[dict[str, Any]] = []

    for inst in genre_matrix_list:
        patched = dict(inst)
        if patched.get("category") == "vocals_choir":
            if patched.get("defaultArticulation") == "DYNAMIC_ARTICULATION":
                patched["defaultArticulation"] = selected["articulation"]
            if patched.get("mixRole") == "DYNAMIC_MIX_ROLE":
                patched["mixRole"] = selected["mix_role"]
        optimized.append(patched)

    return optimized


def vocal_option_from_audio_environment(mode_id: str | None) -> str:
    """Map Flutter [audio_environment_mode] to vocal patch token."""
    mode = (mode_id or "").strip().lower()
    if mode == "live_performance":
        return "live"
    if mode in ("ambient", "ambient_hall", "cathedral"):
        return "ambient"
    return "close-mic"


def run_global_prompt_hygiene(raw_prompt_text: str) -> str:
    """Collapse stacked brackets and normalize whitespace in model output."""
    text = raw_prompt_text or ""
    text = _collapse_stacked_brackets(text)
    text = _MULTI_NL.sub("\n\n", text)
    return text.strip()


def compact_genre_context_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str,
    vibe: str,
    lyric_theme_notes: str,
    language: str,
    extra_lines: tuple[str, ...] = (),
) -> str:
    """Dense pipe-delimited context header for post-process passes."""
    theme = lyric_theme_notes.strip() or "infer"
    g = primary_genre.strip() or "unspecified"
    f = sub_genre_fusion.strip() or "none"
    v = vibe.strip() or "unspecified"
    lang = language.strip() or "English"
    base = f"G:{g}|F:{f}|V:{v}|L:{lang}|T:{theme}"
    extras = [ln.strip() for ln in extra_lines if ln and ln.strip()]
    if not extras:
        return base
    return base + "\n" + "\n".join(extras)
