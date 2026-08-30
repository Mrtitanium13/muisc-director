"""Vibe brief vs source-text-for-lyrics user-block lines (mirrors Dart PromptFlowData)."""

from __future__ import annotations

import re
from typing import NamedTuple

_CUSTOM_LABEL = "Custom"

_MOOD_TONES = [
    "Euphoric",
    "Kinetic",
    "Hypnotic",
    "Brooding",
    "Yearning",
    "Defiant",
    "Meditative",
    "Frenetic",
    "Sensual",
    "Anthemic",
    "Introspective",
    "Dark",
    "Joyful",
    "Melancholic",
    "Cyberpunk",
    "Existential",
    "Aggressive",
    "Triumphant",
    "Rustic",
    "Nostalgic",
    "Rebellious",
    "Vulnerable",
    "Empowered",
    "Seductive",
    "Playful",
    "Bittersweet",
    "Dreamy",
    "Wistful",
    "Hopeful",
    "Tense",
    "Cinematic",
    _CUSTOM_LABEL,
]

_GROOVE_FEELS_BY_GENRE: dict[str, list[str]] = {
    "default": [
        "Standard 4/4",
        "Relaxed",
        "Driving",
        "Swung",
        "Syncopated",
        "Shuffle",
        "Half-time feel",
        _CUSTOM_LABEL,
    ],
    "edm": [
        "Four-on-the-floor",
        "Breakbeat",
        "Driving trance gate",
        "Pounding hardstyle kick",
        "Hypnotic grid",
        "Pumping sidechain",
        "Half-time feel",
        "Rolling bassline",
        "Stutter groove",
        "Uplifting build",
        _CUSTOM_LABEL,
    ],
    "dnb": [
        "Breakbeat",
        "Amen chop feel",
        "Rolling sub-bass drive",
        "Half-time DnB",
        "Liquid roller",
        _CUSTOM_LABEL,
    ],
    "hardstyle": [
        "Pounding hardstyle kick",
        "Reverse-bass pump",
        "Festival mainstage drive",
        "Euphoric build energy",
        "Rawstyle kick drive",
        _CUSTOM_LABEL,
    ],
    "hiphop": [
        "Boom-bap",
        "Trap hi-hat rolls",
        "Swung Dilla feel",
        "Laid-back G-funk",
        "Sliding 808s",
        "Half-time feel",
        "Drill bounce",
        "Jersey club kick pattern",
        "Memphis pocket",
        _CUSTOM_LABEL,
    ],
    "amapiano": [
        "Syncopated log-drum",
        "Log drum bounce",
        "Offbeat bounce grooves",
        "Shuffled hats",
        "Private school piano glide",
        _CUSTOM_LABEL,
    ],
    "afrobeats": [
        "Syncopated log-drum",
        "Offbeat bounce grooves",
        "Talking drum pocket",
        "Driving loops",
        "Highlife guitar pocket",
        _CUSTOM_LABEL,
    ],
    "jazz": [
        "Swing",
        "Latin feel (Bossa/Samba)",
        "Ballad feel",
        "Walking bassline",
        "Swung 16ths",
        "Modal jazz float",
        _CUSTOM_LABEL,
    ],
    "rock": [
        "Driving rock beat",
        "Half-time shuffle",
        "Punk rock energy",
        "Power ballad",
        "Acoustic strum pocket",
        "Double-kick thrash",
        _CUSTOM_LABEL,
    ],
    "country": [
        "Acoustic strum pocket",
        "Two-step country swing",
        "Gospel country lift pocket",
        "Driving rock beat",
        "Train beat",
        _CUSTOM_LABEL,
    ],
    "gospel": [
        "Call-and-response pocket",
        "Worship lift build",
        "Gospel country lift pocket",
        "Ballad feel",
        "Clap-along praise pocket",
        _CUSTOM_LABEL,
    ],
    "latin": [
        "Dem bow drum grid",
        "Salsa clave pocket",
        "Bachata romantic sway",
        "Offbeat bounce grooves",
        "Cumbia guacharaca pulse",
        "Merengue tambora drive",
        "Baile funk bounce",
        "Reggaeton perreo pocket",
        _CUSTOM_LABEL,
    ],
    "pop": [
        "Four-on-the-floor",
        "Driving loops",
        "Half-time feel",
        "Standard 4/4",
        "Trap-pop pocket",
        _CUSTOM_LABEL,
    ],
    "rnb": [
        "Slow jam pocket",
        "Bouncy 808/R&B",
        "Two-step",
        "Trap-soul groove",
        "Half-time feel",
        _CUSTOM_LABEL,
    ],
    "cinematic": [
        "Ballad feel",
        "Driving loops",
        "Half-time feel",
        "Relaxed",
        "Epic crescendo pulse",
        _CUSTOM_LABEL,
    ],
    "reggae": [
        "One drop",
        "Steppers",
        "Rockers",
        "Offbeat skank",
        _CUSTOM_LABEL,
    ],
    "funk": [
        "Pocket",
        "Four-on-the-floor funk",
        "Swung 16ths",
        "Slap bass bounce",
        _CUSTOM_LABEL,
    ],
    "soul": [
        "Slow 6/8 feel",
        "Shuffle",
        "Backbeat pocket",
        "Ballad feel",
        _CUSTOM_LABEL,
    ],
    "blues": [
        "Shuffle",
        "Slow blues",
        "Boogie",
        "Walking bassline",
        _CUSTOM_LABEL,
    ],
    "folk": [
        "Fingerpick pocket",
        "Strum-forward",
        "Waltz feel",
        "Ballad feel",
        _CUSTOM_LABEL,
    ],
    "electronic_experimental": [
        "Glitch stutter",
        "Ambient drift",
        "Industrial grid",
        "IDM breakbeat",
        _CUSTOM_LABEL,
    ],
}

_ERA_SCENES_BY_GENRE: dict[str, list[str]] = {
    "default": [
        "Modern club/streaming",
        "Late-night studio session",
        "Festival main stage",
        "Intimate bedroom session",
        "DIY basement session",
        _CUSTOM_LABEL,
    ],
    "edm": [
        "Modern club/streaming",
        "Afterlife Melodic Techno vibe",
        "Festival Hardstyle Mainstage",
        "90s Detroit techno",
        "Late-70s disco",
        "Early-80s boogie",
        "Mid-2000s UK Funky",
        "Ibiza sunrise set",
        "Warehouse rave",
        _CUSTOM_LABEL,
    ],
    "dnb": [
        "90s jungle warehouse",
        "Liquid lounge session",
        "Festival bass tent",
        "Modern club/streaming",
        _CUSTOM_LABEL,
    ],
    "hardstyle": [
        "Festival Hardstyle Mainstage",
        "Defqon.1-style arena",
        "European rave heritage",
        "Rawstyle underground",
        _CUSTOM_LABEL,
    ],
    "hiphop": [
        "Golden-era boom bap",
        "Dark plugg mood",
        "Modern trap streaming era",
        "90s West Coast cruise",
        "Drill street cipher",
        "Underground SoundCloud era",
        "Memphis phonk tape era",
        _CUSTOM_LABEL,
    ],
    "amapiano": [
        "Modern Amapiano lounge",
        "Authentic Amapiano",
        "Johannesburg late-night",
        "Yanos outdoor groove",
        _CUSTOM_LABEL,
    ],
    "afrobeats": [
        "2010s Afrobeats wave",
        "Lagos rooftop session",
        "High-energy Vinahouse",
        "Accra beach party",
        "Afro-fusion studio",
        _CUSTOM_LABEL,
    ],
    "jazz": [
        "Smoky late-night lounge",
        "Blue Note era intimacy",
        "Modern jazz club",
        "Speakeasy vinyl session",
        _CUSTOM_LABEL,
    ],
    "rock": [
        "Garage rehearsal room",
        "Stadium rock legacy",
        "Indie basement show",
        "Modern arena rock",
        _CUSTOM_LABEL,
    ],
    "country": [
        "2000s Nashville",
        "Polished modern country",
        "Gospel Country Lift",
        "Front-porch acoustic",
        "Texas honky-tonk",
        _CUSTOM_LABEL,
    ],
    "gospel": [
        "Modern Praise & Worship",
        "Soulful prayerful testimony",
        "Afro-Gospel worship",
        "Church sanctuary live",
        "Stadium worship night",
        _CUSTOM_LABEL,
    ],
    "latin": [
        "Urban Latin Pop",
        "Caribbean street party",
        "Romantic bachata night",
        "Salsa club",
        "Reggaeton block party",
        "Baile funk favela party",
        _CUSTOM_LABEL,
    ],
    "pop": [
        "Modern club/streaming",
        "2020s Saigon Pop",
        "Radio hit polish era",
        "Bedroom pop",
        "Stadium pop",
        _CUSTOM_LABEL,
    ],
    "rnb": [
        "90s slow jam",
        "Modern trap-soul bedroom",
        "Smooth neo-soul lounge",
        "00s crunk&B club",
        _CUSTOM_LABEL,
    ],
    "cinematic": [
        "Film trailer climax",
        "Orchestral scoring stage",
        "Epic game soundtrack mood",
        "Intimate indie film cue",
        _CUSTOM_LABEL,
    ],
    "reggae": [
        "Jamaican sound system",
        "Roots reggae studio",
        "Modern dancehall yard",
        "Beach sunset session",
        _CUSTOM_LABEL,
    ],
    "funk": [
        "70s P-Funk jam room",
        "Modern funk revival",
        "Gogo pocket",
        _CUSTOM_LABEL,
    ],
    "soul": [
        "Motown studio",
        "Memphis soul room",
        "Modern soul lounge",
        _CUSTOM_LABEL,
    ],
    "blues": [
        "Delta porch",
        "Chicago blues club",
        "Modern blues bar",
        _CUSTOM_LABEL,
    ],
    "folk": [
        "Front porch session",
        "Coffeehouse open mic",
        "Appalachian cabin",
        _CUSTOM_LABEL,
    ],
    "electronic_experimental": [
        "Modular synth lab",
        "Berghain basement",
        "Experimental radio room",
        _CUSTOM_LABEL,
    ],
}


def _union_lists(mapping: dict[str, list[str]]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for values in mapping.values():
        for item in values:
            if item not in seen:
                seen.add(item)
                out.append(item)
    return out


_ALL_GROOVE_FEELS = _union_lists(_GROOVE_FEELS_BY_GENRE)
_ALL_ERA_SCENES = _union_lists(_ERA_SCENES_BY_GENRE)

_SOURCE_TEXT_HEADER = (
    "[SOURCE TEXT FOR LYRICS] (ROLE: Master Lyricist/Storyteller. TASK: The following "
    "text is the raw material. Your goal is to transform its core themes, narrative, "
    "emotions, and imagery into compelling song lyrics. Deconstruct it, rephrase it, "
    "and find the musicality within the prose. STRICTLY FORBIDDEN: Do NOT simply copy "
    "the text verbatim or treat it as a descriptive note. It is the foundational "
    "content for lyrical creation.)"
)

_SCRIPTURE_NOTE = (
    "(NOTE: Source text appears to be scriptural. Maintain a tone of reverence, or "
    "adapt its message into a modern spiritual context, guided by the overall vibe "
    "and genre.)"
)

_QUOTED_NOTE = (
    "(NOTE: Source text appears to be a quotation. Preserve its intent while adapting "
    "phrasing into singable lyric form.)"
)

_SCRIPTURE_RE = re.compile(r"\b[1-3]?\s?[A-Za-z]+\s\d+[:]\d+\b")
_QUOTED_RE = re.compile(r'[“"].+[”"]')


class ParsedVibe(NamedTuple):
    mood: str | None
    era: str | None
    groove: str | None
    detail: str


def _match_in_list(raw: str, options: list[str]) -> str | None:
    lower = raw.lower().strip()
    if lower == _CUSTOM_LABEL.lower():
        return _CUSTOM_LABEL
    for option in options:
        if option.lower().strip() == lower:
            return option
    return None


def parse_stored_vibe(raw: str) -> ParsedVibe:
    text = str(raw or "").strip()
    if not text:
        return ParsedVibe(None, None, None, "")

    parts = [
        p.strip()
        for p in re.split(r"\s*[·,;\n]\s*", text)
        if p.strip()
    ]
    if not parts:
        return ParsedVibe(None, None, None, text)

    mood: str | None = None
    era: str | None = None
    groove: str | None = None
    leftovers: list[str] = []

    for part in parts:
        if mood is None:
            matched_mood = _match_in_list(part, _MOOD_TONES)
            if matched_mood is not None and matched_mood != _CUSTOM_LABEL:
                mood = matched_mood
                continue
        if era is None:
            matched_era = _match_in_list(part, _ALL_ERA_SCENES)
            if matched_era is not None and matched_era != _CUSTOM_LABEL:
                era = matched_era
                continue
        if groove is None:
            matched_groove = _match_in_list(part, _ALL_GROOVE_FEELS)
            if matched_groove is not None and matched_groove != _CUSTOM_LABEL:
                groove = matched_groove
                continue
        leftovers.append(part)

    detail = "" if not leftovers else " · ".join(leftovers)
    return ParsedVibe(mood, era, groove, detail)


def compose_vibe(
    *,
    mood: str | None = None,
    era: str | None = None,
    groove: str | None = None,
    detail: str = "",
) -> str:
    safe_detail = detail.strip().replace(" · ", " - ")
    out: list[str] = []
    if mood and mood.strip() and mood != _CUSTOM_LABEL:
        out.append(mood.strip())
    if era and era.strip() and era != _CUSTOM_LABEL:
        out.append(era.strip())
    if groove and groove.strip() and groove != _CUSTOM_LABEL:
        out.append(groove.strip())
    if safe_detail:
        out.append(safe_detail)
    return " · ".join(out)


def looks_like_scripture(text: str) -> bool:
    return bool(_SCRIPTURE_RE.search(str(text or "")))


def looks_like_quoted_text(text: str) -> bool:
    t = str(text or "").strip()
    if len(t) < 4:
        return False
    if (t.startswith('"') and t.endswith('"')) or (
        t.startswith("'") and t.endswith("'")
    ):
        return True
    return bool(_QUOTED_RE.search(t))


def build_vibe_user_block_lines(*, vibe: str, use_vibe_as_lyric_source: bool) -> list[str]:
    parts = parse_stored_vibe(vibe)
    vibe_detail = parts.detail.strip()
    core_vibe = compose_vibe(mood=parts.mood, era=parts.era, groove=parts.groove)
    lines: list[str] = []

    if core_vibe:
        lines.append(f"[VIBE BRIEF] (Mood · Era/Scene · Groove Feel): {core_vibe}")
    elif not use_vibe_as_lyric_source and str(vibe or "").strip():
        lines.append(
            "[VIBE BRIEF] (Mood · Era/Scene · Groove Feel · Detail): "
            f"{str(vibe).strip()}"
        )

    if use_vibe_as_lyric_source and vibe_detail:
        lines.append(_SOURCE_TEXT_HEADER)
        if looks_like_scripture(vibe_detail):
            lines.append(_SCRIPTURE_NOTE)
        elif looks_like_quoted_text(vibe_detail):
            lines.append(_QUOTED_NOTE)
        lines.append(vibe_detail)
    elif vibe_detail:
        lines.append(f"Vibe / idea detail: {vibe_detail}")

    return lines
