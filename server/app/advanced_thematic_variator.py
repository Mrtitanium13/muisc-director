"""Advanced thematic variator — runtime guardrails for genre lanes."""

from __future__ import annotations

TOKEN_BLACKLIST: tuple[str, ...] = (
    "neon",
    "cyber",
    "dancefloor",
    "coffee",
    "dashboard",
    "taillights",
    "phone screen",
    "taillight",
    "melancholy drive",
    "car ride",
    "highway tears",
    "club night",
    "hands up",
    "put your hands up",
)

TACTILE_ANCHOR_TOKENS: tuple[str, ...] = (
    "chrome",
    "monochrome",
    "receipts",
    "poker face",
    "concrete",
    "fluorescent",
    "turnstile",
    "linoleum",
    "elevator mirror",
    "subway tile",
    "glass partition",
    "stainless steel",
)

SONGWRITING_ARCHETYPES: dict[str, tuple[str, str]] = {
    "psychological_subtext": (
        "Psychological Subtext",
        "Write beneath the surface: unspoken tension, withheld confession, "
        "body-language cues over exposition. One concrete object carries the emotional weight.",
    ),
    "architectural_realism": (
        "Architectural Realism",
        "Ground every image in built space: corridors, loading bays, service elevators, "
        "receipt printers, security glass. Industrial realism — no fantasy gloss.",
    ),
    "late_night_realist": (
        "Late Night Realist",
        "After-midnight pragmatism: fluorescent hum, empty lobbies, last trains, "
        "vending-machine light. Emotion through routine detail, not melodrama.",
    ),
}

_AMAPIANO_LANES = (
    "amapiano",
    "private school amapiano",
    "private school",
    "yanos",
    "piano amapiano",
    "organic amapiano",
    "afro house",
    "amapiano-vinahouse",
)

AMAPIANO_ARCHETYPES: dict[str, tuple[str, str]] = {
    "spatial_late_night": (
        "Spatial Late-Night Imagery",
        "Contemporary urban night scenes — veranda breeze, okada at the corner, plastic chair on the step, "
        "gold rings, late shifts. Emotion through spatial detail, not melodrama.",
    ),
    "log_drum_build": (
        "Log Drum Build Authority",
        "Rhythmic spacious repetition through intro and verse; reserve density for "
        "percussion breakdown and [Drop: Heavy Rolling Log Drum] chant triggers.",
    ),
    "private_school_groove": (
        "Private School Groove",
        "Atmospheric Rhodes/shaker intros, intimate close-mic English delivery, "
        "soulful chorus stacks, jazzy bridge isolation before the drop.",
    ),
}

AMAPIANO_POP_CLICHE_BAN = (
    "vows",
    "committing sin",
    "forever and always",
    "meant to be",
    "she was nineteen",
    "i was seventeen",
    "she was seventeen",
)

_FUTURE_HOUSE_LANES = (
    "future house",
    "future-house",
    "future_house",
    "bass house",
    "uk house",
)

_HARDSTYLE_LANES = (
    "hardstyle",
    "rawstyle",
    "euphoric hardstyle",
    "hard bounce",
    "edm bounce",
)


from app.big_room_fusion_progressive_vocal_lyric_engine import is_big_room_fusion_lane


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def is_future_house_lane(primary: str, fusion: str = "") -> bool:
    blob = _genre_blob(primary, fusion)
    return any(lane in blob for lane in _FUTURE_HOUSE_LANES)


def is_hardstyle_lane(primary: str, fusion: str = "") -> bool:
    blob = _genre_blob(primary, fusion)
    return any(lane in blob for lane in _HARDSTYLE_LANES)


def select_archetype(seed: str = "") -> str:
    keys = list(SONGWRITING_ARCHETYPES.keys())
    s = seed.strip().lower()
    hash_val = 0
    for ch in s:
        hash_val = (hash_val * 31 + ord(ch)) & 0xFFFFFFFF
    return keys[hash_val % len(keys)]


def is_amapiano_lane(primary: str, fusion: str = "") -> bool:
    blob = _genre_blob(primary, fusion)
    return any(lane in blob for lane in _AMAPIANO_LANES)


def select_amapiano_archetype(seed: str = "") -> str:
    keys = list(AMAPIANO_ARCHETYPES.keys())
    s = seed.strip().lower()
    hash_val = 0
    for ch in s:
        hash_val = (hash_val * 31 + ord(ch)) & 0xFFFFFFFF
    return keys[hash_val % len(keys)]


def resolve_thematic_profile(primary: str, fusion: str = "") -> str | None:
    if is_hardstyle_lane(primary, fusion):
        return "hardstyle"
    if is_amapiano_lane(primary, fusion):
        return "amapiano"
    if is_big_room_fusion_lane(primary_genre=primary, sub_genre_fusion=fusion):
        return "big_room_fusion"
    if is_future_house_lane(primary, fusion):
        return "future_house"
    return None


def build_thematic_guardrails(
    profile: str,
    *,
    primary: str = "",
    fusion: str = "",
    vibe: str = "",
) -> str:
    if profile == "big_room_fusion" or is_big_room_fusion_lane(
        primary_genre=primary,
        sub_genre_fusion=fusion,
    ):
        hands_ban = ", ".join(t for t in TOKEN_BLACKLIST if "hands" in t)
        return "\n".join(
            [
                "ADVANCED THEMATIC GUARDRAILS — BIG ROOM FUSION / PROGRESSIVE HOUSE (runtime constraint):",
                "1. VERSE: internal conversational realism — short blunt lines, intimate psychological state; "
                "no forced scene/time backdrops unless user supplied.",
                "2. BUILD: ascending repetitive hook fragments and vowel extension — chop-ready cells, "
                "not travelogue narration.",
                "3. PRE-DROP: ONE sharp 2–5 syllable command or emotionally heavy phrase before supersaw impact.",
                "4. DROP: anthem mantra/chop loops only — no flowing narrative sentences.",
                f"5. BAN DJ-callout filler ({hands_ban}, feel the beat, we're going higher, infinite skies) "
                "and sci-fi/rave metaphors.",
            ]
        )

    if profile == "future_house" or is_future_house_lane(primary, fusion):
        archetype = select_archetype(f"{primary}|{fusion}|{vibe}")
        label, directive = SONGWRITING_ARCHETYPES[archetype]
        anchors = ", ".join(TACTILE_ANCHOR_TOKENS[:4])
        return "\n".join(
            [
                "ADVANCED THEMATIC GUARDRAILS — FUTURE HOUSE (runtime constraint):",
                f"1. BLACKLIST (zero tolerance): {', '.join(TOKEN_BLACKLIST)}.",
                "2. BAN generic AI buzzwords, car-melancholy loops, and club-hands-up filler.",
                f"3. ARCHETYPE (mandatory): {label} — {directive}",
                (
                    "4. TACTILE TOKENS: weave at least two of: "
                    f"{anchors} (plus chrome, monochrome, receipts, poker face)."
                ),
                (
                    "5. STYLE: high-tier pop-house songwriting — industrial realism, "
                    "punchy pre-drop cues, controlled delivery."
                ),
            ]
        )

    if profile == "hardstyle" or is_hardstyle_lane(primary, fusion):
        return "\n".join(
            [
                "ADVANCED THEMATIC GUARDRAILS — HARDSTYLE (runtime constraint):",
                "1. DYNAMIC SHIFT: [Breakdown] = vulnerable spoken confession; "
                "[Build-up] = cold defiant survival/determination.",
                "2. PRE-DROP: ONE yelled/screamed command word only "
                "(e.g. BREATHE, NEVER, GO) — allowed here even if delivery elsewhere is controlled.",
                "3. BAN melodramatic clichés: we own the night, ghosts pulling near, "
                "strobe light flash, destroy the grid, hollows out my chest cavity.",
                "4. BAN sci-fi/rave metaphors and forced scene/time backdrops.",
                "5. Drop sections: chop/mantra cells only — no flowing poetic sentences.",
            ]
        )

    if profile == "amapiano" or is_amapiano_lane(primary, fusion):
        archetype = select_amapiano_archetype(f"{primary}|{fusion}|{vibe}")
        label, directive = AMAPIANO_ARCHETYPES[archetype]
        return "\n".join(
            [
                "ADVANCED THEMATIC GUARDRAILS — AMAPIANO / PRIVATE SCHOOL (runtime constraint):",
                f"1. POP CLICHÉ BAN: {', '.join(AMAPIANO_POP_CLICHE_BAN)}.",
                "2. English-dominant canvas; cadence/structure from amapianoDataset.json only — never copy hooks.",
                f"3. ARCHETYPE (mandatory): {label} — {directive}",
                "4. LOG DRUM IS KING: soulful keys → [Percussion Breakdown] → [Drop: Heavy Rolling Log Drum].",
                "5. Keep builds spacious and repetitive; do not overcrowd bars before the drop.",
                (
                    "6. COMMERCIAL ORDER: Intro → V1 → Chorus → V2 → Chorus → Bridge → "
                    "Breakdown → Drop → Final Chorus → Outro (Verse 2 BEFORE second Chorus)."
                ),
            ]
        )

    return ""


def advanced_thematic_variator_block(
    *,
    primary: str = "",
    fusion: str = "",
    vibe: str = "",
) -> str:
    profile = resolve_thematic_profile(primary, fusion)
    if not profile:
        return ""
    return build_thematic_guardrails(
        profile,
        primary=primary,
        fusion=fusion,
        vibe=vibe,
    )
