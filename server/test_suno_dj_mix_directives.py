"""Unit tests for DJ mix user-block directives (SECTION 1F runtime inject)."""

from __future__ import annotations

import unittest

from app.dynamic_structural_engine import StructuralFamily
from app.suno_dj_mix_directives import (
    DJ_MIX_USER_BLOCK_CHAR_CAP,
    build_dj_mix_user_block,
    dj_bar_config_for,
    dj_mix_allowed_for_family,
    primary_genre_with_dj_tool_modifier,
)


class DjMixDirectivesTests(unittest.TestCase):
    def test_off_state_returns_empty(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=False,
            dj_outro_mix_out=False,
            suno_version="v5.5",
            primary_genre="Progressive House",
        )
        self.assertEqual(out, "")

    def test_worship_gated_empty(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=True,
            dj_outro_mix_out=True,
            suno_version="v5.5",
            primary_genre="Worship",
        )
        self.assertEqual(out, "")

    def test_intro_content_rich_positive_language(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=True,
            dj_outro_mix_out=False,
            suno_version="v5.5",
            primary_genre="Progressive House",
        )
        lower = out.lower()
        self.assertIn("[PRODUCTION REQUIREMENT: DJ-FRIENDLY STRUCTURE]", out)
        self.assertIn("[DJ INTRO: ON]", out)
        self.assertIn("wordless percussion intro", out)
        self.assertIn("[Instrumental Intro:", out)
        self.assertIn("[Percussion Build:", out)
        self.assertIn("[Riser:", out)
        self.assertIn("~32 bars", out)
        self.assertIn('never "no vocals / no melody"', lower)
        self.assertNotIn("no lead vocal", lower)
        self.assertNotIn("no hard cut", lower)

    def test_outro_content_rich_fade_bookends(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=False,
            dj_outro_mix_out=True,
            suno_version="v5.5",
            primary_genre="Progressive House",
        )
        self.assertIn("[DJ OUTRO: ON]", out)
        self.assertIn("[Instrumental Outro:", out)
        self.assertIn("[Fade Out:", out)
        self.assertIn("loopable fade", out)

    def test_both_within_char_cap(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=True,
            dj_outro_mix_out=True,
            suno_version="v5.5",
            primary_genre="Progressive House",
        )
        self.assertLessEqual(len(out), DJ_MIX_USER_BLOCK_CHAR_CAP)

    def test_v45_soft_bar_phrasing(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=True,
            dj_outro_mix_out=False,
            suno_version="v4.5",
            primary_genre="Progressive House",
        )
        self.assertIn("~32-bar", out)
        self.assertIn("sonic language", out)
        self.assertNotIn("director's notes", out.lower())

    def test_v55_director_notes_hint(self) -> None:
        out = build_dj_mix_user_block(
            dj_intro_mix_in=True,
            dj_outro_mix_out=True,
            suno_version="v5.5",
            primary_genre="Progressive House",
        )
        self.assertIn("director's notes", out.lower())

    def test_amapiano_bar_budget(self) -> None:
        cfg = dj_bar_config_for(StructuralFamily.AMAPIANO)
        self.assertEqual(cfg.intro_bars, 16)
        self.assertEqual(cfg.outro_bars, 16)
        self.assertTrue(dj_mix_allowed_for_family(StructuralFamily.AMAPIANO))

    def test_genre_modifier(self) -> None:
        on = primary_genre_with_dj_tool_modifier(
            primary_genre="Progressive House",
            dj_intro_mix_in=True,
            dj_outro_mix_out=False,
            family=StructuralFamily.EDM_PROGRESSIVE_HOUSE,
        )
        off = primary_genre_with_dj_tool_modifier(
            primary_genre="Progressive House",
            dj_intro_mix_in=False,
            dj_outro_mix_out=False,
            family=StructuralFamily.EDM_PROGRESSIVE_HOUSE,
        )
        self.assertEqual(on, "Progressive House, DJ Tool, Club Mix")
        self.assertEqual(off, "Progressive House")


if __name__ == "__main__":
    unittest.main()
