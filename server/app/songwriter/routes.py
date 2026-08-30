"""FastAPI routes for the multi-stage songwriter lyric pipeline."""

from __future__ import annotations

import logging
import os
import re
import time
from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.llm_config import (
    build_openai_client_kwargs_for_request,
    llm_provider,
    missing_api_key_message,
    resolve_api_key,
)
from app.post_process_common import chat_simple
from app.songwriter.packs import list_genre_pack_ids
from app.songwriter.pipeline import SongBriefInput, SongwriterPipeline, pipeline_enabled
from app.songwriter.router import list_fallback_slugs, resolve_logical_model

logger = logging.getLogger("music_director.songwriter")

router = APIRouter(tags=["songwriter"])

_STAGE_MAX_TOKENS = {
    "analyze": 2048,
    "concepts": 4096,
    "select": 1024,
    "arc": 2048,
    "chorus": 4096,
    "verses": 6144,
    "bridge": 2048,
    "transitions": 6144,
    "rhyme": 6144,
    "anti_ai": 6144,
    "singability": 6144,
    "polish": 8192,
}


def _truthy(name: str) -> bool:
    return os.getenv(name, "").strip().lower() in ("1", "true", "yes", "on")


def songwriter_request_budget_seconds() -> float:
    """Wall-clock budget for the full pipeline (leave headroom under HTTP timeout)."""
    raw = os.getenv("SONGWRITER_REQUEST_BUDGET_SECONDS", "780").strip()
    try:
        return float(max(120.0, min(float(raw), 1140.0)))
    except ValueError:
        return 780.0


class GenerateLyricsRequest(BaseModel):
    genre: str = "pop"
    subgenre: str = ""
    mood: str = ""
    theme: str = ""
    story: str = ""
    language: str = "English"
    energy: int = Field(default=50, ge=0, le=100)
    perspective: str = "I"
    mode: str = "full_song"
    quality_mode: str = "balanced"
    allow_cliches: bool = False
    input_lyrics: str = ""
    bpm: str = ""
    vocal_style: str = ""
    audience: str = ""
    content_rating: str = "clean"
    hook_style: str = ""
    emotional_arc: list[str] = Field(default_factory=list)
    artist_inspiration: list[str] = Field(default_factory=list)
    constraints: list[str] = Field(default_factory=list)
    variation_count: int = Field(default=3, ge=1, le=8)
    code_switching: dict[str, Any] = Field(default_factory=dict)
    extra: dict[str, Any] = Field(default_factory=dict)
    llm_provider: str | None = None
    laozhang_api_key: str | None = None
    openrouter_api_key: str | None = None


def _is_unsupported_max_tokens_error(err: Exception) -> bool:
    msg = str(err).lower()
    return "max_tokens" in msg and (
        "max_completion_tokens" in msg or "unsupported_parameter" in msg
    )


def _make_llm_caller(
    client: Any,
    *,
    genre: str,
    language: str,
    provider_name: str | None,
    stage_hint: str = "polish",
):
    provider = llm_provider(provider_name)
    fallbacks = list_fallback_slugs(provider)

    def caller(system: str, user: str, model: str, temperature: float) -> str:
        stage_id = stage_hint
        marker = re.search(r"\[songwriter_stage=([a-z0-9_]+)\]", system)
        if marker:
            stage_id = marker.group(1)
        logical, routed = resolve_logical_model(
            genre=genre,
            language=language,
            stage=stage_id,
            provider=provider,
        )
        primary = (model or "").strip() or routed
        if primary == logical:
            primary = routed

        max_tokens = int(
            os.getenv("SONGWRITER_MAX_TOKENS", "")
            or _STAGE_MAX_TOKENS.get(stage_id, 4096)
        )
        # Primary + one fallback — avoid burning many models per stage.
        attempts = [primary, *[s for s in fallbacks if s != primary]][:2]
        last_err: Exception | None = None
        for slug in attempts:
            try:
                logger.info(
                    "songwriter chat model=%s stage~=%s temp=%.2f",
                    slug,
                    stage_id,
                    temperature,
                )
                return chat_simple(
                    client,
                    model=slug,
                    system=system,
                    user=user,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
            except Exception as e:  # noqa: BLE001
                last_err = e
                logger.warning("songwriter model failed model=%s err=%s", slug, e)
                if _is_unsupported_max_tokens_error(e):
                    continue
        raise HTTPException(
            status_code=502,
            detail=f"Songwriter LLM failed after fallbacks: {last_err}",
        )

    return caller


@router.get("/songwriter/status")
def songwriter_status() -> dict[str, Any]:
    return {
        "enabled": pipeline_enabled(),
        "feature_flag": "SONGWRITER_PIPELINE",
        "request_budget_seconds": songwriter_request_budget_seconds(),
        "genre_packs": list_genre_pack_ids(),
        "quality_modes": ["fast", "balanced", "premium", "debug"],
    }


@router.post("/generate-lyrics")
def generate_lyrics(body: GenerateLyricsRequest) -> dict[str, Any]:
    if not pipeline_enabled():
        raise HTTPException(
            status_code=503,
            detail="Songwriter pipeline disabled. Set SONGWRITER_PIPELINE=1 on the server.",
        )

    if body.mode in ("rewrite", "improve", "humanize", "translate_singable"):
        if not (body.input_lyrics or "").strip():
            raise HTTPException(
                400,
                f"Mode '{body.mode}' requires input_lyrics.",
            )

    # Soft prompt-injection guard: strip obvious override attempts from story/lyrics
    def _sanitize(text: str) -> str:
        t = text or ""
        t = re.sub(
            r"(?i)(ignore|disregard)\s+(all\s+)?(previous|above|system)\s+instructions?",
            "[filtered]",
            t,
        )
        return t

    provider = (body.llm_provider or "").strip() or None
    key = resolve_api_key(
        provider,
        laozhang_api_key=body.laozhang_api_key,
        openrouter_api_key=body.openrouter_api_key,
    )
    if not key:
        raise HTTPException(503, missing_api_key_message(provider))

    try:
        from openai import OpenAI
    except ImportError as e:
        raise HTTPException(500, "OpenAI package not installed") from e

    client = OpenAI(
        **build_openai_client_kwargs_for_request(
            llm_provider_name=provider,
            laozhang_api_key=body.laozhang_api_key,
            openrouter_api_key=body.openrouter_api_key,
        )
    )

    caller = _make_llm_caller(
        client,
        genre=body.genre,
        language=body.language,
        provider_name=provider,
    )
    pipeline = SongwriterPipeline(llm_caller=caller)
    brief = SongBriefInput(
        genre=body.genre,
        subgenre=body.subgenre,
        mood=body.mood,
        theme=_sanitize(body.theme),
        story=_sanitize(body.story),
        language=body.language,
        energy=body.energy,
        perspective=body.perspective,
        mode=body.mode,
        quality_mode=body.quality_mode,
        allow_cliches=body.allow_cliches,
        input_lyrics=_sanitize(body.input_lyrics),
        emotional_arc=body.emotional_arc,
        vocal_style=body.vocal_style,
        audience=body.audience,
        bpm=body.bpm,
        content_rating=body.content_rating,
        hook_style=body.hook_style,
        variation_count=body.variation_count,
        artist_inspiration=body.artist_inspiration,
        constraints=body.constraints,
        code_switching=body.code_switching,
        extra={
            **body.extra,
            "bpm": body.bpm,
            "vocal_style": body.vocal_style,
            "audience": body.audience,
        },
    )

    budget = songwriter_request_budget_seconds()
    deadline = time.monotonic() + budget
    try:
        result = pipeline.run(brief, deadline_monotonic=deadline)
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.exception("songwriter pipeline error")
        raise HTTPException(500, f"Songwriter pipeline error: {e}") from e

    soft_regen = _truthy("SONGWRITER_SOFT_REGENERATE")
    time_left = deadline - time.monotonic()
    if (
        soft_regen
        and time_left > 90
        and not result.get("ship")
        and not result.get("timed_out")
        and result.get("lyrics")
        and result.get("quality_status") != "failed"
    ):
        directives = []
        for stage in result.get("stages") or []:
            if stage.get("stage_id") == "polish" and isinstance(stage.get("parsed"), dict):
                directives = stage["parsed"].get("rewrite_directives") or []
        if directives:
            brief.extra = {
                **brief.extra,
                "rewrite_directives": directives,
                "prior_lyrics": result.get("lyrics"),
            }
            brief.mode = "improve"
            brief.input_lyrics = str(result.get("lyrics") or "")
            try:
                retry = pipeline.run(brief, deadline_monotonic=deadline)
                if retry.get("weighted_total", 0) >= result.get("weighted_total", 0):
                    result = retry
                    result["regenerated"] = True
            except Exception as e:  # noqa: BLE001
                logger.warning("songwriter regenerate skipped: %s", e)

    if result.get("quality_status") == "failed" and not str(result.get("lyrics") or "").strip():
        raise HTTPException(
            status_code=422,
            detail={
                "message": "Songwriter could not produce an acceptable lyric within budget.",
                "lint": result.get("lint"),
                "generation_id": result.get("generation_id"),
            },
        )

    if result.get("timed_out") and not str(result.get("lyrics") or "").strip() and not result.get("ideas"):
        raise HTTPException(
            status_code=504,
            detail=(
                "Songwriter pipeline timed out before producing lyrics. "
                "Try Chorus only / Improve mode, or raise "
                "SONGWRITER_REQUEST_BUDGET_SECONDS / REQUEST_TIMEOUT_SECONDS."
            ),
        )

    return result
