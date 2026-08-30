"""Deterministic lyric linting / hard gates for the songwriter pipeline."""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

_ROOT = Path(__file__).resolve().parents[3]
_SRC = _ROOT / "tools" / "songwriter"

_SECTION_RE = re.compile(r"^\[([^\]]+)\]\s*$", re.M)
_META_RE = re.compile(
    r"\b(this song|the lyrics|the story|as an ai|in this track)\b",
    re.I,
)
_HAN_RE = re.compile(r"[\u4e00-\u9fff]")
_LATIN_WORD_RE = re.compile(r"[A-Za-z]{3,}")


def _load_forbidden() -> list[str]:
    path = _SRC / "forbidden_phrases.json"
    if path.is_file():
        data = json.loads(path.read_text(encoding="utf-8"))
        return [str(p) for p in (data.get("phrases") or [])]
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        data = SONGWRITER_PROMPTS.get("forbidden_phrases") or {}
        return [str(p) for p in (data.get("phrases") or [])]
    except Exception:
        return []


def scrub_forbidden(lyrics: str, allow_cliches: bool = False) -> tuple[str, list[str]]:
    if allow_cliches or not lyrics:
        return lyrics, []
    hits: list[str] = []
    lower = lyrics.lower()
    for phrase in _load_forbidden():
        if phrase.lower() in lower:
            hits.append(phrase)
    return lyrics, hits


def parse_sections(lyrics: str) -> list[dict[str, Any]]:
    if not lyrics.strip():
        return []
    parts = _SECTION_RE.split(lyrics)
    # parts: [pre, label, body, label, body, ...]
    if len(parts) < 3:
        return [{"type": "body", "label": None, "lines": _lines(lyrics)}]
    sections: list[dict[str, Any]] = []
    # If text before first label, keep as unlabeled
    if parts[0].strip():
        sections.append({"type": "body", "label": None, "lines": _lines(parts[0])})
    for i in range(1, len(parts), 2):
        label = parts[i].strip()
        body = parts[i + 1] if i + 1 < len(parts) else ""
        sections.append(
            {
                "type": _normalize_section_type(label),
                "label": label,
                "lines": _lines(body),
            }
        )
    return sections


def _lines(text: str) -> list[str]:
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def _normalize_section_type(label: str) -> str:
    l = label.lower()
    mapping = [
        ("intro", "intro"),
        ("verse", "verse"),
        ("pre", "pre_chorus"),
        ("chorus", "chorus"),
        ("hook", "chorus"),
        ("post", "post_chorus"),
        ("bridge", "bridge"),
        ("break", "breakdown"),
        ("drop", "breakdown"),
        ("outro", "outro"),
    ]
    for key, typ in mapping:
        if key in l:
            return typ
    return "verse"


def lint_lyrics(
    lyrics: str,
    *,
    mode: str = "full_song",
    language: str = "English",
    allow_cliches: bool = False,
    language_pack_id: str = "en",
) -> dict[str, Any]:
    """Return lint report with hard_fails and soft warnings."""
    hard: list[str] = []
    soft: list[str] = []
    _, forbidden_hits = scrub_forbidden(lyrics, allow_cliches)

    if not lyrics.strip() and mode not in (
        "hook_ideas",
        "song_concepts",
        "song_titles",
        "concepts",
    ):
        hard.append("empty_lyrics")

    if forbidden_hits and not allow_cliches:
        hard.append("forbidden_phrase_hit_without_user_override")

    if _META_RE.search(lyrics or ""):
        soft.append("meta_language_about_song")

    # Repetition: identical non-section lines
    body_lines = [
        ln.strip()
        for ln in (lyrics or "").splitlines()
        if ln.strip() and not ln.strip().startswith("[")
    ]
    counts = Counter(x.lower() for x in body_lines)
    for line, n in counts.items():
        if n > 2 and len(line) > 8:
            hard.append("identical_verse_lines_gt_2")
            break

    sections = parse_sections(lyrics or "")
    types = {s["type"] for s in sections}
    if mode in ("full_song", "chorus_only") and lyrics.strip():
        if "chorus" not in types and mode == "full_song":
            # assembled drafts without labels still OK if content exists
            if "[" in lyrics and "chorus" not in lyrics.lower() and "hook" not in lyrics.lower():
                hard.append("chorus_missing_or_empty")
        if mode == "chorus_only" and not body_lines:
            hard.append("chorus_missing_or_empty")

    # Language / script checks (heuristic)
    han = bool(_HAN_RE.search(lyrics or ""))
    latin_words = len(_LATIN_WORD_RE.findall(lyrics or ""))
    if language_pack_id in ("zh_hans", "zh_hant") and lyrics.strip() and not han:
        hard.append("language_mismatch")
    if language_pack_id == "en" and han and latin_words < 3:
        soft.append("unexpected_cjk_in_english_brief")
    if language_pack_id == "zh_hant" and han:
        # Soft: simplified characters often still appear; warn only on heavy latin
        if latin_words > 40:
            soft.append("heavy_english_in_zh_hant")

    return {
        "hard_fails": hard,
        "soft_warnings": soft,
        "forbidden_hits": forbidden_hits,
        "sections": sections,
        "line_count": len(body_lines),
    }
