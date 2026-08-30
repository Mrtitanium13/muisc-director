"""Cross-genre thick / humanized vocal presence for Suno Block 1 + Block 2."""

from __future__ import annotations

import re
from enum import Enum

from app.vocal_spec_tone import (
    RAP_VOCAL_SPACE_SPEC,
    coerce_spec,
    is_choir,
    is_instrumental_only,
)

_PUNCT_RE = re.compile(r"[^\w\s&]+", re.UNICODE)
_WS_RE = re.compile(r"\s+")


class VocalFamily(str, Enum):
    EDM_DENSE = "edm_dense"
    HIP_HOP = "hip_hop"
    GOSPEL = "gospel"
    AFRO = "afro"
    ASIAN_POP = "asian_pop"
    RNB = "rnb"
    ACOUSTIC = "acoustic"
    ROCK = "rock"
    LATIN = "latin"
    POP = "pop"
    UNKNOWN = "unknown"

    @property
    def display_name(self) -> str:
        return {
            VocalFamily.EDM_DENSE: "EDM Dense / Festival / Hard Dance",
            VocalFamily.HIP_HOP: "Hip-Hop / Trap / Boom Bap",
            VocalFamily.GOSPEL: "Gospel / Worship",
            VocalFamily.AFRO: "Afro / Amapiano",
            VocalFamily.ASIAN_POP: "Asian Pop",
            VocalFamily.RNB: "R&B / Soul / Neo-Soul",
            VocalFamily.ACOUSTIC: "Acoustic / Folk / Singer-Songwriter",
            VocalFamily.ROCK: "Rock / Alternative",
            VocalFamily.LATIN: "Latin / Reggaeton",
            VocalFamily.POP: "Pop",
            VocalFamily.UNKNOWN: "Unknown",
        }[self]


GLOBAL_CORE = """THICK HUMANIZED VOCAL PRESENCE (mandatory — never thin, distant, or buried):
1. PROXIMITY & WEIGHT: Ultra-close-mic intimateness, high-compression proximity effect, detailed chest resonance, audible human breathing dynamics and mouth texture. Lead must read as physically near the capsule — weighty and human, never thin or washed-out.
2. THICKENING: Warm vocal saturation, multi-tracked doubles / formant-aware backing where genre-appropriate, chest-vibrating fundamental body in the low-mids. Prefer organic pitch consistency over glassy robotic thinness.
3. POCKETING & DETACHMENT: Dynamic low-mid separation with a dedicated vocal warmth pocket (~200–300 Hz body). Heavy sidechain ducking on spatial FX and competing beds (not the lead body). Sharp transient isolation. Pristine high-end air boost so the vocal cuts through dense production without becoming harsh.
4. BAN THIN VOCAL ARTIFACTS: Never imply thin, distant, karaoke-wet, buried, or breath-only leads without body. Reject reverb floods that erase proximity. Dense instruments duck around the vocal — never the reverse.
5. BLOCK 1 WEAVE: Embed these descriptors into vocal production prose whenever vocals exist. BLOCK 2: Reflect presence in staging tags (close-mic, doubles, dry pocket, air boost) — do not paste this block as a lyric theme."""

EDM_DENSE_OVERLAY = """FAMILY OVERLAY — EDM DENSE / FESTIVAL / HARD DANCE:
Cut through supersaw walls, distorted kicks, and hypersaw stacks. Dry, weighty climax/drop mantras in a carved pocket, reinforced with stacked drop-mantra doubles for festival scale. Optional hyper-expanding wet hall washout into a sudden silence/vacuum gap before drop impact — then slam the hook dry and present."""

HIP_HOP_OVERLAY = """FAMILY OVERLAY — HIP-HOP / TRAP / BOOM BAP:
Forward booth presence, compressed intelligibility over 808s and sample beds. Dry center lead with stacked hook doubles; ad-libs may widen — never drown the lead in distant room."""

GOSPEL_OVERLAY = """FAMILY OVERLAY — GOSPEL / WORSHIP:
Thick multi-tracked doubles and choir power without losing lead clarity. Close-mic lead tracking; stacks support, never bury."""

ACOUSTIC_OVERLAY = """FAMILY OVERLAY — ACOUSTIC / FOLK / SINGER-SONGWRITER:
Intimate near-capsule body and chest warmth without festival vacuum automation. Short natural room only — never distant wash that thins the lead. Optional tasteful chorus doubles for lift."""

ASIAN_POP_OVERLAY = """FAMILY OVERLAY — ASIAN POP (K/J/C/MANDO):
Hyper-polished air and stack density with weighty lead body — never breath-only thinness. Doubles and air sheen must add thickness, not erase proximity."""

AFRO_OVERLAY = """FAMILY OVERLAY — AFRO / AMAPIANO:
Mid-forward rhythmic vocal pocket over log-drum and percussion beds. Dry intimate lead with stacked chant layers widening behind the topline; sidechain beds under the vocal — never bury the topline under kick/log-drum."""

RNB_OVERLAY = """FAMILY OVERLAY — R&B / SOUL / NEO-SOUL:
Velvet chest weight, stacked harmonies that thicken without distance. Warm saturation and close-mic intimacy; plate/short room only — avoid washed-out karaoke reverb."""

ROCK_OVERLAY = """FAMILY OVERLAY — ROCK / ALTERNATIVE:
Raw SM7B-style bite and chest grit that sits above distorted guitars. Forward compressed lead, double-tracked for chorus weight; guitars duck slightly on vocal phrases."""

LATIN_OVERLAY = """FAMILY OVERLAY — LATIN / REGGAETON / URBANO:
Warm, mid-forward vocal with rhythmic phrase-pocketing over dembow and percussion beds. Crisp consonants and close-mic intimacy; doubles and ad-libs stay dry and present. Never drown the lead in hall reverb — keep vocal body above tropical percussion and brass stabs."""

POP_OVERLAY = """FAMILY OVERLAY — POP / DANCE-POP:
Modern pop vocal chain: weighty lead body, polished air sheen, crisp transient detail. Tuned doubles and stacks add thickness without distance. Short plate/room only; never washed-out or karaoke-thin."""

# Order matters — first match wins for single-family detection.
_RULES: tuple[tuple[VocalFamily, str, tuple[str, ...]], ...] = (
    (
        VocalFamily.EDM_DENSE,
        EDM_DENSE_OVERLAY,
        (
            "hardstyle",
            "rawstyle",
            "hard dance",
            "eurodance",
            "big room",
            "festival anthem",
            "progressive house",
            "future house",
            "electro house",
            "bass house",
            "trance",
            "techno",
            "edm",
            "dubstep",
            "melodic dubstep",
            "riddim",
            "drum and bass",
            "drum & bass",
            "drum n bass",
            "dnb",
            "synthwave",
            "retrowave",
            "jump up",
            "neurofunk",
            "hardcore",
            "frenchcore",
            "uptempo",
            "tek",
            "melbourne bounce",
            "bounce",
            "electro",
        ),
    ),
    (
        VocalFamily.HIP_HOP,
        HIP_HOP_OVERLAY,
        (
            "hip hop",
            "hiphop",
            "hip-hop",
            "trap",
            "boom bap",
            "boombap",
            "boom-bap",
            "rap",
            "drill",
            "grime",
            "phonk",
            "cloud rap",
            "trap soul",
            "melodic rap",
        ),
    ),
    (
        VocalFamily.GOSPEL,
        GOSPEL_OVERLAY,
        (
            "gospel",
            "worship",
            "christian",
            "praise",
            "contemporary christian",
            "choir",
            "cinematic",
            "film score",
            "trailer",
            "orchestral",
        ),
    ),
    (
        VocalFamily.AFRO,
        AFRO_OVERLAY,
        (
            "amapiano",
            "yanos",
            "afro",
            "afro house",
            "afrohouse",
            "afro-house",
            "afrobeat",
            "afrobeats",
            "afro pop",
            "afropop",
            "afro fusion",
            "afrofusion",
            "gqom",
        ),
    ),
    (
        VocalFamily.ASIAN_POP,
        ASIAN_POP_OVERLAY,
        (
            "k-pop",
            "kpop",
            "j-pop",
            "jpop",
            "c-pop",
            "cpop",
            "mandopop",
            "mandarin pop",
            "cantopop",
            "cantonese pop",
            "city pop",
            "anime",
            "anisong",
            "t-pop",
            "thai pop",
            "p-pop",
            "pinoy pop",
        ),
    ),
    (
        VocalFamily.RNB,
        RNB_OVERLAY,
        (
            "r&b",
            "rnb",
            "rhythm and blues",
            "contemporary rnb",
            "alt rnb",
            "alternative rnb",
            "pbrnb",
            "neo-soul",
            "neo soul",
            "soul",
            "quiet storm",
        ),
    ),
    (
        VocalFamily.LATIN,
        LATIN_OVERLAY,
        (
            "latin",
            "latino",
            "latina",
            "reggaeton",
            "regueton",
            "urbano",
            "música urbana",
            "bachata",
            "salsa",
            "merengue",
            "cumbia",
            "dembow",
            "mambo",
            "tango",
            "bossa nova",
            "latin pop",
            "latin house",
        ),
    ),
    (
        VocalFamily.ACOUSTIC,
        ACOUSTIC_OVERLAY,
        (
            "folk",
            "indie folk",
            "singer-songwriter",
            "singer songwriter",
            "acoustic",
            "unplugged",
            "live lounge",
            "coffeehouse",
            "americana",
            "country",
            "bluegrass",
            "jazz",
            "classic swing",
            "swing",
            "blues",
            "ambient",
            "soundscape",
            "reggae",
            "dub",
        ),
    ),
    (
        VocalFamily.ROCK,
        ROCK_OVERLAY,
        (
            "rock",
            "hard rock",
            "classic rock",
            "pop rock",
            "indie rock",
            "alternative",
            "alt rock",
            "punk",
            "post-punk",
            "metal",
            "grunge",
            "emo",
        ),
    ),
    (
        VocalFamily.POP,
        POP_OVERLAY,
        (
            "pop",
            "dance pop",
            "dance-pop",
            "electropop",
            "electro-pop",
            "synth pop",
            "synth-pop",
            "indie pop",
            "indie-pop",
            "hyperpop",
            "dream pop",
            "dream-pop",
            "power pop",
            "power-pop",
            "teen pop",
            "bubblegum pop",
            "art pop",
            "bedroom pop",
            "world",
            "bollywood",
            "mena",
            "middle eastern",
            "bhangra",
            "filmi",
            "punjabi",
        ),
    ),
)


def _normalize_genre(text: str) -> str:
    return _WS_RE.sub(" ", _PUNCT_RE.sub(" ", text.lower())).strip()


_NORMALIZED_KEYWORDS: dict[VocalFamily, tuple[str, ...]] = {
    family: tuple(_normalize_genre(k) for k in keywords)
    for family, _overlay, keywords in _RULES
}

_OVERLAY_BY_FAMILY: dict[VocalFamily, str] = {
    family: overlay for family, overlay, _keywords in _RULES
}

KNOWN_FAMILIES: tuple[VocalFamily, ...] = tuple(
    f for f in VocalFamily if f is not VocalFamily.UNKNOWN
)


def _contains_any(blob: str, phrases: tuple[str, ...]) -> bool:
    for phrase in phrases:
        if not phrase:
            continue
        if re.search(rf"\b{re.escape(phrase)}\b", blob):
            return True
    return False


def should_inject(vocal_spec: str | None) -> bool:
    return not is_instrumental_only(vocal_spec)


def detect_families(
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> list[VocalFamily]:
    blob = _normalize_genre(f"{primary_genre} {sub_genre_fusion}")
    if not blob:
        return []
    found: list[VocalFamily] = []
    for family, _overlay, _keywords in _RULES:
        if _contains_any(blob, _NORMALIZED_KEYWORDS[family]):
            found.append(family)
    return found


def detect_family(primary_genre: str = "", sub_genre_fusion: str = "") -> VocalFamily:
    families = detect_families(primary_genre, sub_genre_fusion)
    return families[0] if families else VocalFamily.UNKNOWN


def overlay_for(family: VocalFamily) -> str:
    if family == VocalFamily.UNKNOWN:
        return ""
    return _OVERLAY_BY_FAMILY.get(family, "").strip()


def _family_from_spec(vocal_spec: str | None) -> VocalFamily | None:
    normalized = coerce_spec(vocal_spec)
    if normalized is None:
        return None
    if normalized == RAP_VOCAL_SPACE_SPEC:
        return VocalFamily.HIP_HOP
    if is_choir(normalized):
        return VocalFamily.GOSPEL
    return None


def family_overlay(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vocal_spec: str | None = None,
    include_all_matches: bool = False,
) -> str:
    families = detect_families(primary_genre, sub_genre_fusion)
    if families:
        selected = families if include_all_matches else families[:1]
        overlays = [overlay_for(f) for f in selected]
        overlays = [o for o in overlays if o]
        return "\n\n".join(overlays)

    spec_family = _family_from_spec(vocal_spec)
    if spec_family is not None:
        return overlay_for(spec_family)
    return ""


def thick_humanized_vocal_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vocal_spec: str | None = None,
    include_all_family_matches: bool = False,
) -> str:
    if not should_inject(vocal_spec):
        return ""
    parts = [GLOBAL_CORE.strip()]
    overlay = family_overlay(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vocal_spec=vocal_spec,
        include_all_matches=include_all_family_matches,
    ).strip()
    if overlay:
        parts.append(overlay)
    return "\n\n".join(parts)
