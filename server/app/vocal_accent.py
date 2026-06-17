"""User-selected singer accent / regional delivery (style only — not voice cloning)."""

from __future__ import annotations

from app.dialect_style import is_nigerian_pidgin

ACCENT_VS_DIALECT_CONSTRAINT = (
    "ACCENT VS. DIALECT CONSTRAINT: When a regional accent or delivery style is specified, "
    "write lyrics in clear, standard English. You are strictly forbidden from translating "
    "text into slang, broken dialects, or patois (completely ban words like dey, na, wahala, "
    "gonna in lyric lines). Let vocal performance style remain purely phonetic in staging "
    "tags; the written lyric text must stay pristine, high-end, and universally legible."
)

REGIONAL_TAG_DEDUP_CONSTRAINT = (
    "ZERO REGIONAL TAG DUPLICATION: Regional delivery modifiers, vocal textures, or accent "
    "descriptors must appear once per section inside the single staging bracket — never "
    "repeat the same regional/accent phrase across consecutive brackets, section headers, "
    "or lyric lines. Block 1 carries primary vocal-accent prose; Block 2 tags reference "
    "delivery phonetically without re-stacking identical regional labels every section."
)


def vocal_accent_user_block(
    accent: str,
    *,
    vocal_spec: str = "",
    language: str = "English",
    dialect_style_id: str = "",
) -> str:
    """Strong runtime directive when user picks an accent in the prompt form."""
    a = (accent or "").strip()
    if not a:
        return ""
    spec = (vocal_spec or "").strip()
    lang = (language or "English").strip() or "English"
    spec_line = f"\n- Lead vocal type: {spec}" if spec else ""
    pidgin = is_nigerian_pidgin(dialect_style_id)
    lyric_line = (
        "- Block 2 lyrics: User selected Nigerian Pidgin dialect — Pidgin grammar applies "
        "in lyric lines; accent delivery still lives in staging tags."
        if pidgin
        else "- Block 2 lyrics: Write in clear, standard English only — accent is phonetic "
        "delivery in staging tags, NOT slang or dialect in the written lines."
    )
    return (
        "VOCAL ACCENT / DELIVERY (USER-SELECTED — NON-NEGOTIABLE):\n"
        f"- Accent: {a}\n"
        f"- Language context: {lang}{spec_line}\n"
        "- Block 1: Weave this regional pronunciation and cadence into the vocal production "
        "description (style/delivery only — never impersonate a real person).\n"
        "- Block 2 staging: Include accent delivery tags in each section's single staging "
        f'bracket (e.g. "{a} Delivery", close-mic proximity) — do not duplicate the same '
        "regional label in lyric lines.\n"
        f"{lyric_line}\n"
        "- Preserve singability; accent is delivery style, not a dialect caricature."
    )


def accent_vs_dialect_constraint_line(
    *,
    vocal_accent: str,
    dialect_style_id: str = "",
) -> str:
    """Stage 3 hard rule when accent is set but lyric dialect is standard English."""
    if not (vocal_accent or "").strip():
        return ""
    if is_nigerian_pidgin(dialect_style_id):
        return ""
    return ACCENT_VS_DIALECT_CONSTRAINT


def regional_tag_deduplication_line(
    *,
    vocal_accent: str = "",
    dialect_style_id: str = "",
) -> str:
    """Stage 5 hard rule when regional delivery is in play."""
    if not (vocal_accent or "").strip() and not is_nigerian_pidgin(dialect_style_id):
        return ""
    return REGIONAL_TAG_DEDUP_CONSTRAINT


def vocal_accent_post_process_context_line(
    accent: str,
    *,
    dialect_style_id: str = "",
) -> str:
    a = (accent or "").strip()
    if not a:
        return ""
    if is_nigerian_pidgin(dialect_style_id):
        return (
            f"VOCAL ACCENT (staging tags only): {a} — lyric dialect is Nigerian Pidgin."
        )
    return (
        f"VOCAL ACCENT (staging tags only — lyrics stay standard English): {a}"
    )


def accent_vs_dialect_compact_line(
    *,
    vocal_accent: str,
    dialect_style_id: str = "",
) -> str:
    if not (vocal_accent or "").strip() or is_nigerian_pidgin(dialect_style_id):
        return ""
    return "RULE:accent-only|lyrics=standard English|no dey/na/wahala in lines"


def regional_tag_deduplication_compact_line(
    *,
    vocal_accent: str = "",
    dialect_style_id: str = "",
) -> str:
    if not (vocal_accent or "").strip() and not is_nigerian_pidgin(dialect_style_id):
        return ""
    return "RULE:regional-tag-once|one accent phrase per section bracket"


def vocal_accent_post_process_compact_line(
    accent: str,
    *,
    dialect_style_id: str = "",
) -> str:
    a = (accent or "").strip()
    if not a:
        return ""
    if is_nigerian_pidgin(dialect_style_id):
        return f"ACCENT:{a}|staging-only|lyrics=Pidgin"
    return f"ACCENT:{a}|staging-only|lyrics=standard English"
