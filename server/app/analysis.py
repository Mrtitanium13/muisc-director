"""Audio analysis: Gemini 2.5 (primary) with librosa fallback for BPM/key/heuristics."""

from __future__ import annotations

import io
import logging
from typing import Any

import librosa
import numpy as np

from app.audd_recognition import fallback_track_metadata
from app.gemini_analysis import (
    FALLBACK_ANALYZER_SUMMARY,
    analyze_audio_semantics,
    build_analyzer_summary_from_result,
    fetch_gemini_audio_analysis,
    merge_librosa_fallback,
    sanitize_analyzer_summary,
)
from app.llm_track_classifier import resolve_track_metadata

logger = logging.getLogger(__name__)

# Cap librosa decode window (memory + latency); 90s captures most song structure.
_LIBROSA_ANALYSIS_DURATION_S = 90.0
# Shorter window for chroma + pYIN (CPU-heavy).
_HARMONY_MELODY_DURATION_S = 60.0


def _librosa_load_from_bytes(
    file_bytes: bytes,
    *,
    sr: int | None,
    mono: bool = True,
    duration: float | None = None,
) -> tuple[np.ndarray, int]:
    """
    Load audio from raw bytes using a fresh in-memory stream (seek at zero).
    Never reuse a stream that was already consumed by AudD or another loader.
    """
    librosa_stream = io.BytesIO(file_bytes)
    librosa_stream.seek(0)
    load_kwargs: dict[str, Any] = {"sr": sr, "mono": mono}
    if duration is not None:
        load_kwargs["duration"] = duration
    y, loaded_sr = librosa.load(librosa_stream, **load_kwargs)
    return y, int(loaded_sr)


# Major / minor Krumhansl-Schmuckler profiles (12-D chroma, C = index 0)
_MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
_MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])

_PITCH_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def _estimate_key_chroma(chroma_mean: np.ndarray) -> tuple[str, str, float]:
    best_corr = -1.0
    best_key = "C"
    best_mode = "Major"
    for mode_name, profile in (("Major", _MAJOR), ("Minor", _MINOR)):
        for shift in range(12):
            rolled = np.roll(profile, shift)
            c = float(np.corrcoef(chroma_mean, rolled)[0, 1])
            if not np.isfinite(c):
                continue
            if c > best_corr:
                best_corr = c
                best_key = _PITCH_NAMES[shift]
                best_mode = mode_name
    if best_corr < 0:
        best_corr = 0.0
    return best_key, best_mode, float(best_corr)


def _peak_normalize(y: np.ndarray) -> np.ndarray:
    """Scale to 0 dB peak so quiet acapellas are not misread as ultra-low energy."""
    if y.size == 0:
        return y
    peak = float(np.max(np.abs(y)))
    if peak < 1e-9:
        return y
    return y / peak


def _robust_energy_0_100(rmse: np.ndarray) -> int:
    """80th-percentile RMS — chorus energy wins over quiet intros."""
    if rmse.size == 0:
        return 50
    robust = float(np.percentile(rmse, 80))
    return int(np.clip(robust * 300.0, 0, 100))


def _operational_dbfs(y: np.ndarray) -> float:
    """Mean-square loudness on peak-normalized audio (realistic dBFS band)."""
    power = float(np.mean(y**2))
    if power <= 0:
        return -60.0
    return float(10.0 * np.log10(power))


def _correct_double_time_tempo(bpm: float, perc_ratio: float) -> float:
    """
    Halve double-time transient rhythms (e.g. 144 → 72) unless percussive
    content suggests true DnB/club tempo.
    """
    x = float(bpm)
    if not np.isfinite(x):
        return 120.0
    if x > 135 and perc_ratio < 0.48:
        half = x * 0.5
        if half >= 62:
            x = half
    return float(np.clip(x, 55.0, 200.0))


def _note_name_without_octave(note: str) -> str:
    """Strip octave digits from librosa note labels (e.g. D4 → D, A♯3 → A#)."""
    out: list[str] = []
    for ch in note:
        if ch.isdigit() or ch in "+-":
            continue
        out.append(ch)
    cleaned = "".join(out).replace("♯", "#").replace("♭", "b").strip()
    return cleaned or note.strip()


_HARMONY_FALLBACK_CHORDS = "Implied Progression Base: D-F#-A"
_HARMONY_FALLBACK_MELODY = "Vocal Melody Range Notes: D, F#, A"
_HARMONY_FALLBACK_BPM = 72.0


def _harmony_fallback_bundle() -> dict[str, Any]:
    return {
        "impliedChords": _HARMONY_FALLBACK_CHORDS,
        "melodyProfile": _HARMONY_FALLBACK_MELODY,
        "percussiveBpm": _HARMONY_FALLBACK_BPM,
    }


def _percussive_onset_bpm(y: np.ndarray, sr: int) -> float:
    """Tempo from percussive-layer onset strength (vocal transient safe)."""
    _, y_perc = librosa.effects.hpss(y)
    onset_env = librosa.onset.onset_strength(y=y_perc, sr=sr)
    tempo_arr, _ = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
    t_flat = np.atleast_1d(tempo_arr).ravel()
    valid_t = t_flat[np.isfinite(t_flat) & (t_flat > 0)]
    if valid_t.size == 0:
        return _HARMONY_FALLBACK_BPM
    bpm = float(np.median(valid_t))
    if not np.isfinite(bpm) or bpm < 40:
        return _HARMONY_FALLBACK_BPM
    return bpm


def _extract_harmonics_and_melody_from_array(
    y: np.ndarray,
    sr: int,
    *,
    duration_cap_s: float = _HARMONY_MELODY_DURATION_S,
) -> dict[str, Any]:
    """
    Peak-normalized harmony pass: percussive BPM, chroma chord roots, pYIN melody.
    Uses native sample rate when provided (sr=None load upstream).
    """
    try:
        if y.size < 4096:
            return _harmony_fallback_bundle()

        max_samples = int(sr * duration_cap_s)
        y_work = y[:max_samples] if y.size > max_samples else y
        y_work = _peak_normalize(y_work)

        perc_bpm = _percussive_onset_bpm(y_work, sr)

        y_harmonic, _ = librosa.effects.hpss(y_work)
        chroma = librosa.feature.chroma_cqt(
            y=y_harmonic,
            sr=sr,
            fmin=librosa.note_to_hz("C2"),
        )
        dominant = np.argmax(chroma, axis=0)
        unique, counts = np.unique(dominant, return_counts=True)
        if unique.size == 0:
            implied_chords = _HARMONY_FALLBACK_CHORDS
        else:
            sorted_idx = unique[np.argsort(-counts)]
            top_notes = [_PITCH_NAMES[int(i)] for i in sorted_idx[:3]]
            implied_chords = f"Implied Progression Base: {'-'.join(top_notes)}"

        f0, _, _ = librosa.pyin(
            y_work,
            fmin=librosa.note_to_hz("C2"),
            fmax=librosa.note_to_hz("C6"),
            sr=sr,
        )
        valid = f0[~np.isnan(f0)] if f0 is not None else np.array([])
        melody_notes: list[str] = []
        if valid.size > 0:
            step = max(1, valid.size // 5)
            for hz in valid[::step]:
                clean = _note_name_without_octave(str(librosa.hz_to_note(float(hz))))
                if clean and clean not in melody_notes:
                    melody_notes.append(clean)
        melody_profile = (
            f"Vocal Melody Range Notes: {', '.join(melody_notes[:4])}"
            if melody_notes
            else _HARMONY_FALLBACK_MELODY
        )

        return {
            "impliedChords": implied_chords,
            "melodyProfile": melody_profile,
            "percussiveBpm": round(perc_bpm, 1),
        }
    except Exception as exc:  # noqa: BLE001
        logger.warning("harmony/melody extract failed: %s", exc)
        return _harmony_fallback_bundle()


def _extract_harmonics_and_melody_from_bytes(data: bytes) -> dict[str, Any]:
    """Native sample-rate load (sr=None) for accurate pitch/chroma grids."""
    y, sr = _librosa_load_from_bytes(
        data,
        sr=None,
        mono=True,
        duration=_HARMONY_MELODY_DURATION_S,
    )
    return _extract_harmonics_and_melody_from_array(y, sr)


def extract_harmonics_and_melody(audio_path: str) -> dict[str, Any]:
    """Standalone harmony + melody profile (file path, native SR)."""
    y, sr = librosa.load(
        audio_path,
        sr=None,
        mono=True,
        duration=_HARMONY_MELODY_DURATION_S,
    )
    return _extract_harmonics_and_melody_from_array(y, int(sr))


def extract_robust_features(audio_path: str) -> dict[str, Any]:
    """
    Standalone robust DSP profile (file path).
    Mirrors the peak-normalize / percentile-energy / tempo-halving pipeline.
    """
    y, sr = librosa.load(audio_path, sr=22050, mono=True, duration=_LIBROSA_ANALYSIS_DURATION_S)
    y = _peak_normalize(y)
    hop_length = 512
    bpm, _ = _estimate_bpm(y, sr, hop_length=hop_length)
    y_harm, y_perc = librosa.effects.hpss(y)
    rms_h = float(np.sqrt(np.mean(y_harm**2)))
    rms_p = float(np.sqrt(np.mean(y_perc**2)))
    perc_ratio = rms_p / (rms_h + rms_p + 1e-9)
    bpm = _correct_double_time_tempo(bpm, perc_ratio)
    rmse = librosa.feature.rms(y=y, hop_length=hop_length)[0]
    return {
        "bpm": int(round(bpm)),
        "energy": _robust_energy_0_100(rmse),
        "loudness": round(_operational_dbfs(y), 1),
    }


def _snap_bpm_octave(bpm: float) -> float:
    x = float(bpm)
    if not np.isfinite(x) or x < 1:
        return 120.0
    while x < 68 and x * 2.0 <= 190:
        x *= 2.0
    while x > 182 and x * 0.5 >= 62:
        x *= 0.5
    return float(np.clip(x, 55.0, 200.0))


def _estimate_bpm(y: np.ndarray, sr: int, hop_length: int = 512) -> tuple[float, int]:
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop_length, aggregate=np.median)
    tempo_arr, beat_frames = librosa.beat.beat_track(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=hop_length,
        trim=False,
        tightness=110,
    )
    t_flat = np.atleast_1d(tempo_arr).ravel()
    valid_t = t_flat[np.isfinite(t_flat) & (t_flat > 0)]
    bpm_lib = float(np.median(valid_t)) if valid_t.size else 120.0
    if not np.isfinite(bpm_lib) or bpm_lib < 40:
        bpm_lib = 120.0

    beat_count = int(np.asarray(beat_frames).size)
    if beat_count >= 4:
        times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=hop_length)
        gaps = np.diff(times)
        gaps = gaps[(gaps > 0.22) & (gaps < 1.75)]
        if gaps.size >= 2:
            med_gap = float(np.median(gaps))
            if med_gap > 1e-3:
                bpm_iv = 60.0 / med_gap
                if 48 <= bpm_iv <= 210:
                    w = min(0.65, 0.35 + 0.04 * min(beat_count, 16))
                    bpm = (1.0 - w) * bpm_lib + w * bpm_iv
                else:
                    bpm = bpm_lib
            else:
                bpm = bpm_lib
        else:
            bpm = bpm_lib
    else:
        bpm = bpm_lib

    bpm = _snap_bpm_octave(bpm)
    return bpm, beat_count


def _confidence_label(duration_s: float, beat_count: int, key_corr: float) -> str:
    score = 0
    if duration_s >= 25:
        score += 1
    if duration_s >= 60:
        score += 1
    if beat_count >= 12:
        score += 1
    if beat_count >= 40:
        score += 1
    if key_corr >= 0.45:
        score += 1
    if key_corr >= 0.62:
        score += 1
    if score >= 5:
        return "High"
    if score >= 3:
        return "Medium"
    return "Low"


def _genre_mood_instruments(
    bpm: float,
    cent_med: float,
    zcr_med: float,
    rolloff_med: float,
    perc_ratio: float,
    contrast_mean: float,
) -> tuple[str, list[str], list[str]]:
    pr = float(np.clip(perc_ratio, 0.0, 1.0))

    if (
        pr < 0.38
        and 100 <= bpm <= 155
        and 1500 < cent_med < 4000
        and contrast_mean > 14
    ):
        genre = "Hip Hop / Rap Vocals / Acapella (estimate)"
        mood = ["Lyric-driven", "Phrase rhythm", "Groove implied"]
        inst = ["Lead Vocals", "Stacks / harmonies", "Ad-libs", "Minimal drums if any"]
        if zcr_med > 0.11:
            mood = list(dict.fromkeys(mood + ["Articulate"]))
        if pr < 0.28:
            mood = list(dict.fromkeys(mood + ["Mostly harmonic"]))
        return genre, mood[:5], inst[:8]

    if bpm >= 158 and cent_med > 2800 and pr > 0.38:
        genre = "Drum & Bass / Jungle (estimate)"
        mood = ["Fast", "Driving", "Percussive"]
        inst = ["Breakbeats", "Sub Bass", "Snares", "Hi-Hats"]
    elif bpm >= 135 and bpm < 150 and pr > 0.48 and cent_med > 2600:
        genre = "Techno / Peak-Time Club (estimate)"
        mood = ["Hypnotic", "Driving", "Industrial-tinged"]
        inst = ["Kick", "Hi-Hats", "Synth Stabs", "Sub"]
    elif 118 <= bpm < 135 and pr > 0.45 and cent_med > 2400:
        genre = "House / Groove Electronic (estimate)"
        mood = ["Groovy", "Warm", "Danceable"]
        inst = ["Four-on-the-floor", "Bass", "Pads", "Percussion"]
    elif bpm < 102 and cent_med < 2500 and pr < 0.42 and zcr_med < 0.13:
        genre = "Hip Hop / R&B (estimate)"
        mood = ["Groovy", "Laid-back", "Moody"]
        inst = ["Drums", "808 / Bass", "Samples", "Vocal space"]
    elif bpm < 92 and cent_med < 2200 and pr < 0.38:
        genre = "Lo-Fi / Chillout (estimate)"
        mood = ["Warm", "Nostalgic", "Relaxed"]
        inst = ["Drums", "Electric Piano", "Noise Texture"]
    elif cent_med > 3800 and bpm > 115 and pr > 0.42:
        genre = "Electronic / Dance (estimate)"
        mood = ["Bright", "Driving", "Energetic"]
        inst = ["Synthesizer", "Hi-Hats", "Sub Bass", "Pads"]
    elif cent_med < 2000 and bpm < 105:
        genre = "Rock / Band (estimate)"
        mood = ["Raw", "Punchy", "Live-room"]
        inst = ["Drums", "Guitars", "Bass Guitar"]
    elif contrast_mean > 22 and 2000 < cent_med < 3500:
        genre = "Pop / Mixed Production (estimate)"
        mood = ["Polished", "Balanced", "Modern"]
        inst = ["Drums", "Bass", "Vocals", "Synths"]
    elif rolloff_med > 8500 and zcr_med > 0.14:
        genre = "Acoustic / Folk / Bright Mix (estimate)"
        mood = ["Airy", "Natural", "Intimate"]
        inst = ["Strings / Air", "Guitar", "Percussion"]
    else:
        genre = "Pop / Mixed (estimate)"
        mood = ["Balanced", "Modern"]
        inst = ["Drums", "Bass", "Harmonic Content"]

    if zcr_med > 0.15:
        mood = list(dict.fromkeys(mood + ["Airy"]))
    if rolloff_med > 8000:
        inst = list(dict.fromkeys(inst + ["Cymbals / Air"]))
    if contrast_mean > 18:
        mood = list(dict.fromkeys(mood + ["Dynamic"]))

    return genre, mood[:5], inst[:8]


def _analyze_librosa_signals(file_bytes: bytes) -> dict[str, Any]:
    y, sr = _librosa_load_from_bytes(
        file_bytes,
        sr=22050,
        mono=True,
        duration=_LIBROSA_ANALYSIS_DURATION_S,
    )
    if y.size < 4096:
        raise ValueError("Audio too short to analyze")

    y = _peak_normalize(y)

    duration_s = float(y.size) / float(sr)
    hop_length = 512

    y_harm, y_perc = librosa.effects.hpss(y)
    rms_h = float(np.sqrt(np.mean(y_harm**2)))
    rms_p = float(np.sqrt(np.mean(y_perc**2)))
    perc_ratio = rms_p / (rms_h + rms_p + 1e-9)

    harmony = _extract_harmonics_and_melody_from_bytes(file_bytes)

    bpm, beat_count = _estimate_bpm(y, sr, hop_length=hop_length)
    if perc_ratio < 0.42:
        perc_bpm = harmony.get("percussiveBpm")
        if perc_bpm is not None:
            try:
                pb = float(perc_bpm)
                if 55 <= pb <= 200:
                    bpm = pb
            except (TypeError, ValueError):
                pass
    bpm = _correct_double_time_tempo(bpm, perc_ratio)

    chroma = librosa.feature.chroma_cqt(y=y, sr=sr, hop_length=hop_length, fmin=librosa.note_to_hz("C2"))
    chroma_med = np.median(chroma, axis=1)
    chroma_med = chroma_med / (np.linalg.norm(chroma_med) + 1e-9)
    root, mode, key_corr = _estimate_key_chroma(chroma_med)
    key_scale = f"{root} {mode}"

    rmse = librosa.feature.rms(y=y, hop_length=hop_length)[0]
    energy_0_100 = _robust_energy_0_100(rmse)
    energy_label = "Low" if energy_0_100 < 35 else "Medium" if energy_0_100 < 70 else "High"
    energy = f"{energy_label} ({energy_0_100}/100)"
    dbfs = _operational_dbfs(y)
    loudness = f"{dbfs:.1f} dBFS"

    cent = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=hop_length)[0]
    zcr = librosa.feature.zero_crossing_rate(y=y, hop_length=hop_length)[0]
    rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr, hop_length=hop_length)[0]
    contrast = librosa.feature.spectral_contrast(y=y, sr=sr, hop_length=hop_length)

    cent_med = float(np.median(cent))
    zcr_med = float(np.median(zcr))
    rolloff_med = float(np.median(rolloff))
    contrast_mean = float(np.mean(contrast))

    ent = float(-np.sum(chroma_med * np.log(chroma_med + 1e-12)))
    chord_complexity = "Low" if ent < 2.0 else "Moderate" if ent < 2.85 else "Rich"

    if bpm < 95:
        tempo_feel = "Laid-back"
    elif bpm < 128:
        tempo_feel = "Mid-tempo groove"
    else:
        tempo_feel = "Driving / Up-tempo"

    duration_seconds = float(y.size) / float(sr)
    minutes = int(duration_seconds // 60)
    seconds = int(duration_seconds % 60)

    return {
        "bpm": round(bpm, 1),
        "keyScale": key_scale,
        "energy": energy,
        "loudness": loudness,
        "tempoFeel": tempo_feel,
        "chordComplexity": chord_complexity,
        "confidenceOverall": _confidence_label(duration_s, beat_count, key_corr),
        "impliedChords": harmony["impliedChords"],
        "melodyProfile": harmony["melodyProfile"],
        "durationSeconds": round(duration_seconds, 2),
        "trackLength": f"{minutes}:{seconds:02d}",
        "_harmony_percussive_bpm": harmony.get("percussiveBpm"),
        "_perc_ratio": perc_ratio,
        "_cent_med": cent_med,
        "_zcr_med": zcr_med,
        "_rolloff_med": rolloff_med,
        "_contrast_mean": contrast_mean,
    }


_ACAPELLA_PRODUCTION_INTENT = (
    "Build a full commercial pop/dance arrangement around this isolated vocal stem. "
    "Inject wide vocal stacks, driving rhythm sections, and warm harmonic chord "
    "progressions to fill the sonic space."
)
_DEFAULT_PRODUCTION_INTENT = (
    "Match the current energy and instrumentation density of the analyzed audio file."
)
_RECOGNIZED_ARTIST_INTENT_TEMPLATE = (
    "Create a custom remix prompt matching the style of {artist}."
)


def _recognized_artist_production_intent(artist: str) -> str:
    clean = artist.strip()
    if not clean or clean in ("User Upload", "Unknown Artist"):
        return _DEFAULT_PRODUCTION_INTENT
    return _RECOGNIZED_ARTIST_INTENT_TEMPLATE.format(artist=clean)


def _estimate_dynamic_genre_profile(
    *,
    actual_bpm: int,
    signals: dict[str, Any],
    base_genre: str | None = None,
    base_instruments: list[str] | None = None,
) -> tuple[str, list[str]]:
    """
    Dynamic genre/instrument tags from physical metrics (BPM pocket, transients,
    spectral rolloff). Used when AudD has no genre or Gemini is unavailable.
    """
    estimated_genre = (base_genre or "Pop / Mixed Production (estimate)").strip()
    estimated_instruments = list(
        base_instruments or ["Drums", "Bass", "Vocals", "Synths"]
    )
    detected_instruments = " · ".join(str(x) for x in estimated_instruments)

    perc_ratio = float(signals.get("_perc_ratio") or 0.0)
    rolloff_med = float(signals.get("_rolloff_med") or 0.0)
    energy = str(signals.get("energy") or "")
    high_energy = energy.startswith("High")
    strong_transients = high_energy or perc_ratio >= 0.40

    if 80 <= actual_bpm <= 110 and strong_transients:
        if "Drums" in detected_instruments and "Bass" in detected_instruments:
            estimated_genre = "Hip-Hop / Rap / Urban Groove (estimate)"
            estimated_instruments = [
                "Boom-Bap Drums",
                "Heavy Sub-Bass",
                "Vocals",
                "Urban Synths",
            ]
        elif rolloff_med > 0 and rolloff_med < 5200 and perc_ratio >= 0.38:
            estimated_genre = "Hip-Hop / Rap / Urban Groove (estimate)"
            estimated_instruments = [
                "Boom-Bap Drums",
                "Heavy Sub-Bass",
                "Vocals",
                "Urban Synths",
            ]

    if (
        rolloff_med >= 6800
        and actual_bpm >= 100
        and "Hip-Hop" not in estimated_genre
        and "Acapella" not in estimated_genre
    ):
        estimated_genre = "Pop / Mixed Production (estimate)"
        estimated_instruments = ["Drums", "Bass", "Vocals", "Synths"]

    if "acapella" in estimated_genre.lower():
        estimated_genre = "Hip Hop / Rap Vocals / Acapella (estimate)"
        estimated_instruments = ["Lead Vocals", "Stacks", "Harmonies"]

    return estimated_genre, estimated_instruments


def _apply_dynamic_genre_and_metadata(
    raw: dict[str, Any],
    *,
    signals: dict[str, Any],
) -> dict[str, Any]:
    """Round BPM and fill genre/instruments gaps after AudD or LLM metadata."""
    out = dict(raw)

    try:
        actual_bpm = int(round(float(out.get("bpm") or signals.get("bpm") or 120)))
    except (TypeError, ValueError):
        actual_bpm = 120
    out["bpm"] = actual_bpm

    has_genre = bool(str(out.get("genre") or "").strip())
    base_inst = out.get("instruments") or []
    if isinstance(base_inst, list):
        inst_list = [str(x) for x in base_inst if str(x).strip()]
    else:
        inst_list = [str(base_inst)] if str(base_inst).strip() else []

    dyn_genre, dyn_inst = _estimate_dynamic_genre_profile(
        actual_bpm=actual_bpm,
        signals=signals,
        base_genre=out.get("genre"),
        base_instruments=inst_list or None,
    )

    if not has_genre:
        out["genre"] = dyn_genre

    if not inst_list:
        out["instruments"] = dyn_inst
    elif "Acapella" in str(out.get("genre") or ""):
        out["instruments"] = dyn_inst

    artist = str(out.get("artist") or "")
    track_recognized = bool(out.get("trackRecognized"))
    if track_recognized and artist not in (
        "User Upload",
        "Unknown Artist",
        "Independent Creator",
    ):
        if not _is_acapella_estimate(out):
            out["productionIntent"] = _recognized_artist_production_intent(artist)

    return out


def _is_acapella_estimate(raw: dict[str, Any]) -> bool:
    genre = str(raw.get("genre") or "")
    if "acapella" in genre.lower():
        return True
    instruments = raw.get("instruments") or []
    if isinstance(instruments, list):
        inst_text = " ".join(str(x) for x in instruments)
    else:
        inst_text = str(instruments)
    if "Lead Vocals" in inst_text:
        return True
    vocals = str(raw.get("vocals") or "").lower()
    if "acapella" in vocals:
        return True
    if "lead" in vocals and "vocal" in vocals and "instrumental" not in vocals:
        return True
    return False


def _acapella_production_intent(*, artist: str, track_recognized: bool) -> str:
    artist_clean = artist.strip()
    if track_recognized and artist_clean and artist_clean not in (
        "User Upload",
        "Unknown Artist",
        "Independent Creator",
    ):
        return _recognized_artist_production_intent(artist_clean)
    return _ACAPELLA_PRODUCTION_INTENT


def _apply_track_identity(
    result: dict[str, Any],
    track_meta: dict[str, Any],
) -> dict[str, Any]:
    out = dict(result)
    for key in (
        "title",
        "artist",
        "album",
        "releaseDate",
        "trackRecognized",
        "genre",
        "instruments",
    ):
        if key in track_meta and track_meta[key] is not None:
            out[key] = track_meta[key]
    return out


def adjust_metadata_for_acapellas(
    raw_analysis: dict[str, Any],
    *,
    signals: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    When the analyzer flags an acapella / isolated vocal stem, correct double-time
    BPM and set production intent so prompt generation builds a full track.
    """
    out = dict(raw_analysis)
    bpm_raw = out.get("bpm", 120)
    try:
        bpm = float(bpm_raw)
    except (TypeError, ValueError):
        bpm = 120.0

    if _is_acapella_estimate(out):
        harmony_bpm = None
        if signals is not None:
            harmony_bpm = signals.get("_harmony_percussive_bpm")
        if harmony_bpm is not None:
            try:
                bpm = float(harmony_bpm)
            except (TypeError, ValueError):
                pass
        if bpm > 135:
            out["bpm"] = round(bpm * 0.5, 1)
        else:
            out["bpm"] = round(bpm, 1)
        out["isAcapella"] = True
        artist = str(out.get("artist") or "")
        track_recognized = bool(out.get("trackRecognized"))
        out["productionIntent"] = _acapella_production_intent(
            artist=artist,
            track_recognized=track_recognized,
        )
        logger.info(
            "acapella stem detected genre=%r bpm=%s",
            out.get("genre"),
            out.get("bpm"),
        )
    else:
        out["isAcapella"] = False
        out["productionIntent"] = _DEFAULT_PRODUCTION_INTENT

    return out


def _dsp_public_metrics(signals: dict[str, Any]) -> dict[str, Any]:
    return {
        "bpm": signals.get("bpm"),
        "keyScale": signals.get("keyScale"),
        "energy": signals.get("energy"),
        "loudness": signals.get("loudness"),
        "tempoFeel": signals.get("tempoFeel"),
        "chordComplexity": signals.get("chordComplexity"),
        "confidenceOverall": signals.get("confidenceOverall"),
    }


def _ensure_analyzer_summary(
    result: dict[str, Any],
    *,
    signals: dict[str, Any],
) -> dict[str, Any]:
    """Always attach a non-empty analyzerSummary for the client parsing layer."""
    out = dict(result)
    existing = out.get("analyzerSummary")
    if existing:
        out["analyzerSummary"] = sanitize_analyzer_summary(str(existing))
        return out

    synthesized = build_analyzer_summary_from_result(out)
    transcription = str(out.get("lyricsTranscription") or "").strip()
    semantic = analyze_audio_semantics(
        _dsp_public_metrics(signals),
        transcription,
    )
    out["analyzerSummary"] = sanitize_analyzer_summary(semantic or synthesized)
    return out


def fallback_analysis_payload(*, reason: str = "") -> dict[str, Any]:
    """Safe schema when DSP/Gemini processing fails — never null fields for UI state."""
    if reason:
        logger.warning("analyze fallback payload: %s", reason)
    return {
        "success": False,
        "analyzerSummary": FALLBACK_ANALYZER_SUMMARY,
        "bpm": 120.0,
        "keyScale": "C Major",
        "energy": "Medium (50/100)",
        "genre": "Analysis unavailable (estimate)",
        "subGenre": None,
        "moodTags": ["Moderate", "Balanced"],
        "loudness": None,
        "instruments": ["Drums", "Bass", "Harmonic Content"],
        "vocals": "General Delivery",
        "structure": None,
        "lyricsTranscription": None,
        "tempoFeel": "Mid-tempo groove",
        "chordComplexity": "Moderate",
        "confidenceOverall": "Low",
        "richDescription": None,
        "analysisMode": "fallback",
        "isAcapella": False,
        "productionIntent": _DEFAULT_PRODUCTION_INTENT,
        "impliedChords": _HARMONY_FALLBACK_CHORDS,
        "melodyProfile": _HARMONY_FALLBACK_MELODY,
        **fallback_track_metadata(),
    }


def _librosa_fallback_result(signals: dict[str, Any]) -> dict[str, Any]:
    genre, mood_tags, instruments = _genre_mood_instruments(
        bpm=float(signals["bpm"]),
        cent_med=float(signals["_cent_med"]),
        zcr_med=float(signals["_zcr_med"]),
        rolloff_med=float(signals["_rolloff_med"]),
        perc_ratio=float(signals["_perc_ratio"]),
        contrast_mean=float(signals["_contrast_mean"]),
    )
    return {
        "bpm": signals["bpm"],
        "keyScale": signals["keyScale"],
        "energy": signals["energy"],
        "genre": genre,
        "subGenre": None,
        "moodTags": mood_tags[:6],
        "loudness": signals["loudness"],
        "instruments": instruments[:10],
        "vocals": None,
        "structure": None,
        "lyricsTranscription": None,
        "tempoFeel": signals["tempoFeel"],
        "chordComplexity": signals["chordComplexity"],
        "confidenceOverall": signals["confidenceOverall"],
        "richDescription": None,
        "analysisMode": "librosa",
        "impliedChords": signals.get("impliedChords"),
        "melodyProfile": signals.get("melodyProfile"),
    }


def _attach_harmony_melody(result: dict[str, Any], signals: dict[str, Any]) -> dict[str, Any]:
    out = dict(result)
    for key in ("impliedChords", "melodyProfile"):
        val = signals.get(key) or out.get(key)
        if val:
            out[key] = str(val)
    return out


def _finalize_analysis_result(
    raw: dict[str, Any],
    *,
    signals: dict[str, Any],
    track_meta: dict[str, Any],
) -> dict[str, Any]:
    adjusted = _attach_harmony_melody(dict(raw), signals)
    adjusted = _apply_track_identity(adjusted, track_meta)
    adjusted = _apply_dynamic_genre_and_metadata(adjusted, signals=signals)
    adjusted = adjust_metadata_for_acapellas(adjusted, signals=signals)
    with_summary = _ensure_analyzer_summary(adjusted, signals=signals)
    public = _public_result(with_summary)
    public["success"] = True
    public["analyzerSummary"] = sanitize_analyzer_summary(
        str(public.get("analyzerSummary") or FALLBACK_ANALYZER_SUMMARY)
    )
    if signals.get("trackLength"):
        public.setdefault("trackLength", signals["trackLength"])
    return public


def _public_result(raw: dict[str, Any]) -> dict[str, Any]:
    """Strip internal keys before JSON response."""
    return {k: v for k, v in raw.items() if not str(k).startswith("_")}


def analyze_audio_bytes(data: bytes, filename: str = "audio") -> dict[str, Any]:
    """Librosa DSP + AudD fingerprint + LLM classifier + optional Gemini audio analysis."""
    try:
        file_bytes = bytes(data)
        if len(file_bytes) < 1024:
            return fallback_analysis_payload(reason="audio too short")

        safe_name = filename or "audio.wav"

        # 1. Librosa DSP (real BPM, key, harmony, duration — no placeholders)
        signals = _analyze_librosa_signals(file_bytes)

        # 2. AudD online match; LLM classifier bridge when AudD returns null
        from app.audd_recognition import recognize_audd_song_raw

        audd_result = recognize_audd_song_raw(file_bytes, filename=safe_name)
        track_meta = resolve_track_metadata(
            audd_result,
            signals=signals,
            filename=safe_name,
        )

        # 3. Optional full Gemini audio semantics (genre, mood, lyrics, structure)
        gemini = fetch_gemini_audio_analysis(data=file_bytes, filename=safe_name)
        if gemini:
            merged = merge_librosa_fallback(gemini, signals)
            logger.info("analyze %s mode=%s", safe_name, merged.get("analysisMode"))
            return _finalize_analysis_result(merged, signals=signals, track_meta=track_meta)

        out = _librosa_fallback_result(signals)
        logger.info("analyze %s mode=librosa (Gemini unavailable)", safe_name)
        return _finalize_analysis_result(out, signals=signals, track_meta=track_meta)
    except Exception as exc:  # noqa: BLE001
        logger.exception("analyze_audio_bytes failed for %s: %s", filename, exc)
        return fallback_analysis_payload(reason=str(exc))
