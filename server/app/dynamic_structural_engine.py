"""
Python port of the Dart Dynamic Structural Engine.

Mirrors:
  - lib/core/utils/dynamic_structural_engine.dart
  - lib/core/utils/structural_family_resolver.dart
  - lib/core/utils/final_chorus_mutation_rule.dart
  - lib/core/utils/structure_assembler.dart
  - lib/core/utils/suno_syntax_renderer.dart

Spec: tools/dynamic_structural_engine.txt
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from typing import Callable, List, Optional

from app.suno_version import PREFERRED, density_key_for, is_rich_density, is_wild_intent

STRUCTURAL_DENSITY_CAP = 0.30
SUNO_LYRICS_FIELD_CAP = 2500
STRUCTURAL_PREAMBLE_CAP = int(SUNO_LYRICS_FIELD_CAP * STRUCTURAL_DENSITY_CAP)


class StructuralFamily(str, Enum):
    POP_STANDARD = "popStandard"
    POP_RADIO = "popRadio"
    EDM_PROGRESSIVE_HOUSE = "edmProgressiveHouse"
    EDM_TRANCE = "edmTrance"
    EDM_TECHNO = "edmTechno"
    EDM_HARDSTYLE = "edmHardstyle"
    EDM_DRUM_AND_BASS = "edmDrumAndBass"
    EDM_BIG_ROOM = "edmBigRoom"
    HIPHOP = "hiphop"
    WORSHIP = "worship"
    AMAPIANO = "amapiano"
    CINEMATIC = "cinematic"
    FOLK = "folk"
    JAZZ_STANDARD = "jazzStandard"
    MANDOPOP = "mandopop"
    TRAP = "trap"


def is_edm_family(family: StructuralFamily) -> bool:
    return family in {
        StructuralFamily.EDM_PROGRESSIVE_HOUSE,
        StructuralFamily.EDM_TRANCE,
        StructuralFamily.EDM_TECHNO,
        StructuralFamily.EDM_HARDSTYLE,
        StructuralFamily.EDM_DRUM_AND_BASS,
        StructuralFamily.EDM_BIG_ROOM,
    }


class SongIntent(str, Enum):
    STANDARD = "standard"
    CONGREGATIONAL = "congregational"
    COMPLEX = "complex"


class FinalChorusMutation(str, Enum):
    KEY_CHANGE_OCTAVE_DOUBLE = "keyChangeAndOctaveDouble"
    AD_LIB_COUNTER_MELODY = "adLibCounterMelody"
    HALF_TIME_FEEL = "halfTimeFeel"
    GOSPEL_VAMP_CALL_AND_RESPONSE = "gospelVampCallAndResponse"
    SPONTANEOUS_FLOW_LIFT = "spontaneousFlowLift"
    BEAT_SWITCH_VARIATION = "beatSwitchVariation"
    HOOK_EXTENSION_WITH_AD_LIB_FLOOD = "hookExtensionWithAdLibFlood"
    LOG_DRUM_BASS_VARIATION = "logDrumBassVariation"
    TRUNCATION_WITH_PIANO_CODA = "truncationWithPianoCoda"
    INSTRUMENTAL_FADE_REENTRY = "instrumentalFadeReentry"
    TRUNCATION_WITH_LYRICAL_TWIST = "truncationWithLyricalTwist"


@dataclass(frozen=True)
class SongSection:
    kind: str
    label: str
    staging_note: Optional[str] = None


def resolve_structural_family(
    primary: str = "",
    fusion: str = "",
    commercial_lane: Optional[str] = None,
) -> StructuralFamily:
    """Mirror of StructuralFamilyResolver.resolve()."""
    if commercial_lane:
        return _resolve_one(commercial_lane)
    if primary:
        from_pair = _resolve_edm_from_genres(primary, fusion)
        if from_pair is not None:
            return from_pair
        return _resolve_one(primary, or_else=_try_fallback(fusion))
    if fusion:
        return _try_fallback(fusion)
    return StructuralFamily.POP_STANDARD


def resolve_structural_profile(primary: str, fusion: str = "") -> str:
    """Legacy profile key for callers expecting gospel|dance_edm|standard."""
    family = resolve_structural_family(primary, fusion)
    legacy = {
        StructuralFamily.WORSHIP: "gospel",
        StructuralFamily.FOLK: "folk_acoustic",
        StructuralFamily.HIPHOP: "hip_hop",
        StructuralFamily.EDM_PROGRESSIVE_HOUSE: "dance_edm",
        StructuralFamily.EDM_TRANCE: "dance_edm",
        StructuralFamily.EDM_TECHNO: "dance_edm",
        StructuralFamily.EDM_HARDSTYLE: "dance_edm",
        StructuralFamily.EDM_DRUM_AND_BASS: "dance_edm",
        StructuralFamily.EDM_BIG_ROOM: "dance_edm",
        StructuralFamily.AMAPIANO: "dance_edm",
        StructuralFamily.TRAP: "dance_edm",
    }
    return legacy.get(family, "standard")


def mutation_for(family: StructuralFamily) -> FinalChorusMutation:
    """Mirror of FinalChorusMutationRule.mutationFor()."""
    table = {
        StructuralFamily.POP_STANDARD: FinalChorusMutation.KEY_CHANGE_OCTAVE_DOUBLE,
        StructuralFamily.POP_RADIO: FinalChorusMutation.KEY_CHANGE_OCTAVE_DOUBLE,
        StructuralFamily.MANDOPOP: FinalChorusMutation.KEY_CHANGE_OCTAVE_DOUBLE,
        StructuralFamily.EDM_PROGRESSIVE_HOUSE: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.EDM_TRANCE: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.EDM_TECHNO: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.EDM_HARDSTYLE: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.EDM_DRUM_AND_BASS: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.EDM_BIG_ROOM: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.TRAP: FinalChorusMutation.BEAT_SWITCH_VARIATION,
        StructuralFamily.HIPHOP: FinalChorusMutation.HOOK_EXTENSION_WITH_AD_LIB_FLOOD,
        StructuralFamily.WORSHIP: FinalChorusMutation.GOSPEL_VAMP_CALL_AND_RESPONSE,
        StructuralFamily.AMAPIANO: FinalChorusMutation.LOG_DRUM_BASS_VARIATION,
        StructuralFamily.CINEMATIC: FinalChorusMutation.TRUNCATION_WITH_PIANO_CODA,
        StructuralFamily.FOLK: FinalChorusMutation.TRUNCATION_WITH_LYRICAL_TWIST,
        StructuralFamily.JAZZ_STANDARD: FinalChorusMutation.TRUNCATION_WITH_LYRICAL_TWIST,
    }
    return table.get(family, FinalChorusMutation.KEY_CHANGE_OCTAVE_DOUBLE)


def staging_note_for(mutation: FinalChorusMutation) -> str:
    notes = {
        FinalChorusMutation.KEY_CHANGE_OCTAVE_DOUBLE: (
            "key-change lift, octave-double vocal, max belt dynamic"
        ),
        FinalChorusMutation.AD_LIB_COUNTER_MELODY: (
            "ad-lib counter-melody, wider harmonies, extended vocal tail"
        ),
        FinalChorusMutation.HALF_TIME_FEEL: (
            "half-time feel, belted chest voice, stripped percussion, trailing plate decay"
        ),
        FinalChorusMutation.GOSPEL_VAMP_CALL_AND_RESPONSE: (
            "gospel call-and-response vamp, spontaneous lift, full choir belt"
        ),
        FinalChorusMutation.SPONTANEOUS_FLOW_LIFT: (
            "spontaneous flow lift, leader ad-libs, congregation response"
        ),
        FinalChorusMutation.BEAT_SWITCH_VARIATION: (
            "beat-switch to half-time final drop variation"
        ),
        FinalChorusMutation.HOOK_EXTENSION_WITH_AD_LIB_FLOOD: (
            "hook extends over fading drum break, ad-lib flood, DJ scratch tag"
        ),
        FinalChorusMutation.LOG_DRUM_BASS_VARIATION: (
            "log drum bass variation with chant accent, full groove climax"
        ),
        FinalChorusMutation.TRUNCATION_WITH_PIANO_CODA: (
            "truncation into piano coda, lingering last phrase"
        ),
        FinalChorusMutation.INSTRUMENTAL_FADE_REENTRY: (
            "instrumental fade then full-band re-entry, final hit"
        ),
        FinalChorusMutation.TRUNCATION_WITH_LYRICAL_TWIST: (
            "truncation, final lyrical twist, closing single line"
        ),
    }
    return notes[mutation]


def directive_for(
    mutation: FinalChorusMutation,
    suno_version: str,
    *,
    inline: bool = False,
) -> str:
    staging = staging_note_for(mutation)
    v = density_key_for(suno_version)
    if inline:
        if v == "v4.5":
            return ""
        if v == "v5.5":
            return staging
        return staging.split(",", 1)[0].strip()
    if v == "v4.5":
        return (
            "Final Chorus mutation: apply lyrical/dynamic mutation only — "
            "staging belongs in Block 1 prose for v4.5."
        )
    return (
        f"Final Chorus mutation ({staging}): mandatory — never copy-paste Chorus 1."
    )


def inline_staging_for(family: StructuralFamily, suno_version: str) -> str:
    """Mirror of FinalChorusMutationRule.inlineStagingFor()."""
    return directive_for(mutation_for(family), suno_version, inline=True)


def assemble_sections(
    family: StructuralFamily,
    suno_version: str = PREFERRED,
    intent: SongIntent = SongIntent.STANDARD,
    include_dj_intro: bool = False,
    include_dj_outro: bool = False,
) -> List[SongSection]:
    """Mirror of DynamicStructuralEngine.assembleSections()."""
    resolved_intent = intent
    if family == StructuralFamily.WORSHIP and resolved_intent == SongIntent.STANDARD:
        resolved_intent = SongIntent.CONGREGATIONAL
    builder = _BUILDERS[family]
    sections = builder(include_dj_outro, resolved_intent)
    if include_dj_intro and sections and sections[0].kind == "intro":
        sections = [SongSection("intro", "Intro — DJ mix-in")] + sections[1:]
    return sections


def render_sections(
    sections: List[SongSection],
    suno_version: str,
    family: Optional[StructuralFamily] = None,
) -> str:
    """Mirror of SunoSyntaxRenderer.renderSections()."""
    return "\n".join(
        _render_section(s, suno_version, family) for s in sections
    )


def enforce_density_budget(
    rendered: str,
    cap: int = STRUCTURAL_PREAMBLE_CAP,
) -> str:
    """Mirror of DensityBudgetEnforcer.enforce()."""
    if len(rendered) <= cap:
        return rendered
    lines = rendered.split("\n")
    for key in ("outro", "intro", "verse", "pre-chorus", "chorus"):
        if len("\n".join(lines)) <= cap:
            break
        lines = [_strip_staging(line, key) for line in lines]
    if len("\n".join(lines)) <= cap:
        return "\n".join(lines)
    return "\n".join(_strip_all_staging(line) for line in lines)


def user_block_directive(
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    suno_version: str = PREFERRED,
    user_sections: Optional[List[SongSection]] = None,
    commercial_lane: Optional[str] = None,
    intent: SongIntent = SongIntent.STANDARD,
    include_dj_intro: bool = False,
    include_dj_outro: bool = False,
) -> str:
    """Mirror of DynamicStructuralEngine.userBlockDirective()."""
    if user_sections:
        rendered = render_sections(user_sections, suno_version)
        return _emit_directive(
            suno_version=suno_version,
            profile="user_defined",
            roadmap="[USER-DEFINED ROADMAP]",
            rendered_sections=rendered,
        )

    family = resolve_structural_family(
        primary_genre, sub_genre_fusion, commercial_lane
    )
    sections = assemble_sections(
        family,
        suno_version,
        intent=intent,
        include_dj_intro=include_dj_intro,
        include_dj_outro=include_dj_outro,
    )
    rendered = render_sections(sections, suno_version, family)
    pruned = enforce_density_budget(rendered)
    mutation_hint = directive_for(mutation_for(family), suno_version)
    roadmap = " → ".join(s.label for s in sections)
    folk_no_drop = family == StructuralFamily.FOLK
    return _emit_directive(
        suno_version=suno_version,
        profile=family.value,
        roadmap=roadmap,
        rendered_sections=pruned,
        mutation_hint=mutation_hint,
        folk_no_drop=folk_no_drop,
    )


def dynamic_structural_user_block(
    primary: str,
    fusion: str = "",
    suno_version: str = PREFERRED,
) -> str:
    """Backwards-compatible entry used by server/app/main.py."""
    return user_block_directive(
        primary_genre=primary,
        sub_genre_fusion=fusion,
        suno_version=suno_version,
    )


# ── Internal helpers ───────────────────────────────────────────────────────────


def _resolve_edm_sub_family(n: str) -> Optional[StructuralFamily]:
    if "progressive house" in n or "prog house" in n or "progressive trance" in n:
        return StructuralFamily.EDM_PROGRESSIVE_HOUSE
    if "trance" in n or "psytrance" in n or "goa" in n or "uplifting trance" in n:
        return StructuralFamily.EDM_TRANCE
    if any(k in n for k in ("techno", "tech house", "tech-house", "minimal house", "dj house")):
        return StructuralFamily.EDM_TECHNO
    if "hardstyle" in n or "hard dance" in n:
        return StructuralFamily.EDM_HARDSTYLE
    if any(k in n for k in ("drum and bass", "drum & bass", "dnb", "jungle", "neurofunk", "liquid dnb")):
        return StructuralFamily.EDM_DRUM_AND_BASS
    if any(k in n for k in ("big room", "bigroom", "festival house", "mainstage")):
        return StructuralFamily.EDM_BIG_ROOM
    return None


def _resolve_edm_from_genres(primary: str, fusion: str = "") -> Optional[StructuralFamily]:
    for raw in (primary, fusion):
        if not raw:
            continue
        sub = _resolve_edm_sub_family(raw.lower())
        if sub is not None:
            return sub
    return None


def _resolve_one(name: str, or_else: StructuralFamily = StructuralFamily.POP_STANDARD) -> StructuralFamily:
    n = name.lower()
    edm_sub = _resolve_edm_sub_family(n)
    if edm_sub is not None:
        return edm_sub
    if "worship" in n or "gospel" in n:
        return StructuralFamily.WORSHIP
    if any(k in n for k in ("jazz", "bebop", "swing", "big band", "nu-jazz", "acid jazz")):
        return StructuralFamily.JAZZ_STANDARD
    if any(
        k in n
        for k in (
            "cinematic",
            "ambient",
            "orchestral",
            "film score",
            "trailer",
            "dark ambient",
            "vaporwave",
            "synthwave",
        )
    ):
        return StructuralFamily.CINEMATIC
    if "amapiano" in n:
        return StructuralFamily.AMAPIANO
    if any(k in n for k in ("folk", "bluegrass", "singer-songwriter", "americana", "indie folk")):
        return StructuralFamily.FOLK
    if "mandopop" in n or "c-pop" in n:
        return StructuralFamily.MANDOPOP
    if any(k in n for k in ("trap", "melodic trap", "drill", "phonk")):
        return StructuralFamily.TRAP
    if any(
        k in n
        for k in (
            "hip hop",
            "hip-hop",
            "rap",
            "boom bap",
            "lo-fi hip hop",
            "chillhop",
            "cloud rap",
            "jazz rap",
        )
    ):
        return StructuralFamily.HIPHOP
    if any(
        k in n
        for k in (
            "edm",
            "electronic",
            "house",
            "dubstep",
            "bass",
            "bounce",
            "garage",
            "future bass",
            "future house",
            "nu-disco",
            "vinahouse",
            "jersey club",
            "gqom",
        )
    ):
        return StructuralFamily.EDM_PROGRESSIVE_HOUSE
    if "pop" in n:
        return StructuralFamily.POP_STANDARD
    if any(k in n for k in ("rock", "metal", "punk", "shoegaze", "emo", "alt rock", "post-rock")):
        return StructuralFamily.POP_STANDARD
    if any(k in n for k in ("r&b", "rnb", "soul", "funk", "neo-soul", "quiet storm", "new jack", "trap soul")):
        return StructuralFamily.POP_STANDARD
    if "country" in n:
        return StructuralFamily.POP_STANDARD
    if any(
        k in n
        for k in (
            "reggae",
            "dub",
            "dancehall",
            "reggaeton",
            "latin",
            "bachata",
            "salsa",
            "cumbia",
            "forró",
            "sertanejo",
            "bossa nova",
        )
    ):
        return StructuralFamily.POP_RADIO
    return or_else


def _try_fallback(fusion: str) -> StructuralFamily:
    if not fusion:
        return StructuralFamily.POP_STANDARD
    return _resolve_one(fusion)


def _sanitise_staging(s: str) -> str:
    banned = [
        "eq",
        "compression",
        "bus routing",
        "sidechain",
        "mastering",
        "limiter",
        "automation",
        "daw",
        "plugin",
        "vst",
    ]
    out = s
    for b in banned:
        out = re.sub(b, "", out, flags=re.IGNORECASE)
    return re.sub(r",\s*,", ",", out).strip()


def _default_staging(kind: str) -> str:
    defaults = {
        "intro": "sonic world establish",
        "verse": "sparse instrumentation, ground the listener",
        "preChorus": "accelerate, rising tension",
        "chorus": "full vocal width, maximum hook",
        "hook": "lead hook repeat",
        "bridge": "the turn, strip back or shift feel",
        "breakdown": "stripped atmospheric space",
        "buildUp": "rising white noise, snare roll tension",
        "drop": "signature instrument / hook land",
        "finalChorus": "key-change lift, max dynamics",
        "finalDrop": "second half-time variation",
        "vamp": "congregational call-and-response",
        "spontaneousFlow": "leader ad-libs over chord",
        "interlude": "instrumental interlude",
        "solo": "instrumental solo",
        "outro": "decay / fade / tag",
        "end": "",
    }
    return defaults.get(kind, "")


def _render_section(
    section: SongSection,
    suno_version: str,
    family: Optional[StructuralFamily],
) -> str:
    v = density_key_for(suno_version)
    if section.kind == "end":
        return "[End]"
    staging = section.staging_note or _default_staging(section.kind)
    if section.kind in ("finalChorus", "finalDrop") and family is not None:
        inline = directive_for(mutation_for(family), suno_version, inline=True)
        if inline:
            staging = inline
    if v == "v4.5":
        return f"[{section.label}]"
    if v == "v5.5":
        clean = _sanitise_staging(staging)
        return f"[{section.label}: {clean}]" if clean else f"[{section.label}]"
    first = staging.split(",")[0].strip()
    clean = _sanitise_staging(first)
    return f"[{section.label}: {clean}]" if clean else f"[{section.label}]"


def _syntax_doc_block(suno_version: str) -> str:
    key = density_key_for(suno_version)
    raw = (suno_version or PREFERRED).strip().lower()
    if key == "v4.5":
        return (
            "v4.5 syntax: [Brackets] = section names ONLY (1–2 words). "
            "(Parentheses) = vocal delivery 1–3 words. "
            "NO production cues in brackets — Block 1 prose only."
        )
    if key == "v5.5":
        label = (
            "v6-wild rich syntax"
            if is_wild_intent(raw)
            else ("v6 rich syntax (flagship)" if raw.startswith("v6") else "v5.5 PRO syntax")
        )
        return (
            f"{label}: [Brackets] = cinematic director's notes "
            "(multi-descriptor). (Parentheses) = granular vocal/phonetic cues including "
            "(sigh), (chuckles), (trailing off...). Cross-rules: no nested brackets; "
            "no DAW jargon in brackets; always [End]."
        )
    label = "v6-mini hybrid syntax" if raw.startswith("v6") else "v5 syntax"
    return (
        f"{label}: [Brackets] = section + ONE staging descriptor. "
        "(Parentheses) = vocal cues + phonetics + brief ad-libs. "
        "Cross-rules: no nested brackets; no mix notes in parens; always [End]."
    )


def _emit_directive(
    *,
    suno_version: str,
    profile: str,
    roadmap: str,
    rendered_sections: str,
    mutation_hint: str = "",
    folk_no_drop: bool = False,
) -> str:
    max_arc = (
        "v5.5_max_arc=true (full ~4-min single-pass allowed)"
        if is_rich_density(suno_version)
        else "v5.5_max_arc=false"
    )
    folk_note = " — STRICTLY NO [Drop] modules." if folk_no_drop else ""
    mutation_block = f"{mutation_hint}\n" if mutation_hint else ""
    return (
        "DYNAMIC STRUCTURAL ENGINE (Block 2 — assembled & pruned, never static):\n"
        f"{_syntax_doc_block(suno_version)}\n"
        f"{max_arc}\n"
        f"Resolved structural family: {profile}\n"
        f"Section roadmap: {roadmap}{folk_note}\n\n"
        "RENDERED BRACKET LAYOUT (use these exact bracket lines, in this order):\n"
        f"{rendered_sections}\n\n"
        f"{mutation_block}"
        "SHIP GATE: output ONLY the structure + performable lyrics through [End]. "
        "No meta-commentary. No DAW jargon. No nested brackets. "
        "Vocal/phonetic cues go in (parentheses) only. "
        "Structure/staging goes in [brackets] only."
    ).strip()


def _strip_staging(line: str, key: str) -> str:
    lower = line.lower()
    if not lower.startswith(f"[{key}") or ":" not in line:
        return line
    idx = line.index(":")
    return f"{line[:idx]}]"


def _strip_all_staging(line: str) -> str:
    if ":" not in line:
        return line
    idx = line.index(":")
    close = line.rfind("]")
    if close > idx:
        return f"{line[:idx]}]"
    return line


def _sec(kind: str, label: str, staging: Optional[str] = None) -> SongSection:
    return SongSection(kind=kind, label=label, staging_note=staging)


def _build_pop_standard(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — mix-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("preChorus", "Pre-Chorus"),
        _sec("chorus", "Chorus"),
        _sec("verse", "Verse 2"),
        _sec("preChorus", "Pre-Chorus"),
        _sec("chorus", "Chorus"),
        _sec("bridge", "Bridge"),
        _sec("finalChorus", "Final Chorus"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_pop_radio(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — mix-out" if dj_outro else "Outro"
    return [
        _sec("verse", "Verse 1"),
        _sec("chorus", "Chorus"),
        _sec("verse", "Verse 2"),
        _sec("chorus", "Chorus"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_progressive_house(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Verse"),
        _sec("buildUp", "Build-up"),
        _sec("dropA", "Drop A"),
        _sec("breakdown", "Breakdown"),
        _sec("buildUp", "Build-up 2"),
        _sec("dropB", "Drop B"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_trance(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("buildUp", "Build-up"),
        _sec("dropA", "Drop A"),
        _sec("atmosphericBreak", "Atmospheric Break"),
        _sec("buildUp", "Build-up 2", staging="euphoric riser"),
        _sec("finalDrop", "Final Drop"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_techno(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("buildUp", "Build-up"),
        _sec("mainDrop", "Main Drop"),
        _sec("breakdown", "Breakdown"),
        _sec("buildUp", "Build-up 2"),
        _sec("mainDrop", "Main Drop 2"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_hardstyle(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("buildUp", "Build-up"),
        _sec("antiClimax", "Anti-Climax"),
        _sec("mainDrop", "Main Drop", staging="distorted hardstyle kick"),
        _sec("breakdown", "Breakdown", staging="melodic synth lead"),
        _sec("finalDrop", "Final Drop"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_drum_and_bass(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("buildUp", "Build-up"),
        _sec("dropA", "Drop A"),
        _sec("breakdown", "Breakdown"),
        _sec("buildUp", "Build-up 2"),
        _sec("finalDrop", "Final Drop"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_edm_big_room(dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    outro = "Outro — DJ loop-out" if dj_outro else "Outro"
    return [
        _sec("intro", "Intro"),
        _sec("buildUp", "Build-up"),
        _sec("mainDrop", "Main Drop"),
        _sec("breakdown", "Breakdown"),
        _sec("riser", "Riser"),
        _sec("finalDrop", "Final Drop"),
        _sec("outro", outro),
        _sec("end", "End"),
    ]


def _build_hiphop(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("hook", "Hook"),
        _sec("verse", "Verse 2"),
        _sec("hook", "Hook"),
        _sec("bridge", "Bridge"),
        _sec("hook", "Hook"),
        _sec("outro", "Outro"),
        _sec("end", "End"),
    ]


def _build_worship(_dj_outro: bool, intent: SongIntent) -> List[SongSection]:
    sections = [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("chorus", "Chorus"),
        _sec("verse", "Verse 2"),
        _sec("chorus", "Chorus"),
        _sec("bridge", "Bridge"),
    ]
    if intent == SongIntent.CONGREGATIONAL:
        sections.append(_sec("vamp", "Vamp"))
    sections.extend(
        [
            _sec("spontaneousFlow", "Spontaneous Flow"),
            _sec("finalChorus", "Final Chorus"),
            _sec("outro", "Outro"),
            _sec("end", "End"),
        ]
    )
    return sections


def _build_amapiano(_dj_outro: bool, intent: SongIntent) -> List[SongSection]:
    sections = [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("chorus", "Chorus"),
        _sec("verse", "Verse 2"),
    ]
    if intent == SongIntent.COMPLEX:
        sections.append(_sec("bridge", "Bridge"))
    sections.extend(
        [
            _sec("chorus", "Chorus"),
            _sec("breakdown", "Breakdown"),
            _sec("finalChorus", "Final Chorus"),
            _sec("outro", "Outro"),
            _sec("end", "End"),
        ]
    )
    return sections


def _build_cinematic(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Theme A"),
        _sec("interlude", "Development"),
        _sec("drop", "Climax"),
        _sec("outro", "Coda"),
        _sec("end", "End"),
    ]


def _build_folk(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("chorus", "Chorus"),
        _sec("interlude", "Instrumental Interlude"),
        _sec("verse", "Verse 2"),
        _sec("chorus", "Chorus"),
        _sec("bridge", "Bridge"),
        _sec("finalChorus", "Final Chorus"),
        _sec("outro", "Outro"),
        _sec("end", "End"),
    ]


def _build_jazz(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("verse", "A Section (Head)"),
        _sec("verse", "A Section"),
        _sec("bridge", "B Section (Middle Eight)"),
        _sec("verse", "A Section (Head Return)"),
        _sec("solo", "Instrumental Solo"),
        _sec("outro", "Head Out"),
        _sec("end", "End"),
    ]


def _build_mandopop(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("intro", "Intro"),
        _sec("verse", "Verse 1"),
        _sec("preChorus", "Pre-Chorus"),
        _sec("chorus", "Chorus"),
        _sec("verse", "Verse 2"),
        _sec("preChorus", "Pre-Chorus"),
        _sec("chorus", "Chorus"),
        _sec("bridge", "Bridge"),
        _sec("finalChorus", "Final Chorus"),
        _sec("outro", "Outro"),
        _sec("end", "End"),
    ]


def _build_trap(_dj_outro: bool, _intent: SongIntent) -> List[SongSection]:
    return [
        _sec("intro", "Intro"),
        _sec("hook", "Hook"),
        _sec("verse", "Verse 1"),
        _sec("hook", "Hook"),
        _sec("verse", "Verse 2"),
        _sec("bridge", "Bridge (beat-switch)"),
        _sec("hook", "Hook"),
        _sec("outro", "Outro"),
        _sec("end", "End"),
    ]


_BUILDERS: dict[StructuralFamily, Callable[[bool, SongIntent], List[SongSection]]] = {
    StructuralFamily.POP_STANDARD: _build_pop_standard,
    StructuralFamily.POP_RADIO: _build_pop_radio,
    StructuralFamily.EDM_PROGRESSIVE_HOUSE: _build_edm_progressive_house,
    StructuralFamily.EDM_TRANCE: _build_edm_trance,
    StructuralFamily.EDM_TECHNO: _build_edm_techno,
    StructuralFamily.EDM_HARDSTYLE: _build_edm_hardstyle,
    StructuralFamily.EDM_DRUM_AND_BASS: _build_edm_drum_and_bass,
    StructuralFamily.EDM_BIG_ROOM: _build_edm_big_room,
    StructuralFamily.HIPHOP: _build_hiphop,
    StructuralFamily.WORSHIP: _build_worship,
    StructuralFamily.AMAPIANO: _build_amapiano,
    StructuralFamily.CINEMATIC: _build_cinematic,
    StructuralFamily.FOLK: _build_folk,
    StructuralFamily.JAZZ_STANDARD: _build_jazz,
    StructuralFamily.MANDOPOP: _build_mandopop,
    StructuralFamily.TRAP: _build_trap,
}
