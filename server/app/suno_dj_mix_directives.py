"""DJ mix-in/outro production brief — mirrors lib/core/constants/suno_dj_mix_directives.dart."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Final

from app.dynamic_structural_engine import (
    StructuralFamily,
    is_edm_family,
    resolve_structural_family,
)

DJ_INTRO_ON_TOKEN: Final[str] = "[DJ INTRO: ON]"
DJ_OUTRO_ON_TOKEN: Final[str] = "[DJ OUTRO: ON]"

DJ_MIX_USER_BLOCK_CHAR_CAP: Final[int] = 1600

DJ_MIX_IMPL_V1: Final[str] = (
    "SECTION 1F: DJ framing in first 40 words of Block 1 + 12–18 word closing "
    "clause. Block 2: content-rich [Instrumental Intro]/[Instrumental Outro] "
    "bookends with follow-up staging brackets."
)

DJ_MIX_BRIEF_ROUTING: Final[str] = (
    "Block 1: DJ framing in first 40 words + closing reinforcement "
    "(≤150 words, ≤1000 chars). Block 2: content-rich [Instrumental Intro]/"
    "[Instrumental Outro] bookends with follow-up staging brackets."
)


@dataclass(frozen=True)
class DjIntroConfig:
    intro_bars: int
    outro_bars: int


_DJ_BAR_TABLE: Final[dict[StructuralFamily, DjIntroConfig]] = {
    StructuralFamily.EDM_PROGRESSIVE_HOUSE: DjIntroConfig(32, 32),
    StructuralFamily.EDM_TRANCE: DjIntroConfig(32, 32),
    StructuralFamily.EDM_TECHNO: DjIntroConfig(32, 32),
    StructuralFamily.EDM_HARDSTYLE: DjIntroConfig(32, 32),
    StructuralFamily.EDM_DRUM_AND_BASS: DjIntroConfig(32, 32),
    StructuralFamily.EDM_BIG_ROOM: DjIntroConfig(32, 32),
    StructuralFamily.TRAP: DjIntroConfig(4, 4),
    StructuralFamily.HIPHOP: DjIntroConfig(4, 4),
    StructuralFamily.AMAPIANO: DjIntroConfig(16, 16),
    StructuralFamily.POP_RADIO: DjIntroConfig(4, 4),
    StructuralFamily.POP_STANDARD: DjIntroConfig(4, 4),
}

_DEFAULT_DJ_BARS = DjIntroConfig(4, 4)

_DJ_ALLOWED_FAMILIES: Final[frozenset[StructuralFamily]] = frozenset(
    {
        StructuralFamily.TRAP,
        StructuralFamily.HIPHOP,
        StructuralFamily.AMAPIANO,
        StructuralFamily.POP_RADIO,
        StructuralFamily.POP_STANDARD,
    }
)


def dj_bar_config_for(family: StructuralFamily) -> DjIntroConfig:
    return _DJ_BAR_TABLE.get(family, _DEFAULT_DJ_BARS)


def dj_mix_allowed_for_family(family: StructuralFamily) -> bool:
    if is_edm_family(family):
        return True
    return family in _DJ_ALLOWED_FAMILIES


def primary_genre_with_dj_tool_modifier(
    *,
    primary_genre: str,
    dj_intro_mix_in: bool,
    dj_outro_mix_out: bool,
    family: StructuralFamily,
) -> str:
    base = (primary_genre or "").strip()
    if not base:
        return base
    if not dj_mix_allowed_for_family(family):
        return base
    if not dj_intro_mix_in and not dj_outro_mix_out:
        return base
    return f"{base}, DJ Tool, Club Mix"


def _v45_impl(*, intro_bars: int, outro_bars: int) -> str:
    return (
        "DJ arc (v4.5): Block 1 early positive framing + closing clause; Block 2 "
        "content-rich bookends with follow-up staging brackets — wordless "
        "percussion building layer by layer, sonic language is primary "
        f"(~{intro_bars}-bar intro / ~{outro_bars}-bar outro soft)."
    )


def _v5_bracket_hint(*, dj_intro: bool, dj_outro: bool) -> str:
    parts = ["v5: keep each DJ bracket to a single descriptor"]
    if dj_intro:
        parts.append("intro tag opens Block 2")
    if dj_outro:
        parts.append("outro tag + [End] close Block 2")
    return "; ".join(parts) + "."


def _v55_bracket_hint(*, dj_intro: bool, dj_outro: bool) -> str:
    parts = [
        "v5.5: render the DJ bookend brackets above as full multi-descriptor "
        "director's notes"
    ]
    if dj_intro:
        parts.append("intro names its layers one by one")
    if dj_outro:
        parts.append("outro names each layer as it fades")
    return "; ".join(parts) + "."


def build_dj_mix_user_block(
    *,
    dj_intro_mix_in: bool,
    dj_outro_mix_out: bool,
    suno_version: str,
    primary_genre: str = "",
    fusion_genre: str = "",
    commercial_lane: str = "",
    v2_unified_output: bool = False,
) -> str:
    if not dj_intro_mix_in and not dj_outro_mix_out:
        return ""

    family = resolve_structural_family(
        primary_genre or "",
        fusion=fusion_genre or "",
        commercial_lane=commercial_lane or None,
    )
    if not dj_mix_allowed_for_family(family):
        return ""

    v = (suno_version or "").strip().lower()
    from app.suno_version import density_key_for, is_rich_density

    key = density_key_for(suno_version)
    is_v45 = key == "v4.5"
    is_v55 = is_rich_density(suno_version)
    is_v5 = key == "v5.0"
    use_v2_impl = v2_unified_output or is_v5 or is_v55
    bars = dj_bar_config_for(family)

    lines = [
        "[PRODUCTION REQUIREMENT: DJ-FRIENDLY STRUCTURE]",
        "(MANDATORY SECTION 1F: name the playing instruments — Suno renders "
        "what you describe. Say \"wordless\", \"percussion-only\", never "
        "\"no vocals / no melody\" phrasing.)",
    ]

    if dj_intro_mix_in:
        lines.extend(
            [
                "",
                DJ_INTRO_ON_TOKEN,
                (
                    "- Block 1 first 40 words: built for club mix-in blending — opens "
                    "with an extended wordless percussion intro (kick loop, closed hats, "
                    "shaker groove, layers building one by one into Verse 1; "
                    f"~{bars.intro_bars} bars soft)."
                ),
                (
                    "- Block 2 FIRST: [Instrumental Intro: four-on-the-floor kick "
                    "loop, closed hi-hats, shaker groove, extended wordless club mix-in] "
                    "then 1–2 follow-up staging brackets ([Percussion Build: …], "
                    "[Riser: …]) so the intro fills real time. Zero lyric lines inside "
                    "the intro region; first lyric tag is [Verse 1]."
                ),
            ]
        )

    if dj_outro_mix_out:
        lines.extend(
            [
                "",
                DJ_OUTRO_ON_TOKEN,
                (
                    "- Block 1 closing clause: outro rides kick and hats into a long "
                    f"loopable fade (~{bars.outro_bars} bars soft)."
                ),
                (
                    "- Block 2 LAST: [Instrumental Outro: kick and hats groove, "
                    "synth layers fading one by one, long loopable mix-out] then "
                    "[Fade Out: percussion slowly dissolves to a lone kick, loop-ready "
                    "tail] → [End]. Zero lyric lines or ad-libs in the outro region."
                ),
            ]
        )

    if not is_v45:
        lines.append(DJ_MIX_BRIEF_ROUTING if use_v2_impl else DJ_MIX_IMPL_V1)
    elif dj_intro_mix_in or dj_outro_mix_out:
        lines.append(
            _v45_impl(intro_bars=bars.intro_bars, outro_bars=bars.outro_bars)
        )

    if is_v5 and (dj_intro_mix_in or dj_outro_mix_out):
        lines.append(
            _v5_bracket_hint(dj_intro=dj_intro_mix_in, dj_outro=dj_outro_mix_out)
        )

    if is_v55 and (dj_intro_mix_in or dj_outro_mix_out):
        lines.append(
            _v55_bracket_hint(dj_intro=dj_intro_mix_in, dj_outro=dj_outro_mix_out)
        )

    out = "\n".join(lines).strip()
    if len(out) > DJ_MIX_USER_BLOCK_CHAR_CAP:
        raise AssertionError(
            f"DJ directive total {len(out)} exceeds "
            f"{DJ_MIX_USER_BLOCK_CHAR_CAP}-char cap"
        )
    return out
