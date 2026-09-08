"""Smoke/unit tests for LaoZhang + Gemini analysis + hybrid prompt pipeline."""

from __future__ import annotations

import io
import os
import unittest
from unittest.mock import MagicMock, patch

import numpy as np
import soundfile as sf
from fastapi.testclient import TestClient

from app.analysis import (
    _acapella_production_intent,
    _correct_double_time_tempo,
    _estimate_dynamic_genre_profile,
    _extract_harmonics_and_melody_from_array,
    _note_name_without_octave,
    _operational_dbfs,
    _peak_normalize,
    _robust_energy_0_100,
    adjust_metadata_for_acapellas,
)
from app.audd_recognition import audd_genre_from_result, fallback_track_metadata, recognize_audio_metadata
from app.llm_track_classifier import (
    classify_track_with_llm,
    heuristic_track_metadata,
    resolve_track_metadata,
)
from app.gemini_analysis import (
    _normalize_gemini_result,
    _parse_json_response,
    build_analyzer_summary_from_result,
    sanitize_analyzer_summary,
)
from app.llm_config import (
    LAOZHANG_COMPRESSION_MODEL,
    LAOZHANG_DRAFT_MODEL,
    LAOZHANG_DRAFT_MULTILINGUAL_MODEL,
    LAOZHANG_GEMINI_FLASH,
    LAOZHANG_GEMINI_PRO,
    LAOZHANG_HUMANIZATION_MULTILINGUAL_MODEL,
    LAOZHANG_LYRICS_PRIMARY_MODEL,
    LAOZHANG_PROMPT_MODEL,
    LAOZHANG_THEME_CONSISTENCY_MODEL,
    LAOZHANG_VISION_MODEL,
    prefer_laozhang_multilingual_humanization,
    OPENROUTER_COMPRESSION_MODEL,
    OPENROUTER_GENERATE_MODEL,
    OPENROUTER_HUMANIZATION_MODEL,
    OPENROUTER_PRIMARY_MODEL,
    OPENROUTER_THEME_CONSISTENCY_MODEL,
    hybrid_prompt_enabled,
    llm_provider,
    resolve_analysis_model,
    resolve_base_url,
    resolve_draft_model,
    resolve_laozhang_lyrics_secondary_model,
    resolve_polish_model,
    resolve_compression_model,
    resolve_humanization_model,
    resolve_theme_consistency_model,
    two_pass_prompt_enabled,
)
from app.architect_pass import (
    inject_blueprint_into_user,
    parse_architect_blueprint,
)
from app.block1_mix_master_directive import block1_mix_master_user_block
from app.drum_matrix import build_drum_staging_line, drum_matrix_user_block, resolve_drum_profile
from app.genre_hybridization import genre_hybridization_user_block
from app.live_instrument_matrix import (
    augment_avoid_clause,
    generate_live_instrument_prompt,
    live_instrument_user_block,
    resolve_genre_instrument_key,
)
from app.code_translation_matrix import (
    apply_genre_specific_codes,
    code_translation_user_block,
    get_genre_category,
)
from app.suno_system_prompt_v2 import SYSTEM_PROMPT_V2
from app.post_process_common import load_tool_prompt
from app.suno_compression_pass import (
    apply_suno_compression_pass,
    suno_compression_pass_enabled,
)
from app.theme_consistency import (
    apply_theme_consistency_pass,
    merge_block2_parts,
    split_block2_parts,
    theme_consistency_enabled,
)
from app.suno_prompt_builder import (
    build_suno_prompt,
    genre_fx_user_block,
    resolve_genre_fx_key,
    strip_fx_layout,
)
from app.human_authenticity import (
    human_authenticity_user_block,
    is_electronic_lane,
    is_festival_vocal_lane,
    is_gospel_lane,
    is_mantra_dominant_lane,
    is_partial_situation_story_lane,
    is_situation_first_story_lane,
)
from app.human_realism import band_label, clamp_level, human_realism_user_block
from app.elite_human_lyricist_directive import (
    ELITE_HUMAN_LYRICIST_DIRECTIVE,
    build_phonetic_integrity_rule,
)
from app.audio_environment import (
    LIVE_PERFORMANCE_ID,
    audio_environment_user_block,
    is_live_performance_mode,
)
from app.dialect_style import (
    NIGERIAN_PIDGIN_ID,
    dialect_style_user_block,
    is_nigerian_pidgin,
)
from app.vocal_accent import (
    ACCENT_VS_DIALECT_CONSTRAINT,
    accent_vs_dialect_constraint_line,
    layer1_descriptor_for,
    regional_tag_deduplication_line,
    vocal_accent_user_block,
)
from app.vocal_spec_tone import (
    user_block_directive as vocal_spec_tone_user_block,
    user_block_line as vocal_spec_tone_user_block_line,
)
from app.payload_optimization import (
    append_laozhang_system_prompt_boundary,
    compact_payload_text,
    enforce_laozhang_syntax_hygiene,
    process_dynamic_vocal_and_instrument_payload,
    run_global_prompt_hygiene,
    truncate_continuation_prior,
    vocal_option_from_audio_environment,
)
from app.remix_engine import (
    apply_instrumental_remix_output,
    remix_engine_active,
    remix_style_flip_user_block_supplement,
)
from app.post_process_common import genre_context_block
from app.main import GeneratePromptBody, _build_user_block, create_app
from app.prompt_pipeline import (
    generate_prompt_completion,
    generate_prompt_hybrid,
    generate_suno_prompt,
)
from app.suno_internal_output_strip import strip_internal_cognition_blocks
from app.suno_lyric_phonetic_sanitize import (
    apply_critical_reconciliation,
    sanitize_gospel_staging_tags,
    sanitize_studio_isolation_tags,
    sanitize_instrumental_staging_tags,
    sanitize_suno_lyric_phonetics,
    sanitize_suno_post_output,
)
from app.suno_lyrics_audio_normalizer import (
    apply_audio_engine_normalization_to_suno_output,
    normalize_lyrics_for_audio_engine,
)
from app.suno_output_qa import (
    block1_probably_truncated,
    should_format_retry,
    unified_block2_missing,
)
from app.http_middleware import request_timeout_seconds


def _tiny_wav_bytes(duration_s: float = 2.0, sr: int = 22050) -> bytes:
    t = np.linspace(0, duration_s, int(sr * duration_s), endpoint=False)
    y = 0.3 * np.sin(2 * np.pi * 440 * t)
    buf = io.BytesIO()
    sf.write(buf, y, sr, format="WAV")
    return buf.getvalue()


class TestLlmConfig(unittest.TestCase):
    def test_laozhang_default_base_url(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENAI_BASE_URL", None)
            os.environ.pop("OPENROUTER_ONLY", None)
            self.assertEqual(resolve_base_url(), "https://api.laozhang.ai/v1")
            self.assertEqual(llm_provider(), "laozhang")

    def test_hybrid_default_for_laozhang_lyrics_only(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENROUTER_ONLY", None)
            os.environ.pop("PROMPT_PIPELINE", None)
            os.environ.pop("PROMPT_HYBRID", None)
            self.assertTrue(
                hybrid_prompt_enabled(
                    lightweight=False, provider="laozhang", lyrics_task=True
                ),
            )
            self.assertFalse(
                hybrid_prompt_enabled(
                    lightweight=False, provider="laozhang", lyrics_task=False
                ),
            )
            self.assertFalse(
                hybrid_prompt_enabled(lightweight=False, provider="openrouter"),
            )
        with patch.dict(os.environ, {"PROMPT_PIPELINE": "single"}, clear=False):
            self.assertFalse(
                hybrid_prompt_enabled(
                    lightweight=False, provider="laozhang", lyrics_task=True
                ),
            )
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("PROMPT_PIPELINE", None)
            self.assertFalse(hybrid_prompt_enabled(lightweight=True, provider="laozhang"))

    def test_two_pass_mode_disables_hybrid(self):
        with patch.dict(os.environ, {"PROMPT_PIPELINE": "two_pass"}, clear=False):
            self.assertTrue(
                two_pass_prompt_enabled(lightweight=False, lyrics_task=True),
            )
            self.assertFalse(
                hybrid_prompt_enabled(
                    lightweight=False, provider="laozhang", lyrics_task=True
                ),
            )
            self.assertFalse(
                two_pass_prompt_enabled(lightweight=False, lyrics_task=False),
            )
        with patch.dict(os.environ, {"PROMPT_PIPELINE": "architect"}, clear=False):
            self.assertTrue(two_pass_prompt_enabled(lyrics_task=True))

    def test_draft_and_polish_models(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("PROMPT_DRAFT_MODEL", None)
            os.environ.pop("PROMPT_POLISH_MODEL", None)
            os.environ.pop("PROMPT_LYRICS_MODEL", None)
            self.assertEqual(
                resolve_draft_model(
                    language="English", provider="laozhang", lyrics_task=True
                ),
                LAOZHANG_DRAFT_MODEL,
            )
            self.assertEqual(
                resolve_draft_model(
                    language="English", provider="laozhang", lyrics_task=False
                ),
                LAOZHANG_GEMINI_PRO,
            )
            self.assertEqual(
                resolve_draft_model(language="English", provider="openrouter"),
                OPENROUTER_PRIMARY_MODEL,
            )
            self.assertEqual(resolve_analysis_model(), LAOZHANG_GEMINI_FLASH)
            self.assertEqual(
                resolve_polish_model(provider="laozhang", lyrics_task=True),
                LAOZHANG_LYRICS_PRIMARY_MODEL,
            )
            self.assertEqual(
                resolve_theme_consistency_model(
                    language="English", provider="laozhang"
                ),
                LAOZHANG_THEME_CONSISTENCY_MODEL,
            )
            self.assertEqual(
                resolve_theme_consistency_model(
                    language="Spanish", provider="openrouter"
                ),
                OPENROUTER_THEME_CONSISTENCY_MODEL,
            )
            self.assertEqual(
                resolve_humanization_model(provider="openrouter"),
                OPENROUTER_HUMANIZATION_MODEL,
            )
            self.assertEqual(
                resolve_compression_model(provider="openrouter"),
                OPENROUTER_COMPRESSION_MODEL,
            )
            self.assertEqual(OPENROUTER_PRIMARY_MODEL, OPENROUTER_GENERATE_MODEL)
            self.assertEqual(
                resolve_laozhang_lyrics_secondary_model(),
                LAOZHANG_GEMINI_PRO,
            )
            self.assertEqual(
                resolve_draft_model(
                    language="French", lightweight=False, provider="laozhang"
                ),
                LAOZHANG_DRAFT_MULTILINGUAL_MODEL,
            )

    def test_openrouter_prod_env_does_not_override_laozhang(self):
        with patch.dict(
            os.environ,
            {
                "OPENROUTER_GENERATE_MODEL": "qwen/qwen3.7-plus",
                "THEME_CONSISTENCY_MODEL": "qwen/qwen3.7-plus",
                "HUMANIZATION_MODEL": "mistralai/mistral-large",
                "SUNO_COMPRESSION_MODEL": "qwen/qwen3.7-plus",
                "PROMPT_POLISH_MODEL": "qwen/qwen3.7-plus",
            },
            clear=False,
        ):
            self.assertEqual(
                resolve_theme_consistency_model(
                    language="English", provider="laozhang"
                ),
                LAOZHANG_THEME_CONSISTENCY_MODEL,
            )
            self.assertEqual(
                resolve_humanization_model(
                    provider="laozhang", language="English"
                ),
                LAOZHANG_LYRICS_PRIMARY_MODEL,
            )
            self.assertEqual(
                resolve_humanization_model(
                    provider="laozhang", language="French"
                ),
                LAOZHANG_HUMANIZATION_MULTILINGUAL_MODEL,
            )
            self.assertEqual(
                resolve_humanization_model(
                    provider="laozhang",
                    language="English",
                    dialect_style_id="nigerian_pidgin",
                ),
                LAOZHANG_HUMANIZATION_MULTILINGUAL_MODEL,
            )
            self.assertEqual(
                resolve_compression_model(provider="laozhang"),
                LAOZHANG_COMPRESSION_MODEL,
            )
            self.assertEqual(
                resolve_polish_model(provider="laozhang", lyrics_task=True),
                LAOZHANG_LYRICS_PRIMARY_MODEL,
            )
            self.assertEqual(
                resolve_theme_consistency_model(
                    language="English", provider="openrouter"
                ),
                "qwen/qwen3.7-plus",
            )
            self.assertEqual(
                resolve_humanization_model(provider="openrouter"),
                "mistralai/mistral-large",
            )
            self.assertEqual(
                resolve_polish_model(provider="openrouter", lyrics_task=True),
                "qwen/qwen3.7-plus",
            )


class TestGeminiParsing(unittest.TestCase):
    def test_parse_json_with_fence(self):
        raw = '''```json
{"genre": "House", "subGenre": "Deep", "bpm": 124, "keyScale": "A Minor",
 "moodTags": ["groovy"], "instruments": ["kick"], "vocals": "Instrumental",
 "structure": "Intro → Drop", "lyricsTranscription": "",
 "tempoFeel": "Driving", "chordComplexity": "Moderate",
 "loudness": "-8 LUFS", "confidenceOverall": "High",
 "richDescription": "A tight club track."}
```'''
        parsed = _parse_json_response(raw)
        self.assertIsNotNone(parsed)
        out = _normalize_gemini_result(parsed, model="gemini-2.5-flash")
        self.assertEqual(out["bpm"], 124.0)
        self.assertIn("House", out["genre"])
        self.assertEqual(out["analysisMode"], "gemini")
        self.assertEqual(out["structure"], "Intro → Drop")
        self.assertIn(",", out["analyzerSummary"])

    def test_sanitize_analyzer_summary_requires_four_tags(self):
        raw = "Male Lead, Emotional Close-Mic, Low Energy, Dead-Room Isolation"
        self.assertEqual(sanitize_analyzer_summary(raw), raw)
        self.assertEqual(
            sanitize_analyzer_summary(""),
            "General Delivery, Smooth Close-Mic, Moderate Energy, Pristine Studio Environment",
        )

    def test_build_analyzer_summary_from_vocals_and_energy(self):
        summary = build_analyzer_summary_from_result(
            {
                "vocals": "Female lead breathy",
                "energy": "High (78/100)",
                "tempoFeel": "Driving",
                "loudness": "-8 LUFS",
            }
        )
        self.assertIn("Female lead breathy", summary)
        self.assertGreaterEqual(summary.count(","), 3)


class TestPromptPipeline(unittest.TestCase):
    def test_hybrid_calls_draft_then_polish(self):
        client = MagicMock()
        draft_resp = MagicMock()
        draft_resp.choices = [MagicMock(message=MagicMock(content="BLOCK 1 draft"))]
        polish_resp = MagicMock()
        polish_resp.choices = [MagicMock(message=MagicMock(content="BLOCK 1 polished"))]

        client.chat.completions.create.side_effect = [draft_resp, polish_resp]

        with patch.dict(os.environ, {"OPENAI_API_KEY": "test-key"}, clear=False):
            os.environ.pop("PROMPT_PIPELINE", None)
            text, pipeline = generate_prompt_hybrid(
                client,
                system_prompt="sys",
                user_content="user",
                language="English",
                lightweight=False,
                max_tokens=500,
            )
        self.assertEqual(text, "BLOCK 1 polished")
        self.assertIn(LAOZHANG_DRAFT_MODEL, pipeline)
        draft_model = client.chat.completions.create.call_args_list[0].kwargs["model"]
        polish_model = client.chat.completions.create.call_args_list[1].kwargs["model"]
        self.assertEqual(draft_model, LAOZHANG_DRAFT_MODEL)
        self.assertEqual(polish_model, LAOZHANG_LYRICS_PRIMARY_MODEL)
        self.assertEqual(client.chat.completions.create.call_count, 2)

    def test_single_mode_when_pipeline_single(self):
        client = MagicMock()
        resp = MagicMock()
        resp.choices = [MagicMock(message=MagicMock(content="only one"))]
        client.chat.completions.create.return_value = resp

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "k", "PROMPT_PIPELINE": "single"},
            clear=False,
        ):
            result = generate_suno_prompt(
                client,
                system_prompt="sys",
                user_content="user",
                language="English",
                lightweight=False,
                max_tokens=400,
            )
        self.assertEqual(result.text, "only one")
        self.assertEqual(client.chat.completions.create.call_count, 1)
        self.assertIsNone(result.architect_blueprint)

    def test_two_pass_architect_then_lyricist(self):
        b1 = " ".join(["producer"] * 140)
        lyric_out = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(line)\n[Chorus]\nhook\n[End]"
        )
        architect_json = """{
  "genre_primary": "Techno",
  "genre_fusion": "",
  "songwriting_mode": "B",
  "bpm_intent": 140,
  "key_intent": "A minor",
  "emotion_before": "tense",
  "emotion_after": "released",
  "transformation_arc": "tension to release",
  "audience": "club",
  "commercial_objective": "Festival Anthem",
  "hook_concept": "we don't stop",
  "three_second_intro_anchor": "breath chop",
  "user_proxy_moment": "we don't stop",
  "section_roadmap": ["Intro", "Verse 1", "Chorus", "Drop", "Outro"],
  "syllable_density": "short punchy",
  "artist_dna_traits": ["driving", "dark"],
  "vocal_character": "processed male",
  "production_keywords": ["sidechain", "riser"],
  "conflict_resolution_notes": "aligned"
}"""
        client = MagicMock()
        arch_resp = MagicMock()
        arch_resp.choices = [
            MagicMock(message=MagicMock(content=architect_json), finish_reason="stop")
        ]
        lyric_resp = MagicMock()
        lyric_resp.choices = [
            MagicMock(message=MagicMock(content=lyric_out), finish_reason="stop")
        ]
        client.chat.completions.create.side_effect = [arch_resp, lyric_resp]

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "k", "PROMPT_PIPELINE": "two_pass"},
            clear=False,
        ):
            result = generate_suno_prompt(
                client,
                system_prompt="sys",
                user_content="genre: Techno",
                language="English",
                lightweight=False,
                max_tokens=800,
                provider="laozhang",
                lyrics_task=True,
            )
        self.assertEqual(result.text, lyric_out)
        self.assertTrue(result.pipeline.startswith("two-pass:"))
        self.assertIsNotNone(result.architect_blueprint)
        self.assertIn("Techno", result.architect_blueprint or "")
        self.assertEqual(client.chat.completions.create.call_count, 2)
        # Pass 2 user must include blueprint
        pass2_user = client.chat.completions.create.call_args_list[1].kwargs[
            "messages"
        ][-1]["content"]
        self.assertIn("MASTER BLUEPRINT", pass2_user)
        self.assertIn("we don't stop", pass2_user)

    def test_two_pass_reuses_cached_blueprint(self):
        b1 = " ".join(["producer"] * 140)
        lyric_out = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\nx\n[End]"
        )
        cached = '{"genre_primary":"House","songwriting_mode":"A","hook_concept":"stay",'
        cached += '"section_roadmap":["Intro","Chorus"],"artist_dna_traits":["warm"]}'
        client = MagicMock()
        lyric_resp = MagicMock()
        lyric_resp.choices = [
            MagicMock(message=MagicMock(content=lyric_out), finish_reason="stop")
        ]
        client.chat.completions.create.return_value = lyric_resp

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "k", "PROMPT_PIPELINE": "two_pass"},
            clear=False,
        ):
            result = generate_suno_prompt(
                client,
                system_prompt="sys",
                user_content="genre: House",
                language="English",
                lightweight=False,
                max_tokens=800,
                provider="laozhang",
                lyrics_task=True,
                architect_blueprint=cached,
            )
        self.assertEqual(client.chat.completions.create.call_count, 1)
        self.assertEqual(result.architect_blueprint, cached)


class TestArchitectPass(unittest.TestCase):
    def test_parse_fenced_json(self):
        raw = """```json
{"genre_primary": "Afrobeats", "songwriting_mode": "B",
 "hook_concept": "small small", "section_roadmap": ["Intro", "Chorus"],
 "artist_dna_traits": ["groovy"]}
```"""
        bp = parse_architect_blueprint(raw)
        self.assertEqual(bp["genre_primary"], "Afrobeats")
        self.assertEqual(bp["songwriting_mode"], "B")

    def test_inject_blueprint_appends_rules(self):
        out = inject_blueprint_into_user("USER", {"genre_primary": "Pop", "songwriting_mode": "C",
                                                   "hook_concept": "x", "section_roadmap": ["Chorus"],
                                                   "artist_dna_traits": []})
        self.assertIn("USER", out)
        self.assertIn("MASTER BLUEPRINT", out)
        self.assertIn("PASS 2 RULES", out)
        self.assertIn("[End]", out)


class TestSunoOutputQa(unittest.TestCase):
    def test_detects_missing_block2_and_short_block1(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            "Suno v5.5. Peak-time techno at 148 BPM. The [Intro] initiates a"
        )
        self.assertTrue(unified_block2_missing(raw))
        self.assertTrue(block1_probably_truncated(raw))
        self.assertTrue(
            should_format_retry(raw, use_v2=True, block2_opt_out=False),
        )

    def test_complete_two_block_passes_qa(self):
        b1 = " ".join(["producer"] * 140)
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(line)\n[End]"
        )
        self.assertFalse(unified_block2_missing(raw))
        self.assertFalse(block1_probably_truncated(raw))
        self.assertFalse(
            should_format_retry(raw, use_v2=True, block2_opt_out=False),
        )


class TestRobustDsp(unittest.TestCase):
    def test_peak_normalize_scales_quiet_acapella(self):
        y = np.array([0.01, -0.005, 0.008], dtype=np.float32)
        out = _peak_normalize(y)
        self.assertAlmostEqual(float(np.max(np.abs(out))), 1.0, places=5)

    def test_robust_energy_uses_upper_percentile(self):
        # Quiet intro (70%) + loud chorus (30%) — p80 should land in chorus band.
        rmse = np.array([0.005] * 70 + [0.35] * 30)
        mean_score = int(np.clip(float(np.mean(rmse)) * 300, 0, 100))
        robust = _robust_energy_0_100(rmse)
        self.assertGreater(robust, mean_score)
        self.assertGreaterEqual(robust, 90)

    def test_tempo_halving_for_double_time_low_perc(self):
        self.assertEqual(_correct_double_time_tempo(144.0, 0.25), 72.0)

    def test_tempo_kept_for_percussive_club(self):
        self.assertEqual(_correct_double_time_tempo(160.0, 0.55), 160.0)

    def test_operational_dbfs_not_extreme_after_normalize(self):
        y = _peak_normalize(np.array([0.02, -0.01, 0.015], dtype=np.float32))
        dbfs = _operational_dbfs(y)
        self.assertGreater(dbfs, -30.0)
        self.assertLess(dbfs, 0.0)


class TestHarmonyMelodyExtract(unittest.TestCase):
    def test_note_name_without_octave(self):
        self.assertEqual(_note_name_without_octave("D4"), "D")
        self.assertIn("A", _note_name_without_octave("A4"))

    def test_harmony_melody_on_tonal_signal(self):
        sr = 22050
        t = np.linspace(0, 3.0, int(sr * 3), endpoint=False)
        y = 0.5 * np.sin(2 * np.pi * 440 * t)
        out = _extract_harmonics_and_melody_from_array(y, sr)
        self.assertIn("Implied Progression Base:", out["impliedChords"])
        self.assertIn("Vocal Melody Range Notes:", out["melodyProfile"])
        self.assertIn("percussiveBpm", out)

    def test_harmony_fallback_bundle_on_tiny_buffer(self):
        out = _extract_harmonics_and_melody_from_array(np.zeros(100), 22050)
        self.assertEqual(out["impliedChords"], "Implied Progression Base: D-F#-A")
        self.assertIn("D, F#, A", out["melodyProfile"])
        self.assertEqual(out["percussiveBpm"], 72.0)

    def test_analyze_route_includes_harmony_fields(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENAI_API_KEY", None)
            os.environ.pop("AUDD_API_KEY", None)
            os.environ["ANALYSIS_MODE"] = "librosa"
            os.environ["LLM_TRACK_CLASSIFIER"] = "false"
            data = _tiny_wav_bytes(duration_s=3.0)
            r = TestClient(create_app()).post(
                "/analyze",
                files={"file": ("test.wav", data, "audio/wav")},
            )
        self.assertEqual(r.status_code, 200)
        body = r.json()
        self.assertIn("impliedChords", body)
        self.assertIn("melodyProfile", body)
        self.assertEqual(body.get("title"), "Original Track / Voice Memo")


class TestAuddRecognition(unittest.TestCase):
    def test_fallback_when_api_key_missing(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("AUDD_API_KEY", None)
            meta = recognize_audio_metadata(b"fake-audio", filename="test.wav")
        self.assertEqual(meta["title"], "Original Recording / Stem")
        self.assertFalse(meta["trackRecognized"])

    def test_parses_successful_audd_response(self):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.text = '{"status":"success","result":{"title":"Blinding Lights","artist":"The Weeknd","album":"After Hours","release_date":"2020-03-20"}}'
        mock_response.json.return_value = {
            "status": "success",
            "result": {
                "title": "Blinding Lights",
                "artist": "The Weeknd",
                "album": "After Hours",
                "release_date": "2020-03-20",
            },
        }
        with patch.dict(os.environ, {"AUDD_API_KEY": "test-token"}, clear=False):
            with patch("requests.post", return_value=mock_response) as post:
                meta = recognize_audio_metadata(b"fake-audio", filename="test.mp3")
        self.assertEqual(meta["title"], "Blinding Lights")
        self.assertEqual(meta["artist"], "The Weeknd")
        self.assertTrue(meta["trackRecognized"])
        args, kwargs = post.call_args
        files = kwargs["files"]
        self.assertIn("file", files)
        upload_name, stream, mime = files["file"]
        self.assertEqual(upload_name, "test.mp3")
        self.assertEqual(mime, "audio/mpeg")
        self.assertIsInstance(stream, io.BytesIO)
        stream.seek(0)
        self.assertEqual(stream.read(), b"fake-audio")

    def test_acapella_uses_recognized_artist_in_production_intent(self):
        intent = _acapella_production_intent(
            artist="The Weeknd",
            track_recognized=True,
        )
        self.assertIn("The Weeknd", intent)
        self.assertIn("custom remix", intent)


class TestDynamicGenreEstimator(unittest.TestCase):
    def test_hip_hop_pocket_for_92_bpm_dmx_style(self):
        signals = {
            "_perc_ratio": 0.52,
            "_rolloff_med": 4800.0,
            "energy": "High (78/100)",
        }
        genre, inst = _estimate_dynamic_genre_profile(
            actual_bpm=92,
            signals=signals,
        )
        self.assertIn("Hip-Hop", genre)
        self.assertIn("Boom-Bap", " · ".join(inst))

    def test_bright_pop_for_high_rolloff_104_bpm(self):
        signals = {
            "_perc_ratio": 0.35,
            "_rolloff_med": 7200.0,
            "energy": "Medium (55/100)",
        }
        genre, inst = _estimate_dynamic_genre_profile(
            actual_bpm=104,
            signals=signals,
        )
        self.assertIn("Pop", genre)
        self.assertIn("Synths", " · ".join(inst))

    def test_audd_genre_extracted_from_nested_payload(self):
        genre = audd_genre_from_result(
            {
                "title": "Ghost",
                "artist": "Justin Bieber",
                "apple_music": {"genre": "Pop"},
            }
        )
        self.assertEqual(genre, "Pop")


class TestLlmTrackClassifier(unittest.TestCase):
    def test_heuristic_hip_hop_pocket(self):
        meta = heuristic_track_metadata({"bpm": 92})
        self.assertIn("Hip-Hop", meta["genre"])
        self.assertEqual(meta["artist"], "Independent Creator")

    def test_heuristic_acoustic_pop_outside_pocket(self):
        meta = heuristic_track_metadata({"bpm": 120})
        self.assertIn("Acoustic Pop", meta["genre"])

    def test_resolve_uses_audd_when_present(self):
        meta = resolve_track_metadata(
            {
                "title": "Ghost",
                "artist": "Justin Bieber",
                "album": "Justice",
                "release_date": "2021-03-19",
                "apple_music": {"genre": "Pop"},
            },
            signals={"bpm": 72},
            filename="ghost.mp3",
        )
        self.assertEqual(meta["title"], "Ghost")
        self.assertEqual(meta["metadataSource"], "audd")
        self.assertTrue(meta["trackRecognized"])

    def test_llm_classifier_when_audd_null(self):
        mock_response = MagicMock()
        mock_response.choices = [
            MagicMock(
                message=MagicMock(
                    content=(
                        '{"title": "Ghost", "artist": "Justin Bieber", "album": "Justice", '
                        '"releaseDate": "2021", "genre": "Pop", "instruments": ["Lead Vocals"], '
                        '"identified": true}'
                    )
                )
            )
        ]
        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response

        with patch.dict(os.environ, {"LLM_TRACK_CLASSIFIER": "true"}, clear=False):
            with patch(
                "app.llm_track_classifier.build_openai_client_kwargs",
                return_value={"api_key": "test"},
            ):
                with patch("openai.OpenAI", return_value=mock_client):
                    meta = resolve_track_metadata(
                        None,
                        signals={
                            "bpm": 72,
                            "keyScale": "F# Minor",
                            "trackLength": "3:14",
                            "impliedChords": "Implied Progression Base: F#-A-C#",
                        },
                        filename="stem.wav",
                    )
        self.assertEqual(meta["title"], "Ghost")
        self.assertEqual(meta["metadataSource"], "llm")
        self.assertTrue(meta["trackRecognized"])

    def test_heuristic_when_audd_and_llm_unavailable(self):
        with patch.dict(os.environ, {"LLM_TRACK_CLASSIFIER": "false"}, clear=False):
            os.environ.pop("OPENAI_API_KEY", None)
            meta = resolve_track_metadata(None, signals={"bpm": 92}, filename="demo.mp3")
        self.assertEqual(meta["metadataSource"], "heuristic")
        self.assertFalse(meta["trackRecognized"])


class TestAcapellaMetadata(unittest.TestCase):
    def test_halves_bpm_and_sets_production_intent(self):
        raw = {
            "bpm": 144.0,
            "genre": "Hip Hop / Rap Vocals / Acapella (estimate)",
            "instruments": ["Lead Vocals", "Ad-libs"],
        }
        out = adjust_metadata_for_acapellas(raw)
        self.assertEqual(out["bpm"], 72.0)
        self.assertTrue(out["isAcapella"])
        self.assertIn("full commercial pop/dance arrangement", out["productionIntent"])

    def test_lead_vocals_instruments_triggers_acapella(self):
        out = adjust_metadata_for_acapellas(
            {
                "bpm": 120,
                "genre": "Pop / Mixed (estimate)",
                "instruments": ["Lead Vocals", "Stacks / harmonies"],
            }
        )
        self.assertTrue(out["isAcapella"])
        self.assertEqual(out["bpm"], 120)

    def test_full_mix_keeps_default_intent(self):
        out = adjust_metadata_for_acapellas(
            {
                "bpm": 128,
                "genre": "House / Groove Electronic (estimate)",
                "instruments": ["Kick", "Bass", "Pads"],
            }
        )
        self.assertFalse(out["isAcapella"])
        self.assertIn("Match the current energy", out["productionIntent"])


class TestHttpMiddleware(unittest.TestCase):
    def test_request_timeout_default(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("REQUEST_TIMEOUT_SECONDS", None)
            self.assertEqual(request_timeout_seconds(), 360.0)


class TestCompletionTokenKwargs(unittest.TestCase):
    def test_gpt56_sol_uses_max_completion_tokens_only(self):
        from app.llm_config import completion_token_kwargs

        kw = completion_token_kwargs("gpt-5.6-sol", 4096)
        self.assertEqual(kw, {"max_completion_tokens": 4096})

    def test_gpt6_astra_uses_max_completion_tokens_only(self):
        from app.llm_config import completion_token_kwargs

        kw = completion_token_kwargs("gpt-6-astra", 4096)
        self.assertEqual(kw, {"max_completion_tokens": 4096})
        self.assertNotIn("max_tokens", kw)

    def test_claude_keeps_max_tokens(self):
        from app.llm_config import completion_token_kwargs

        kw = completion_token_kwargs("claude-sonnet-4-5", 2048)
        self.assertEqual(kw, {"max_tokens": 2048})


class TestApiRoutes(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(create_app())

    def test_health(self):
        r = self.client.get("/")
        self.assertEqual(r.status_code, 200)
        self.assertIn("generate_prompt", r.json().get("routes", {}))

        r = self.client.post("/generate", json={"suno_version": "v5.0", "primary_genre": "House"})
        self.assertIn(r.status_code, (200, 502, 503))

        r = self.client.get("/health")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json(), {"status": "ok"})

    def test_analyze_librosa_fallback_without_api_key(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENAI_API_KEY", None)
            os.environ.pop("AUDD_API_KEY", None)
            os.environ["ANALYSIS_MODE"] = "librosa"
            os.environ["LLM_TRACK_CLASSIFIER"] = "false"
            data = _tiny_wav_bytes()
            r = self.client.post(
                "/analyze",
                files={"file": ("test.wav", data, "audio/wav")},
            )
        self.assertEqual(r.status_code, 200)
        body = r.json()
        self.assertIn("bpm", body)
        self.assertIn("keyScale", body)
        self.assertEqual(body.get("analysisMode"), "librosa")
        self.assertIn("analyzerSummary", body)
        self.assertIn(",", body["analyzerSummary"])
        self.assertIn("title", body)
        self.assertIn("artist", body)

    def test_generate_prompt_503_without_key(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENAI_API_KEY", None)
            r = self.client.post(
                "/generate-prompt",
                json={"suno_version": "v5.0", "primary_genre": "House", "vibe": "test"},
            )
        self.assertEqual(r.status_code, 503)

    def test_generate_prompt_accepts_app_laozhang_key_without_env(self):
        client = MagicMock()
        draft_resp = MagicMock()
        draft_resp.choices = [
            MagicMock(message=MagicMock(content="BLOCK 1 — PASTE INTO SUNO: STYLE\n\nok"))
        ]
        client.chat.completions.create.return_value = draft_resp

        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("OPENAI_API_KEY", None)
            os.environ["PROMPT_PIPELINE"] = "single"
            with patch("app.main.OpenAI", return_value=client):
                r = self.client.post(
                    "/generate-prompt",
                    json={
                        "suno_version": "v5.0",
                        "primary_genre": "House",
                        "vibe": "test",
                        "llm_provider": "laozhang",
                        "laozhang_api_key": "lz-from-app",
                        "prefer_lightweight_model": True,
                    },
                )
        self.assertEqual(r.status_code, 200)
        self.assertIn("ok", r.json()["prompt"])

    @patch("app.laozhang_post_process.suno_compression_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.humanization_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.theme_consistency_enabled", return_value=False)
    def test_generate_prompt_hybrid_with_mocked_llm(
        self, _theme_off, _humanize_off, _compress_off
    ):
        b1 = " ".join(["producer"] * 140)
        complete = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(staging)\n[End]"
        )
        client = MagicMock()
        draft_resp = MagicMock()
        draft_resp.choices = [
            MagicMock(
                message=MagicMock(content=complete.replace("producer", "draft")),
                finish_reason="stop",
            )
        ]
        polish_resp = MagicMock()
        polish_resp.choices = [
            MagicMock(
                message=MagicMock(content=complete),
                finish_reason="stop",
            )
        ]
        client.chat.completions.create.side_effect = [draft_resp, polish_resp]

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "test-key", "PROMPT_PIPELINE": "hybrid"},
            clear=False,
        ):
            with patch("app.main.OpenAI", return_value=client):
                r = self.client.post(
                    "/generate-prompt",
                    json={
                        "suno_version": "v5.0",
                        "primary_genre": "House",
                        "vibe": "dark club",
                        "prefer_lightweight_model": False,
                        "llm_provider": "laozhang",
                    },
                )
        self.assertEqual(r.status_code, 200)
        body = r.json()
        self.assertIn("BLOCK 2", body["prompt"])
        self.assertIn(LAOZHANG_DRAFT_MODEL, body.get("pipeline", ""))
        self.assertEqual(client.chat.completions.create.call_count, 2)

    @patch("app.laozhang_post_process.suno_compression_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.humanization_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.theme_consistency_enabled", return_value=False)
    def test_laozhang_default_uses_hybrid_llm_calls(
        self, _theme_off, _humanize_off, _compress_off
    ):
        b1 = " ".join(["word"] * 140)
        complete = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(line)\n[End]"
        )
        client = MagicMock()
        draft_resp = MagicMock()
        draft_resp.choices = [
            MagicMock(message=MagicMock(content=complete), finish_reason="stop")
        ]
        polish_resp = MagicMock()
        polish_resp.choices = [
            MagicMock(message=MagicMock(content=complete), finish_reason="stop")
        ]
        client.chat.completions.create.side_effect = [draft_resp, polish_resp]

        with patch.dict(os.environ, {"OPENAI_API_KEY": "test-key"}, clear=False):
            os.environ.pop("PROMPT_PIPELINE", None)
            os.environ.pop("PROMPT_HYBRID", None)
            with patch("app.main.OpenAI", return_value=client):
                r = self.client.post(
                    "/generate-prompt",
                    json={
                        "suno_version": "v5.5",
                        "primary_genre": "Techno",
                        "vibe": "peak",
                        "llm_provider": "laozhang",
                    },
                )
        self.assertEqual(r.status_code, 200)
        self.assertIn("hybrid:", r.json().get("pipeline", ""))
        self.assertEqual(client.chat.completions.create.call_count, 2)

    @patch("app.laozhang_post_process.suno_compression_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.humanization_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.theme_consistency_enabled", return_value=False)
    def test_generate_prompt_two_pass_with_mocked_llm(
        self, _theme_off, _humanize_off, _compress_off
    ):
        b1 = " ".join(["producer"] * 140)
        lyric_out = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(line)\n[Chorus]\nhook\n[End]"
        )
        architect_json = (
            '{"genre_primary":"House","songwriting_mode":"B","hook_concept":"stay",'
            '"section_roadmap":["Intro","Chorus","Outro"],'
            '"artist_dna_traits":["groovy"],"conflict_resolution_notes":"ok"}'
        )
        client = MagicMock()
        arch_resp = MagicMock()
        arch_resp.choices = [
            MagicMock(message=MagicMock(content=architect_json), finish_reason="stop")
        ]
        lyric_resp = MagicMock()
        lyric_resp.choices = [
            MagicMock(message=MagicMock(content=lyric_out), finish_reason="stop")
        ]
        client.chat.completions.create.side_effect = [arch_resp, lyric_resp]

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "test-key", "PROMPT_PIPELINE": "two_pass"},
            clear=False,
        ):
            with patch("app.main.OpenAI", return_value=client):
                r = self.client.post(
                    "/generate-prompt",
                    json={
                        "suno_version": "v5.5",
                        "primary_genre": "House",
                        "vibe": "warm groove",
                        "prefer_lightweight_model": False,
                        "llm_provider": "laozhang",
                    },
                )
        self.assertEqual(r.status_code, 200)
        body = r.json()
        self.assertIn("BLOCK 2", body["prompt"])
        self.assertTrue(body.get("pipeline", "").startswith("two-pass:"))
        self.assertEqual(client.chat.completions.create.call_count, 2)
        pass2_user = client.chat.completions.create.call_args_list[1].kwargs[
            "messages"
        ][-1]["content"]
        self.assertIn("MASTER BLUEPRINT", pass2_user)

    @patch("app.laozhang_post_process.suno_compression_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.humanization_pass_enabled", return_value=False)
    @patch("app.laozhang_post_process.theme_consistency_enabled", return_value=False)
    def test_format_retry_on_incomplete_output(
        self, _theme_off, _humanize_off, _compress_off
    ):
        incomplete = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            "Suno v5.5. Peak-time techno at 148 BPM. The [Intro] initiates a"
        )
        b1 = " ".join(["word"] * 140)
        complete = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            f"{b1}\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n(staging)\n[Verse]\n(line)\n[End]"
        )
        client = MagicMock()
        resp1 = MagicMock()
        resp1.choices = [
            MagicMock(
                message=MagicMock(content=incomplete),
                finish_reason="stop",
            )
        ]
        resp2 = MagicMock()
        resp2.choices = [
            MagicMock(
                message=MagicMock(content=complete),
                finish_reason="stop",
            )
        ]
        client.chat.completions.create.side_effect = [resp1, resp2]

        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "test-key", "PROMPT_PIPELINE": "single"},
            clear=False,
        ):
            with patch("app.main.OpenAI", return_value=client):
                r = self.client.post(
                    "/generate-prompt",
                    json={
                        "suno_version": "v5.5",
                        "primary_genre": "Techno",
                        "vibe": "peak time",
                    },
                )
        self.assertEqual(r.status_code, 200)
        self.assertIn("BLOCK 2", r.json()["prompt"])
        pipeline = r.json().get("pipeline", "")
        # Recovery may happen via format-retry loop or LaoZhang single-path model fallback.
        self.assertTrue(
            "format-retry" in pipeline
            or "completion" in pipeline
            or "fallback" in pipeline
            or "compact" in pipeline
            or "secondary" in pipeline
            or "lyrics-full" in pipeline
            or "primary-full" in pipeline
        )
        self.assertGreaterEqual(client.chat.completions.create.call_count, 2)


class TestBlock1MixMaster(unittest.TestCase):
    def test_part_e_profile_includes_hardware_lufs_and_dj_phrasing(self):
        from app.genre_hardware_profiles import resolve_hardware_profile

        techno = block1_mix_master_user_block(
            primary_genre="Techno",
            sub_genre_fusion="",
            dj_intro=True,
            dj_outro=True,
        )
        self.assertIn("GENRE HARDWARE DEFAULTS (Part E v2.1", techno)
        self.assertIn("[HW.", techno)
        self.assertEqual(resolve_hardware_profile("Techno").cluster_id, "EDM.5")
        self.assertIn("LUFS", techno)
        self.assertIn("−1.0 dBTP", techno)
        self.assertIn("sixteen-bar filtered drum intro", techno)

        prog = block1_mix_master_user_block(primary_genre="Progressive House")
        self.assertIn("[HW.", prog)
        self.assertEqual(
            resolve_hardware_profile("Progressive House").cluster_id, "EDM.3"
        )
        self.assertIn("sidechain", prog.lower())

        amapiano = block1_mix_master_user_block(
            primary_genre="Amapiano-Vinahouse",
        )
        self.assertIn("[HW.", amapiano)
        self.assertEqual(
            resolve_hardware_profile("Amapiano-Vinahouse").cluster_id, "EDM.12"
        )
        self.assertIn("log drum", amapiano.lower())

    def test_build_user_block_injects_part_e_hardware(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="House",
            vibe="club",
            dj_intro_mix_in=True,
            dj_outro_mix_out=True,
        )
        block = _build_user_block(body)
        self.assertIn("GENRE HARDWARE DEFAULTS (Part E v2.1", block)


class TestDrumMatrix(unittest.TestCase):
    def test_resolve_longest_match(self):
        key, profile = resolve_drum_profile("Melodic Techno", "House")
        self.assertEqual(key, "melodic techno")
        self.assertIn("driving clean kick", profile.kit)

    def test_modern_country_and_trailer_profiles(self):
        country_key, _ = resolve_drum_profile("Modern Country", "Americana")
        self.assertEqual(country_key, "modern country")
        trailer_key, _ = resolve_drum_profile("Trailer", "Orchestral")
        self.assertEqual(trailer_key, "trailer")

    def test_dnb_alias(self):
        key, _ = resolve_drum_profile("Liquid DnB", "")
        self.assertEqual(key, "drum and bass")

    def test_staging_line_max_len(self):
        _, profile = resolve_drum_profile("Hardstyle", "")
        line = build_drum_staging_line(profile, max_len=120)
        self.assertLessEqual(len(line), 120)

    def test_user_block_includes_profile(self):
        block = drum_matrix_user_block("Hardstyle", suno_version="v5.5")
        self.assertIn("DRUM MATRIX", block)
        self.assertIn("[hardstyle]", block)
        self.assertIn("reverse-bass kick", block.lower())

    def test_build_user_block_injects_drum_matrix(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Trap",
            vibe="dark",
        )
        block = _build_user_block(body)
        self.assertIn("DRUM MATRIX", block)
        self.assertIn("[trap]", block)

    def test_suno_prompt_builder_all_genres_max_intensity(self):
        genres = (
            "edm",
            "techno",
            "dnb",
            "synthwave",
            "dubstep",
            "ambient",
            "hiphop",
            "trap",
            "pop",
            "rnb",
            "reggaeton",
            "rock",
            "metal",
            "indie",
            "country",
            "folk",
            "afrobeats",
            "latin",
            "cinematic",
            "jazz",
        )
        for genre in genres:
            output = build_suno_prompt(
                "Base Style Text",
                "[Chorus]\nSinging lyrics here...",
                genre,
                intensity=3,
            )
            self.assertIn("Base Style Text", output.prompt)
            self.assertIn("[Chorus]", output.lyrics)

    def test_build_user_block_injects_genre_fx_matrix(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Hard Techno",
            vibe="dark",
            production_intensity=3,
        )
        block = _build_user_block(body)
        self.assertIn("GENRE FX:", block)
        self.assertIn("[techno]", block)
        self.assertIn("PRODUCTION FX INTENSITY: 3", block)

    def test_apply_genre_fx_to_body_metal_high_intensity(self):
        from app.main import _apply_genre_fx_to_body

        body = GeneratePromptBody(
            primary_genre="Metal",
            vibe="Melodic vocal melody",
            optional_lyrics="[Verse 1]\nUser line here",
            production_intensity=3,
            genre_fx_lane="metal",
        )
        applied = _apply_genre_fx_to_body(body)
        self.assertIn("djent", applied.vibe.lower())
        self.assertIn("[Pre-Breakdown", applied.optional_lyrics)
        self.assertIn("[Verse 1]", applied.optional_lyrics)

    def test_strip_fx_layout_idempotent(self):
        built = build_suno_prompt(
            "style",
            "[Chorus]\nLyrics",
            "metal",
            intensity=3,
        )
        stripped = strip_fx_layout(built.lyrics)
        self.assertIn("[Chorus]", stripped)
        self.assertNotIn("[Pre-Breakdown", stripped)

    def test_resolve_genre_fx_key_aliases(self):
        self.assertEqual(resolve_genre_fx_key("Liquid DnB", ""), "dnb")
        self.assertEqual(resolve_genre_fx_key("Modern Country", ""), "country")

    def test_genre_hybridization_user_block(self):
        block = genre_hybridization_user_block("Melodic Techno", "Indie Acoustic")
        self.assertIn("GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX", block)
        self.assertIn("primaryGenre=Melodic Techno", block)
        self.assertIn("subGenreFusion=Indie Acoustic", block)

    def test_build_user_block_injects_hybridization_when_fusion_set(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Melodic Techno",
            sub_genre_fusion="Indie Acoustic",
            vibe="cinematic",
        )
        block = _build_user_block(body)
        self.assertIn("GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX", block)
        self.assertIn("Split-DNA", block)
        self.assertIn("Subordinate tag accent rule", block)

    def test_block2_opt_out_skips_drum_matrix(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Trap",
            vibe="style only",
        )
        block = _build_user_block(body)
        self.assertNotIn("DRUM MATRIX", block)


class TestCodeTranslationMatrix(unittest.TestCase):
    def test_shoegaze_tender_l99(self):
        self.assertEqual(get_genre_category("Shoegaze", ""), "rock_metal")
        c_final = apply_genre_specific_codes(
            "Shoegaze",
            "/TENDER /L99",
            version="v5.5",
        )
        self.assertIn("clean chorus guitar", c_final)
        self.assertIn("Les Paul", c_final)

    def test_lofi_hip_hop_beastmode_v45(self):
        self.assertEqual(get_genre_category("Lo-Fi Hip Hop", ""), "hiphop")
        c_final = apply_genre_specific_codes(
            "Lo-Fi Hip Hop",
            "/BEASTMODE",
            version="v4.5",
        )
        parts = c_final.split(",")
        self.assertLessEqual(len(parts), 2)

    def test_build_user_block_injects_code_translation(self):
        body = GeneratePromptBody(
            suno_version="v5.5",
            primary_genre="Praise and Worship",
            vibe="uplifting",
            active_modifier_codes="/TENDER /L99",
        )
        block = _build_user_block(body)
        self.assertIn("[CODE TRANSLATION: /TENDER for rnb_soul]", block)
        self.assertIn("[CODE TRANSLATION: /L99 for rnb_soul]", block)
        self.assertIn("Apply these specific sonic characteristics", block)


class TestLiveInstrumentMatrix(unittest.TestCase):
    def test_resolve_neo_soul(self):
        self.assertEqual(resolve_genre_instrument_key("Neo-Soul", ""), "neo_soul")

    def test_harmonized_aliases_and_primary_first(self):
        self.assertEqual(
            resolve_genre_instrument_key("Praise/Worship", ""),
            "praise_and_worship",
        )
        self.assertEqual(resolve_genre_instrument_key("Vinahouse", ""), "vinahouse")
        self.assertEqual(
            resolve_genre_instrument_key("Amapiano", "Soulful House"),
            "amapiano",
        )
        self.assertEqual(
            resolve_genre_instrument_key("Reggaeton", "Latin Pop"),
            "latin",
        )
        self.assertEqual(resolve_genre_instrument_key("Tech House", ""), "deep_house")

    def test_generate_v55_with_l99(self):
        style, meta = generate_live_instrument_prompt(
            "Neo-Soul",
            "Wurlitzer Electric Piano, Fender Jazz Bass",
            version="v5.5",
            power_codes="/L99",
        )
        self.assertIn("elevated by", style)
        self.assertIn("Neve 1073", style)
        self.assertIn("[Instrumental Break:", meta)
        self.assertIn("[Bridge:", meta)

    def test_build_user_block_injects_live_instrument_protocol(self):
        body = GeneratePromptBody(
            suno_version="v5.5",
            primary_genre="Neo-Soul",
            vibe="intimate",
            real_instrumentals="Wurlitzer Electric Piano, Fender Jazz Bass",
            active_modifier_codes="/L99",
            audio_environment_mode="studio_isolated",
        )
        block = _build_user_block(body)
        self.assertIn("REAL INSTRUMENT ACCOMPANIMENT", block)
        self.assertIn("[neo_soul]", block)
        self.assertIn("Vocal backing patch: [close-mic]", block)
        self.assertIn("MANDATORY: Feature the following", block)
        self.assertIn("styleInjection", block)
        self.assertIn("metaTagInjection", block)

    def test_live_instrument_avoid_augment(self):
        out = augment_avoid_clause(
            avoid="harsh clipping",
            real_instrumentals="Live Drum Kit & Congas",
        )
        self.assertIn("dead-room isolation", out)
        self.assertNotIn("crowd noise", out)
        self.assertIn("harsh clipping", out)

    def test_pop_live_drum_uses_prompt_text(self):
        style, _meta = generate_live_instrument_prompt(
            "Pop",
            "Live Drum Kit & Congas",
            version="v5.5",
        )
        self.assertIn("Acoustic studio drum kit", style)
        self.assertNotIn("stadium snare", style.lower())

    def test_live_environment_patches_vocal_doubles(self):
        rows = [
            {
                "id": "vocal-doubles-soul",
                "name": "Neo-Soul Vocal Beds",
                "category": "vocals_choir",
                "defaultArticulation": "DYNAMIC_ARTICULATION",
                "mixRole": "DYNAMIC_MIX_ROLE",
            }
        ]
        live = process_dynamic_vocal_and_instrument_payload(rows, "live")
        self.assertIn("stadium depth", live[0]["mixRole"])
        studio = process_dynamic_vocal_and_instrument_payload(rows, "close-mic")
        self.assertIn("close-mic isolation", studio[0]["mixRole"])


class TestHumanRealism(unittest.TestCase):
    def test_clamp_and_band_labels(self):
        self.assertEqual(clamp_level(-5), 0)
        self.assertEqual(clamp_level(150), 100)
        self.assertEqual(band_label(10), "Highly poetic and stylized")
        self.assertEqual(band_label(85), "Raw human realism")

    def test_user_block_includes_level(self):
        block = human_realism_user_block(75)
        self.assertIn("Human Realism Level: 75/100", block)
        self.assertIn("Prioritize authenticity", block)
        self.assertIn("PHONETIC INTEGRITY", block)

    def test_phonetic_integrity_pidgin_vs_standard(self):
        std = build_phonetic_integrity_rule(None)
        pidgin = build_phonetic_integrity_rule("nigerian_pidgin")
        self.assertIn("PHONETIC INTEGRITY", std)
        self.assertIn("breathing", std)
        self.assertIn("Nigerian Pidgin", pidgin)
        self.assertIn("wahala", pidgin)

    def test_elite_directive_stage1_audit_sections(self):
        self.assertIn("§0.3A", ELITE_HUMAN_LYRICIST_DIRECTIVE)
        self.assertIn("Genre Overlap Rule", ELITE_HUMAN_LYRICIST_DIRECTIVE)
        self.assertIn("FIELD:simple", ELITE_HUMAN_LYRICIST_DIRECTIVE)
        self.assertIn("§0.8 VOCAL SPEC, TONE & ACCENT", ELITE_HUMAN_LYRICIST_DIRECTIVE)
        self.assertNotIn("k_genre_cliche_blacklist.dart", ELITE_HUMAN_LYRICIST_DIRECTIVE)

    def test_human_realism_passes_dialect_to_phonetic_rule(self):
        block = human_realism_user_block(75, dialect_style_id="nigerian_pidgin")
        self.assertIn("DO NOT normalize", block)
        self.assertIn("dey", block)

    def test_build_user_block_injects_human_realism(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Pop",
            vibe="summer",
            human_realism=90,
        )
        block = _build_user_block(body)
        self.assertIn("ELITE HUMAN LYRICIST", block)
        self.assertIn("HUMAN REALISM", block)
        self.assertIn("Human Realism Level: 90/100", block)
        self.assertIn("Maximum human realism", block)
        self.assertIn("**Primary objective:** Write lyrics that sound like they came from a real human artist", block)

    def test_block2_opt_out_skips_human_realism(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Pop",
            vibe="style only",
            human_realism=90,
        )
        block = _build_user_block(body)
        self.assertNotIn("HUMAN REALISM", block)
        self.assertNotIn("HUMAN AUTHENTICITY ENGINE", block)


class TestDialectStyle(unittest.TestCase):
    def test_nigerian_pidgin_user_block(self):
        block = dialect_style_user_block(NIGERIAN_PIDGIN_ID)
        self.assertIn("NON-NEGOTIABLE", block)
        self.assertIn("Nigerian Pidgin", block)
        self.assertIn("wahala", block)
        self.assertTrue(is_nigerian_pidgin(NIGERIAN_PIDGIN_ID))

    def test_standard_english_empty_block(self):
        self.assertEqual(dialect_style_user_block("standard_english"), "")

    def test_ibibio_variant_user_block(self):
        block = dialect_style_user_block(
            NIGERIAN_PIDGIN_ID, dialect_variant_id="ibibio"
        )
        self.assertIn("Ibibio", block)
        self.assertIn("Regional flavor", block)


class TestVocalAccent(unittest.TestCase):
    def test_user_block_mandates_accent_in_block1_and_block2(self):
        block = vocal_accent_user_block(
            "British (England)",
            vocal_spec="Female Lead",
            language="English",
        )
        self.assertIn("NON-NEGOTIABLE", block)
        self.assertIn("user_selected_accent: british", block)
        self.assertIn("Layer 1 descriptor set", block)
        self.assertIn("dry room close-mic", block)
        self.assertIn("STAGING AND ACCENT RULES", block)
        self.assertIn("English only", block)
        self.assertIn("Female Lead", block)

    def test_accent_vs_dialect_constraint_when_accent_only(self):
        line = accent_vs_dialect_constraint_line(
            vocal_accent="British (England)",
            dialect_style_id="standard_english",
        )
        self.assertIn("ACCENT VS. DIALECT", line)
        self.assertIn("wahala", line)

    def test_accent_constraint_skipped_for_pidgin_dialect(self):
        self.assertEqual(
            accent_vs_dialect_constraint_line(
                vocal_accent="West African (Nigeria)",
                dialect_style_id=NIGERIAN_PIDGIN_ID,
            ),
            "",
        )

    def test_regional_tag_dedup_when_accent_set(self):
        line = regional_tag_deduplication_line(
            vocal_accent="British (England)",
        )
        self.assertIn("ZERO REGIONAL TAG DUPLICATION", line)

    def test_empty_accent_returns_empty_block(self):
        self.assertEqual(vocal_accent_user_block(""), "")

    def test_post_process_context_includes_accent(self):
        ctx = genre_context_block(
            primary_genre="Pop",
            sub_genre_fusion="",
            vibe="warm",
            lyric_theme_notes="",
            language="English",
            vocal_accent="West African (Nigeria)",
        )
        self.assertIn("G:Pop|", ctx)
        self.assertIn("ACCENT:nigerian", ctx)
        self.assertIn("RULE:accent-only", ctx)
        self.assertIn("RULE:regional-tag-once", ctx)

    def test_ibibio_layer1_omits_calabar_tokens(self):
        desc = layer1_descriptor_for("nigerian_ibibio")
        self.assertIn("Cross-river coastal cadence", desc)
        self.assertNotIn("Calabar", desc)

    def test_accent_smoke_gospel_ibibio(self):
        block = vocal_accent_user_block("nigerian_ibibio", vocal_spec="Male Lead")
        self.assertIn("Cross-river coastal cadence", block)
        self.assertNotIn("British Accent", block)

    def test_accent_smoke_afrobeats_lagos(self):
        block = vocal_accent_user_block("nigerian")
        self.assertIn("Afrobeats vocal pocket", block)

    def test_accent_smoke_reggaeton_latin(self):
        block = vocal_accent_user_block("latin_american")
        self.assertIn("Spanish consonant treatment", block)

    def test_accent_smoke_jazz_american(self):
        block = vocal_accent_user_block("american")
        self.assertIn("polished vocal", block)

    def test_accent_smoke_metal_british(self):
        block = vocal_accent_user_block("british")
        self.assertIn("dry room close-mic", block)


class TestVocalSpecTone(unittest.TestCase):
    def test_user_block_line_labels_spec_and_tone(self):
        line = vocal_spec_tone_user_block_line(
            vocal_spec="Male Lead",
            vocal_tone="Breathy",
        )
        self.assertEqual(line, "Vocal: spec=Male Lead · tone=Breathy")

    def test_user_block_directive_routes_instrumental(self):
        block = vocal_spec_tone_user_block(
            vocal_spec="Instrumental Only",
            vocal_tone=None,
        )
        self.assertIn("instrumental-only", block)
        self.assertIn("user_vocal_spec", block)

    def test_predicate_helpers(self):
        from app.vocal_spec_tone import (
            is_choir,
            is_custom_spec,
            is_rap_forward,
            normalize_tone,
            routes_to_block2,
            suppresses_lead_lyrics,
        )

        self.assertTrue(is_choir("Gospel Choir"))
        self.assertTrue(is_rap_forward("rap vocal space"))
        self.assertTrue(routes_to_block2("Instrumental Only"))
        self.assertTrue(suppresses_lead_lyrics("Instrumental Only"))
        self.assertTrue(is_custom_spec("Custom Breath Stack"))
        self.assertEqual(normalize_tone("  warm   breathy  "), "warm breathy")

    def test_build_user_block_injects_vocal_spec_tone_directive(self):
        body = GeneratePromptBody(
            suno_version="v5.5",
            primary_genre="Amapiano",
            vibe="club",
            vocal_spec="Vocal Chants Only",
            vocal_tone="hypnotic spoken chant hooks",
        )
        block = _build_user_block(body)
        self.assertIn("Vocal: spec=Vocal Chants Only", block)
        self.assertIn("VOCAL SPEC & TONE", block)
        self.assertIn("chant-first", block)


class TestPayloadOptimization(unittest.TestCase):
    def test_vocal_option_from_audio_environment(self):
        self.assertEqual(
            vocal_option_from_audio_environment("live_performance"),
            "live",
        )
        self.assertEqual(
            vocal_option_from_audio_environment("studio_isolated"),
            "close-mic",
        )

    def test_run_global_prompt_hygiene_collapses_brackets(self):
        raw = "[Intro] [Verse 1]\n\n\nTail"
        out = run_global_prompt_hygiene(raw)
        self.assertIn("[Intro, Verse 1]", out)
        self.assertNotIn("\n\n\n", out)

    def test_truncate_continuation_prior_keeps_ends(self):
        prior = "A" * 2000 + "\n" + "B" * 8000
        out = truncate_continuation_prior(prior, max_chars=3000)
        self.assertIn("truncated for token budget", out)
        self.assertTrue(out.startswith("A"))
        self.assertTrue(out.rstrip().endswith("B"))

    def test_compact_payload_text_collapses_blank_lines(self):
        raw = "line one  \n\n\n\nline two  \n"
        out = compact_payload_text(raw)
        self.assertEqual(out, "line one\n\nline two")

    def test_compact_genre_context_with_pidgin_and_live_env(self):
        ctx = genre_context_block(
            primary_genre="Praise and Worship",
            sub_genre_fusion="",
            vibe="joyful",
            lyric_theme_notes="faith",
            language="English",
            dialect_style_id="nigerian_pidgin",
            audio_environment_mode="live_performance",
        )
        self.assertIn("DIALECT:pidgin", ctx)
        self.assertIn("ENV:live-arena", ctx)
        self.assertNotIn("CRITICAL DIRECTIVE", ctx)

    def test_enforce_laozhang_syntax_hygiene_collapses_brackets(self):
        raw = "[Intro]\n[Dead-room isolation] [Close-mic vocal]\nLine."
        out = enforce_laozhang_syntax_hygiene(raw)
        self.assertIn("[Dead-room isolation, Close-mic vocal]", out)
        self.assertNotIn("] [", out)

    def test_enforce_laozhang_syntax_hygiene_evicts_crowd_triggers(self):
        raw = "[Chorus]\n[Studio Harmonic Backing, SATB Choir, Live Drum Kit]"
        out = enforce_laozhang_syntax_hygiene(raw)
        self.assertIn("Isolated multi-tracked vocal doubles", out)
        self.assertNotIn("Harmonic Backing", out)
        self.assertNotIn("SATB", out)
        self.assertIn("Studio drum backbeat", out)

    def test_append_laozhang_system_prompt_boundary(self):
        out = append_laozhang_system_prompt_boundary("BASE")
        self.assertTrue(out.startswith("BASE"))
        self.assertIn("[LAOZHANG ARCHITECTURE BOUNDARY]", out)


class TestRemixEngine(unittest.TestCase):
    def test_remix_engine_active(self):
        self.assertTrue(
            remix_engine_active(original_song_title="Mercy", original_artist="Band")
        )
        self.assertFalse(remix_engine_active(original_song_title="", original_artist="X"))

    def test_remix_user_block_supplement(self):
        block = remix_style_flip_user_block_supplement(
            original_song_title="Mercy",
            original_artist="Worship",
            target_genre="Techno",
            generation_type="instrumental",
        )
        self.assertIn("LAYER 4.8", block)
        self.assertIn("Harmonic skeleton", block)
        self.assertIn("INSTRUMENTAL MODE", block)
        self.assertIn("topline melody", block)
        self.assertIn("DESCRIPTOR-ONLY", block)
        self.assertIn("Never print song titles", block)
        self.assertNotIn("Mercy", block)
        self.assertNotIn("Worship", block)

    def test_instrumental_remix_output_strips_lyrics(self):
        raw = (
            "BLOCK 2 — LYRICS\n"
            "[Verse 1]\n"
            "[Close-mic delivery]\n"
            "Lyric line here.\n"
            "[Chorus]\n"
            "[Wide stacks]\n"
            "Hook line."
        )
        out = apply_instrumental_remix_output(raw)
        self.assertNotIn("Lyric line", out)
        self.assertNotIn("Hook line", out)
        self.assertIn("Close-mic delivery", out)


class TestHumanAuthenticity(unittest.TestCase):
    def test_festival_lane_detection(self):
        self.assertTrue(is_festival_vocal_lane("Uplifting Trance", ""))
        self.assertTrue(is_festival_vocal_lane("Melodic Techno", ""))
        self.assertFalse(is_festival_vocal_lane("Bluegrass", ""))

    def test_word_boundaries_prevent_false_positives(self):
        self.assertFalse(is_electronic_lane("warehouse", ""))
        self.assertTrue(is_electronic_lane("Future Bass", ""))
        self.assertTrue(is_situation_first_story_lane("singer-songwriter", ""))
        self.assertTrue(is_festival_vocal_lane("k-pop", ""))

    def test_rnb_resolves_as_story_lane(self):
        self.assertTrue(is_situation_first_story_lane("r&b", ""))
        self.assertTrue(is_situation_first_story_lane("rnb", ""))

    def test_gospel_is_story_lane_but_not_partial(self):
        self.assertTrue(is_situation_first_story_lane("gospel", ""))
        self.assertFalse(is_partial_situation_story_lane("gospel", ""))

    def test_situation_first_story_lane_scope(self):
        self.assertTrue(is_situation_first_story_lane("Modern Country", ""))
        self.assertTrue(is_situation_first_story_lane("Boom Bap", ""))
        self.assertTrue(is_situation_first_story_lane("Gospel", ""))
        self.assertFalse(is_situation_first_story_lane("Hard Techno", ""))
        self.assertTrue(is_partial_situation_story_lane("Progressive House", ""))
        self.assertTrue(is_mantra_dominant_lane("Hard Techno", ""))
        self.assertTrue(is_mantra_dominant_lane("Peak-Time Techno", ""))

    def test_user_block_situation_first_for_country(self):
        block = human_authenticity_user_block(primary_genre="Modern Country")
        self.assertIn("§17 SITUATION-FIRST STORY", block)

    def test_user_block_waives_situation_first_for_hard_techno(self):
        block = human_authenticity_user_block(primary_genre="Hard Techno")
        self.assertIn("§17 WAIVED", block)
        self.assertNotIn("SITUATION-FIRST STORY (active)", block)

    def test_user_block_includes_specificity_and_zero_names(self):
        block = human_authenticity_user_block(
            primary_genre="Melodic Techno",
            dj_outro=True,
        )
        self.assertIn("HUMAN AUTHENTICITY ENGINE", block)
        self.assertIn("concrete images", block)
        self.assertIn("NEVER output artist", block)
        self.assertIn("Festival/melodic electronic", block)
        self.assertIn("Electronic: breakdown intimacy", block)
        self.assertIn("DJ-friendly", block)

    def test_build_user_block_injects_authenticity(self):
        body = GeneratePromptBody(
            suno_version="v5.0",
            primary_genre="Trance",
            vibe="euphoric",
        )
        block = _build_user_block(body)
        self.assertIn("HUMAN AUTHENTICITY ENGINE", block)


class TestThemeConsistency(unittest.TestCase):
    def test_split_and_merge_block2(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            "producer prose here\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[16-bar kick]\n(line)\n[End]\n\n"
            "→ optional follow-up"
        )
        parts = split_block2_parts(raw)
        self.assertIsNotNone(parts)
        prefix, body, suffix = parts
        self.assertIn("BLOCK 2", prefix)
        self.assertIn("[Intro]", body)
        self.assertIn("[End]", body)
        self.assertIn("follow-up", suffix)
        merged = merge_block2_parts(prefix, body, suffix)
        self.assertIn("producer prose", merged)
        self.assertIn("[End]", merged)

    def test_theme_consistency_enabled_by_default(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("THEME_CONSISTENCY_PASS", None)
            self.assertTrue(theme_consistency_enabled())

    def test_apply_theme_consistency_pass_mocked(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            + " ".join(["word"] * 140)
            + "\n\nBLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[16-bar kick]\nDrift line lonely tears\n[Chorus]\nWe rise\n[End]"
        )
        revised_body = "[Intro]\n[16-bar kick]\nWe rise up clean\n[Chorus]\nWe rise\n[End]"
        client = MagicMock()
        resp = MagicMock()
        resp.choices = [MagicMock(message=MagicMock(content=revised_body))]
        client.chat.completions.create.return_value = resp
        out, label = apply_theme_consistency_pass(
            client,
            text=raw,
            primary_genre="Hip Hop",
            vibe="confidence",
        )
        self.assertIn("theme-pass", label)
        self.assertIn("We rise up clean", out)
        self.assertIn("BLOCK 1", out)
        self.assertNotIn("Drift line", out)


class TestSunoCompressionPass(unittest.TestCase):
    def test_compression_prompt_includes_stage5_syntax_law(self):
        prompt = load_tool_prompt("suno_compression_pass.txt", fallback="")
        self.assertIn("STAGE 5 SYNTAX COMPRESSION LAW", prompt)
        self.assertIn("NO MULTI-BRACKET STACKING", prompt)
        self.assertIn("NO VERB PHRASES", prompt)
        self.assertIn("APOSTROPHE SANITIZATION", prompt)
        self.assertIn("ZERO REGIONAL TAG DUPLICATION", prompt)
        self.assertIn("GOLDEN REFERENCE", prompt)

    def test_humanization_prompt_includes_accent_vs_dialect(self):
        prompt = load_tool_prompt("humanization_pass.txt", fallback="")
        self.assertIn("ACCENT VS. DIALECT CONSTRAINT", prompt)
        self.assertIn("clear, standard English", prompt)
        self.assertIn("wahala", prompt)
        self.assertIn("purely phonetic", prompt)
        self.assertIn("LaoZhang English song context", prompt)
        self.assertIn("GPT-6 Astra", prompt)

    def test_laozhang_humanization_model_routing(self):
        self.assertTrue(
            prefer_laozhang_multilingual_humanization(
                language="English", dialect_style_id="nigerian_pidgin"
            )
        )
        self.assertTrue(
            prefer_laozhang_multilingual_humanization(language="Yoruba")
        )
        self.assertFalse(
            prefer_laozhang_multilingual_humanization(language="English")
        )
        from app.humanization_pass import humanization_pass_enabled

        self.assertTrue(humanization_pass_enabled(provider="laozhang"))
        self.assertTrue(humanization_pass_enabled(provider="openrouter"))

    def test_compression_enabled_on_laozhang(self):
        self.assertTrue(suno_compression_pass_enabled(provider="laozhang"))
        self.assertEqual(
            resolve_compression_model(provider="laozhang"),
            LAOZHANG_COMPRESSION_MODEL,
        )

    def test_apply_compression_pass_mocked(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            + " ".join(["word"] * 140)
            + "\n\nBLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[Tag A] [Tag B]\nFeature bright strummed rhythm\n[End]"
        )
        compressed = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            + " ".join(["word"] * 130)
            + "\n\nBLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[Tag A, Tag B, Bright Strummed Acoustic Rhythm]\n[End]"
        )
        client = MagicMock()
        resp = MagicMock()
        resp.choices = [MagicMock(message=MagicMock(content=compressed))]
        client.chat.completions.create.return_value = resp
        with patch.dict(os.environ, {"OPENROUTER_ONLY": "true"}, clear=False):
            out, label = apply_suno_compression_pass(
                client,
                text=raw,
                primary_genre="Gospel",
                provider="openrouter",
            )
        self.assertIn("compress:", label)
        self.assertIn("[Tag A, Tag B", out)

    def test_apply_compression_pass_laozhang_mocked(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            + " ".join(["word"] * 140)
            + "\n\nBLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[Tag A] [Tag B]\nLine one\n[End]"
        )
        compressed = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n\n"
            + " ".join(["word"] * 135)
            + "\n\nBLOCK 2 — PASTE INTO SUNO: LYRICS\n\n"
            "[Intro]\n[Tag A, Tag B]\nLine one\n[End]"
        )
        client = MagicMock()
        resp = MagicMock()
        resp.choices = [MagicMock(message=MagicMock(content=compressed))]
        client.chat.completions.create.return_value = resp
        out, label = apply_suno_compression_pass(
            client,
            text=raw,
            primary_genre="House",
            provider="laozhang",
        )
        self.assertIn("compress:", label)
        self.assertIn("[Tag A, Tag B", out)


class TestSunoInternalOutputStrip(unittest.TestCase):
    def test_strip_psychology_audit_before_block1(self):
        raw = (
            "<psychology_audit>\n"
            "  <target_audience>Young Adult</target_audience>\n"
            "</psychology_audit>\n\n"
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n"
            "Neo-soul at 92 BPM.\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n"
            "[Verse 1]\nLine\n[End]"
        )
        out = strip_internal_cognition_blocks(raw)
        self.assertNotIn("psychology_audit", out.lower())
        self.assertIn("BLOCK 1", out)
        self.assertIn("[End]", out)

    def test_strip_psychology_audit_between_blocks(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\nStyle.\n\n"
            "<psychology_audit><cliche_sweep>No</cliche_sweep></psychology_audit>\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n[Chorus]\nHook\n[End]"
        )
        out = strip_internal_cognition_blocks(raw)
        self.assertEqual(
            out,
            "BLOCK 1 — PASTE INTO SUNO: STYLE\nStyle.\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n[Chorus]\nHook\n[End]",
        )

    def test_unchanged_without_audit(self):
        raw = "BLOCK 1 — PASTE INTO SUNO: STYLE\nOnly style."
        self.assertEqual(strip_internal_cognition_blocks(raw), raw)

    def test_strip_master_blueprint(self):
        raw = (
            "<master_blueprint>\n"
            "  <song_purpose>Festival Anthem</song_purpose>\n"
            "</master_blueprint>\n\n"
            "BLOCK 1 — PASTE INTO SUNO: STYLE\nStyle.\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n[End]"
        )
        out = strip_internal_cognition_blocks(raw)
        self.assertNotIn("master_blueprint", out.lower())
        self.assertIn("BLOCK 1", out)

    def test_strip_all_internal_blocks(self):
        raw = (
            "<master_blueprint><qa_pass>Yes</qa_pass></master_blueprint>\n"
            "<psychology_audit><cliche_sweep>No</cliche_sweep></psychology_audit>\n"
            "<lyric_audit><show_dont_tell_check>Yes</show_dont_tell_check></lyric_audit>\n"
            "BLOCK 1 — PASTE INTO SUNO: STYLE\nStyle."
        )
        out = strip_internal_cognition_blocks(raw)
        self.assertNotIn("master_blueprint", out.lower())
        self.assertNotIn("psychology_audit", out.lower())
        self.assertNotIn("lyric_audit", out.lower())


class TestSunoSystemPromptV2(unittest.TestCase):
    def test_block2_arrangement_staging_format(self):
        self.assertTrue(
            SYSTEM_PROMPT_V2.startswith(
                "Before emitting any staging bracket, scan it against SECTION D"
            )
        )
        self.assertIn("SECTION D — AI-GENERIC WORD BLACKLIST", SYSTEM_PROMPT_V2)
        self.assertIn(
            "STAGING COHERENCE + ACCENT ROUTING + GENRE HYGIENE",
            SYSTEM_PROMPT_V2,
        )
        self.assertIn("ARRANGEMENT STAGING FORMAT & LEXICON", SYSTEM_PROMPT_V2)
        self.assertIn("[{staging}]", SYSTEM_PROMPT_V2)
        self.assertIn("GENRE-SPECIFIC LYRICS PROMPTS", SYSTEM_PROMPT_V2)
        self.assertIn("ELECTRONIC LOOP GRIDS", SYSTEM_PROMPT_V2)
        self.assertIn("GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX", SYSTEM_PROMPT_V2)
        self.assertIn("Dead-room isolation, Pristine studio environment", SYSTEM_PROMPT_V2)
        self.assertIn("Thunderous stadium crowd cheering", SYSTEM_PROMPT_V2)
        # Two-pass blueprint (Suno-only; Udio temporarily disabled)
        self.assertIn(
            "CREATION PIPELINE — TWO-PASS EXECUTION ORDER (SUNO ONLY)",
            SYSTEM_PROMPT_V2,
        )
        self.assertIn("Conflict resolution", SYSTEM_PROMPT_V2)
        self.assertIn("SUNO METATAG SYNTAX — ALLOWLIST", SYSTEM_PROMPT_V2)
        self.assertIn("Udio temporarily disabled", SYSTEM_PROMPT_V2)
        self.assertNotIn("Udio (if specified)", SYSTEM_PROMPT_V2)


class TestSunoLyricPhoneticSanitize(unittest.TestCase):
    def test_strips_trailing_apostrophes(self):
        raw = "turnin' round the floor, glidin' slow, ridin' high, huggin' close"
        out = sanitize_suno_lyric_phonetics(raw)
        self.assertNotIn("turnin'", out)
        self.assertIn("turnin", out)
        self.assertIn("glidin", out)
        self.assertIn("ridin", out)
        self.assertIn("huggin", out)

    def test_expands_round_contraction(self):
        out = sanitize_suno_lyric_phonetics("'round the block we go")
        self.assertIn("around the block", out)
        self.assertNotIn("'round", out)

    def test_curly_apostrophe_stripped(self):
        out = sanitize_suno_lyric_phonetics("countin\u2019 slow")
        self.assertEqual(out, "countin slow")

    def test_instrumental_break_strips_feature_verb(self):
        raw = (
            "[Instrumental Break: Feature bright strummed rhythm, "
            "tight pocket Acoustic Guitar, wide stereo, glossy pop sheen]"
        )
        out = sanitize_instrumental_staging_tags(raw)
        self.assertNotIn("Feature ", out)
        self.assertIn("bright strummed rhythm", out)
        self.assertIn("Acoustic Guitar", out)

    def test_gospel_staging_replaces_sidechain(self):
        raw = "[Chorus: wide stacks, sidechain pump, hook lift]"
        out = sanitize_gospel_staging_tags(
            raw, primary_genre="Praise and Worship", sub_genre_fusion=""
        )
        self.assertNotIn("sidechain", out.lower())
        self.assertIn("Analog VCA glue", out)

    def test_gospel_staging_inert_for_trap(self):
        raw = "[Chorus: sidechain pump, 808 bloom]"
        out = sanitize_gospel_staging_tags(raw, primary_genre="Trap", sub_genre_fusion="")
        self.assertIn("sidechain pump", out)

    def test_reconciliation_strips_drum_loop_on_folk(self):
        raw = "[Intro: Acoustic Guitar, drum loop, warm room]"
        out = apply_critical_reconciliation(raw, primary_genre="Folk", sub_genre_fusion="")
        self.assertNotIn("drum loop", out.lower())
        self.assertIn("Acoustic Guitar", out)

    def test_hybrid_techno_fusion_keeps_sidechain_globally(self):
        raw = "[Main Climax: sidechain pump, rolling bass]"
        out = apply_critical_reconciliation(
            raw, primary_genre="Melodic Techno", sub_genre_fusion="Indie Acoustic"
        )
        self.assertIn("sidechain pump", out)

    def test_studio_isolation_skipped_for_live_performance_mode(self):
        raw = (
            "[Intro]\n"
            "[Live band count-in, Full SATB Choir Stack, Sanctuary reverb]\n"
            "Opening line."
        )
        out = sanitize_studio_isolation_tags(
            raw,
            primary_genre="Praise and Worship",
            sub_genre_fusion="",
            audio_environment_mode=LIVE_PERFORMANCE_ID,
        )
        self.assertIn("SATB", out)
        self.assertIn("Sanctuary", out)

    def test_studio_isolation_strips_crowd_triggers_from_intro(self):
        raw = (
            "[Intro]\n"
            "[Live band count-in, Full SATB Choir Stack, Sanctuary reverb]\n"
            "Opening line.\n"
            "[Chorus]\n"
            "[Full SATB Choir Stack, hook lift]"
        )
        out = sanitize_studio_isolation_tags(
            raw, primary_genre="Praise and Worship", sub_genre_fusion=""
        )
        intro_block = out.split("[Chorus]")[0]
        self.assertNotIn("SATB", intro_block)
        self.assertNotIn("Sanctuary", intro_block)
        self.assertNotIn("Live band", intro_block)
        self.assertIn("Isolated multi-tracked vocal doubles", intro_block)
        self.assertNotIn("Harmonic Backing", intro_block)

    def test_studio_isolation_swaps_tape_hiss_in_intro(self):
        raw = (
            "[Intro]\n"
            "[Dead-room isolation, Subtle Tape Hiss, close-mic vocal]\n"
            "Opening line."
        )
        out = sanitize_studio_isolation_tags(raw, primary_genre="Indie Acoustic")
        self.assertNotIn("tape hiss", out.lower())
        self.assertIn("focused studio room", out.lower())

    def test_studio_isolation_swaps_harmonic_backing_in_chorus(self):
        raw = (
            "[Chorus]\n"
            "[Studio Harmonic Backing, Hammond swell]\n"
            "Hook line."
        )
        out = sanitize_studio_isolation_tags(raw, primary_genre="Praise and Worship")
        self.assertIn("Isolated multi-tracked vocal doubles", out)
        self.assertNotIn("Harmonic Backing", out)

    def test_studio_isolation_strips_crowd_from_chorus(self):
        raw = (
            "[Chorus]\n"
            "[Thunderous stadium crowd cheering, crowd singing along loudly]\n"
            "Hook line."
        )
        out = sanitize_studio_isolation_tags(raw, primary_genre="Afrobeats")
        self.assertNotIn("crowd", out.lower())
        self.assertNotIn("stadium", out.lower())
        self.assertIn("Multi-tracked vocal overlays", out)

    def test_studio_isolation_scrubs_block1_crowd_tokens(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n"
            "Afrobeats, zero audience noise, no crowd sounds.\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n"
            "[Intro]\n"
            "[Dead-room isolation]\n"
            "Line one."
        )
        out = sanitize_studio_isolation_tags(raw, primary_genre="Afrobeats")
        block1 = out.split("BLOCK 2")[0]
        self.assertNotIn("audience", block1.lower())
        self.assertNotIn("crowd", block1.lower())

    def test_audio_engine_normalizer_strips_dj_intro_in_block_2(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n"
            "Progressive house, intimate male vocal.\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n"
            "[16-bar DJ intro, filtered TR-909 kick, low-pass sweep opening]\n"
            "[Build-up]\n"
            "[Male Vocal, Intimate, American (General) Delivery]\n"
            "Headlights paint the ceiling white\n"
            "[Drop]\n"
            "(Tonight...)\n"
            "(Tonight...)\n"
            "[End]"
        )
        out = sanitize_suno_post_output(raw)
        self.assertIn("[Intro]", out)
        self.assertIn("[Atmospheric Synth Intro]", out)
        self.assertNotIn("TR-909", out)
        self.assertIn("[Intimate Male Vocal]", out)
        self.assertNotIn("American (General) Delivery", out)
        self.assertIn("[Pre-Drop]", out)
        self.assertIn("Tonight!", out)
        self.assertIn("[Instrumental Drop]", out)
        self.assertNotIn("(Tonight...)", out)

    def test_normalize_lyrics_for_audio_engine_final_drop_trap(self):
        raw = (
            "[Final Drop]\n"
            "(We're infinite...)\n"
            "(We're infinite...)"
        )
        out = normalize_lyrics_for_audio_engine(raw)
        self.assertIn("[Maximum Energy Instrumental Drop]", out)
        self.assertIn("[Pre-Drop]", out)

    def test_apply_audio_engine_normalization_block_2_only(self):
        raw = (
            "BLOCK 1 — PASTE INTO SUNO: STYLE\n"
            "TR-909 kick in style prose stays\n\n"
            "BLOCK 2 — PASTE INTO SUNO: LYRICS\n"
            "[Drop]\n"
            "(Tonight...)\n"
            "[End]"
        )
        out = apply_audio_engine_normalization_to_suno_output(raw)
        self.assertIn("TR-909 kick in style prose stays", out)
        self.assertIn("[Instrumental Drop]", out)


class TestAudioEnvironment(unittest.TestCase):
    def test_live_performance_mode_detected(self):
        self.assertTrue(is_live_performance_mode(LIVE_PERFORMANCE_ID))
        self.assertFalse(is_live_performance_mode("studio_isolated"))

    def test_user_block_injects_directive(self):
        block = audio_environment_user_block(LIVE_PERFORMANCE_ID)
        self.assertIn("AUDIO ENVIRONMENT", block)
        self.assertIn("Thunderous stadium crowd cheering", block)

    def test_generate_body_includes_audio_environment(self):
        body = GeneratePromptBody(
            primary_genre="Praise and Worship",
            audio_environment_mode=LIVE_PERFORMANCE_ID,
        )
        block = _build_user_block(body)
        self.assertIn("Live Arena", block)
        self.assertIn("stadium concert", block.lower())


class TestHumanAuthenticityGospel(unittest.TestCase):
    def test_is_gospel_lane(self):
        self.assertTrue(is_gospel_lane("Praise and Worship", ""))
        self.assertFalse(is_gospel_lane("Trap", ""))

    def test_gospel_block_bans_dj_mix_out(self):
        block = human_authenticity_user_block(
            primary_genre="Gospel",
            sub_genre_fusion="",
            dj_outro=True,
        )
        self.assertIn("Traditional Gospel Architecture", block)
        self.assertIn("Studio-Isolation Directive", block)
        self.assertIn("Isolated multi-tracked vocal doubles", block)
        self.assertIn("trailing organ decay", block)
        self.assertNotIn("DJ-friendly", block)

    def test_gospel_live_arena_overrides_studio_isolation(self):
        block = human_authenticity_user_block(
            primary_genre="Gospel",
            sub_genre_fusion="",
            audio_environment_mode=LIVE_PERFORMANCE_ID,
        )
        self.assertIn("Live Performance Arena Mode", block)
        self.assertNotIn("Studio-Isolation Directive", block)

    def test_amapiano_genre_lyrics_includes_guardrail(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Amapiano",
            sub_genre_fusion="Private School",
            vibe="log drum lounge",
        )
        self.assertIn("GLOBAL LYRICIST GUARDRAIL", block)
        self.assertIn("LOG DRUM IS KING", block)

    def test_amapiano_thematic_variator_block(self):
        from app.advanced_thematic_variator import advanced_thematic_variator_block

        block = advanced_thematic_variator_block(
            primary="Amapiano",
            fusion="Private School",
            vibe="log drum lounge",
        )
        self.assertIn("AMAPIANO", block)
        self.assertIn("LOG DRUM IS KING", block)
        self.assertIn("vows", block)

    def test_secret_inside_chest_injects_template(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Amapiano",
            vibe="Secret Inside Your Chest",
            lyric_theme_notes="affair at midnight",
        )
        self.assertIn("Secret Inside Your Chest", block)
        self.assertIn("[Drop: Destructive 32nd-Note Log Drum]", block)

    def test_dont_call_me_lonely_injects_master(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Amapiano",
            vibe="Don't call me lonely",
            lyric_theme_notes="call me outside",
        )
        self.assertIn("Don't Call Me Lonely", block)
        self.assertIn("Rain on the pavement", block)
        self.assertIn("[Verse 2]", block)
        self.assertIn("COMMERCIAL ARRANGEMENT ORDER", block)
        self.assertIn("she was nineteen", block.lower())

    def test_amapiano_theme_fit_rule_not_locked_chorus(self):
        from app.genre_lyrics_directives import (
            amapiano_lyrics_user_block,
            genre_lyrics_user_block,
        )

        amapiano = amapiano_lyrics_user_block()
        self.assertIn("THEME FIT", amapiano)
        self.assertIn("off-theme", amapiano.lower())
        self.assertIn("log drum understand", amapiano.lower())
        self.assertNotIn("LOCKED CHORUS", amapiano.upper())
        self.assertNotIn("twoPinkLines_master", amapiano)

        block = genre_lyrics_user_block(
            primary_genre="Amapiano",
            vibe="pregnancy reveal",
            lyric_theme_notes="office after dark reputation",
        )
        self.assertNotIn("LOCKED CHORUS", block.upper())
        self.assertNotIn("two pink lines on a plastic stick", block.lower())

    def test_amapiano_bans_age_cliche_in_directive(self):
        from app.genre_lyrics_directives import amapiano_lyrics_user_block

        block = amapiano_lyrics_user_block()
        self.assertIn("she was nineteen", block.lower())
        self.assertIn("Verse 2", block)

    def test_dynamic_structural_engine_amapiano_breakdown(self):
        from app.dynamic_structural_engine import dynamic_structural_user_block

        block = dynamic_structural_user_block(
            "Amapiano",
            fusion="Private School",
            suno_version="v5.5",
        )
        self.assertIn("DYNAMIC STRUCTURAL ENGINE", block)
        self.assertIn("Breakdown", block)
        self.assertIn("v5.5 PRO syntax", block)
        self.assertIn("v5.5_max_arc=true", block)
        self.assertIn("[End]", block)
        self.assertIn("RENDERED BRACKET LAYOUT", block)
        self.assertIn("amapiano", block)

    def test_dynamic_structural_engine_folk_no_drop(self):
        from app.dynamic_structural_engine import dynamic_structural_user_block

        block = dynamic_structural_user_block("Folk", fusion="Acoustic", suno_version="v5.0")
        self.assertIn("NO [Drop]", block)
        self.assertIn("Instrumental Interlude", block)
        self.assertIn("v5.5_max_arc=false", block)

    def test_dynamic_structural_engine_v45_syntax(self):
        from app.dynamic_structural_engine import dynamic_structural_user_block

        block = dynamic_structural_user_block("Synth Pop", suno_version="v4.5")
        self.assertIn("v4.5 syntax", block)
        self.assertIn("1–2 words", block)

    def test_future_house_thematic_variator_block(self):
        from app.advanced_thematic_variator import advanced_thematic_variator_block

        block = advanced_thematic_variator_block(
            primary="Future House",
            fusion="",
            vibe="chrome lobby",
        )
        self.assertIn("FUTURE HOUSE", block)
        self.assertIn("BLACKLIST", block)
        self.assertIn("neon", block)
        self.assertIn("ARCHETYPE", block)

    def test_hardstyle_genre_lyrics_includes_variator(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Hardstyle",
            sub_genre_fusion="",
            vibe="festival",
        )
        self.assertIn("HARDSTYLE", block)
        self.assertIn("DYNAMIC SHIFT", block)
        self.assertIn("PRE-DROP", block)
        self.assertIn("we own the night", block)

    def test_edm_breakdown_genre_lyrics_includes_guardrails(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Uplifting Trance",
            sub_genre_fusion="",
            vibe="euphoric festival",
        )
        # Master EDM lyric engine owns the lane (legacy breakdown engine is
        # fallback-only) and carries a native trance profile.
        self.assertIn("CROSS-ARCHITECTURE NON-NEGOTIABLES", block)
        self.assertIn("SUB-GENRE: TRANCE / UPLIFTING TRANCE", block)
        self.assertIn("STRICT WRITING RULES FOR ALL EDM", block)
        self.assertIn("Pre-drop trigger", block)
        self.assertNotIn("4 AM", block)

    def test_hardstyle_wins_over_edm_breakdown(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(primary_genre="Hardstyle")
        self.assertIn("HARDSTYLE", block)
        self.assertNotIn("EDM BREAKDOWN VOCAL GUARDRAILS", block)

    def test_hardstyle_euro_dance_bootleg_lyrics_profile(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Hardstyle",
            sub_genre_fusion="Euro-Dance Bootleg",
            vibe="150 BPM festival rave bootleg",
        )
        # Master hardstyle lyric engine owns the lane and carries a native
        # euro-dance bootleg sub-genre profile.
        self.assertIn("EURO-DANCE BOOTLEG HARDSTYLE", block)
        self.assertIn("Euro-dance", block)
        self.assertIn("pitch-shifted vocal chops", block)
        self.assertIn("HARDSTYLE", block.upper())

    def test_big_room_fusion_genre_lyrics_includes_guardrails(self):
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Progressive House",
            sub_genre_fusion="Big Room House",
            vibe="festival anthem supersaw",
        )
        self.assertIn("CROSS-ARCHITECTURE NON-NEGOTIABLES", block)
        self.assertIn("BIG ROOM FUSION", block)
        self.assertIn("Pre-Drop Trigger", block)
        self.assertIn("THICK HUMANIZED VOCAL PRESENCE", block)
        self.assertNotIn("EDM BREAKDOWN VOCAL GUARDRAILS", block)

    def test_big_room_fusion_elite_engine_user_block(self):
        from app.big_room_fusion_progressive_engine import (
            compose_arrangement_architecture,
            compose_elite_module_block,
            user_block_append_for,
        )

        block = user_block_append_for(
            primary_genre="Progressive House",
            sub_genre_fusion="Big Room House",
        )
        self.assertIn("ELITE BIG ROOM FUSION", block)
        self.assertIn("Mainstage EDM", block)
        self.assertIn("Layered supersaw leads", block)
        self.assertIn("Access Virus TI", block)
        self.assertIn("pre-shifted acoustic claps", block)
        self.assertIn("ARRANGEMENT ARCHITECTURE", block)
        self.assertIn("INSTANT TENSION", block)
        self.assertEqual(
            block,
            compose_elite_module_block(
                primary_genre="Progressive House",
                sub_genre_fusion="Big Room House",
            ).strip(),
        )
        lane_a = compose_arrangement_architecture(
            primary_genre="Progressive Big Room House",
        )
        self.assertIn("8-PART ARRANGEMENT", lane_a)

    def test_big_room_hardstyle_cinematic_hybrid_lyrics_and_elite(self):
        from app.big_room_hardstyle_cinematic_hybrid_engine import (
            compose_arrangement_architecture,
            compose_block1_seed,
            compose_dj_mix_enforcement_block,
            compose_structural_constraints_block,
            user_block_append_for as hybrid_elite,
        )
        from app.genre_lyrics_directives import genre_lyrics_user_block

        block = genre_lyrics_user_block(
            primary_genre="Hardstyle",
            sub_genre_fusion="Euphoric Hardstyle / Rawstyle",
            vibe="150 BPM mainstage hard dance",
        )
        # Master hardstyle lyric engine owns this lane (the cinematic-hybrid
        # specialty path requires big-room/cinematic markers) and resolves a
        # native rawstyle profile.
        self.assertIn("STRICT WRITING RULES FOR ALL HARDSTYLE", block)
        self.assertIn("SUB-GENRE: RAWSTYLE", block)
        self.assertIn("[Mid-Intro]", block)
        self.assertIn("ADVANCED THEMATIC GUARDRAILS — HARDSTYLE", block)
        self.assertIn("250Hz vocal warmth pocket", block)
        elite = hybrid_elite(
            primary_genre="Hardstyle",
            sub_genre_fusion="Euphoric Hardstyle / Rawstyle",
        )
        self.assertIn("150 BPM", elite)
        self.assertIn("CLIMAX DROP", elite.upper())
        self.assertIn("STRUCTURAL CONSTRAINTS", elite)
        self.assertIn("ELITE HARDSTYLE ARRANGEMENT MODULE", elite)
        seed = compose_block1_seed()
        self.assertIn("Authentic Hardstyle intro tool", seed)
        self.assertIn("Authentic Hardstyle outro tool", seed)
        self.assertIn("REQUIRED", compose_dj_mix_enforcement_block())
        self.assertIn(
            "[Percussive fade out, final low-end hit, complete silence]",
            compose_structural_constraints_block(),
        )
        progressive = compose_arrangement_architecture(
            primary_genre="Progressive Hardstyle",
        )
        self.assertIn("8-PART HARD DANCE ARC", progressive)

    def test_anti_scream_scrubs_exclamations_and_tags(self):
        from app.anti_scream_filter import apply_anti_scream_to_lyrics

        raw = (
            "[Chorus]\nWake up now!\n[Maximum Aggression]\n"
            "Feel the power!\n[Drop]\nGo now!"
        )
        out = apply_anti_scream_to_lyrics(raw, primary_genre="hardstyle")
        self.assertNotIn("!", out)
        self.assertIn("[Heavy Produced Mix]", out)

    def test_anti_scream_hardstyle_monologue_delivery_tags(self):
        from app.anti_scream_filter import apply_anti_scream_to_lyrics

        raw = "[Monologue]\nThe clock strikes midnight.\n[Drop]\nDrop."
        out = apply_anti_scream_to_lyrics(raw, primary_genre="hardstyle")
        self.assertIn("[Deep Pitch-Down Male Voiceover]", out)
        self.assertIn("[Calm Controlled Spoken Word]", out)


class TestMusicPromptRouting(unittest.TestCase):
    def _body(self, **kwargs):
        from types import SimpleNamespace

        defaults = dict(
            primary_genre="",
            sub_genre_fusion="",
            vibe="",
            language="English",
            vocal_accent="",
            dialect_style_id="",
            dialect_variant_id="",
            bpm=None,
        )
        defaults.update(kwargs)
        return SimpleNamespace(**defaults)

    def test_amapiano_mainstream(self):
        from app.music_prompt_routing import classify_from_body

        c = classify_from_body(self._body(vibe="Amapiano groove, log drum"))
        self.assertEqual(c.routing_key, "GEN_AFRICAN_MAINSTREAM")

    def test_pidgin_ibibio(self):
        from app.music_prompt_routing import classify_from_body

        c = classify_from_body(
            self._body(
                vibe="Nigerian Pidgin gospel",
                vocal_accent="nigerian_ibibio",
                dialect_variant_id="ibibio",
            )
        )
        self.assertEqual(c.routing_key, "GEN_AFRICAN_PIDGIN")
        self.assertEqual(c.pidgin_sub_variant, "ibibio")

    def test_hybrid_multi_genre(self):
        from app.music_prompt_routing import classify_from_body, pick_model_key

        c = classify_from_body(
            self._body(
                primary_genre="Amapiano",
                sub_genre_fusion="Vinahouse",
                vibe="Amapiano + Vinahouse hybrid",
            )
        )
        self.assertEqual(c.routing_key, "HYBRID_MULTI_GENRE")
        self.assertTrue(c.is_hybrid)
        self.assertEqual(pick_model_key(c), "glm")
        self.assertEqual(c.hybrid_resolution.tempo_strategy, "dual_section")

    def test_hybrid_tempo_in_user_block(self):
        from app.music_prompt_routing import (
            build_routing_user_block_append,
            classify_from_body,
        )

        c = classify_from_body(
            self._body(primary_genre="Amapiano", sub_genre_fusion="Vinahouse")
        )
        block = build_routing_user_block_append(c)
        self.assertIn("tempo_strategy=dual_section", block)
        self.assertIn("TEMPO_STRATEGY=dual_section", block)

    def test_hybrid_cultural(self):
        from app.music_prompt_routing import classify_from_body

        c = classify_from_body(
            self._body(vibe="K-pop with English verse and Korean chorus")
        )
        self.assertEqual(c.routing_key, "HYBRID_CULTURAL")

    def test_routing_append_includes_key(self):
        from app.music_prompt_routing import (
            build_routing_user_block_append,
            classify_from_body,
        )

        c = classify_from_body(self._body(vibe="Reggaeton"))
        block = build_routing_user_block_append(c)
        self.assertIn("routing_key=GEN_LATIN", block)


if __name__ == "__main__":
    unittest.main()
