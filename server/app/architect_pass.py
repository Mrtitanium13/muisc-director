"""Pass 1 Architect — compact JSON blueprint for the two-pass Suno pipeline.

Udio is temporarily disabled; blueprints target Suno Block 1/2 only.
"""

from __future__ import annotations

import json
import logging
import re
from typing import Any

logger = logging.getLogger(__name__)

_ARCHITECT_MAX_TOKENS = 2048

# Required keys — soft-fill defaults if the model omits them.
_REQUIRED_KEYS = (
    "genre_primary",
    "songwriting_mode",
    "hook_concept",
    "section_roadmap",
    "artist_dna_traits",
)

ARCHITECT_SYSTEM = """You are the Music Director ARCHITECT (Pass 1 only).

Platform: Suno only (Udio disabled). Output **JSON only** — no Block 1, no lyrics, no markdown fences, no commentary.

Your job: resolve creative conflicts BEFORE lyrics. Reconcile Artist DNA traits with genre so they never fight (e.g. soft narrative-pop DNA on death metal → rewrite DNA to aggressive/abrasive traits that still honor the reference's useful sonic DNA).

Return one JSON object with exactly these keys:
{
  "genre_primary": "string",
  "genre_fusion": "string or empty",
  "songwriting_mode": "A" | "B" | "C",
  "bpm_intent": number or null,
  "key_intent": "string or empty",
  "emotion_before": "string",
  "emotion_after": "string",
  "transformation_arc": "string",
  "audience": "string",
  "commercial_objective": "string",
  "hook_concept": "string",
  "three_second_intro_anchor": "string",
  "user_proxy_moment": "string",
  "section_roadmap": ["Intro", "Verse 1", "Pre-Chorus", "Chorus", "...", "Outro"],
  "syllable_density": "string (e.g. short punchy / mid narrative)",
  "artist_dna_traits": ["trait", "..."],
  "vocal_character": "string",
  "production_keywords": ["keyword", "..."],
  "conflict_resolution_notes": "how Genre/DNA/Mode were reconciled"
}

Rules:
- section_roadmap stems must be Suno-canonical (Intro, Verse, Pre-Chorus, Chorus, Post-Chorus, Bridge, Breakdown, Build-Up, Drop, Break, Outro, etc.). No invented names like Hook Drop.
- artist_dna_traits: characteristics only — never artist/song/album names.
- Keep values concrete and short. No nested objects beyond the schema above.
"""


def architect_max_tokens() -> int:
    return _ARCHITECT_MAX_TOKENS


def _extract_json_object(raw: str) -> dict[str, Any]:
    text = (raw or "").strip()
    if not text:
        raise ValueError("empty architect response")
    # Strip optional ```json fences
    fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", text, re.IGNORECASE)
    if fence:
        text = fence.group(1).strip()
    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return data
    except json.JSONDecodeError:
        pass
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("no JSON object in architect response")
    data = json.loads(text[start : end + 1])
    if not isinstance(data, dict):
        raise ValueError("architect JSON root must be an object")
    return data


def normalize_blueprint(data: dict[str, Any]) -> dict[str, Any]:
    """Fill defaults and coerce types for a usable Pass 2 blueprint."""
    out: dict[str, Any] = dict(data)
    out.setdefault("genre_primary", "")
    out.setdefault("genre_fusion", "")
    mode = str(out.get("songwriting_mode") or "B").strip().upper()
    out["songwriting_mode"] = mode if mode in ("A", "B", "C") else "B"
    out.setdefault("bpm_intent", None)
    out.setdefault("key_intent", "")
    out.setdefault("emotion_before", "")
    out.setdefault("emotion_after", "")
    out.setdefault("transformation_arc", "")
    out.setdefault("audience", "")
    out.setdefault("commercial_objective", "")
    out.setdefault("hook_concept", "")
    out.setdefault("three_second_intro_anchor", "")
    out.setdefault("user_proxy_moment", "")
    roadmap = out.get("section_roadmap")
    if not isinstance(roadmap, list) or not roadmap:
        out["section_roadmap"] = [
            "Intro",
            "Verse 1",
            "Pre-Chorus",
            "Chorus",
            "Verse 2",
            "Chorus",
            "Bridge",
            "Final Chorus",
            "Outro",
        ]
    else:
        out["section_roadmap"] = [str(x).strip() for x in roadmap if str(x).strip()]
    out.setdefault("syllable_density", "short punchy")
    traits = out.get("artist_dna_traits")
    if not isinstance(traits, list):
        out["artist_dna_traits"] = []
    else:
        out["artist_dna_traits"] = [str(x).strip() for x in traits if str(x).strip()]
    out.setdefault("vocal_character", "")
    keywords = out.get("production_keywords")
    if not isinstance(keywords, list):
        out["production_keywords"] = []
    else:
        out["production_keywords"] = [str(x).strip() for x in keywords if str(x).strip()]
    out.setdefault("conflict_resolution_notes", "")
    return out


def parse_architect_blueprint(raw: str) -> dict[str, Any]:
    data = _extract_json_object(raw)
    normalized = normalize_blueprint(data)
    missing = [k for k in _REQUIRED_KEYS if not normalized.get(k)]
    if missing:
        logger.warning("architect blueprint missing soft fields: %s", missing)
    return normalized


def blueprint_to_json(blueprint: dict[str, Any]) -> str:
    return json.dumps(blueprint, ensure_ascii=False, indent=2)


def inject_blueprint_into_user(
    user_content: str,
    blueprint: dict[str, Any] | str,
    *,
    user_suffix: str | None = None,
) -> str:
    """Append Master Blueprint + hard emit constraints (recency bias: last)."""
    if isinstance(blueprint, str):
        blob = blueprint.strip()
    else:
        blob = blueprint_to_json(blueprint)
    parts = [
        user_content.strip(),
        "",
        "---MASTER BLUEPRINT (Pass 1 Architect — honor exactly; do NOT reprint)---",
        blob,
        "---END MASTER BLUEPRINT---",
        "",
        "PASS 2 RULES (absolute):",
        "- Emit ONLY BLOCK 1 — PASTE INTO SUNO: STYLE and BLOCK 2 — PASTE INTO SUNO: LYRICS.",
        "- Follow section_roadmap with whitelist Suno metatags only; end Block 2 with [End].",
        "- No stage names, scores, JSON, or internal thoughts in the reply.",
        "- Block 1: 130–150 words, ≤1000 characters of producer prose.",
    ]
    if user_suffix and user_suffix.strip():
        parts.extend(["", user_suffix.strip()])
    return "\n".join(parts)
