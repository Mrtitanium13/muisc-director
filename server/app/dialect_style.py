"""Lyric dialect mode — Nigerian Pidgin vs standard English + regional variants."""

from __future__ import annotations

STANDARD_ENGLISH_ID = "standard_english"
NIGERIAN_PIDGIN_ID = "nigerian_pidgin"
GENERAL_VARIANT_ID = "general"

_OPTIONS: dict[str, tuple[str, str]] = {
    STANDARD_ENGLISH_ID: (
        "Standard English (with Accent)",
        "Write lyrics in standard, grammatically clean English. Let the style tags handle the phonetic vocal accent.",
    ),
    NIGERIAN_PIDGIN_ID: (
        "Nigerian Pidgin English (Dialect Mode)",
        "CRITICAL DIRECTIVE: Write the lyrics natively in authentic Nigerian Pidgin English. Utilize true regional vocabulary (e.g., dey, na, wahala, e don set, small small) to craft deep, culturally accurate, rhythmic storytelling while maintaining the Lyric Fourth-Wall Law.",
    ),
}

_VARIANTS: dict[str, tuple[str, str]] = {
    GENERAL_VARIANT_ID: (
        "General Nigerian Pidgin",
        "Pan-Nigerian Pidgin flow — dey, na, wahala, e don set, small small — without forcing one ethnic tongue.",
    ),
    "ibibio": (
        "Ibibio-inflected Pidgin",
        "Inflect Pidgin with Ibibio (Akwa Ibom / Cross River) color: warm vowels, local proverb rhythm, "
        "community-call phrasing; ground worship/street story in South-South Nigerian lived texture.",
    ),
    "efik": (
        "Efik-inflected Pidgin",
        "Efik (Calabar) inflection on Pidgin — melodic call-and-response cadence, coastal warmth, "
        "congregational hook phrasing.",
    ),
    "yoruba": (
        "Yoruba-inflected Pidgin",
        "Yoruba color on Pidgin — percussive syllables, praise-call energy, proverb turns.",
    ),
    "igbo": (
        "Igbo-inflected Pidgin",
        "Igbo inflection on Pidgin — declarative hook lines, testimony cadence, Eastern Nigerian street warmth.",
    ),
    "hausa": (
        "Hausa-inflected Pidgin",
        "Hausa color on Pidgin — north Nigerian phrasing, measured groove, market/street imagery.",
    ),
    "urhobo": (
        "Urhobo-inflected Pidgin",
        "Urhobo (Delta) inflection on Pidgin — riverine storytelling, communal chorus feel.",
    ),
}


def coerce_dialect_style_id(raw: str | None) -> str:
    key = (raw or "").strip()
    return key if key in _OPTIONS else STANDARD_ENGLISH_ID


def coerce_dialect_variant_id(raw: str | None) -> str:
    key = (raw or "").strip()
    return key if key in _VARIANTS else GENERAL_VARIANT_ID


def is_nigerian_pidgin(raw: str | None) -> bool:
    return coerce_dialect_style_id(raw) == NIGERIAN_PIDGIN_ID


def dialect_prompt_line(raw: str | None) -> str:
    _label, line = _OPTIONS[coerce_dialect_style_id(raw)]
    return line


def dialect_style_user_block(
    raw: str | None,
    *,
    dialect_variant_id: str | None = None,
) -> str:
    key = coerce_dialect_style_id(raw)
    if key == STANDARD_ENGLISH_ID:
        return ""
    label, prompt_line = _OPTIONS[key]
    variant_key = coerce_dialect_variant_id(dialect_variant_id)
    variant_label, variant_line = _VARIANTS[variant_key]
    variant_block = ""
    if variant_key != GENERAL_VARIANT_ID:
        variant_block = (
            f"\n- Regional flavor: {variant_label}\n- {variant_line}"
        )
    return (
        "LYRIC DIALECT MODE (USER-SELECTED — NON-NEGOTIABLE):\n"
        f"- Mode: {label}\n"
        f"- {prompt_line}{variant_block}\n"
        "- Apply LAYER 4.5 Nigerian Pidgin Dialect Module (system prompt). "
        "Stage 3 humanization must write natively in this dialect.\n"
        "- Stage 5 compression: preserve Pidgin grammar — do NOT normalize to standard English."
    )


def dialect_post_process_context_line(
    raw: str | None,
    *,
    dialect_variant_id: str | None = None,
) -> str:
    key = coerce_dialect_style_id(raw)
    if key == STANDARD_ENGLISH_ID:
        return ""
    label, prompt_line = _OPTIONS[key]
    variant_key = coerce_dialect_variant_id(dialect_variant_id)
    variant_label, variant_line = _VARIANTS[variant_key]
    variant_suffix = (
        f" · {variant_label}: {variant_line}"
        if variant_key != GENERAL_VARIANT_ID
        else ""
    )
    return (
        f"LYRIC DIALECT (NON-NEGOTIABLE — preserve in all lyric lines): "
        f"{label}{variant_suffix} — {prompt_line}"
    )


def dialect_post_process_compact_line(
    raw: str | None,
    *,
    dialect_variant_id: str | None = None,
) -> str:
    key = coerce_dialect_style_id(raw)
    if key == STANDARD_ENGLISH_ID:
        return ""
    variant_key = coerce_dialect_variant_id(dialect_variant_id)
    variant = f"|variant:{variant_key}" if variant_key != GENERAL_VARIANT_ID else ""
    return f"DIALECT:pidgin|preserve dey/na/wahala|no normalize{variant}"
