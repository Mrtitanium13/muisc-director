"""Music Director unified API: audio analysis + optional OpenAI prompt generation."""

from __future__ import annotations

import asyncio
import logging
import math
import os
import re
from pathlib import Path
from typing import Any

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from fastapi import FastAPI, File, HTTPException, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.analysis import analyze_audio_bytes
from app.http_middleware import RequestTimeoutMiddleware
from app.legacy_system_prompt import SYSTEM_PROMPT
from app.llm_config import (
    build_openai_client_kwargs_for_request,
    llm_provider,
    missing_api_key_message,
    resolve_api_key,
)
from app.laozhang_post_process import run_laozhang_post_process
from app.openrouter_post_process import run_openrouter_post_process
from app.prompt_pipeline import (
    completion_suffix_for,
    generate_prompt_completion,
    generate_suno_prompt as run_prompt_pipeline,
)
from app.block1_mix_master_directive import block1_mix_master_user_block
from app.drum_matrix import drum_matrix_user_block
from app.genre_hybridization import genre_hybridization_user_block
from app.genre_lyrics_directives import genre_lyrics_user_block
from app.live_instrument_matrix import live_instrument_user_block
from app.code_translation_matrix import code_translation_user_block
from app.human_authenticity import human_authenticity_user_block
from app.human_realism import human_realism_user_block
from app.suno_prompt_builder import (
    build_suno_prompt,
    fx_lyrics_anchor,
    production_intensity_user_block,
    resolve_genre_fx_key,
    strip_fx_layout,
)
from app.audio_environment import audio_environment_user_block
from app.payload_optimization import (
    append_laozhang_system_prompt_boundary,
    enforce_laozhang_syntax_hygiene,
    truncate_continuation_prior,
)
from app.dialect_style import dialect_style_user_block
from app.vocal_accent import vocal_accent_user_block
from app.suno_internal_output_strip import strip_internal_cognition_blocks
from app.suno_lyric_phonetic_sanitize import sanitize_suno_post_output
from app.suno_output_qa import prompt_qa_snapshot, should_format_retry
from app.remix_engine import (
    apply_remix_generation_type_output,
    remix_engine_active,
    remix_style_flip_user_block_supplement,
)
from app.suno_system_prompt_v2 import SYSTEM_PROMPT_V2

logger = logging.getLogger(__name__)

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None  # type: ignore


def _env_use_suno_v2(default: bool = True) -> bool:
    """V2 is on unless explicitly disabled (false/0/no/off)."""
    v = os.getenv("USE_SUNO_PROMPT_V2", "").strip().lower()
    if v in ("0", "false", "no", "off"):
        return False
    if v in ("1", "true", "yes"):
        return True
    return default


def _active_system_prompt() -> str:
    """V2 master prompt (Path A/B/C + genre appendix) by default; opt out with USE_SUNO_PROMPT_V2=false."""
    return SYSTEM_PROMPT_V2 if _env_use_suno_v2() else SYSTEM_PROMPT


class GeneratePromptBody(BaseModel):
    suno_version: str = Field(default="v5.0")
    primary_genre: str = ""
    sub_genre_fusion: str = ""
    vibe: str = ""
    bpm: str | None = None
    key_root: str | None = None
    scale: str | None = None
    vocal_spec: str | None = None
    vocal_tone: str | None = None
    vocal_accent: str | None = None
    dialect_style_id: str = "standard_english"
    dialect_variant_id: str = "general"
    audio_environment_mode: str = "studio_isolated"
    reference_artists: str = ""
    avoid: str = ""
    language: str = "English"
    include_analyzer_data: bool = False
    analyzer_summary: str = ""
    track_duration_label: str | None = None
    dj_intro_mix_in: bool = False
    dj_outro_mix_out: bool = False
    song_structure_directive: str = ""
    optional_lyrics: str = ""
    remix_from_analyzer: bool = False
    remix_original_song_title: str = ""
    remix_original_artist: str = ""
    song_generation_type: str = "full_song"
    real_instrumentals: str = ""
    chord_progression: str = ""
    melody_user_block: str = ""
    generate_lyrics: bool = False
    lyric_theme_notes: str = ""
    lyric_temperament_codes: str = ""
    human_realism: int = 75
    production_intensity: int = 2
    genre_fx_lane: str = ""
    duration_user_block: str = ""
    field_output_mode: str = "custom"
    user_block_suffix: str = ""
    continuation_prior_output: str = ""
    continuation_user_request: str = ""
    prefer_lightweight_model: bool = False
    # Optional: app forwards keys when server env is empty (local dev).
    llm_provider: str | None = None
    laozhang_api_key: str | None = None
    openrouter_api_key: str | None = None


def _use_v2_prompt() -> bool:
    return _env_use_suno_v2()


BLOCK1_SIMPLE_MAX = 1000
BLOCK1_CUSTOM_MAX = 1000
BLOCK1_WORD_MIN = 130
BLOCK1_WORD_MAX = 150
LYRICS_CHAR_MAX = 2500


def _normalize_field_mode(raw: str | None) -> str:
    m = (raw or "custom").strip().lower()
    return m if m in ("custom", "simple") else "custom"


def _resolve_fx_lane(body: GeneratePromptBody) -> str:
    lane = str(body.genre_fx_lane or "").strip().lower()
    if lane:
        return lane
    return resolve_genre_fx_key(
        str(body.primary_genre or ""),
        str(body.sub_genre_fusion or ""),
    )


def _apply_genre_fx_to_body(body: GeneratePromptBody) -> GeneratePromptBody:
    """Compile genre FX into vibe and optional_lyrics before LLM execution."""
    lane = _resolve_fx_lane(body)
    intensity = body.production_intensity
    vibe = str(body.vibe or "").strip()
    lyrics = strip_fx_layout(str(body.optional_lyrics or ""))
    if not vibe and not lyrics:
        return body
    built = build_suno_prompt(
        vibe,
        lyrics or fx_lyrics_anchor(lane),
        lane,
        intensity=intensity,
    )
    updates: dict[str, str] = {}
    if vibe:
        updates["vibe"] = built.prompt
    if lyrics:
        updates["optional_lyrics"] = built.lyrics
    return body.model_copy(update=updates) if updates else body


def _genre_fx_preservation_line(body: GeneratePromptBody) -> str:
    lane = _resolve_fx_lane(body)
    clamped = max(1, min(3, int(body.production_intensity or 2)))
    return (
        f"GENRE FX: lane [{lane}] at intensity {clamped} — production clauses in VIBE "
        "and arrangement tags in USER LYRICS are pre-compiled. Preserve bracket scaffolding, "
        "evolve staging per ARRANGEMENT STAGING FORMAT, and do not duplicate FX blocks."
    )


def _user_requested_block2_opt_out(b: GeneratePromptBody) -> bool:
    """Mirrors Flutter userRequestedBlock2OptOut — substring match, case-insensitive."""
    blob = " ".join(
        [
            str(b.vibe or ""),
            str(b.optional_lyrics or ""),
            str(b.lyric_theme_notes or ""),
            str(b.song_structure_directive or ""),
            str(b.avoid or ""),
        ]
    ).lower()
    return (
        "style only" in blob
        or "no lyrics" in blob
        or "no song structure" in blob
        or "block 1 only" in blob
    )


def _style_char_limit(suno_version: str) -> int:
    v = (suno_version or "").strip()
    if v in ("v3", "v4"):
        return 200
    return 400


def _v2_field_budget_line(
    suno_version: str,
    *,
    has_lyrics: bool,
    generate_lyrics: bool,
    field_mode: str,
    block2_opt_out: bool,
) -> str:
    _ = (suno_version or "").strip() or "v5.0"
    fm = _normalize_field_mode(field_mode)
    wmin, wmax = BLOCK1_WORD_MIN, BLOCK1_WORD_MAX
    lc = LYRICS_CHAR_MAX
    if block2_opt_out:
        cap = BLOCK1_SIMPLE_MAX if fm == "simple" else BLOCK1_CUSTOM_MAX
        mode = "SIMPLE" if fm == "simple" else "CUSTOM"
        tgt = f"850–{cap}" if fm == "simple" else f"850–{cap}"
        return (
            f"SUNO OUTPUT MODE: {mode}. USER REQUESTED BLOCK 1 ONLY (explicit opt-out: "
            "style only / no lyrics / no song structure / block 1 only). "
            f"Output Block 1 **only** — producer prose **{wmin}–{wmax} words** (max {wmax}), "
            f"**≤{cap}** characters (target {tgt}). "
            "Do **not** output a Block 2 banner or Lyrics-field content."
        )
    if fm == "simple":
        return (
            "SUNO OUTPUT MODE: SIMPLE. BLOCK 1 — Suno Description: rich producer prose "
            f"**{wmin}–{wmax} words** (max {wmax}), **≤{BLOCK1_SIMPLE_MAX}** characters "
            f"(target 850–{BLOCK1_SIMPLE_MAX}). One cohesive paragraph — not tag-only lists; "
            "optional final comma-dense clause when SECTION 1D/1E apply (system SECTION 0B). "
            f"BLOCK 2 — Lyrics: max {lc} chars through [End] — **always** "
            "(genre template or instrumental sections); still output Block 2 even though "
            "Simple mode uses Description only in Suno."
        )
    if has_lyrics:
        return (
            "SUNO OUTPUT MODE: CUSTOM. BLOCK 1 — STYLE: producer prose "
            f"**{wmin}–{wmax} words** (max {wmax}), **≤{BLOCK1_CUSTOM_MAX}** characters "
            f"(target 850–{BLOCK1_CUSTOM_MAX}). Narrative prose first — not tag-only; "
            "optional 1D/1E tail per SECTION 0B. "
            f"BLOCK 2 — Lyrics: max {lc} chars through [End]. Path A — refine USER LYRICS."
        )
    if generate_lyrics:
        return (
            f"SUNO OUTPUT MODE: CUSTOM. BLOCK 1 prose **{wmin}–{wmax} words**, "
            f"≤{BLOCK1_CUSTOM_MAX} chars. BLOCK 2 ≤{lc} chars. Path C — GENERATE LYRICS."
        )
    return (
        f"SUNO OUTPUT MODE: CUSTOM. BLOCK 1 prose **{wmin}–{wmax} words**, "
        f"≤{BLOCK1_CUSTOM_MAX} chars. BLOCK 2 ≤{lc} chars through [End] — **always** "
        "(Path B: genre template or instrumental sections; original lyric lines when the genre is vocal)."
    )


def _suno_style_word_range(suno_version: str) -> tuple[int, int]:
    """Inclusive [min, max] for SUNO STYLE only — aligned with Flutter SunoPromptLimits."""
    v = (suno_version or "").strip()
    if v == "v4.5":
        return 80, 150
    if v == "v5.5":
        return 200, 350
    return 150, 250


def _suno_structure_word_range(suno_version: str) -> tuple[int, int]:
    """Inclusive [min, max] for SUNO STRUCTURE — aligned with Flutter structureWordRangeFor."""
    v = (suno_version or "").strip()
    if v == "v4.5":
        return 50, 130
    if v == "v5.5":
        return 80, 200
    return 60, 160


def _lyrics_word_count(text: str | None) -> int:
    if not text:
        return 0
    s = str(text).strip()
    if not s:
        return 0
    return len(s.split())


def _max_completion_tokens(
    suno_version: str,
    *,
    has_user_lyrics: bool,
    user_lyrics_word_count: int = 0,
    generate_lyrics: bool = False,
    field_mode: str = "custom",
    block2_opt_out: bool = False,
) -> int:
    """Aligned with Flutter SunoPromptLimits.maxCompletionTokensFor."""
    tokens_per_word = 1.35
    if _use_v2_prompt():
        fm = _normalize_field_mode(field_mode)
        b1w = BLOCK1_WORD_MAX
        block1_tokens = math.ceil(b1w * tokens_per_word) + 320
        if block2_opt_out:
            if fm == "simple":
                return max(900, min(3200, block1_tokens))
            return max(1000, min(3400, block1_tokens))
        if fm == "simple":
            return max(1400, min(4200, block1_tokens + 900))
        if not has_user_lyrics:
            return max(1400, min(4200, block1_tokens + 900))
        lw = user_lyrics_word_count if user_lyrics_word_count > 0 else 80
        lw = max(0, min(5000, lw))
        lyrics_tokens = math.ceil(lw * tokens_per_word) + 220
        return max(1500, min(4500, block1_tokens + lyrics_tokens))

    _smin, smax = _suno_structure_word_range(suno_version)
    _wmin, wmax = _suno_style_word_range(suno_version)
    structure_style_tokens = math.ceil((smax + wmax) * tokens_per_word) + 130
    if not has_user_lyrics and generate_lyrics:
        return max(1200, min(3200, structure_style_tokens + 1300))
    if not has_user_lyrics:
        return max(400, min(1100, structure_style_tokens))
    lw = user_lyrics_word_count if user_lyrics_word_count > 0 else 80
    lw = max(0, min(5000, lw))
    lyrics_tokens = math.ceil(lw * tokens_per_word) + 200
    return max(700, min(4000, structure_style_tokens + lyrics_tokens))


def _word_budget_line(suno_version: str, *, has_user_lyrics: bool) -> str:
    wmin, wmax = _suno_style_word_range(suno_version)
    smin, smax = _suno_structure_word_range(suno_version)
    v = (suno_version or "").strip() or "v5.0"
    if not has_user_lyrics:
        return (
            f"WORD BUDGET (Suno {v}): Output SUNO STRUCTURE then SUNO STYLE in that order. "
            f"SUNO STRUCTURE: between {smin} and {smax} words — MUST use bracketed section lines [Intro], [Verse], etc., "
            "each on its own line; optional (parenthetical staging notes) on the following lines — see system prompt "
            "BRACKET STRUCTURE FORMAT; no plain prose paragraph for structure. "
            f"SUNO STYLE: between {wmin} and {wmax} words — production and sonic description only; "
            "must include genre-appropriate pro studio, microphone/instrument capture, and mix polish (see system prompt); "
            "do not repeat the full roadmap here; do not invent a full song lyric.\n"
            f"HARD LIMITS (Suno fields truncate): SUNO STRUCTURE body ≤ {smax} words total (count every word: "
            "[Section] labels + all parenthetical notes). "
            f"SUNO STYLE paragraph ≤ {wmax} words. Never exceed these maximums — shorten (notes) first, then compress STYLE; "
            "Power Codes do not increase caps."
        )
    return (
        f"WORD BUDGET (Suno {v}): Output SUNO STRUCTURE, then SUNO STYLE, then SUNO LYRICS in that order. "
        f"SUNO STRUCTURE: {smin}–{smax} words — bracketed [Section] format with optional (notes) per system prompt; "
        "not a prose paragraph. "
        f"SUNO STYLE: {wmin}–{wmax} words (music/production only — not the section roadmap); "
        "must include genre-appropriate pro studio, microphone/instrument capture, and mix polish (see system prompt). "
        "SUNO LYRICS: not counted in those budgets; format for Suno's Lyrics box with section tags.\n"
        f"HARD LIMITS: SUNO STRUCTURE ≤ {smax} words; SUNO STYLE ≤ {wmax} words — never exceed; shorten (notes) and "
        "dense-phrase STYLE if over; Power Codes do not raise caps."
    )


def _remix_from_analyzer_user_block_supplement(suno_version: str) -> str:
    """Aligned with Flutter SunoPromptLimits.remixFromAnalyzerUserBlockSupplement (legacy v1)."""
    wmin, wmax = _suno_style_word_range(suno_version)
    smin, smax = _suno_structure_word_range(suno_version)
    v = (suno_version or "").strip() or "v5.0"
    return (
        "REMIX / GENRE-FLIP (from audio analysis): Describe how the source becomes the target "
        "genre in SUNO STYLE only — weave analyzer cues briefly; do not paste or summarize raw "
        "analysis at length. Suno inputs are size-limited: strictly honor the WORD BUDGET line "
        f"above for this Suno {v} tier (SUNO STRUCTURE {smin}-{smax} words; SUNO STYLE "
        f"{wmin}-{wmax} words). Keep bracket (notes) concise; no preamble or postscript outside "
        "the three blocks when lyrics are provided, or two blocks when not."
    )


def _remix_from_analyzer_user_block_supplement_v2(suno_version: str) -> str:
    """Aligned with Flutter SunoPromptLimits.remixFromAnalyzerUserBlockSupplementV2."""
    v = (suno_version or "").strip() or "v5.0"
    wmin, wmax = BLOCK1_WORD_MIN, BLOCK1_WORD_MAX
    return (
        "REMIX / GENRE-FLIP (from audio analysis): Describe the transformation in "
        f"**Block 1** producer prose (**{wmin}–{wmax} words**, ≤{BLOCK1_CUSTOM_MAX} chars) — "
        "weave analyzer cues; do not paste raw analysis. "
        f"Suno {v}. Block 2 ≤ {LYRICS_CHAR_MAX} chars when lyrics apply."
    )


def _dj_mix_user_block(b: GeneratePromptBody) -> str:
    if not b.dj_intro_mix_in and not b.dj_outro_mix_out:
        return (
            "DJ mix: intro (mix-in)=false, outro (mix-out)=false — no special DJ blending."
        )
    parts: list[str] = [
        "DJ MIX (user enabled) — NON-NEGOTIABLE; Suno must follow this in the generated audio:",
    ]
    if b.dj_intro_mix_in:
        parts.append(
            "DJ INTRO (mix-in) = ON — REQUIRED BEHAVIOR:\n"
            "- The song MUST NOT start at full energy. Begin with a long DJ-friendly blend-in from a hypothetical previous track (16–48+ bars): sparse rhythm, filtered drums, rising hi-hats, subtle FX; main groove / chorus energy enters only AFTER this intro.\n"
            "- No instant drop or full vocal hook at bar 0; leave space for a crossfader blend (sidechain-friendly kick, mono-safe low end, gradual filter opening).\n"
            "- Describe the full blend-in in **Block 1** producer prose (bars, filter arc, energy staging) within **130–150 words** and **≤1000 characters**; mirror it as the FIRST section in Block 2; include key mix words (filter sweep, kick creep, snare roll, energy step at bar ~X)."
        )
    if b.dj_outro_mix_out:
        parts.append(
            "DJ OUTRO (mix-out) = ON — REQUIRED BEHAVIOR:\n"
            "- The song MUST NOT end cold on the last downbeat. Finish with a long mix-out tail for blending into the next track: strip leads and hook, sustain hats/ride, filter down or open noise, gradual energy decay; avoid a hard stop.\n"
            "- Describe the full mix-out in **Block 1** prose within **130–150 words** and **≤1000 characters**; mirror it as the LAST section in Block 2 (tail length, fade, last elements left in the mix)."
        )
    parts.append(
        "Implementation rule: Full DJ arc in **Block 1** producer prose (≤150 words, ≤1000 chars). "
        "In Block 2, the section timeline MUST start with a long intro segment (if intro on) and end with a long outro segment (if outro on) around the main song body — never skip or shorten these."
    )
    return "\n".join(parts)


def _vocal_user_block_line(b: GeneratePromptBody) -> str:
    spec = str(b.vocal_spec or "").strip()
    tone = str(b.vocal_tone or "").strip()
    accent = str(b.vocal_accent or "").strip()
    parts: list[str] = []
    if spec:
        parts.append(spec)
    if tone:
        parts.append(tone)
    if accent:
        parts.append(
            "accent/delivery (style-only, not impersonation or voice cloning): "
            + accent
        )
    if not parts:
        return "Vocal:"
    return "Vocal: " + " — ".join(parts)


def _build_user_block(b: GeneratePromptBody) -> str:
    has_lyrics = bool(str(b.optional_lyrics or "").strip())
    field_mode = _normalize_field_mode(b.field_output_mode)
    path_c = bool(b.generate_lyrics) and not has_lyrics and field_mode != "simple"
    block2_opt_out = _user_requested_block2_opt_out(b)
    if _use_v2_prompt():
        lines = [
            _v2_field_budget_line(
                b.suno_version,
                has_lyrics=has_lyrics,
                generate_lyrics=path_c,
                field_mode=field_mode,
                block2_opt_out=block2_opt_out,
            ),
        ]
    else:
        lines = [_word_budget_line(b.suno_version, has_user_lyrics=has_lyrics)]
    if b.remix_from_analyzer:
        lines.append(
            _remix_from_analyzer_user_block_supplement_v2(b.suno_version)
            if _use_v2_prompt()
            else _remix_from_analyzer_user_block_supplement(b.suno_version)
        )
    if remix_engine_active(
        original_song_title=str(b.remix_original_song_title or ""),
        original_artist=str(b.remix_original_artist or ""),
    ):
        lines.append(
            remix_style_flip_user_block_supplement(
                original_song_title=str(b.remix_original_song_title or ""),
                original_artist=str(b.remix_original_artist or ""),
                target_genre=str(b.primary_genre or ""),
                generation_type=str(b.song_generation_type or "full_song"),
            )
        )
    code_block = ""
    if _use_v2_prompt():
        code_block = code_translation_user_block(
            primary_genre=str(b.primary_genre or ""),
            sub_genre_fusion=str(b.sub_genre_fusion or ""),
            codes_blob=str(b.lyric_temperament_codes or ""),
            suno_version=str(b.suno_version or "v5.0"),
            vibe=str(b.vibe or ""),
        )
    lines.extend(
        [
        f"Suno version: {b.suno_version}",
        f"Primary genre: {b.primary_genre}",
        f"Fusion / sub-genre: {b.sub_genre_fusion}",
        f"Vibe / idea: {b.vibe}",
    ]
    )
    if _use_v2_prompt():
        hybrid_block = genre_hybridization_user_block(
            str(b.primary_genre or ""),
            fusion=str(b.sub_genre_fusion or ""),
        )
        if hybrid_block:
            lines.append(hybrid_block)
    lines.extend(
        [
        f"BPM: {b.bpm or 'unspecified'}",
        f"Key: {(b.key_root or '') + ' ' + (b.scale or '')}".strip(),
        _vocal_user_block_line(b),
    ]
    )
    accent_block = vocal_accent_user_block(
        str(b.vocal_accent or ""),
        vocal_spec=str(b.vocal_spec or ""),
        language=str(b.language or "English"),
        dialect_style_id=str(b.dialect_style_id or ""),
    )
    if accent_block:
        lines.append(accent_block)
    dialect_block = dialect_style_user_block(
        str(b.dialect_style_id or ""),
        dialect_variant_id=str(b.dialect_variant_id or ""),
    )
    if dialect_block:
        lines.append(dialect_block)
    env_block = audio_environment_user_block(str(b.audio_environment_mode or ""))
    if env_block:
        lines.append(env_block)
    lines.extend(
        [
        "Reference influences (artist/producer/DJ/song/album names OK here — "
        "ARTIST REFERENCE PROCESSING: build hidden_internal_only DNA profile; "
        "merge if multiple; never output names, song titles, or albums in final reply): "
        f"{b.reference_artists}",
        f"Avoid: {b.avoid}",
        f"Language: {b.language}",
    ]
    )
    if code_block:
        lines.append(code_block)
    cp = str(b.chord_progression or "").strip()
    if cp:
        if _use_v2_prompt():
            lines.append(
                "CHORD PROGRESSION (user specified — integrate into Block 1 prose within 130–150 words / ≤1000 chars; mirror harmony changes in Block 2 section flow; align with Key/scale when both are set): "
                + cp
            )
        else:
            lines.append(
                "CHORD PROGRESSION (user specified — integrate into SUNO STRUCTURE: parenthetical harmony per section where chords change; echo briefly as chord/pad/guitar voicing language in SUNO STYLE; align with Key/scale when both are set): "
                + cp
            )
    mu = str(b.melody_user_block or "").strip()
    if mu:
        lines.append(mu)
    ri = str(b.real_instrumentals or "").strip()
    if ri:
        if _use_v2_prompt():
            lines.append(
                live_instrument_user_block(
                    primary_genre=str(b.primary_genre or ""),
                    sub_genre_fusion=str(b.sub_genre_fusion or ""),
                    selection_raw=ri,
                    suno_version=str(b.suno_version or "v5.0"),
                    power_codes=str(b.lyric_temperament_codes or ""),
                    audio_environment_mode=str(b.audio_environment_mode or ""),
                )
            )
        else:
            lines.append(
                "Real / acoustic instruments (live or mic'd — foreground in SUNO STYLE, not as lyrics): "
                + ri
            )
    if b.track_duration_label and str(b.track_duration_label).strip():
        lines.append(
            f"Target track duration (reference): {str(b.track_duration_label).strip()}"
        )
    lines.append(_dj_mix_user_block(b))
    dur = str(b.duration_user_block or "").strip()
    if dur:
        lines.append(dur)
    if _use_v2_prompt():
        lines.append(
            block1_mix_master_user_block(
                primary_genre=str(b.primary_genre or ""),
                sub_genre_fusion=str(b.sub_genre_fusion or ""),
                dj_intro=bool(b.dj_intro_mix_in),
                dj_outro=bool(b.dj_outro_mix_out),
            )
        )
    if b.song_structure_directive.strip():
        lines.append(b.song_structure_directive.strip())
    if field_mode == "simple":
        lines.append("USER LYRICS (not provided)")
    elif has_lyrics:
        lines.append("USER LYRICS (provided)")
        lines.append(str(b.optional_lyrics).strip())
    else:
        lines.append("USER LYRICS (not provided)")
        if path_c:
            lines.append("GENERATE LYRICS")
            lines.append("/WRITEIT")
            tn = str(b.lyric_theme_notes or "").strip()
            if tn:
                lines.append(f"Lyric theme / subject / POV / keywords: {tn}")
            tc = str(b.lyric_temperament_codes or "").strip()
            if tc:
                lines.append(f"TEMPERAMENT CODES: {tc}")
    if _use_v2_prompt():
        lines.append(production_intensity_user_block(b.production_intensity))
        lines.append(_genre_fx_preservation_line(b))
    if not block2_opt_out:
        if _use_v2_prompt():
            lines.append(
                drum_matrix_user_block(
                    str(b.primary_genre or ""),
                    fusion=str(b.sub_genre_fusion or ""),
                    suno_version=str(b.suno_version or "v5.0"),
                )
            )
        lines.append(human_realism_user_block(b.human_realism))
        lines.append(
            human_authenticity_user_block(
                primary_genre=str(b.primary_genre or ""),
                sub_genre_fusion=str(b.sub_genre_fusion or ""),
                dj_outro=bool(b.dj_outro_mix_out),
                audio_environment_mode=str(b.audio_environment_mode or ""),
            )
        )
        genre_lyrics = genre_lyrics_user_block(
            primary_genre=str(b.primary_genre or ""),
            sub_genre_fusion=str(b.sub_genre_fusion or ""),
        )
        if genre_lyrics:
            lines.append(genre_lyrics)
    if b.include_analyzer_data:
        from app.gemini_analysis import FALLBACK_ANALYZER_SUMMARY, sanitize_analyzer_summary

        summary = str(b.analyzer_summary or "").strip()
        profile = FALLBACK_ANALYZER_SUMMARY
        if summary:
            for line in summary.splitlines():
                t = line.strip()
                if "," in t and not t.endswith(":") and "TARGET AUDIO PROFILE" not in t:
                    if ":" not in t or t.index(",") < t.index(":"):
                        profile = sanitize_analyzer_summary(t)
                        break
            else:
                for i, line in enumerate(summary.splitlines()):
                    if line.strip().startswith("TARGET AUDIO PROFILE") and i + 1 < len(
                        summary.splitlines()
                    ):
                        profile = sanitize_analyzer_summary(
                            summary.splitlines()[i + 1].strip()
                        )
                        break
        lines.append(
            "TARGET AUDIO PROFILE (foundational layout constraints — anchor vocal tags, "
            "mix styles, arrangement pacing):\n" + profile
        )
        if summary:
            lines.append("Audio analysis detail:\n" + summary)
    cp = truncate_continuation_prior(str(b.continuation_prior_output or ""))
    cr = str(b.continuation_user_request or "").strip()
    if cp and cr:
        lines.append(
            "PRIOR OUTPUT (revise to one full Suno reply; keep intent unless follow-up contradicts):\n"
            f"---\n{cp}\n---\n\nFOLLOW-UP:\n{cr}"
        )
    suf = str(b.user_block_suffix or "").strip()
    if suf:
        lines.append(suf)
    return "\n".join(lines)


def _is_separator_or_banner_only_line(t: str) -> bool:
    if not t:
        return False
    sep = "━═─▔▁‐-–—"
    for ch in t:
        if ch.isspace():
            continue
        if ch in sep:
            continue
        if ch in ("📋", "⚡"):
            continue
        return False
    return True


def _strip_decorative_lines_block1_body(text: str) -> str:
    out_lines: list[str] = []
    for line in text.split("\n"):
        t = line.strip()
        if not t:
            out_lines.append(line)
            continue
        if re.match(r"^[\-=]{3,}$", t):
            continue
        if _is_separator_or_banner_only_line(t):
            continue
        out_lines.append(line)
    return "\n".join(out_lines)


def _line_is_block1_style_header(line: str) -> bool:
    t = line.strip()
    if not t:
        return False
    u = t.upper()
    if "PASTE INTO SUNO:" in u and "STYLE" in u and "LYRICS" not in u:
        return True
    if "BLOCK" not in u:
        return False
    if not re.search(r"BLOCK\s*1", u):
        return False
    return "STYLE" in u


def _line_is_block2_lyrics_header(line: str) -> bool:
    u = line.strip().upper()
    if "PASTE INTO SUNO:" in u and "LYRICS" in u:
        return True
    if "BLOCK" not in u:
        return False
    if not re.search(r"BLOCK\s*2", u):
        return False
    return "LYRICS" in u


def _flatten_block1_body_simple(stripped: str) -> str:
    s = re.sub(r"[\r\n]+", " ", stripped)
    return re.sub(r"\s+", " ", s).strip()


def _flatten_block1_body_comma(stripped: str) -> str:
    s = re.sub(r"[\r\n]+", ", ", stripped)
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r",\s*,+", ",", s)
    s = re.sub(r"^\s*,\s*", "", s)
    s = re.sub(r",\s*$", "", s)
    return s


def _smart_trim_comma_block1(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    sub = text[:limit]
    last_comma = sub.rfind(",")
    if last_comma > 0:
        return text[:last_comma].rstrip()
    return sub.rstrip()


def _smart_trim_simple_description(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    sub = text[:limit]
    last_sp = sub.rfind(" ")
    if last_sp > limit - 40:
        return sub[:last_sp].rstrip()
    return sub.rstrip()


def _enforce_unified_block1_char_limit(raw: str, field_mode: str) -> str:
    fm = _normalize_field_mode(field_mode)
    limit = BLOCK1_SIMPLE_MAX if fm == "simple" else BLOCK1_CUSTOM_MAX
    normalized = raw.replace("\r\n", "\n")
    lines = normalized.split("\n")
    i_block1 = -1
    i_block2 = -1
    for i, line in enumerate(lines):
        if _line_is_block2_lyrics_header(line) and i_block2 < 0:
            i_block2 = i
        elif _line_is_block1_style_header(line) and i_block1 < 0:
            i_block1 = i
    if i_block1 < 0:
        return raw
    end_excl = i_block2 if i_block2 >= 0 else len(lines)
    if i_block1 + 1 >= end_excl:
        return raw
    body_chunk = "\n".join(lines[i_block1 + 1 : end_excl])
    stripped = _strip_decorative_lines_block1_body(body_chunk).strip()
    if not stripped:
        return raw
    flat = (
        _flatten_block1_body_simple(stripped)
        if fm == "simple"
        else _flatten_block1_body_comma(stripped)
    )
    trimmed = (
        flat
        if len(flat) <= limit
        else (
            _smart_trim_simple_description(flat, limit)
            if fm == "simple"
            else _smart_trim_comma_block1(flat, limit)
        )
    )
    if "\n" not in stripped and trimmed == flat and len(flat) <= limit:
        return raw
    return "\n".join(lines[: i_block1 + 1] + [trimmed] + lines[end_excl:])


def _resolve_system_prompt(
    provider: str | None,
    system_prompt: str | None = None,
) -> str:
    sys = system_prompt if system_prompt is not None else _active_system_prompt()
    if llm_provider(provider) == "laozhang":
        sys = append_laozhang_system_prompt_boundary(sys)
    return sys


def _call_prompt_pipeline(
    client: Any,
    *,
    body: GeneratePromptBody,
    user_content: str,
    max_tok: int,
    temperature: float,
    provider: str | None,
    user_suffix: str | None = None,
    lyrics_task: bool = True,
    system_prompt: str | None = None,
) -> tuple[str, str]:
    sys = _resolve_system_prompt(provider, system_prompt)
    try:
        text, pipeline = run_prompt_pipeline(
            client,
            system_prompt=sys,
            user_content=user_content,
            language=str(body.language),
            lightweight=bool(body.prefer_lightweight_model),
            max_tokens=max_tok,
            temperature=temperature,
            provider=provider,
            user_suffix=user_suffix,
            lyrics_task=lyrics_task,
        )
        return text, pipeline
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"LLM error: {e!s}") from e


def _finalize_prompt_text(
    text: str,
    field_mode: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    audio_environment_mode: str = "",
    sanitize_output: bool = True,
) -> str:
    text = strip_internal_cognition_blocks(text)
    if _use_v2_prompt():
        if sanitize_output:
            text = sanitize_suno_post_output(
                text,
                primary_genre=primary_genre,
                sub_genre_fusion=sub_genre_fusion,
                audio_environment_mode=audio_environment_mode,
            )
        return _enforce_unified_block1_char_limit(text, field_mode)
    return text


def _run_generate_prompt(body: GeneratePromptBody) -> dict[str, str]:
    """Blocking LLM work (Gemini draft + optional Flash polish)."""
    body = _apply_genre_fx_to_body(body)
    provider = (body.llm_provider or "").strip() or None
    key = resolve_api_key(
        provider,
        laozhang_api_key=body.laozhang_api_key,
        openrouter_api_key=body.openrouter_api_key,
    )
    if not key:
        raise HTTPException(503, missing_api_key_message(provider))
    if OpenAI is None:
        raise HTTPException(500, "OpenAI package not installed")

    client = OpenAI(
        **build_openai_client_kwargs_for_request(
            llm_provider_name=provider,
            laozhang_api_key=body.laozhang_api_key,
            openrouter_api_key=body.openrouter_api_key,
        )
    )
    lyrics = str(body.optional_lyrics or "").strip()
    has_lyrics = bool(lyrics)
    field_mode = _normalize_field_mode(body.field_output_mode)
    path_c = bool(body.generate_lyrics) and not has_lyrics and field_mode != "simple"
    block2_opt_out = _user_requested_block2_opt_out(body)
    lyrics_task = not block2_opt_out
    max_tok = _max_completion_tokens(
        body.suno_version,
        has_user_lyrics=has_lyrics,
        user_lyrics_word_count=_lyrics_word_count(body.optional_lyrics),
        generate_lyrics=path_c,
        field_mode=field_mode,
        block2_opt_out=block2_opt_out,
    )

    user_content = _build_user_block(body)
    text, pipeline = _call_prompt_pipeline(
        client,
        body=body,
        user_content=user_content,
        max_tok=max_tok,
        temperature=0.85,
        provider=provider,
        lyrics_task=lyrics_task,
    )
    pg = str(body.primary_genre or "")
    fg = str(body.sub_genre_fusion or "")
    env_mode = str(body.audio_environment_mode or "")
    text = _finalize_prompt_text(
        text,
        field_mode,
        primary_genre=pg,
        sub_genre_fusion=fg,
        audio_environment_mode=env_mode,
        sanitize_output=False,
    )

    use_v2 = _use_v2_prompt()
    for attempt in range(2):
        snap = prompt_qa_snapshot(
            text, use_v2=use_v2, block2_opt_out=block2_opt_out
        )
        if not snap["should_format_retry"]:
            break
        suffix = completion_suffix_for(text)
        prior_suffix = str(body.user_block_suffix or "").strip()
        retry_body = body.model_copy(
            update={
                "user_block_suffix": (
                    f"{prior_suffix}\n\n{suffix}".strip() if prior_suffix else suffix
                ),
            }
        )
        retry_content = _build_user_block(retry_body)
        max_tok_retry = min(int(max_tok * (1.25 + attempt * 0.25)), 8192)
        retry_text, retry_pipeline = _call_prompt_pipeline(
            client,
            body=retry_body,
            user_content=retry_content,
            max_tok=max_tok_retry,
            temperature=0.35,
            provider=provider,
            lyrics_task=lyrics_task,
        )
        retry_text = _finalize_prompt_text(
            retry_text,
            field_mode,
            primary_genre=pg,
            sub_genre_fusion=fg,
            audio_environment_mode=env_mode,
            sanitize_output=False,
        )
        retry_snap = prompt_qa_snapshot(
            retry_text, use_v2=use_v2, block2_opt_out=block2_opt_out
        )
        if not retry_snap["should_format_retry"] or len(retry_text) > len(text):
            text, pipeline = retry_text, f"{retry_pipeline}:format-retry-{attempt + 1}"

    final_snap = prompt_qa_snapshot(
        text, use_v2=use_v2, block2_opt_out=block2_opt_out
    )
    if final_snap["should_format_retry"]:
        try:
            completion_text, completion_pipeline = generate_prompt_completion(
                client,
                system_prompt=_resolve_system_prompt(provider),
                user_content=user_content,
                partial=text,
                language=str(body.language),
                lightweight=bool(body.prefer_lightweight_model),
                max_tokens=max_tok,
                provider=provider,
                lyrics_task=lyrics_task,
            )
            completion_text = _finalize_prompt_text(
                completion_text,
                field_mode,
                primary_genre=pg,
                sub_genre_fusion=fg,
                audio_environment_mode=env_mode,
                sanitize_output=False,
            )
            comp_snap = prompt_qa_snapshot(
                completion_text, use_v2=use_v2, block2_opt_out=block2_opt_out
            )
            if not comp_snap["should_format_retry"] or len(completion_text) > len(text):
                text, pipeline = completion_text, completion_pipeline
        except Exception as e:  # noqa: BLE001
            logger.warning("completion pass failed: %s", e)

    remix_title = str(body.remix_original_song_title or "")
    remix_artist = str(body.remix_original_artist or "")
    remix_gen_type = str(body.song_generation_type or "full_song")
    remix_instrumental = (
        remix_engine_active(original_song_title=remix_title, original_artist=remix_artist)
        and remix_gen_type.strip().lower() == "instrumental"
    )
    pp_lyrics_task = lyrics_task and not remix_instrumental

    if use_v2 and lyrics_task:
        try:
            if llm_provider(provider) == "openrouter":
                text, pp_suffix = run_openrouter_post_process(
                    client,
                    text=text,
                    primary_genre=str(body.primary_genre or ""),
                    sub_genre_fusion=str(body.sub_genre_fusion or ""),
                    vibe=str(body.vibe or ""),
                    lyric_theme_notes=str(body.lyric_theme_notes or ""),
                    language=str(body.language or "English"),
                    vocal_accent=str(body.vocal_accent or ""),
                    dialect_style_id=str(body.dialect_style_id or ""),
                    dialect_variant_id=str(body.dialect_variant_id or ""),
                    audio_environment_mode=env_mode,
                    field_mode=field_mode,
                    provider=provider,
                    lightweight=bool(body.prefer_lightweight_model),
                    lyrics_task=pp_lyrics_task,
                    remix_original_song_title=remix_title,
                    remix_original_artist=remix_artist,
                    song_generation_type=remix_gen_type,
                )
                if pp_suffix:
                    pipeline = f"{pipeline}:{pp_suffix}"
            elif llm_provider(provider) == "laozhang" and pp_lyrics_task:
                text, pp_suffix = run_laozhang_post_process(
                    client,
                    text=text,
                    primary_genre=str(body.primary_genre or ""),
                    sub_genre_fusion=str(body.sub_genre_fusion or ""),
                    vibe=str(body.vibe or ""),
                    lyric_theme_notes=str(body.lyric_theme_notes or ""),
                    language=str(body.language or "English"),
                    vocal_accent=str(body.vocal_accent or ""),
                    dialect_style_id=str(body.dialect_style_id or ""),
                    dialect_variant_id=str(body.dialect_variant_id or ""),
                    audio_environment_mode=env_mode,
                    field_mode=field_mode,
                    provider=provider,
                    lightweight=bool(body.prefer_lightweight_model),
                    lyrics_task=pp_lyrics_task,
                    remix_original_song_title=remix_title,
                    remix_original_artist=remix_artist,
                    song_generation_type=remix_gen_type,
                )
                if pp_suffix:
                    pipeline = f"{pipeline}:{pp_suffix}"
        except Exception as e:  # noqa: BLE001
            logger.warning("post-process pass failed: %s", e)

    text = _finalize_prompt_text(
        text,
        field_mode,
        primary_genre=pg,
        sub_genre_fusion=fg,
        audio_environment_mode=env_mode,
    )
    text = apply_remix_generation_type_output(
        text,
        original_song_title=remix_title,
        original_artist=remix_artist,
        generation_type=remix_gen_type,
    )
    return {"prompt": text, "pipeline": pipeline}


def create_app() -> FastAPI:
    app = FastAPI(title="Music Director API", version="1.0.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    # Outermost: allow long analyze + hybrid generate (added after CORS → runs first).
    app.add_middleware(RequestTimeoutMiddleware)

    @app.get("/")
    def root() -> dict[str, Any]:
        return {
            "service": "Music Director API",
            "version": "1.0.0",
            "routes": {
                "health": "GET /health",
                "analyze": "POST /analyze (multipart file)",
                "generate_prompt": "POST /generate-prompt (JSON)",
            },
        }

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    async def _analyze_upload(file: UploadFile) -> dict[str, Any]:
        if not file.filename:
            raise HTTPException(400, "No file wrapper found")
        filename = file.filename

        # 1. SAFE BYTE EXTRACTION — read once; never pass UploadFile stream to librosa
        file_bytes = await file.read()
        if len(file_bytes) < 1024:
            raise HTTPException(400, "File too small")
        from app.analysis import fallback_analysis_payload

        try:
            return await asyncio.to_thread(analyze_audio_bytes, file_bytes, filename)
        except Exception as e:  # noqa: BLE001
            logger.exception("CRITICAL SYSTEM ERROR during /analyze: %s", e)
            return fallback_analysis_payload(reason=str(e))

    @app.post("/analyze")
    async def analyze(file: UploadFile = File(...)) -> dict[str, Any]:
        return await _analyze_upload(file)

    async def _generate_prompt_route(body: GeneratePromptBody) -> dict[str, str]:
        response = await asyncio.to_thread(_run_generate_prompt, body)
        if llm_provider(body.llm_provider) == "laozhang" and "prompt" in response:
            response = dict(response)
            response["prompt"] = enforce_laozhang_syntax_hygiene(response["prompt"])
        return response

    @app.post("/generate-prompt")
    async def generate_prompt(body: GeneratePromptBody) -> dict[str, str]:
        return await _generate_prompt_route(body)

    # Legacy / mistaken paths (avoid 404 when base URL or old clients are wrong).
    @app.post("/generate")
    async def generate_prompt_legacy(
        body: GeneratePromptBody, response: Response
    ) -> dict[str, str]:
        response.headers["X-API-Deprecation-Warning"] = (
            "Route /generate is legacy. Upgrade client."
        )
        return await _generate_prompt_route(body)

    @app.post("/api/generate-prompt")
    async def generate_prompt_api_prefix(
        body: GeneratePromptBody, response: Response
    ) -> dict[str, str]:
        response.headers["X-API-Deprecation-Warning"] = (
            "Route /api/generate-prompt is legacy. Upgrade client."
        )
        return await _generate_prompt_route(body)

    return app


app = create_app()
