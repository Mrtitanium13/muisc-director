"""Human Realism slider (0–100) — lyric authenticity vs polished AI writing."""

from __future__ import annotations

from app.elite_human_lyricist_directive import elite_human_lyricist_user_block

DEFAULT_LEVEL = 75
MIN_LEVEL = 0
MAX_LEVEL = 100


def clamp_level(value: int) -> int:
    return max(MIN_LEVEL, min(MAX_LEVEL, int(value)))


def band_label(value: int) -> str:
    v = clamp_level(value)
    if v <= 20:
        return "Highly poetic and stylized"
    if v <= 40:
        return "Professional songwriter"
    if v <= 60:
        return "Balanced"
    if v <= 80:
        return "Authentic artist"
    return "Raw human realism"


def _band_instructions(level: int) -> str:
    if level <= 20:
        return """Generate highly lyrical and artistic lyrics.

Use:
* Dense rhyme schemes
* Metaphors
* Symbolism
* Strong imagery
* Technical writing
* Polished songwriting

Minimize:
* Everyday details
* Imperfections
* Conversational language"""
    if level <= 40:
        return """Generate professional commercial songwriting.

Use:
* Strong hooks
* Good imagery
* Clean structure
* Controlled storytelling

Allow some realism but maintain polished writing."""
    if level <= 60:
        return """Balance artistry and realism.

Use:
* Personal observations
* Memorable hooks
* Occasional imperfections
* Natural speech

Avoid excessive poetic language."""
    if level <= 80:
        return """Prioritize authenticity.

Use:
* Real-life situations
* Personal details
* Specific observations
* Natural conversations
* Human contradictions

Reduce:
* Excessive metaphors
* Forced rhymes
* Abstract imagery

Allow some rough edges."""
    return """Maximum human realism.

Write as if a real artist drafted the lyrics in a notebook.

Requirements:
* Use specific details.
* Use realistic situations.
* Include flaws.
* Include uncertainty.
* Include opinions.
* Include unique observations.
* Include occasional incomplete thoughts.
* Allow imperfect rhyme schemes.
* Allow conversational language.
* Allow surprising topic shifts.

Avoid:
* AI-style motivational language
* Generic inspiration
* Excessive imagery
* Every line sounding profound
* Constant metaphors
* Overly polished writing

Lyrics should feel lived-in rather than written.
The listener should believe a real person experienced these events."""


def human_realism_user_block(value: int) -> str:
    level = clamp_level(value)
    band = _band_instructions(level)
    lines = [
        elite_human_lyricist_user_block(),
        "",
        "HUMAN REALISM (scales poetic polish vs authentic grit on top of Elite Human Lyricist; Block 2 only):",
        band,
        "",
        f"Human Realism Level: {level}/100",
        "Adjust lyric generation accordingly.",
        "Higher values: increase authenticity, specificity, conversational language, and imperfections; "
        "decrease metaphor density, poetic abstraction, and forced rhyming.",
        "Lower values: increase lyricism, poetic imagery, technical rhymes, and stylization.",
        "Maintain genre conventions while applying the realism level.",
    ]
    if level <= 40:
        lines.append(
            "At this Human Realism level you MAY increase poetic density, metaphors, and rhyme craft "
            "per the band instructions above, but you MUST still obey the Elite Human Lyricist core bans "
            "(no motivational clichés, no AI-favored vocabulary spam, no making every line profound)."
        )
    return "\n".join(lines)
