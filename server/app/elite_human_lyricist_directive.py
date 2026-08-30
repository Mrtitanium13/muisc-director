"""Elite human lyricist core — Block 2 authenticity (mirrors tools/elite_human_lyricist_directive.txt)."""

from __future__ import annotations

from pathlib import Path

_TOOLS_PATH = (
    Path(__file__).resolve().parents[2] / "tools" / "elite_human_lyricist_directive.txt"
)

_FALLBACK = """# ELITE HUMAN LYRICIST — CORE DIRECTIVE

**Suno scope:** Apply to Block 2 — LYRICS only.

You are an elite songwriter, rapper, and lyricist. Primary objective: lyrics that sound written by a real human with real experiences — not beautiful AI poetry. Avoid AI patterns, clichés, motivational language, perfect rhymes every line, and overused words (soul, truth, journey, destiny, shadows, dreams, etc.). Favor specificity over poetry. Allow imperfect rhymes and conversational phrasing. Before finalizing: would a listener believe a real human wrote this?"""


def _load_directive() -> str:
    try:
        if _TOOLS_PATH.is_file():
            return _TOOLS_PATH.read_text(encoding="utf-8").strip()
    except OSError:
        pass
    return _FALLBACK.strip()


ELITE_HUMAN_LYRICIST_DIRECTIVE = _load_directive()


def build_phonetic_integrity_rule(dialect_style_id: str | None = None) -> str:
    if (dialect_style_id or "").strip() == "nigerian_pidgin":
        return (
            "PHONETIC INTEGRITY (runtime): User LYRIC DIALECT is Nigerian Pidgin. "
            "DO NOT normalize lyric lines back to standard English. Preserve words like "
            "dey, na, wahala, e don set, small small exactly as intended by the story."
        )
    return (
        "PHONETIC INTEGRITY (runtime): Do not use trailing apostrophes to simulate "
        "loose casual speech (write breathing not breathin, going to not gonna) unless "
        "genre/dialect explicitly permits (Reggae/Dub patois, Hip Hop AAVE). "
        "Ensures clean phoneme mapping in downstream vocal synthesis."
    )


def elite_human_lyricist_user_block(dialect_style_id: str | None = None) -> str:
    phonetic = build_phonetic_integrity_rule(dialect_style_id)
    return (
        "ELITE HUMAN LYRICIST (Block 2 — mandatory craft layer; maintain genre conventions):\n"
        + ELITE_HUMAN_LYRICIST_DIRECTIVE
        + "\n\n"
        + phonetic
    )
