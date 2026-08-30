# Soulful Southern Gospel & Raw Country lyric engine — runtime source for server.

SOULFUL_SOUTHERN_GOSPEL_COUNTRY_LANE_MARKERS = (
    "southern gospel",
    "country gospel",
    "gospel country",
    "traditional gospel",
    "outlaw country",
    "americana",
    "worship ballad",
    "modern country",
    "country",
    "gospel",
    "praise/worship",
    "praise and worship",
    "ccm",
)

CORE_ARCHITECTURE = """\
SOULFUL SOUTHERN GOSPEL & RAW COUNTRY LYRIC ENGINE (mandatory for this lane)

You are an expert lyricist in Soulful Southern Gospel and Raw Country. Lyrics must feel deeply personal, spiritually heavy, and universally relatable — never template worship or stock country.

STRICT WRITING RULES:
1. BAN THE CLICHÉS: Never use generic physical placeholders for rebellion or emptiness (e.g. "cheap wine," "city lights," "neon," "empty bottle," "lost keys," dirt-road/pickup/porch stock). Replace with existential or psychological specificity ("crowded, lonely room," "monument of pride," "fleeting shadow").

BANNED PLACEHOLDER IMAGERY (rewrite if tempted): cheap wine, city lights, neon, empty bottle, lost keys, generic bar-on-Main-street vignettes without psychological specificity."""

FEW_SHOT_USER = (
    "Write a verse about realizing you made a mistake and wanting to go back to God."
)

FEW_SHOT_ASSISTANT = """\
BAD (Avoid this style):
I hit the bar on Main street, drank until the dawn
Thinking about the good times and how they're all now gone
I lost my silver cross, I spent my final dime
Now I'm sitting in the dark, just wasting all my time.

GOOD (Write in this style):
I traded your inheritance for a crowded, lonely room
Chasing any fleeting shadow that could hide me from the truth
Woke up at 3 AM with a hunger in my heart
Realized the things I fought for only left me more oppressed."""


def is_southern_gospel_country_lane(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> bool:
    blob = (
        f"{primary_genre} {sub_genre_fusion} {vibe} {lyric_theme_notes}".lower()
    )
    if not blob.strip():
        return False
    if any(m in blob for m in SOULFUL_SOUTHERN_GOSPEL_COUNTRY_LANE_MARKERS):
        return True
    if "gospel country lift" in blob:
        return True
    if "soulful" in blob and "gospel" in blob:
        return True
    return "raw country" in blob


def ui_directive_append(
    *,
    vocal_spec: str = "",
    vocal_tone: str = "",
    vibe: str = "",
    melody_style_id: str = "",
    melody_custom_notes: str = "",
) -> str:
    parts: list[str] = []
    spec = vocal_spec.lower()
    tone = vocal_tone.lower()
    vibe_l = vibe.lower()
    melody_blob = f"{melody_style_id} {melody_custom_notes}".lower()

    soulful_female_prayerful = (
        any(x in spec for x in ("female", "woman", "soprano"))
        and any(
            x in tone
            for x in ("prayerful", "soulful", "breathy", "warm")
        )
    ) or "prayerful" in vibe_l or "soulful female" in vibe_l

    if soulful_female_prayerful:
        parts.append(
            "VOCAL CADENCE DIRECTIVE: Write short, rhythmic lines with heavy vowel "
            "sounds (oh, ah) that allow a vocalist to bend notes and deliver a slow, "
            "bluesy, prayerful cadence."
        )

    if (
        "gospel country lift" in vibe_l
        or "gospel choir" in vibe_l
        or "choir lift" in vibe_l
        or "call_response" in melody_blob
        or "anthemic" in melody_blob
        or "blues_gospel" in melody_blob
    ):
        parts.append(
            "CHORUS DIRECTIVE (Gospel Country Lift): Ensure the chorus uses simple, "
            "anthemic, easily harmonized declarations that a full gospel choir could "
            "instantly back up."
        )

    if "twang" in tone or "male lead" in spec:
        parts.append(
            "RAW COUNTRY DELIVERY: Conversational story-first phrasing; concrete "
            "geography over abstract grief; let testimony land in the chest voice."
        )

    return "\n".join(parts)


def few_shot_prefix_messages() -> list[dict[str, str]]:
    return [
        {"role": "user", "content": FEW_SHOT_USER},
        {"role": "assistant", "content": FEW_SHOT_ASSISTANT},
    ]


def southern_gospel_country_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    melody_style_id: str = "",
    melody_custom_notes: str = "",
) -> str:
    if not is_southern_gospel_country_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ):
        return ""
    from app.master_gospel_lyric_engine import is_gospel_lane

    parts: list[str] = []
    if not is_gospel_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ):
        parts.append(CORE_ARCHITECTURE)
    ui = ui_directive_append(
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        vibe=vibe,
        melody_style_id=melody_style_id,
        melody_custom_notes=melody_custom_notes,
    )
    if ui:
        parts.append(ui)
    return "\n\n".join(parts)
