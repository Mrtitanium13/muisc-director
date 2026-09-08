"""Genre-specific Block 2 lyric direction — runtime user-block overrides before generation."""

from __future__ import annotations

from pathlib import Path

from app.advanced_thematic_variator import (
    advanced_thematic_variator_block,
    is_future_house_lane,
    is_hardstyle_lane,
)
from app.big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine import (
    big_room_hardstyle_cinematic_hybrid_vocal_user_block,
    is_big_room_hardstyle_cinematic_hybrid_lane,
)
from app.big_room_fusion_progressive_vocal_lyric_engine import (
    big_room_fusion_progressive_vocal_user_block,
    is_big_room_fusion_lane,
)
from app.edm_breakdown_vocal_lyric_engine import edm_breakdown_vocal_user_block
from app.hardstyle_vocal_lyric_engine import hardstyle_vocal_user_block
from app.master_gospel_lyric_engine import master_gospel_user_block
from app.master_hardstyle_lyric_engine import (
    is_hardstyle_lane as is_master_hardstyle_lane,
    master_hardstyle_user_block,
)
from app.master_progressive_big_room_house_lyric_engine import (
    is_progressive_big_room_lane,
    master_progressive_big_room_user_block,
)
from app.master_edm_lyric_engine import (
    is_edm_lane as is_master_edm_lane,
    master_edm_user_block,
)
from app.master_pop_lyric_engine import master_pop_user_block
from app.master_rock_lyric_engine import master_rock_user_block
from app.master_country_lyric_engine import master_country_user_block
from app.master_hiphop_lyric_engine import master_hiphop_user_block
from app.master_rnb_lyric_engine import master_rnb_user_block
from app.southern_gospel_country_lyric_engine import southern_gospel_country_user_block
from app.suno_prompt_builder import resolve_genre_fx_key
from app.genre_lyric_engines import (
    format_engine,
    global_guardrail,
    inline_directive,
    lane_lyric_directive,
)

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

_SECRET_INSIDE_MARKERS = (
    "secret inside your chest",
    "secret inside",
)

_DONT_CALL_ME_LONELY_MARKERS = (
    "don't call me lonely",
    "dont call me lonely",
    "call me outside",
)


def _matches_secret_inside_chest(*, vibe: str = "", lyric_theme_notes: str = "") -> bool:
    blob = f"{vibe} {lyric_theme_notes}".lower()
    return any(marker in blob for marker in _SECRET_INSIDE_MARKERS)


def _matches_dont_call_me_lonely(*, vibe: str = "", lyric_theme_notes: str = "") -> bool:
    blob = f"{vibe} {lyric_theme_notes}".lower()
    return any(marker in blob for marker in _DONT_CALL_ME_LONELY_MARKERS)


def _dont_call_me_lonely_block() -> str:
    path = (
        Path(__file__).resolve().parents[2]
        / "tools"
        / "lyrics_training"
        / "dontCallMeLonely_master.txt"
    )
    if path.is_file():
        body = path.read_text(encoding="utf-8").strip()
        return (
            'DEFINITIVE MASTER — "Don\'t Call Me Lonely" / "Call Me Outside" '
            "(commercial Amapiano structure reference):\n"
            f"{body}\n\n"
            "When revising: preserve section order and production tags; lyrics may be "
            "rewritten but must stay 100% original and mature (no age-number tropes)."
        )
    return (
        "DEFINITIVE MASTER — commercial Amapiano order: "
        "Intro → Verse 1 → Chorus → Verse 2 → Chorus → Bridge → "
        "Percussion Breakdown → Drop → Final Chorus → Outro."
    )


def _secret_inside_chest_block() -> str:
    path = (
        Path(__file__).resolve().parents[2]
        / "tools"
        / "lyrics_training"
        / "secretInsideYourChest_template.txt"
    )
    if path.is_file():
        body = path.read_text(encoding="utf-8").strip()
        return (
            'SIGNATURE TRACK LAYOUT — "Secret Inside Your Chest" (mandatory structure):\n'
            f"{body}\n\n"
            "Rewrite using 100% original lyrics — preserve section tags, production cues, "
            "and Private School pacing."
        )
    return (
        'SIGNATURE TRACK LAYOUT — "Secret Inside Your Chest": follow Private School '
        "Amapiano intro → verse → chorus → bridge → percussion breakdown → "
        "[Drop: Heavy Rolling Log Drum] → outro."
    )


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def _blob_contains_any(blob: str, needles: tuple[str, ...]) -> bool:
    return any(kw in blob for kw in needles)


def is_amapiano_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _AMAPIANO_LANES)


def global_lyricist_guardrail() -> str:
    return (
        "GLOBAL LYRICIST GUARDRAIL (strict):\n"
        "Do NOT copy, reuse, or interpolate exact lyrics, phrases, or signature hooks "
        "from existing artists or reference datasets (tools/lyrics_training/*Dataset.json). "
        "All lyrics must be 100% original. References are cadence, structure, and tone only.\n"
        "THEME FIT (mandatory): every sung line — especially chorus — must advance or "
        "emotionally land the stated vibe/theme/story. Reject off-theme words, generic "
        "club filler, and production-meta lines (instrument/drum personification). "
        "Put groove/instrument cues only in [section tags], never as chorus meaning. "
        "Do not lock specific chorus text; rewrite freely within the theme."
    )


def hardstyle_lyrics_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    master = master_hardstyle_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
    )
    if master:
        return master
    block = hardstyle_vocal_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    if block:
        return block
    return (
        "CRITICAL DIRECTION FOR HARDSTYLE / RAWSTYLE / EUPHORIC HARDSTYLE LYRICS:\n"
        "Follow hardstyle_vocal_lyricist_engine.txt runtime guardrails."
    )


def big_room_hardstyle_cinematic_hybrid_lyrics_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    block = big_room_hardstyle_cinematic_hybrid_vocal_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    if block:
        return block
    return (
        "CRITICAL DIRECTION FOR BIG ROOM / HARDSTYLE CINEMATIC HYBRID LYRICS:\n"
        "Follow big_room_hardstyle_cinematic_hybrid_vocal_lyricist_engine.txt runtime guardrails."
    )


def big_room_fusion_progressive_lyrics_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    master = master_progressive_big_room_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
    )
    if master:
        return master
    block = big_room_fusion_progressive_vocal_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    if block:
        return block
    return (
        "CRITICAL DIRECTION FOR BIG ROOM FUSION / PROGRESSIVE HOUSE LYRICS:\n"
        "Follow big_room_fusion_progressive_vocal_lyricist_engine.txt runtime guardrails."
    )


def future_house_lyrics_user_block() -> str:
    return (
        "CRITICAL DIRECTION FOR FUTURE HOUSE LYRICS:\n"
        "1. Industrial realism and tactile imagery — concrete objects, built spaces, "
        "routine detail.\n"
        "2. Zero generic AI buzzwords, car-melancholy loops, or club clichés.\n"
        "3. High-tier pop-house songwriting: punchy pre-drop cues, controlled vocal delivery.\n"
        "4. Prefer [Verse], [Pre-Chorus], [Chorus], [Drop] with minimalist drop anchors."
    )


def amapiano_lyrics_user_block() -> str:
    return (
        "CRITICAL DIRECTION FOR AMAPIANO / PRIVATE SCHOOL / AFRO-HOUSE LYRICS:\n"
        "1. English-dominant canvas — contemporary global urban phrasing, spatial "
        "late-night imagery, smooth vocal pockets for deep house tempo. "
        'BAN generic Western pop clichés ("vows," "committing sin") and age-number '
        'tropes ("she was nineteen," "i was seventeen," numeric youth hooks). '
        "Prefer atmospheric maturity: receipts, gate lights, rain, auntie asking, city detail.\n"
        "2. COMMERCIAL ARRANGEMENT ORDER (mandatory): "
        "Intro → Verse 1 → Chorus → Verse 2 → Chorus → Bridge → "
        "Percussion Breakdown → Drop → Final Chorus → Outro. "
        "NEVER place Verse 2 after Drop/Final Chorus. "
        "NEVER sandwich two Choruses with only Drop/Breakdown between before Verse 2.\n"
        "3. LOG DRUM IS KING: tag progression to percussive log drum punch "
        "(e.g. [Drop: Heavy Rolling Log Drum], [Vocal Chant Interlude]). "
        "Log drum = FM synthesized club bass in tags — never live/acoustic log drum.\n"
        "4. Embed production-ready layout via Dynamic Structural Engine "
        "(tools/dynamic_structural_engine.txt) — assemble & prune per genre; "
        "never static one-size-fits-all templates.\n"
        "5. Cadence reference only: tools/lyrics_training/amapianoDataset.json "
        "(20 English-led hits) — never copy artist hooks or lyric phrases.\n"
        "6. Definitive polished master (structure + tone): "
        "tools/lyrics_training/dontCallMeLonely_master.txt\n"
        "7. THEME FIT (mandatory): every sung line — especially chorus — must "
        "advance or emotionally land the stated vibe/theme/story. Reject words "
        "or phrases that are off-theme, generic club filler, or production-meta "
        '(instrument/drum personification like "log drum understand", '
        '"rhythm heals the plan", empty "pieces click"). Put groove/instrument '
        "cues only in [section tags], never as chorus meaning."
    )


def genre_lyrics_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    melody_style_id: str = "",
    melody_custom_notes: str = "",
    bpm_hint: str = "",
    genre_fx_lane: str = "",
) -> str:
    """Runtime lyric overrides keyed to primary/fusion genre."""
    parts: list[str] = [global_guardrail()]
    engine_body = ""

    sg_block = southern_gospel_country_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        melody_style_id=melody_style_id,
        melody_custom_notes=melody_custom_notes,
    )
    gospel_block = master_gospel_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
    )
    if gospel_block:
        engine_body = gospel_block
        if sg_block and sg_block not in gospel_block:
            engine_body = f"{engine_body}\n\n{sg_block}"
    elif sg_block:
        engine_body = sg_block
    elif is_big_room_hardstyle_cinematic_hybrid_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        engine_body = big_room_hardstyle_cinematic_hybrid_lyrics_user_block(
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
        )
    elif is_master_hardstyle_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ) or is_hardstyle_lane(primary_genre, sub_genre_fusion):
        engine_body = hardstyle_lyrics_user_block(
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            vocal_spec=vocal_spec,
            vocal_tone=vocal_tone,
            bpm_hint=bpm_hint,
        )
    elif is_future_house_lane(primary_genre, sub_genre_fusion):
        engine_body = inline_directive("future_house") or future_house_lyrics_user_block()
    elif is_progressive_big_room_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ) or is_big_room_fusion_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        engine_body = big_room_fusion_progressive_lyrics_user_block(
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            vocal_spec=vocal_spec,
            vocal_tone=vocal_tone,
            bpm_hint=bpm_hint,
        )
    elif is_master_edm_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ):
        engine_body = master_edm_user_block(
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
            vibe=vibe,
            lyric_theme_notes=lyric_theme_notes,
            vocal_spec=vocal_spec,
            vocal_tone=vocal_tone,
            bpm_hint=bpm_hint,
        )
        if is_amapiano_lane(primary_genre, sub_genre_fusion):
            # Amapiano lanes always carry the dedicated inline directive
            # (log-drum laws, commercial arrangement order, theme fit) —
            # appended after the EDM master block when it composes one.
            amapiano = inline_directive("amapiano") or amapiano_lyrics_user_block()
            if amapiano:
                engine_body = (
                    f"{engine_body}\n\n{amapiano}" if engine_body else amapiano
                )
        if not engine_body:
            engine_body = edm_breakdown_vocal_user_block(
                primary_genre=primary_genre,
                sub_genre_fusion=sub_genre_fusion,
            )
    elif is_amapiano_lane(primary_genre, sub_genre_fusion):
        engine_body = inline_directive("amapiano") or amapiano_lyrics_user_block()
    else:
        edm_block = edm_breakdown_vocal_user_block(
            primary_genre=primary_genre,
            sub_genre_fusion=sub_genre_fusion,
        )
        if edm_block:
            engine_body = edm_block

    if not engine_body.strip():
        # Core commercial masters (R&B before Hip-Hop; Country/Rock before Pop).
        for composer in (
            master_rnb_user_block,
            master_hiphop_user_block,
            master_country_user_block,
            master_rock_user_block,
            master_pop_user_block,
        ):
            block = composer(
                primary_genre=primary_genre,
                sub_genre_fusion=sub_genre_fusion,
                vibe=vibe,
                lyric_theme_notes=lyric_theme_notes,
                vocal_spec=vocal_spec,
                vocal_tone=vocal_tone,
                bpm_hint=bpm_hint,
            )
            if block.strip():
                engine_body = block
                break

    if not engine_body.strip():
        lane = (genre_fx_lane or "").strip().lower() or resolve_genre_fx_key(
            primary_genre,
            sub_genre_fusion,
        )
        engine_body = lane_lyric_directive(lane)

    formatted = format_engine(engine_body)
    if formatted:
        parts.append(formatted)

    thematic = advanced_thematic_variator_block(
        primary=primary_genre,
        fusion=sub_genre_fusion,
        vibe=vibe,
    )
    if thematic:
        parts.append(thematic)

    if _matches_secret_inside_chest(vibe=vibe, lyric_theme_notes=lyric_theme_notes):
        parts.append(_secret_inside_chest_block())

    if _matches_dont_call_me_lonely(vibe=vibe, lyric_theme_notes=lyric_theme_notes):
        parts.append(_dont_call_me_lonely_block())

    return "\n\n".join(parts)
