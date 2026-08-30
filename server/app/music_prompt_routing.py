"""Music Prompt Router — Stage 1 classify → Stage 2 model (Python mirror)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from app.dialect_style import is_nigerian_pidgin
from app.genre_hybridization import fusion_active
from app.human_voice_directive import HUMAN_VOICE_DIRECTIVE, emits_lyrics
from app.llm_config import (
    LAOZHANG_GEMINI_FLASH,
    LAOZHANG_LYRICS_PRIMARY_MODEL,
    LAOZHANG_LIGHT_MODEL,
    LAOZHANG_PROMPT_MODEL,
    OPENROUTER_GENERATE_MODEL,
    OPENROUTER_HUMANIZATION_MODEL,
    OPENROUTER_LIGHT_MODEL,
    llm_provider,
    resolve_draft_model,
    resolve_polish_model,
)

ROUTING_KEYS = {
    "GEN_AFRICAN_MAINSTREAM",
    "GEN_AFRICAN_PIDGIN",
    "GEN_EAST_ASIAN",
    "GEN_LATIN",
    "GEN_WESTERN_POP",
    "GEN_EUROPEAN_LINGUAL",
    "GEN_SEA",
    "GEN_MIDDLE_EASTERN",
    "HYBRID_MULTI_GENRE",
    "HYBRID_CULTURAL",
}

MODEL_KEYS = {
    "claude-sonnet",
    "gpt-5",
    "glm",
    "mistral",
    "qwen",
}

_AFRICAN_MAINSTREAM = (
    "afrobeats", "afrobeat", "amapiano", "highlife", "gqom", "afropop", "fuji",
)
_EAST_ASIAN = (
    "k-pop", "kpop", "j-pop", "jpop", "c-pop", "mandopop", "vinahouse", "v-pop", "trot",
)
_LATIN = (
    "reggaeton", "bachata", "salsa", "cumbia", "bossa nova", "dembow", "latin pop",
)
_EUROPEAN = ("french chanson", "chanson", "schlager", "italian pop", "german pop")
_SEA = ("thai pop", "dangdut", "indonesian", "filipino", "opm")
_MIDDLE_EASTERN = ("arabic pop", "turkish pop", "persian", "middle eastern")

BANNED_QA_WORDS = (
    "immersive", "captivating", "mesmerizing", "tapestry", "seamless", "ethereal",
    "haunting", "lush", "vibrant",
)


@dataclass
class GenreSlot:
    genre: str
    weight: float = 1.0
    bpm: int | None = None
    language: str | None = None


@dataclass
class HybridResolution:
    dominant: GenreSlot
    secondary: list[GenreSlot]
    tempo_strategy: str
    structure_strategy: str
    vocabulary_merge: str = "blended"


@dataclass
class Stage1Classification:
    routing_key: str
    is_hybrid: bool
    primary_slot: GenreSlot
    secondary_slots: list[GenreSlot] = field(default_factory=list)
    dominant_mood: str = "neutral"
    estimated_bpm: int = 100
    dominant_language: str = "English"
    languages_detected: list[str] = field(default_factory=list)
    hybrid_resolution: HybridResolution | None = None
    pidgin_sub_variant: str | None = None
    east_asian_sub_variant: str | None = None


def _blob_has(blob: str, needles: tuple[str, ...]) -> bool:
    return any(n in blob for n in needles)


def _parse_bpm(raw: str | None) -> int | None:
    if not raw:
        return None
    try:
        n = int(str(raw).strip())
    except ValueError:
        return None
    return n if 40 <= n <= 250 else None


def _estimate_bpm(blob: str) -> int:
    if _blob_has(blob, ("hardstyle", "dnb", "drum and bass")):
        return 150
    if _blob_has(blob, ("amapiano", "afrobeats")):
        return 112
    if _blob_has(blob, ("house", "techno", "reggaeton")):
        return 128
    return 100


def _resolve_pidgin(accent: str, dialect_style_id: str, dialect_variant_id: str) -> str | None:
    a = accent.strip().lower()
    if "ibibio" in a or dialect_variant_id == "ibibio":
        return "ibibio"
    if "igbo" in a or dialect_variant_id == "igbo":
        return "igbo"
    if "rivers" in a or dialect_variant_id == "rivers":
        return "rivers_state"
    if a.startswith("nigerian") or is_nigerian_pidgin(dialect_style_id):
        return "lagos_standard"
    return None


def _resolve_east_asian(blob: str) -> str | None:
    if "mandopop" in blob or "c-pop" in blob:
        return "mandopop"
    if "j-pop" in blob or "jpop" in blob:
        return "jpop"
    if "k-pop" in blob or "kpop" in blob:
        return "kpop"
    if "vinahouse" in blob or "v-pop" in blob:
        return "vpop_vinahouse"
    if "trot" in blob:
        return "trot"
    return None


def _resolve_hybrid(primary: GenreSlot, secondaries: list[GenreSlot]) -> HybridResolution | None:
    if not secondaries:
        return None
    pb = primary.bpm or 100
    max_delta = max(abs((s.bpm or pb) - pb) for s in secondaries)
    tempo = "dominant_lock" if max_delta <= 8 else "midpoint" if max_delta <= 20 else "dual_section"
    total = primary.weight + sum(s.weight for s in secondaries)
    structure = "alternating_sections" if primary.weight / total < 0.5 else "dominant_only"
    return HybridResolution(
        dominant=primary,
        secondary=secondaries,
        tempo_strategy=tempo,
        structure_strategy=structure,
    )


def _genre_family(genre: str) -> str:
    g = genre.lower()
    if _blob_has(g, _AFRICAN_MAINSTREAM):
        return "african"
    if _blob_has(g, _EAST_ASIAN):
        return "east_asian"
    if _blob_has(g, _LATIN):
        return "latin"
    if _blob_has(g, ("edm", "house", "techno", "trance", "dubstep")):
        return "edm"
    if _blob_has(g, ("hip hop", "hip-hop", "trap", "drill")):
        return "hiphop"
    return g


def _genre_families_differ(primary: str, fusion: str) -> bool:
    pf = _genre_family(primary)
    ff = _genre_family(fusion)
    return bool(pf and ff and pf != ff)


def _estimate_bpm_for_genre(genre: str) -> int:
    g = genre.strip().lower()
    if not g:
        return 100
    if _blob_has(g, ("hardstyle", "drum and bass", "dnb")):
        return 150
    if "amapiano" in g or "afrobeat" in g:
        return 112
    if _blob_has(g, ("vinahouse", "v-pop", "vpop")):
        return 140
    if _blob_has(g, ("house", "techno", "reggaeton", "trance")):
        return 128
    if _blob_has(g, ("hip hop", "hip-hop", "trap", "drill")):
        return 140
    return 100


def _hybrid_tempo_overlay(c: Stage1Classification) -> str:
    h = c.hybrid_resolution
    if not h:
        return ""
    dom_bpm = h.dominant.bpm or c.estimated_bpm
    max_delta = max(abs((s.bpm or dom_bpm) - dom_bpm) for s in h.secondary) if h.secondary else 0
    sec = " + ".join(s.genre for s in h.secondary)
    tempo_line = {
        "dominant_lock": f"TEMPO_STRATEGY=dominant_lock — lock to {dom_bpm} BPM.",
        "midpoint": f"TEMPO_STRATEGY=midpoint — blend toward center BPM.",
        "dual_section": f"TEMPO_STRATEGY=dual_section — BPM gap {max_delta} (>20).",
    }.get(h.tempo_strategy, f"TEMPO_STRATEGY={h.tempo_strategy}")
    return (
        f"tempo_strategy={h.tempo_strategy}\n"
        f"HYBRID DISPATCH: dominant={h.dominant.genre}@{dom_bpm}BPM; secondary={sec}; "
        f"{tempo_line}"
    )


def classify_from_body(body: Any) -> Stage1Classification:
    """Heuristic Stage 1 from GeneratePromptBody-like object."""
    primary = str(getattr(body, "primary_genre", "") or "").strip()
    fusion = str(getattr(body, "sub_genre_fusion", "") or "").strip()
    vibe = str(getattr(body, "vibe", "") or "").strip()
    language = str(getattr(body, "language", "") or "English")
    accent = str(getattr(body, "vocal_accent", "") or "")
    dialect_style_id = str(getattr(body, "dialect_style_id", "") or "")
    dialect_variant_id = str(getattr(body, "dialect_variant_id", "") or "")
    blob = f"{primary} {fusion} {vibe}".lower()
    bpm = _parse_bpm(getattr(body, "bpm", None)) or _estimate_bpm(blob)
    languages = [language.lower()]
    if is_nigerian_pidgin(dialect_style_id):
        languages.append("nigerian_pidgin")

    def _build(key: str, hybrid: bool, pidgin: str | None = None, east: str | None = None):
        primary_bpm = _parse_bpm(getattr(body, "bpm", None)) or _estimate_bpm_for_genre(primary or "Pop")
        p_slot = GenreSlot(genre=primary or "Pop", weight=0.6 if hybrid else 1.0, bpm=primary_bpm, language=language)
        s_slots: list[GenreSlot] = []
        if fusion_active(fusion):
            s_slots.append(
                GenreSlot(
                    genre=fusion,
                    weight=0.4,
                    bpm=_parse_bpm(getattr(body, "bpm", None)) or _estimate_bpm_for_genre(fusion),
                    language=language,
                )
            )
        return Stage1Classification(
            routing_key=key,
            is_hybrid=hybrid,
            primary_slot=p_slot,
            secondary_slots=s_slots,
            dominant_mood=vibe or "neutral",
            estimated_bpm=primary_bpm,
            dominant_language=language,
            languages_detected=languages,
            hybrid_resolution=_resolve_hybrid(p_slot, s_slots) if hybrid else None,
            pidgin_sub_variant=pidgin,
            east_asian_sub_variant=east,
        )

    if (
        "bilingual" in blob
        or "code-switch" in blob
        or "code switch" in blob
        or "spanglish" in blob
        or "english verse" in blob
        or "korean chorus" in blob
        or "spanish chorus" in blob
    ):
        return _build("HYBRID_CULTURAL", True)
    if fusion_active(fusion) or " hybrid" in blob or " crossover" in blob:
        return _build("HYBRID_MULTI_GENRE", True)
    if primary and fusion and _genre_families_differ(primary, fusion):
        return _build("HYBRID_MULTI_GENRE", True)
    if "+" in blob and " hybrid" in blob:
        return _build("HYBRID_MULTI_GENRE", True)
    pidgin = _resolve_pidgin(accent, dialect_style_id, dialect_variant_id)
    if pidgin or is_nigerian_pidgin(dialect_style_id) or _blob_has(blob, ("pidgin", "wahala")):
        return _build("GEN_AFRICAN_PIDGIN", False, pidgin=pidgin or "lagos_standard")
    if _blob_has(blob, _EAST_ASIAN):
        return _build("GEN_EAST_ASIAN", False, east=_resolve_east_asian(blob))
    if _blob_has(blob, _LATIN):
        return _build("GEN_LATIN", False)
    if _blob_has(blob, _EUROPEAN):
        return _build("GEN_EUROPEAN_LINGUAL", False)
    if _blob_has(blob, _SEA):
        return _build("GEN_SEA", False)
    if _blob_has(blob, _MIDDLE_EASTERN):
        return _build("GEN_MIDDLE_EASTERN", False)
    if _blob_has(blob, _AFRICAN_MAINSTREAM):
        return _build("GEN_AFRICAN_MAINSTREAM", False)
    return _build("GEN_WESTERN_POP", False)


ROUTING_TO_MODEL: dict[str, str] = {
    "GEN_AFRICAN_MAINSTREAM": "claude-sonnet",
    "GEN_AFRICAN_PIDGIN": "claude-sonnet",
    "GEN_EAST_ASIAN": "glm",
    "GEN_EUROPEAN_LINGUAL": "mistral",
    "HYBRID_CULTURAL": "gpt-5",
    "GEN_LATIN": "claude-sonnet",
    "GEN_WESTERN_POP": "gpt-5",
    "GEN_SEA": "mistral",
    "GEN_MIDDLE_EASTERN": "gpt-5",
    "HYBRID_MULTI_GENRE": "gpt-5",
}


def pick_model_key(c: Stage1Classification) -> str:
    if c.routing_key == "HYBRID_MULTI_GENRE":
        genres = [c.primary_slot.genre.lower()] + [s.genre.lower() for s in c.secondary_slots]
        langs = [x.lower() for x in c.languages_detected]
        if any(l in langs for l in ("zh", "ja", "ko", "vi")) or any(
            g in genres for g in ("kpop", "jpop", "mandopop", "vinahouse")
        ):
            return "glm"
        if any(l in langs for l in ("es", "pt")) or any("reggaeton" in g for g in genres):
            return "claude-sonnet"
        return "gpt-5"
    return ROUTING_TO_MODEL.get(c.routing_key, "gpt-5")


def _slug(model_key: str, *, provider: str | None, lightweight: bool) -> str:
    if lightweight:
        return OPENROUTER_LIGHT_MODEL if llm_provider(provider) == "openrouter" else LAOZHANG_LIGHT_MODEL
    if llm_provider(provider) == "openrouter":
        return {
            "claude-sonnet": "anthropic/claude-sonnet-4",
            "gpt-5": OPENROUTER_GENERATE_MODEL,
            "glm": "zhipu/glm-4-plus",
            "mistral": OPENROUTER_HUMANIZATION_MODEL,
            "qwen": OPENROUTER_GENERATE_MODEL,
        }.get(model_key, OPENROUTER_GENERATE_MODEL)
    return {
        "claude-sonnet": LAOZHANG_LYRICS_PRIMARY_MODEL,
        "gpt-5": LAOZHANG_PROMPT_MODEL,
        "glm": LAOZHANG_PROMPT_MODEL,
        "mistral": LAOZHANG_PROMPT_MODEL,
        "qwen": LAOZHANG_GEMINI_FLASH,
    }.get(model_key, LAOZHANG_PROMPT_MODEL)


def resolve_routed_draft_model(
    *,
    classification: Stage1Classification,
    language: str,
    lightweight: bool,
    provider: str | None,
    lyrics_task: bool = True,
) -> str:
    if lightweight:
        return _slug("gpt-5", provider=provider, lightweight=True)
    return _slug(pick_model_key(classification), provider=provider, lightweight=False)


def resolve_routed_polish_model(
    *,
    classification: Stage1Classification,
    provider: str | None,
    lyrics_task: bool = True,
) -> str:
    if llm_provider(provider) == "openrouter":
        return resolve_polish_model(provider=provider, lyrics_task=lyrics_task)
    key = pick_model_key(classification)
    if key == "claude-sonnet":
        return LAOZHANG_LYRICS_PRIMARY_MODEL
    return LAOZHANG_PROMPT_MODEL


def build_routing_user_block_append(c: Stage1Classification) -> str:
    lines = [
        "MUSIC PROMPT ROUTER (Stage 1 classification — internal):",
        f"routing_key={c.routing_key}",
        f"is_hybrid={str(c.is_hybrid).lower()}",
        f"estimated_bpm={c.estimated_bpm}",
        f"dominant_language={c.dominant_language}",
    ]
    if c.pidgin_sub_variant:
        lines.append(f"pidgin_sub_variant={c.pidgin_sub_variant}")
        if c.pidgin_sub_variant == "ibibio":
            lines.append(
                "IBIBIO VOCABULARY (preserve in draft AND polish): "
                "Abasi, esie, kpa, edinen, emi, idaha, nno, fo, mmo, mi"
            )
    if c.east_asian_sub_variant:
        lines.append(f"east_asian_sub_variant={c.east_asian_sub_variant}")
    if c.is_hybrid and c.hybrid_resolution:
        lines.append(_hybrid_tempo_overlay(c))
    if c.routing_key in ("GEN_AFRICAN_MAINSTREAM", "GEN_AFRICAN_PIDGIN"):
        lines.append(
            "PART 2 ANTI-REPETITION: swap Zinc/Generator Hum/Tea/Kitchen Counter per cultural routing matrix. "
            "BANNED STOCK FORMULAS: 3 AM on cold tile in Lagos, bleach/scrubbing floors, "
            "bent receipt by the kettle, Mama said… count grace before receipts."
        )
    lines.append(
        "Apply kStagingAndAccentRules Section D blacklist on all staging brackets before emission."
    )
    primary = str(c.primary_slot.genre or "")
    if emits_lyrics(primary):
        lines.append(HUMAN_VOICE_DIRECTIVE)
    return "\n".join(lines)


def qa_check_output(text: str) -> list[str]:
    lower = text.lower()
    issues: list[str] = []
    hits = [w for w in BANNED_QA_WORDS if w in lower]
    if hits:
        issues.append(f"output contains banned words: {', '.join(hits)}")
    if "[" not in text or "]" not in text:
        issues.append("output contains no bracketed structural markers")
    return issues
