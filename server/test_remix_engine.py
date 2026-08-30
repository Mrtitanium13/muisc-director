"""Parity tests for Layer 4.8 remix engine (fixtures/remix/)."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from app.remix_engine import (
    REMIX_BLOCK_VERSION,
    RemixMode,
    remix_engine_active,
    remix_post_process_compact_line,
    remix_style_flip_user_block_supplement,
    resolve_remix_mode,
    source_leak_guard,
)

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "fixtures" / "remix"


class RemixEngineFixtureTests(unittest.TestCase):
    def _load(self, name: str) -> dict:
        return json.loads((FIXTURES / name).read_text(encoding="utf-8"))

    def test_interpolation_full_basic(self) -> None:
        fx = self._load("interpolation_full_basic.json")
        inp = fx["input"]
        exp = fx["expect"]
        res = resolve_remix_mode(
            remix_original_song_title=inp["title"],
            remix_original_artist=inp["artist"],
            remix_from_analyzer=inp.get("remix_from_analyzer", False),
        )
        self.assertEqual(res.mode, RemixMode.INTERPOLATION)
        self.assertTrue(exp["engine_active"])
        block = remix_style_flip_user_block_supplement(
            original_song_title=inp["title"],
            original_artist=inp["artist"],
            target_genre=inp["primary_genre"],
            generation_type="full_song",
            bpm=inp.get("bpm", ""),
            key_root=inp.get("key_root", ""),
            scale=inp.get("scale", ""),
        )
        for needle in exp["block_contains"]:
            self.assertIn(needle, block)
        for bad in exp.get("block_excludes", []):
            self.assertNotIn(bad, block)
        compact = remix_post_process_compact_line(
            original_song_title=inp["title"],
            original_artist=inp["artist"],
            generation_type="full_song",
        )
        for needle in exp["compact_contains"]:
            self.assertIn(needle, compact)
        for bad in exp["compact_excludes"]:
            self.assertNotIn(bad, compact)
        self.assertEqual(REMIX_BLOCK_VERSION, exp["block_version"])

    def test_conflict_analyzer_wins(self) -> None:
        fx = self._load("conflict_analyzer_wins.json")
        inp = fx["input"]
        res = resolve_remix_mode(
            remix_original_song_title=inp["title"],
            remix_original_artist=inp["artist"],
            remix_from_analyzer=True,
        )
        self.assertEqual(res.mode, RemixMode.ANALYZER_GENRE_FLIP)
        self.assertEqual(fx["expect"]["mode"], "analyzer_genre_flip")
        # Injection must use resolve_remix_mode — not legacy remix_engine_active alone.

    def test_near_activation_title_only(self) -> None:
        fx = self._load("near_activation_title_only.json")
        inp = fx["input"]
        res = resolve_remix_mode(
            remix_original_song_title=inp["title"],
            remix_original_artist=inp.get("artist", ""),
            remix_from_analyzer=False,
        )
        self.assertEqual(res.mode, RemixMode.NONE)
        self.assertTrue(res.near_activation)

    def test_leak_feat_variant(self) -> None:
        cleaned, leaked = source_leak_guard(
            "Style about Someone and Test Song vibes",
            "Test Song",
            "Test Artist feat. Someone",
        )
        self.assertTrue(leaked)
        self.assertNotIn("Test Song", cleaned)
        self.assertIn("[redacted]", cleaned)

    def test_idempotent_injection(self) -> None:
        block = remix_style_flip_user_block_supplement(
            original_song_title="Mercy",
            original_artist="Band",
            target_genre="Jazz",
            existing_user_block="REMIX / MUSICAL INTERPOLATION ENGINE already",
        )
        self.assertEqual(block, "")

    def test_telemetry_never_logs_raw_title_artist(self) -> None:
        from app.remix_telemetry import log_remix_activation, log_remix_post_process

        title = "Secret Song Title XYZ"
        artist = "Secret Artist Name ABC"
        with self.assertLogs("music_director.remix", level="INFO") as cm:
            log_remix_activation(
                mode=RemixMode.INTERPOLATION,
                near_activation=False,
                genre="House",
                song_generation_type="full_song",
                title=title,
                artist=artist,
                block_injected=True,
            )
            log_remix_post_process(
                mode=RemixMode.INTERPOLATION,
                song_generation_type="instrumental",
                stripped_lyric_lines=2,
                staging_injected=1,
                leak_hit=True,
                title=title,
                artist=artist,
            )
        joined = " ".join(cm.output)
        self.assertNotIn(title, joined)
        self.assertNotIn(artist, joined)
        self.assertIn("fp=", joined)
        self.assertIn("strip_n=2", joined)
        self.assertIn("leak=True", joined)


if __name__ == "__main__":
    unittest.main()
