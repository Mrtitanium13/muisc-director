"""Vocal spec (arrangement) vs vocal tone (timbre/delivery) — accent is separate (vocal_accent.py)."""

from __future__ import annotations

import re

MALE_LEAD_SPEC = "Male Lead"
FEMALE_LEAD_SPEC = "Female Lead"
DUAL_LEAD_SPEC = "Dual Lead"
RAP_VOCAL_SPACE_SPEC = "Rap Vocal Space"
GOSPEL_CHOIR_SPEC = "Gospel Choir"
CHILDRENS_CHOIR_SPEC = "Children's Choir"
VOCAL_CHANTS_ONLY_SPEC = "Vocal Chants Only"
UNISON_STACKS_SPEC = "Unison Stacks"
INSTRUMENTAL_ONLY_SPEC = "Instrumental Only"

VOCAL_SPECS: tuple[str, ...] = (
    MALE_LEAD_SPEC,
    FEMALE_LEAD_SPEC,
    DUAL_LEAD_SPEC,
    RAP_VOCAL_SPACE_SPEC,
    GOSPEL_CHOIR_SPEC,
    CHILDRENS_CHOIR_SPEC,
    VOCAL_CHANTS_ONLY_SPEC,
    UNISON_STACKS_SPEC,
    INSTRUMENTAL_ONLY_SPEC,
)

_CHOIR_SPECS = frozenset({GOSPEL_CHOIR_SPEC, CHILDRENS_CHOIR_SPEC})

_BLOCK2_OVERRIDE_SPECS = frozenset(
    {
        INSTRUMENTAL_ONLY_SPEC,
        VOCAL_CHANTS_ONLY_SPEC,
        UNISON_STACKS_SPEC,
        RAP_VOCAL_SPACE_SPEC,
        *_CHOIR_SPECS,
    }
)

_WS_RE = re.compile(r"\s+")


def coerce_spec(raw: str | None) -> str | None:
    """Match a raw string to a canonical chip, or return trimmed custom text."""
    t = str(raw or "").strip()
    if not t:
        return None
    lower = t.lower()
    for v in VOCAL_SPECS:
        if v.lower() == lower:
            return v
    return t


def normalize_tone(raw: str | None) -> str | None:
    """Trim and collapse internal whitespace for free-text tone values."""
    if raw is None:
        return None
    t = str(raw).strip()
    if not t:
        return None
    return _WS_RE.sub(" ", t)


def is_instrumental_only(spec: str | None) -> bool:
    return str(spec or "").strip() == INSTRUMENTAL_ONLY_SPEC


def is_known_spec(spec: str | None) -> bool:
    return spec is not None and spec in VOCAL_SPECS


def is_custom_spec(raw: str | None) -> bool:
    spec = coerce_spec(raw)
    return spec is not None and not is_known_spec(spec)


def suppresses_lead_lyrics(spec: str | None) -> bool:
    return is_instrumental_only(spec)


def routes_to_block2(spec: str | None) -> bool:
    return coerce_spec(spec) in _BLOCK2_OVERRIDE_SPECS


def is_choir(spec: str | None) -> bool:
    return coerce_spec(spec) in _CHOIR_SPECS


def is_rap_forward(spec: str | None) -> bool:
    return coerce_spec(spec) == RAP_VOCAL_SPACE_SPEC


def _routing_for_spec(spec: str) -> str:
    if spec == INSTRUMENTAL_ONLY_SPEC:
        return (
            "Block 2: **instrumental-only** — bracket sections and production tags only; "
            "no lead-vocal lyric lines, hooks, or sung verses."
        )
    if spec == VOCAL_CHANTS_ONLY_SPEC:
        return (
            "Block 2: chant-first — short repetitive loops on `[Chant]` headers; "
            "minimal narrative verse density; hookable syllable stacks."
        )
    if spec == UNISON_STACKS_SPEC:
        return (
            "Block 2: unison-stack delivery — thick doubled lead lines; "
            "staging may reference stacked unison; avoid complex independent harmony parts in lyrics."
        )
    if spec == RAP_VOCAL_SPACE_SPEC:
        return (
            "Block 2: rap-forward pocket — rhythmic density, internal rhyme, "
            "clear downbeat phrasing; sung sections only when genre lane expects them."
        )
    if spec in _CHOIR_SPECS:
        return (
            "Block 2: choir / group vocal staging — call-and-response or sectional "
            "group tags where natural; lead lines optional per genre lane."
        )
    return (
        "Block 1: weave spec into vocal production prose (gender/role/line-up only — "
        "never impersonate a real person)."
    )


def user_block_line(*, vocal_spec: str | None, vocal_tone: str | None) -> str:
    spec = str(vocal_spec or "").strip()
    tone = str(vocal_tone or "").strip()
    parts: list[str] = []
    if spec:
        parts.append(f"spec={spec}")
    if tone:
        parts.append(f"tone={tone}")
    if not parts:
        return "Vocal:"
    return "Vocal: " + " · ".join(parts)


def user_block_directive(
    *,
    vocal_spec: str | None,
    vocal_tone: str | None,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    """Expanded routing directive when spec or tone is set.

    primary_genre / sub_genre_fusion are accepted for signature stability with
    callers that already hold genre context; this block stays focused on user
    chip routing.
    """
    _ = (primary_genre, sub_genre_fusion)
    spec = coerce_spec(vocal_spec)
    tone = normalize_tone(vocal_tone)
    if not spec and not tone:
        return ""

    lines = [
        "VOCAL SPEC & TONE (USER-SELECTED — NON-NEGOTIABLE):",
        "- **Vocal spec** = lead singer / choir / chant arrangement (form chip). "
        "**Vocal tone** = timbre / delivery / processing mix (optional dropdown or custom text). "
        "**Vocal accent** is a separate field — see VOCAL ACCENT block when present.",
    ]
    if spec:
        lines.append(f"- user_vocal_spec: {spec}")
        lines.append(f"- {_routing_for_spec(spec)}")
    if tone:
        lines.append(f"- user_vocal_tone: {tone}")
        lines.append(
            "- Block 1: embed tone as mix / timbre / delivery texture in vocal prose. "
            "Block 2: reflect tone in staging bracket tags — do not paste tone label as a lyric theme."
        )
    return "\n".join(lines)
