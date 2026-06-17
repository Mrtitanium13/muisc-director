"""Full-track audio analysis via LaoZhang Gemini 2.5 Flash / Pro."""

from __future__ import annotations

import base64
import io
import json
import logging
import os
import re
from typing import Any

import librosa
import numpy as np
import soundfile as sf

from app.llm_config import (
    analysis_gemini_enabled,
    build_openai_client_kwargs,
    resolve_analysis_model,
)

logger = logging.getLogger(__name__)

FALLBACK_ANALYZER_SUMMARY = (
    "General Delivery, Smooth Close-Mic, Moderate Energy, Pristine Studio Environment"
)

_MAX_AUDIO_BYTES = 12 * 1024 * 1024
_DEFAULT_GEMINI_CLIP_SECONDS = 120.0
_GEMINI_SAMPLE_RATE = 16000

_GEMINI_SYSTEM = """You are an expert musicologist and production analyst for a Suno prompt director app.
Listen to the uploaded audio carefully. Return ONLY valid JSON (no markdown) matching this schema:

{
  "genre": "string — primary genre",
  "subGenre": "string — sub-genre or fusion lane",
  "moodTags": ["3-6 short mood/energy adjectives"],
  "energy": "string — e.g. High (78/100) or Medium (52/100)",
  "bpm": number — best estimate (integer or one decimal),
  "keyScale": "string — e.g. F# Minor",
  "instruments": ["4-10 dominant instruments/sounds"],
  "vocals": "string — vocal type/delivery; use Instrumental if none",
  "structure": "string — one-line roadmap e.g. Intro → Verse → Chorus → Bridge → Outro",
  "structureSections": [{"name": "Intro", "barsOrTime": "optional", "description": "what happens"}],
  "lyricsTranscription": "string — transcribe sung/rapped lyrics if present; empty string if instrumental",
  "tempoFeel": "string",
  "chordComplexity": "Low | Moderate | Rich",
  "loudness": "string — perceived loudness estimate",
  "confidenceOverall": "High | Medium | Low",
  "richDescription": "string — 2-4 sentences: production, groove, mix, emotional arc for a producer",
  "analyzerSummary": "string — EXACTLY 4 comma-separated tags, no other punctuation: [Vocal Register/Accent], [Delivery Style], [Tempo/Energy Level], [Production Environment]",
  "vocalDelivery": "string — register, accent, mic distance (for analyzerSummary)",
  "tempoEnergy": "string — tempo feel + energy band (for analyzerSummary)",
  "moodProfile": "string — 2-4 mood adjectives (for analyzerSummary)",
  "productionEnvironment": "string — room/stage/mix environment (for analyzerSummary)"
}

Rules:
- Be specific; avoid generic filler.
- analyzerSummary is MANDATORY: one line, four tags, commas only — no markdown, greeting, or explanation.
  Example: Male Lead Raspy West African Delivery, Emotional Close-Mic, Low Energy Sparse Groove, Dead-Room Isolation
- If unsure on BPM/key, give your best estimate and set confidenceOverall accordingly.
- structureSections: 4-10 items when the track has clear sections; fewer for ambient/loop material.
- lyricsTranscription: only when intelligible vocals exist; otherwise "".
"""

_SEMANTIC_PROFILE_SYSTEM = """You are an expert audio engineering translation service.
Return ONLY valid JSON (no markdown) with a single key:

{"analyzerSummary": "Tag1, Tag2, Tag3, Tag4"}

Tag order (mandatory):
1. Vocal Register/Accent (or Instrumental Lead if no vocals)
2. Delivery Style (mic distance, articulation, performance)
3. Tempo/Energy Level (tempo feel + energy band)
4. Production Environment (room, stage, isolation, mix aesthetic)

No greeting, explanation, or extra keys. Four comma-separated phrases only."""

_SEMANTIC_USER_TEMPLATE = """Translate DSP metrics and optional transcription into analyzerSummary JSON.

DSP METRICS: {dsp_json}
VOICE TRANSCRIPT: "{transcription}"

Return JSON only."""

_USER_TEMPLATE = """Analyze this audio file for music production and Suno prompt generation.

Filename: {filename}
File size: {size_kb} KB
{audio_note}

Return JSON only."""


def _gemini_clip_seconds() -> float:
    raw = os.getenv("ANALYSIS_GEMINI_MAX_SECONDS", "").strip()
    if not raw:
        return _DEFAULT_GEMINI_CLIP_SECONDS
    try:
        return float(np.clip(float(raw), 30.0, 240.0))
    except ValueError:
        return _DEFAULT_GEMINI_CLIP_SECONDS


def _clip_audio_for_gemini(data: bytes, filename: str) -> tuple[bytes, str, bool]:
    """
    Downsample + trim for Gemini upload (faster API, smaller payload).
    Returns (bytes, filename_for_mime, was_clipped).
    """
    max_s = _gemini_clip_seconds()
    try:
        buf = io.BytesIO(data)
        y, sr = librosa.load(buf, sr=_GEMINI_SAMPLE_RATE, mono=True, duration=max_s)
        if y.size < 1024:
            return data, filename, False
        out = io.BytesIO()
        sf.write(out, y, sr, format="WAV")
        clipped = out.getvalue()
        base = os.path.splitext(filename or "audio")[0]
        return clipped, f"{base}_clip.wav", True
    except Exception as e:  # noqa: BLE001
        logger.warning("Gemini audio clip failed, using full file: %s", e)
        return data, filename, False


def _guess_audio_format(filename: str, data: bytes) -> str:
    ext = os.path.splitext(filename or "")[1].lower().lstrip(".")
    if ext in ("mp3", "wav", "m4a", "webm", "ogg", "flac", "mpeg", "mpga"):
        return ext if ext != "mpeg" else "mp3"
    if data[:3] == b"ID3" or (len(data) > 2 and data[0] == 0xFF and (data[1] & 0xE0) == 0xE0):
        return "mp3"
    if data[:4] == b"RIFF":
        return "wav"
    if len(data) > 8 and data[4:8] == b"ftyp":
        return "m4a"
    return "mp3"


def _mime_for_format(fmt: str) -> str:
    return {
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "m4a": "audio/mp4",
        "webm": "audio/webm",
        "ogg": "audio/ogg",
        "flac": "audio/flac",
    }.get(fmt, "audio/mpeg")


def _audio_parts(data: bytes, filename: str) -> list[dict[str, Any]]:
    fmt = _guess_audio_format(filename, data)
    mime = _mime_for_format(fmt)
    b64 = base64.standard_b64encode(data).decode("ascii")
    return [
        {
            "type": "input_audio",
            "input_audio": {"data": b64, "format": fmt},
        },
        {
            "type": "image_url",
            "image_url": {"url": f"data:{mime};base64,{b64}"},
        },
    ]


def sanitize_analyzer_summary(raw: str | None) -> str:
    """Normalize to exactly four comma-separated tags; never return empty."""
    if raw is None:
        return FALLBACK_ANALYZER_SUMMARY
    text = str(raw).replace("`", "").replace("\n", " ").strip()
    text = re.sub(
        r"^(here is|output:|analysis:|target audio profile:)\s*",
        "",
        text,
        flags=re.IGNORECASE,
    ).strip()
    if not text:
        return FALLBACK_ANALYZER_SUMMARY
    parts = [p.strip() for p in text.split(",") if p.strip()]
    if len(parts) >= 4:
        return ", ".join(parts[:4])
    if len(parts) == 3:
        return ", ".join(parts + ["Pristine Studio Environment"])
    if len(parts) == 2:
        return ", ".join(
            parts + ["Moderate Energy", "Pristine Studio Environment"]
        )
    if len(parts) == 1:
        return (
            f"{parts[0]}, Smooth Close-Mic, Moderate Energy, "
            "Pristine Studio Environment"
        )
    return FALLBACK_ANALYZER_SUMMARY


def build_analyzer_summary_from_result(result: dict[str, Any]) -> str:
    """Deterministic profile from normalized analysis fields (no API call)."""
    direct = result.get("analyzerSummary")
    if direct:
        return sanitize_analyzer_summary(str(direct))

    vocals = str(result.get("vocals") or "").strip()
    if not vocals or vocals.lower() == "instrumental":
        tag1 = "Instrumental Lead"
    else:
        tag1 = vocals

    delivery = str(
        result.get("vocalDelivery")
        or result.get("vocal_delivery")
        or "Smooth Close-Mic"
    ).strip()

    energy = str(result.get("tempoEnergy") or result.get("energy") or "").strip()
    tempo = str(result.get("tempoFeel") or "").strip()
    if energy and tempo:
        tag3 = f"{tempo} · {energy}"
    else:
        tag3 = energy or tempo or "Moderate Energy"

    env = str(
        result.get("productionEnvironment")
        or result.get("production_environment")
        or ""
    ).strip()
    if not env:
        loud = str(result.get("loudness") or "").lower()
        if "room" in loud or "dry" in loud:
            env = "Dead-Room Isolation"
        elif "live" in loud or "crowd" in loud:
            env = "Live Stage Wash"
        else:
            inst = result.get("instruments") or []
            if isinstance(inst, list) and any(
                "acoustic" in str(x).lower() for x in inst
            ):
                env = "Natural Room Ambience"
            else:
                env = "Pristine Studio Environment"

    return sanitize_analyzer_summary(f"{tag1}, {delivery}, {tag3}, {env}")


def analyze_audio_semantics(
    audio_features_from_dsp: dict[str, Any],
    transcription_text: str = "",
    *,
    model: str | None = None,
) -> str:
    """
    Text-only Gemini pass: DSP metrics + optional lyrics → constrained analyzerSummary.
    Falls back to synthesized profile when the API is unavailable.
    """
    synthesized = build_analyzer_summary_from_result(
        {
            **audio_features_from_dsp,
            "lyricsTranscription": transcription_text,
        }
    )
    try:
        from openai import OpenAI
    except ImportError:
        return synthesized

    kwargs = build_openai_client_kwargs()
    if not kwargs.get("api_key"):
        return synthesized

    resolved_model = (model or "").strip() or resolve_analysis_model()
    dsp_json = json.dumps(audio_features_from_dsp, default=str)
    user_msg = _SEMANTIC_USER_TEMPLATE.format(
        dsp_json=dsp_json,
        transcription=(transcription_text or "").replace('"', "'")[:1200],
    )

    try:
        client = OpenAI(**kwargs)
        timeout_s = float(os.getenv("ANALYSIS_GEMINI_TIMEOUT", "90"))
        resp = client.chat.completions.create(
            model=resolved_model,
            messages=[
                {"role": "system", "content": _SEMANTIC_PROFILE_SYSTEM},
                {"role": "user", "content": user_msg},
            ],
            temperature=0.15,
            max_tokens=256,
            timeout=timeout_s,
        )
        raw = (resp.choices[0].message.content or "").strip()
        parsed = _parse_json_response(raw)
        if parsed and parsed.get("analyzerSummary"):
            return sanitize_analyzer_summary(str(parsed["analyzerSummary"]))
        if raw and "," in raw:
            return sanitize_analyzer_summary(raw)
    except Exception as exc:  # noqa: BLE001
        logger.warning("analyze_audio_semantics failed: %s", exc)

    return synthesized


def _parse_json_response(raw: str) -> dict[str, Any] | None:
    text = raw.strip()
    fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if fence:
        text = fence.group(1).strip()
    try:
        obj = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start < 0 or end <= start:
            return None
        try:
            obj = json.loads(text[start : end + 1])
        except json.JSONDecodeError:
            return None
    return obj if isinstance(obj, dict) else None


def _as_str_list(val: Any, *, limit: int) -> list[str]:
    if val is None:
        return []
    if isinstance(val, list):
        return [str(x).strip() for x in val if str(x).strip()][:limit]
    s = str(val).strip()
    return [s] if s else []


def _structure_line(parsed: dict[str, Any]) -> str | None:
    direct = str(parsed.get("structure") or "").strip()
    if direct:
        return direct
    sections = parsed.get("structureSections") or parsed.get("structure_sections")
    if not isinstance(sections, list):
        return None
    parts: list[str] = []
    for item in sections[:12]:
        if isinstance(item, dict):
            name = str(item.get("name") or item.get("section") or "").strip()
            if name:
                parts.append(name)
        elif isinstance(item, str) and item.strip():
            parts.append(item.strip())
    return " → ".join(parts) if parts else None


def _normalize_gemini_result(parsed: dict[str, Any], *, model: str) -> dict[str, Any]:
    mood = _as_str_list(parsed.get("moodTags") or parsed.get("mood_tags"), limit=6)
    instruments = _as_str_list(parsed.get("instruments"), limit=10)

    bpm_raw = parsed.get("bpm")
    bpm: float | None = None
    if isinstance(bpm_raw, (int, float)) and bpm_raw > 0:
        bpm = round(float(bpm_raw), 1)
    elif isinstance(bpm_raw, str):
        m = re.search(r"(\d+(?:\.\d+)?)", bpm_raw)
        if m:
            bpm = round(float(m.group(1)), 1)

    lyrics = str(
        parsed.get("lyricsTranscription")
        or parsed.get("lyrics_transcription")
        or parsed.get("lyrics")
        or ""
    ).strip()

    sub_genre = str(parsed.get("subGenre") or parsed.get("sub_genre") or "").strip()
    genre = str(parsed.get("genre") or "").strip()
    if sub_genre and genre and sub_genre.lower() not in genre.lower():
        genre_display = f"{genre} · {sub_genre}"
    else:
        genre_display = genre or sub_genre

    conf = str(parsed.get("confidenceOverall") or parsed.get("confidence") or "Medium").strip()
    if conf not in ("High", "Medium", "Low"):
        conf = "Medium"

    structure = _structure_line(parsed)

    base = {
        "bpm": bpm,
        "keyScale": str(parsed.get("keyScale") or parsed.get("key_scale") or "").strip() or None,
        "energy": str(parsed.get("energy") or "").strip() or None,
        "genre": genre_display or None,
        "subGenre": sub_genre or None,
        "moodTags": mood,
        "loudness": str(parsed.get("loudness") or "").strip() or None,
        "instruments": instruments,
        "vocals": str(parsed.get("vocals") or "").strip() or None,
        "structure": structure,
        "lyricsTranscription": lyrics or None,
        "tempoFeel": str(parsed.get("tempoFeel") or parsed.get("tempo_feel") or "").strip() or None,
        "chordComplexity": str(
            parsed.get("chordComplexity") or parsed.get("chord_complexity") or ""
        ).strip()
        or None,
        "confidenceOverall": conf,
        "richDescription": str(
            parsed.get("richDescription")
            or parsed.get("rich_description")
            or parsed.get("description")
            or ""
        ).strip()
        or None,
        "vocalDelivery": str(
            parsed.get("vocalDelivery") or parsed.get("vocal_delivery") or ""
        ).strip()
        or None,
        "tempoEnergy": str(
            parsed.get("tempoEnergy") or parsed.get("tempo_energy") or ""
        ).strip()
        or None,
        "moodProfile": str(
            parsed.get("moodProfile") or parsed.get("mood_profile") or ""
        ).strip()
        or None,
        "productionEnvironment": str(
            parsed.get("productionEnvironment")
            or parsed.get("production_environment")
            or ""
        ).strip()
        or None,
        "analysisMode": "gemini",
        "_analysisModel": model,
    }
    base["analyzerSummary"] = build_analyzer_summary_from_result(base)
    return base


def _call_gemini(
    *,
    data: bytes,
    filename: str,
    model: str,
) -> dict[str, Any] | None:
    try:
        from openai import OpenAI
    except ImportError:
        logger.warning("openai package missing; Gemini analysis skipped")
        return None

    kwargs = build_openai_client_kwargs()
    if not kwargs.get("api_key"):
        return None

    client = OpenAI(**kwargs)
    gemini_data, gemini_name, clipped = _clip_audio_for_gemini(data, filename)
    if len(gemini_data) > _MAX_AUDIO_BYTES:
        logger.warning("Gemini clip still %s KB — sending text + librosa hints only", len(gemini_data) // 1024)
        gemini_data = b""

    audio_note = (
        f"Audio clip: first ~{int(_gemini_clip_seconds())}s at {_GEMINI_SAMPLE_RATE} Hz mono."
        if clipped and gemini_data
        else "Full file reference (audio attached or infer from metadata)."
    )
    text_part = _USER_TEMPLATE.format(
        filename=filename or "audio",
        size_kb=max(1, len(data) // 1024),
        audio_note=audio_note,
    )
    audio_parts = _audio_parts(gemini_data, gemini_name) if gemini_data else []

    content_variants: list[list[dict[str, Any]]] = []
    for audio in audio_parts:
        content_variants.append([{"type": "text", "text": text_part}, audio])
    content_variants.append([{"type": "text", "text": text_part + "\n\n(Audio bytes omitted — too large; infer from filename only.)"}])

    last_err: Exception | None = None
    for content in content_variants:
        try:
            timeout_s = float(os.getenv("ANALYSIS_GEMINI_TIMEOUT", "180"))
            resp = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": _GEMINI_SYSTEM},
                    {"role": "user", "content": content},
                ],
                temperature=0.25,
                max_tokens=2500,
                timeout=timeout_s,
            )
            raw = (resp.choices[0].message.content or "").strip()
            parsed = _parse_json_response(raw)
            if parsed:
                return _normalize_gemini_result(parsed, model=model)
        except Exception as e:  # noqa: BLE001
            last_err = e
            logger.debug("Gemini content variant failed: %s", e)
            continue

    if last_err:
        logger.warning("Gemini audio analysis failed: %s", last_err)
    return None


def fetch_gemini_audio_analysis(
    *,
    data: bytes,
    filename: str,
) -> dict[str, Any] | None:
    """
    Full Gemini 2.5 analysis: genre, mood, BPM/key, instruments, vocals,
    structure, lyrics transcription, rich description.
    """
    if not analysis_gemini_enabled():
        return None

    model = os.getenv("ANALYSIS_GEMINI_MODEL", "").strip() or resolve_analysis_model()

    return _call_gemini(data=data, filename=filename, model=model)


def merge_librosa_fallback(
    gemini: dict[str, Any],
    signals: dict[str, Any],
) -> dict[str, Any]:
    """Fill missing numeric/tempo fields from librosa when Gemini omits them."""
    out = dict(gemini)
    if out.get("bpm") is None and signals.get("bpm") is not None:
        out["bpm"] = signals["bpm"]
    if not out.get("keyScale") and signals.get("keyScale"):
        out["keyScale"] = signals["keyScale"]
    if not out.get("energy") and signals.get("energy"):
        out["energy"] = signals["energy"]
    if not out.get("loudness") and signals.get("loudness"):
        out["loudness"] = signals["loudness"]
    if not out.get("tempoFeel") and signals.get("tempoFeel"):
        out["tempoFeel"] = signals["tempoFeel"]
    if not out.get("chordComplexity") and signals.get("chordComplexity"):
        out["chordComplexity"] = signals["chordComplexity"]
    if out.get("analysisMode") == "gemini":
        out["analysisMode"] = "gemini+librosa"
    return out
