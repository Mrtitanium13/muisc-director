"""Unit tests for songwriter packs, routing, linting, and emit modes."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))

from app.songwriter.linting import lint_lyrics, parse_sections, scrub_forbidden  # noqa: E402
from app.songwriter.packs import (  # noqa: E402
    list_genre_pack_ids,
    resolve_genre_pack,
    resolve_genre_pack_id,
    resolve_language_pack,
    resolve_language_pack_id,
)
from app.songwriter.pipeline import SongBriefInput, SongwriterPipeline  # noqa: E402
from app.songwriter.router import decide_route, match_route  # noqa: E402


class TestGenrePacks(unittest.TestCase):
    def test_required_packs_exist(self):
        ids = set(list_genre_pack_ids())
        required = {
            "pop", "edm", "house", "big_room", "techno", "rock", "metal",
            "country", "hiphop", "trap", "afrobeats", "amapiano", "dancehall",
            "gospel", "rnb", "soul", "blues", "folk", "jazz", "latin",
            "reggaeton", "mandopop", "cantopop", "kpop", "jpop",
        }
        missing = required - ids
        self.assertFalse(missing, f"missing genre packs: {missing}")

    def test_alias_resolution(self):
        self.assertEqual(resolve_genre_pack_id("Big Room House"), "big_room")
        self.assertEqual(resolve_genre_pack_id("R&B"), "rnb")
        self.assertEqual(resolve_genre_pack_id("hip-hop"), "hiphop")
        pack = resolve_genre_pack("Amapiano")
        self.assertEqual(pack.get("_resolved_id"), "amapiano")
        self.assertTrue(pack.get("hook_style"))


class TestLanguagePacks(unittest.TestCase):
    def test_language_ids(self):
        self.assertEqual(resolve_language_pack_id("English"), "en")
        self.assertEqual(resolve_language_pack_id("zh-Hans"), "zh_hans")
        self.assertEqual(resolve_language_pack_id("Traditional Chinese"), "zh_hant")
        self.assertEqual(resolve_language_pack_id("mixed zh-en"), "mixed_zh_en")
        pack = resolve_language_pack("Mandarin")
        self.assertEqual(pack.get("_resolved_id"), "zh_hans")


class TestRouting(unittest.TestCase):
    def test_english_pop_prefers_gpt(self):
        route = match_route("pop", "English")
        self.assertEqual(route.get("primary"), "gpt-5.5")

    def test_country_prefers_claude(self):
        route = match_route("country", "en")
        self.assertEqual(route.get("primary"), "claude-opus")

    def test_mandopop_prefers_kimi(self):
        route = match_route("mandopop", "zh-Hans")
        self.assertEqual(route.get("primary"), "kimi")

    def test_routing_decision_structure(self):
        d = decide_route(genre="edm", language="English", stage="chorus")
        self.assertTrue(d.primary.logical)
        self.assertTrue(d.primary.slug)
        self.assertTrue(d.reason_codes)
        self.assertTrue(d.policy_version)
        as_dict = d.to_dict()
        self.assertIn("primary", as_dict)
        self.assertIn("fallbacks", as_dict)


class TestLinting(unittest.TestCase):
    def test_forbidden_hit(self):
        lyrics = "[Chorus]\nThrough the night I find myself\n"
        _, hits = scrub_forbidden(lyrics, allow_cliches=False)
        self.assertTrue(hits)
        report = lint_lyrics(lyrics, mode="chorus_only", allow_cliches=False)
        self.assertIn(
            "forbidden_phrase_hit_without_user_override",
            report["hard_fails"],
        )

    def test_parse_sections(self):
        lyrics = "[Verse 1]\nHello world\n\n[Chorus]\nStay with me\n"
        sections = parse_sections(lyrics)
        types = [s["type"] for s in sections]
        self.assertIn("verse", types)
        self.assertIn("chorus", types)

    def test_zh_mismatch(self):
        report = lint_lyrics(
            "[Chorus]\nOnly English here tonight\n",
            mode="chorus_only",
            language="zh-Hans",
            language_pack_id="zh_hans",
        )
        self.assertIn("language_mismatch", report["hard_fails"])


class TestGenreEngineInjection(unittest.TestCase):
    def test_resolve_amapiano_engine_nonempty(self):
        from app.songwriter.genre_engines import resolve_genre_lyric_engine

        eng = resolve_genre_lyric_engine(genre="Amapiano", theme="late night drive")
        self.assertTrue(eng.get("text"))
        self.assertGreater(eng.get("char_count") or 0, 100)
        self.assertEqual(eng.get("master_lane"), "amapiano")
        self.assertFalse(eng.get("truncated"), "amapiano should fit heavy budget")

    def test_resolve_gospel_engine_nonempty(self):
        from app.songwriter.genre_engines import resolve_genre_lyric_engine

        eng = resolve_genre_lyric_engine(genre="Gospel", theme="testimony")
        self.assertTrue(eng.get("text"))
        self.assertEqual(eng.get("master_lane"), "gospel")
        self.assertFalse(eng.get("truncated"))

    def test_heavy_masters_not_truncated(self):
        from app.songwriter.genre_engines import resolve_genre_lyric_engine

        cases = [
            ("Hardstyle", "", "hardstyle"),
            ("EDM", "Progressive House", "edm"),
        ]
        for genre, sub, lane in cases:
            with self.subTest(genre=genre):
                eng = resolve_genre_lyric_engine(
                    genre=genre, subgenre=sub, theme="festival night"
                )
                self.assertEqual(eng.get("master_lane"), lane)
                self.assertTrue(eng.get("text"))
                self.assertFalse(
                    eng.get("truncated"),
                    f"{genre} truncated at {eng.get('char_count')}/{eng.get('raw_char_count')}",
                )

    def test_stage_context_only_on_draft_stages(self):
        from app.songwriter.genre_engines import stage_user_context

        base = {"genre_rules": {"id": "pop"}}
        eng = {"text": "ENGINE BODY", "truncated": False, "char_count": 11, "source": "t"}
        chorus_ctx = stage_user_context(base, stage_id="chorus", genre_engine=eng)
        analyze_ctx = stage_user_context(base, stage_id="analyze", genre_engine=eng)
        self.assertIn("genre_lyric_engine", chorus_ctx)
        self.assertEqual(chorus_ctx["genre_lyric_engine"], "ENGINE BODY")
        self.assertNotIn("genre_lyric_engine", analyze_ctx)

    def test_pipeline_injects_on_chorus_stage(self):
        seen_users: list[str] = []

        def fake_llm(system, user, model, temperature):
            seen_users.append(user)
            if "songwriter_stage=analyze" in system:
                return json.dumps({"ok": True})
            if "songwriter_stage=concepts" in system:
                return json.dumps({"concepts": [{"title_ideas": ["X"], "logline": "y"}]})
            if "songwriter_stage=chorus" in system:
                return json.dumps(
                    {
                        "hook_candidates": [{"text": "Stay", "score": 90}],
                        "selected_hook": "Stay",
                        "chorus_lyrics": "Stay with me",
                        "title": "Stay",
                    }
                )
            return "{}"

        pipe = SongwriterPipeline(llm_caller=fake_llm)
        out = pipe.run(
            SongBriefInput(
                genre="Amapiano",
                language="English",
                mode="hook_ideas",
                theme="rooftop chill",
            )
        )
        self.assertTrue(out["metadata"].get("genreLyricEngineInjected"))
        # Last user payload should be chorus (hook_ideas: analyze, concepts, chorus)
        self.assertIn("genre_lyric_engine", seen_users[-1])
        # First stage (analyze) should not carry the engine
        self.assertNotIn('"genre_lyric_engine"', seen_users[0])


class TestEmitModes(unittest.TestCase):
    def test_hooks_list_emit(self):
        def fake_llm(system, user, model, temperature):
            if "songwriter_stage=analyze" in system:
                return json.dumps({"genre": "pop", "theme": "leaving"})
            if "songwriter_stage=concepts" in system:
                return json.dumps(
                    {
                        "concepts": [
                            {
                                "id": "c1",
                                "title_ideas": ["Neon Exit"],
                                "logline": "Leaving a rooftop party",
                                "hook_seed": "I'm already gone",
                            }
                        ]
                    }
                )
            if "songwriter_stage=chorus" in system:
                return json.dumps(
                    {
                        "hook_candidates": [
                            {"text": "I'm already gone", "score": 90},
                            {"text": "Don't wait up", "score": 80},
                        ],
                        "selected_hook": "I'm already gone",
                        "title": "Already Gone",
                        "chorus_lyrics": "I'm already gone\nDon't wait up",
                    }
                )
            return "{}"

        pipe = SongwriterPipeline(llm_caller=fake_llm)
        out = pipe.run(
            SongBriefInput(genre="pop", language="English", mode="hook_ideas")
        )
        self.assertTrue(out.get("ideas"))
        self.assertIn("I'm already gone", out["ideas"])
        self.assertEqual(out.get("quality_status"), "passed")
        self.assertEqual(out["metadata"]["emit"], "hooks_list")

    def test_titles_list_emit(self):
        def fake_llm(system, user, model, temperature):
            if "songwriter_stage=analyze" in system:
                return json.dumps({"ok": True})
            if "songwriter_stage=concepts" in system:
                return json.dumps(
                    {
                        "concepts": [
                            {"title_ideas": ["Glass Elevator", "Quiet Floor"]},
                            {"title_ideas": ["Last Train Home"]},
                        ]
                    }
                )
            return "{}"

        pipe = SongwriterPipeline(llm_caller=fake_llm)
        out = pipe.run(
            SongBriefInput(genre="pop", language="English", mode="song_titles")
        )
        self.assertGreaterEqual(len(out.get("ideas") or []), 3)

    def test_fast_quality_skips_stages(self):
        called: list[str] = []

        def fake_llm(system, user, model, temperature):
            import re

            m = re.search(r"\[songwriter_stage=([a-z0-9_]+)\]", system)
            if m:
                called.append(m.group(1))
            if "chorus" in system:
                return json.dumps(
                    {
                        "hook_candidates": [{"text": "Stay", "score": 80}],
                        "selected_hook": "Stay",
                        "chorus_lyrics": "Stay a little longer",
                        "title": "Stay",
                    }
                )
            if "polish" in system:
                return json.dumps(
                    {
                        "lyrics": "[Chorus]\nStay a little longer\n",
                        "title": "Stay",
                        "scores": {"hook_strength": 90},
                        "weighted_total": 91,
                        "ship": True,
                    }
                )
            return json.dumps({"ok": True, "lyrics": "[Chorus]\nStay a little longer\n"})

        pipe = SongwriterPipeline(llm_caller=fake_llm)
        out = pipe.run(
            SongBriefInput(
                genre="pop",
                language="English",
                mode="chorus_only",
                quality_mode="fast",
            )
        )
        self.assertNotIn("select", called)
        self.assertNotIn("arc", called)
        self.assertTrue(out.get("lyrics"))


if __name__ == "__main__":
    unittest.main()
