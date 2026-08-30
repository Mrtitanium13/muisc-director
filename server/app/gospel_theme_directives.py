"""Dynamic theme → lyric directive mapping for Gospel lanes."""

from __future__ import annotations

THEME_FORGIVENESS = "forgiveness"
THEME_GRATITUDE = "gratitude"
THEME_SPIRITUAL_WARFARE = "spiritual_warfare"

_FORGIVENESS_MARKERS = (
    "forgive",
    "forgiveness",
    "redemption",
    "prodigal",
    "reconcil",
    "mercy",
    "guilt",
    "repent",
    "mistake",
    "return home",
    "second chance",
)

_GRATITUDE_MARKERS = (
    "gratitude",
    "grateful",
    "thankful",
    "thanksgiving",
    "blessing",
    "counting blessings",
    "overflowing",
    "harvest praise",
    "celebrat",
)

_WARFARE_MARKERS = (
    "warfare",
    "spiritual war",
    "victory",
    "deliverance",
    "break chains",
    "breakthrough",
    "armor",
    "weapons of praise",
    "walls falling",
    "stand firm",
    "overcome",
)

THEME_DIRECTIVES: dict[str, str] = {
    THEME_FORGIVENESS: """\
THEME DIRECTIVES for Forgiveness:
- Focus on redemption, washing away guilt, and reconciliation.
- Feel free to use the 'Prodigal Son' paradigm or an overwhelming embrace framework.
- Contrast the weight of past mistakes with the lightness of being forgiven.""",
    THEME_GRATITUDE: """\
THEME DIRECTIVES for Gratitude/Praise:
- Focus on counting blessings, thanking God for life, breath, and unseen protection.
- Use imagery of harvest, overflowing cups, or a song rising from the heart.
- Avoid heavy themes of guilt or running away; keep the tone celebratory or deeply humbled.""",
    THEME_SPIRITUAL_WARFARE: """\
THEME DIRECTIVES for Warfare/Victory:
- Focus on overcoming obstacles, breaking chains, and standing firm in faith.
- Use imagery of valleys, armor, weapons of praise, and walls falling down.
- Tone should be authoritative, driving, and triumphant.""",
}


def resolve_theme_key(
    *,
    lyric_theme_notes: str = "",
    vibe: str = "",
) -> str | None:
    blob = f"{lyric_theme_notes.strip()} {vibe.strip()}".lower()
    if not blob.strip():
        return None
    if any(m in blob for m in _FORGIVENESS_MARKERS):
        return THEME_FORGIVENESS
    if any(m in blob for m in _GRATITUDE_MARKERS):
        return THEME_GRATITUDE
    if any(m in blob for m in _WARFARE_MARKERS):
        return THEME_SPIRITUAL_WARFARE
    if "praise" in blob and "warfare" not in blob:
        if not any(m in blob for m in _FORGIVENESS_MARKERS):
            return THEME_GRATITUDE
    return None


def directive_block(
    *,
    lyric_theme_notes: str = "",
    vibe: str = "",
) -> str:
    key = resolve_theme_key(
        lyric_theme_notes=lyric_theme_notes,
        vibe=vibe,
    )
    if key:
        return THEME_DIRECTIVES.get(key, "")
    custom = lyric_theme_notes.strip()
    if custom:
        return f"THEME NOTES:\n- Honor the user theme: {custom}"
    return ""
