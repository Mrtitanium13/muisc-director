"""LLM track classifier — metadata + genre when AudD fingerprinting returns nothing."""

from __future__ import annotations

import logging
import os
from typing import Any

from app.audd_recognition import audd_genre_from_result, track_metadata_from_audd
from app.gemini_analysis import _parse_json_response
from app.llm_config import build_openai_client_kwargs, resolve_analysis_model

logger = logging.getLogger(__name__)

_CLASSIFIER_SYSTEM = """You are a music identification and classification expert for a production app.
Given physical audio metrics (BPM, duration, key, energy, harmony footprint) and an optional filename hint,
identify the most likely commercial song OR provide an accurate smart classification for an unknown upload.

Return ONLY valid JSON (no markdown):
{
  "title": "Song Title or descriptive label",
  "artist": "Artist Name or Independent Creator",
  "album": "Album name or Studio Session",
  "releaseDate": "YYYY or year string",
  "genre": "Primary genre label",
  "instruments": ["4-6 dominant instruments/sounds"],
  "identified": true|false
}

Rules:
- Set identified=true only when confident this is a specific known commercial release.
- For unknown voice memos, stems, or originals use identified=false with honest descriptive labels.
- Genre and instruments must reflect the BPM pocket, energy, and harmonic profile — never generic filler.
- Famous stem examples: Ghost by Justin Bieber (~72/144 BPM, F# Minor); use identified=true only when metrics fit strongly.
"""


def llm_track_classifier_enabled() -> bool:
    flag = os.getenv("LLM_TRACK_CLASSIFIER", "").strip().lower()
    if flag in ("0", "false", "no", "off"):
        return False
    if flag in ("1", "true", "yes", "on"):
        return True
    legacy = os.getenv("METADATA_AI_RECONCILE", "").strip().lower()
    if legacy in ("0", "false", "no", "off"):
        return False
    return bool(build_openai_client_kwargs().get("api_key"))


def _format_track_length(signals: dict[str, Any]) -> str:
    if signals.get("trackLength"):
        return str(signals["trackLength"])
    try:
        seconds = float(signals.get("durationSeconds") or 0)
    except (TypeError, ValueError):
        return "Unknown"
    minutes = int(seconds // 60)
    secs = int(seconds % 60)
    return f"{minutes}:{secs:02d}"


def heuristic_track_metadata(
    signals: dict[str, Any],
    *,
    filename: str = "audio",
) -> dict[str, Any]:
    """Deterministic metadata when AudD and LLM are both unavailable."""
    try:
        calculated_bpm = int(round(float(signals.get("bpm") or 120)))
    except (TypeError, ValueError):
        calculated_bpm = 120

    if 85 <= calculated_bpm <= 105:
        genre = "Hip-Hop / Rap / Urban Beat (estimate)"
        instruments = ["Drums", "Heavy Bass", "Synths", "Vocals"]
    else:
        genre = "Acoustic Pop / Mixed Production (estimate)"
        instruments = ["Acoustic Guitar", "Keys", "Soft Peripherals"]

    return {
        "title": "Original Track / Voice Memo",
        "artist": "Independent Creator",
        "album": "Studio Session",
        "releaseDate": "2026",
        "genre": genre,
        "instruments": instruments,
        "trackRecognized": False,
        "metadataSource": "heuristic",
    }


def classify_track_with_llm(
    *,
    signals: dict[str, Any],
    filename: str = "audio",
) -> dict[str, Any] | None:
    """Ask Gemini/LLM to deduce title, artist, genre from physical audio footprints."""
    if not llm_track_classifier_enabled():
        return None

    try:
        from openai import OpenAI
    except ImportError:
        return None

    kwargs = build_openai_client_kwargs()
    if not kwargs.get("api_key"):
        return None

    try:
        calculated_bpm = int(round(float(signals.get("bpm") or 120)))
    except (TypeError, ValueError):
        calculated_bpm = 120

    track_length = _format_track_length(signals)
    user_prompt = f"""Analyze this uploaded song profile:
- Physical BPM: {calculated_bpm}
- Track Duration: {track_length}
- Key / scale: {signals.get("keyScale") or "Unknown"}
- Energy: {signals.get("energy") or "Unknown"}
- Implied harmony: {signals.get("impliedChords") or "Unknown"}
- Melody range: {signals.get("melodyProfile") or "Unknown"}
- File name: {filename}

Identify what song this likely is, or provide a highly accurate smart classification.
Return strict JSON with keys: title, artist, album, releaseDate, genre, instruments, identified."""

    resolved_model = resolve_analysis_model()
    timeout_s = float(os.getenv("LLM_TRACK_CLASSIFIER_TIMEOUT", "25"))

    try:
        client = OpenAI(**kwargs)
        resp = client.chat.completions.create(
            model=resolved_model,
            messages=[
                {"role": "system", "content": _CLASSIFIER_SYSTEM},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.15,
            max_tokens=384,
            timeout=timeout_s,
        )
        raw = (resp.choices[0].message.content or "").strip()
        parsed = _parse_json_response(raw)
    except Exception as exc:  # noqa: BLE001
        logger.warning("LLM track classifier failed: %s", exc)
        return None

    if not parsed:
        return None

    title = str(parsed.get("title") or "").strip()
    artist = str(parsed.get("artist") or "").strip()
    if not title or not artist:
        return None

    instruments_raw = parsed.get("instruments")
    if isinstance(instruments_raw, list):
        instruments = [str(x).strip() for x in instruments_raw if str(x).strip()]
    elif isinstance(instruments_raw, str) and instruments_raw.strip():
        instruments = [p.strip() for p in instruments_raw.replace("·", ",").split(",") if p.strip()]
    else:
        instruments = []

    release = str(
        parsed.get("releaseDate") or parsed.get("release") or parsed.get("release_date") or ""
    ).strip() or "Custom"

    identified = bool(parsed.get("identified"))
    if parsed.get("matched") is True:
        identified = True

    logger.info(
        "LLM track classifier: %r by %r (identified=%s)",
        title,
        artist,
        identified,
    )
    return {
        "title": title,
        "artist": artist,
        "album": str(parsed.get("album") or "").strip() or "Single",
        "releaseDate": release,
        "genre": str(parsed.get("genre") or "").strip() or "Detected Production (estimate)",
        "instruments": instruments or ["Drums", "Bass", "Vocals", "Synths"],
        "trackRecognized": identified,
        "metadataSource": "llm",
    }


def resolve_track_metadata(
    audd_result: dict[str, Any] | None,
    *,
    signals: dict[str, Any],
    filename: str = "audio",
) -> dict[str, Any]:
    """
    AudD match first; otherwise LLM classifier on librosa footprints;
    finally deterministic heuristic from BPM pocket.
    """
    if audd_result:
        meta = track_metadata_from_audd(audd_result)
        genre = audd_genre_from_result(audd_result)
        if genre:
            meta["genre"] = genre
        else:
            meta["genre"] = "Detected Production (estimate)"
        meta["metadataSource"] = "audd"
        return meta

    logger.info("AudD returned null. Passing physical audio footprints to Gemini...")
    classified = classify_track_with_llm(signals=signals, filename=filename)
    if classified:
        return classified

    return heuristic_track_metadata(signals, filename=filename)
