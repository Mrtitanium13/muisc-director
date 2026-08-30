"""Tests for vibe brief vs source-text-for-lyrics user-block lines."""

from __future__ import annotations

import unittest

from app.vibe_brief_user_block import build_vibe_user_block_lines, looks_like_scripture


class TestVibeBriefUserBlock(unittest.TestCase):
    def test_source_text_path_splits_brief_and_lyric_material(self) -> None:
        vibe = (
            "Yearning · Modern Praise & Worship · Worship lift build · "
            "John 3:16 For God so loved the world"
        )
        lines = build_vibe_user_block_lines(
            vibe=vibe,
            use_vibe_as_lyric_source=True,
        )
        self.assertTrue(lines[0].startswith("[VIBE BRIEF] (Mood · Era/Scene · Groove Feel):"))
        self.assertTrue(any("[SOURCE TEXT FOR LYRICS]" in line for line in lines))
        self.assertTrue(any("scriptural" in line for line in lines))
        self.assertIn("John 3:16", lines[-1])

    def test_detail_stays_in_vibe_when_toggle_off(self) -> None:
        lines = build_vibe_user_block_lines(
            vibe="Dark · rooftop afterparty",
            use_vibe_as_lyric_source=False,
        )
        self.assertIn("[VIBE BRIEF] (Mood · Era/Scene · Groove Feel): Dark", lines)
        self.assertIn("Vibe / idea detail: rooftop afterparty", lines)
        self.assertNotIn("[SOURCE TEXT FOR LYRICS]", lines)

    def test_scripture_heuristic(self) -> None:
        self.assertTrue(looks_like_scripture("John 3:16 For God so loved the world"))
        self.assertFalse(looks_like_scripture("rooftop summer rain"))


if __name__ == "__main__":
    unittest.main()
