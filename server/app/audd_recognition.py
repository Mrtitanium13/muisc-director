"""Commercial track fingerprinting via AudD.io (optional — requires AUDD_API_KEY)."""

from __future__ import annotations

import io
import logging
import os
from typing import Any

logger = logging.getLogger(__name__)

AUDD_API_URL = "https://api.audd.io/"

_FALLBACK_TITLE = "Original Recording / Stem"
_FALLBACK_ARTIST = "User Upload"
_FALLBACK_ALBUM = "Session"
_FALLBACK_RELEASE = "Custom"

_MIME_BY_EXT = {
    ".mp3": "audio/mpeg",
    ".mpeg": "audio/mpeg",
    ".mpga": "audio/mpeg",
    ".wav": "audio/wav",
    ".m4a": "audio/mp4",
    ".aac": "audio/aac",
    ".flac": "audio/flac",
    ".ogg": "audio/ogg",
    ".webm": "audio/webm",
}


def audd_recognition_enabled() -> bool:
    return bool(os.getenv("AUDD_API_KEY", "").strip())


def _audd_log_raw() -> bool:
    return os.getenv("AUDD_LOG_RAW", "true").strip().lower() in ("1", "true", "yes", "on")


def _mime_for_filename(filename: str) -> str:
    ext = os.path.splitext(filename or "")[1].lower()
    return _MIME_BY_EXT.get(ext, "audio/mpeg")


def _safe_upload_name(filename: str) -> str:
    name = os.path.basename(filename or "").strip() or "audio.mp3"
    if "." not in name:
        return f"{name}.mp3"
    return name


def fallback_track_metadata() -> dict[str, Any]:
    return {
        "title": _FALLBACK_TITLE,
        "artist": _FALLBACK_ARTIST,
        "album": _FALLBACK_ALBUM,
        "releaseDate": _FALLBACK_RELEASE,
        "trackRecognized": False,
    }


def _song_metadata_from_audd_result(song: dict[str, Any]) -> dict[str, Any]:
    title = str(song.get("title") or "").strip() or _FALLBACK_TITLE
    artist = str(song.get("artist") or "").strip() or _FALLBACK_ARTIST
    album = str(song.get("album") or "").strip() or _FALLBACK_ALBUM
    release = str(song.get("release_date") or "").strip() or _FALLBACK_RELEASE
    recognized = not (
        title == _FALLBACK_TITLE
        and artist in (_FALLBACK_ARTIST, "Unknown Artist")
    )
    return {
        "title": title,
        "artist": artist,
        "album": album,
        "releaseDate": release,
        "trackRecognized": recognized,
    }


def _recognize_audio_metadata(
    file_bytes: bytes,
    filename: str,
    *,
    api_key: str,
    timeout_s: float,
) -> dict[str, Any] | None:
    """
    Bulletproof binary stream transmission using AudD's primary endpoint.
    Returns parsed metadata on match, otherwise None.
    """
    try:
        import requests
    except ImportError:
        logger.warning("requests package missing; AudD fingerprinting skipped")
        return None

    upload_name = _safe_upload_name(filename)
    mime = _mime_for_filename(upload_name)

    audio_stream = io.BytesIO(file_bytes)
    audio_stream.seek(0)

    files = {
        "file": (upload_name, audio_stream, mime),
    }
    payload = {
        "api_token": api_key,
        "return": "apple_music,spotify",
    }

    logger.info(
        "[AudD Outbound] Sending data to AudD... File: %s (%s)",
        upload_name,
        mime,
    )

    response = requests.post(
        AUDD_API_URL,
        data=payload,
        files=files,
        timeout=timeout_s,
    )

    if _audd_log_raw():
        logger.info("[AudD Raw Server Response]: %s", response.text)
    else:
        logger.debug("[AudD Raw Server Response]: %s", response.text)

    if response.status_code != 200:
        logger.warning(
            "AudD fingerprinting HTTP %s for %s",
            response.status_code,
            upload_name,
        )
        return None

    result = response.json()
    if result.get("status") != "success" or not result.get("result"):
        return None

    song = result["result"]
    if not isinstance(song, dict):
        return None

    return song


def track_metadata_from_audd(song: dict[str, Any]) -> dict[str, Any]:
    meta = _song_metadata_from_audd_result(song)
    audd_genre = audd_genre_from_result(song)
    if audd_genre:
        meta["auddGenre"] = audd_genre
    return meta


def audd_genre_from_result(audd_result: dict[str, Any]) -> str | None:
    """Extract genre label from AudD song payload when present."""
    direct = audd_result.get("genre")
    if direct:
        text = str(direct).strip()
        if text:
            return text

    label = audd_result.get("label")
    if isinstance(label, str) and label.strip():
        return label.strip()

    for nest_key in ("apple_music", "spotify"):
        nested = audd_result.get(nest_key)
        if not isinstance(nested, dict):
            continue
        for gkey in ("genre", "genres"):
            value = nested.get(gkey)
            if isinstance(value, list) and value:
                text = str(value[0]).strip()
                if text:
                    return text
            if isinstance(value, str) and value.strip():
                return value.strip()
    return None


def recognize_audd_song_raw(
    file_bytes: bytes,
    *,
    filename: str = "audio.wav",
) -> dict[str, Any] | None:
    """Run AudD fingerprinting; return the raw song dict or None."""
    api_key = os.getenv("AUDD_API_KEY", "").strip()
    if not api_key:
        return None

    max_bytes = int(os.getenv("AUDD_MAX_BYTES", str(12 * 1024 * 1024)))
    chunk = file_bytes[:max_bytes] if len(file_bytes) > max_bytes else file_bytes
    timeout_s = float(os.getenv("AUDD_TIMEOUT_SECONDS", "15"))

    try:
        return _recognize_audio_metadata(
            chunk,
            filename,
            api_key=api_key,
            timeout_s=timeout_s,
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("[AudD Error] Handshake failed: %s", exc)
        return None


def recognize_audio_metadata(
    file_bytes: bytes,
    *,
    filename: str = "audio.wav",
) -> dict[str, Any]:
    """
    Identify commercial song metadata from audio bytes.
    Returns safe fallback when AudD is disabled or no match is found.
    """
    audd_result = recognize_audd_song_raw(file_bytes, filename=filename)
    if audd_result:
        return track_metadata_from_audd(audd_result)
    return fallback_track_metadata()
