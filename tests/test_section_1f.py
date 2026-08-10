"""Tests for Section 1F and build_dj_mix_user_block (Python mirror)."""

from __future__ import annotations

from pathlib import Path

import pytest

from muisc_director.build_dj_mix_user_block import DjMixRequest, build_dj_mix_user_block
from muisc_director.prompts.consolidated_body import (
    build_consolidated_body,
    build_section_1f_standalone,
    section_1f_content,
)
from muisc_director.prompts.section_ids import (
    DJ_MIX_IN_TAG,
    DJ_MIX_OUT_TAG,
    END_TAG,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
PROMPTS_ROOT = REPO_ROOT / "prompts"


class TestSection1F:
    def test_loads_positive_content_first_dj_mix_rules(self) -> None:
        content = section_1f_content(base_path=PROMPTS_ROOT)

        assert "SECTION 1F" in content
        assert DJ_MIX_IN_TAG in content
        assert DJ_MIX_OUT_TAG in content
        assert END_TAG in content
        assert "8–16 bars" in content
        assert "16–32 bars" in content
        assert "VERIFICATION CHECKLIST" in content

    def test_positive_content_first_not_negative_only(self) -> None:
        content = section_1f_content(base_path=PROMPTS_ROOT)

        assert "Establish the kick drum" in content
        assert "Maintain the kick drum" in content
        assert "MUST open with a DJ Mix-In intro" in content
        assert "MUST close with a DJ Mix-Out outro" in content

    def test_standalone_module_framing(self) -> None:
        standalone = build_section_1f_standalone(base_path=PROMPTS_ROOT)

        assert "DJ MIX BOOKEND MODULE" in standalone
        assert "Standalone" in standalone
        assert DJ_MIX_IN_TAG in standalone
        assert DJ_MIX_OUT_TAG in standalone

    def test_consolidated_body_section_order(self) -> None:
        body = build_consolidated_body(base_path=PROMPTS_ROOT)

        for section_label in (
            "SECTION 1A",
            "SECTION 1B",
            "SECTION 1C",
            "SECTION 1D",
            "SECTION 1E",
            "SECTION 1F",
        ):
            assert section_label in body

        assert body.index("SECTION 1A") < body.index("SECTION 1F")


class TestBuildDjMixUserBlock:
    def test_mandatory_structure_requirements(self) -> None:
        block = build_dj_mix_user_block(
            DjMixRequest(
                track_title="Midnight Pulse",
                genre="deep house",
                bpm=124,
            )
        )

        assert "[Intro: DJ Mix-In]" in block
        assert "[Outro: DJ Mix-Out]" in block
        assert "[End]" in block
        assert "124 BPM" in block
        assert "Midnight Pulse" in block
        assert "deep house" in block

    def test_dj_tag_included_when_provided(self) -> None:
        block = build_dj_mix_user_block(
            DjMixRequest(
                track_title="Sunrise Set",
                genre="progressive house",
                bpm=128,
                dj_tag="You are listening to DJ Titanium",
            )
        )

        assert "DJ tag (spoken during mix-in only)" in block
        assert "You are listening to DJ Titanium" in block
        assert "Include the DJ tag as spoken word" in block

    def test_instrumental_mix_in_without_dj_tag(self) -> None:
        block = build_dj_mix_user_block(
            DjMixRequest(
                track_title="Instrumental Groove",
                genre="techno",
                bpm=130,
            )
        )

        assert "Keep the mix-in instrumental (no vocals)" in block
        assert "Include the DJ tag" not in block

    def test_optional_fields(self) -> None:
        block = build_dj_mix_user_block(
            DjMixRequest(
                track_title="Key Test",
                genre="house",
                bpm=126,
                mood="euphoric",
                key_signature="A minor",
                vocal_style="female, breathy",
                additional_notes="Peak-time club weapon",
            )
        )

        assert "Mood: euphoric" in block
        assert "Key: A minor" in block
        assert "Vocal style: female, breathy" in block
        assert "Notes: Peak-time club weapon" in block


class TestGeneratedPrompts:
    def test_generated_files_exist_after_regeneration(self) -> None:
        full_path = PROMPTS_ROOT / "generated" / "system_prompt_full.txt"
        standalone_path = PROMPTS_ROOT / "generated" / "system_prompt_1f_standalone.txt"

        assert full_path.is_file(), "Run regenerate_system_prompts first"
        assert standalone_path.is_file(), "Run regenerate_system_prompts first"

        full_content = full_path.read_text(encoding="utf-8")
        standalone_content = standalone_path.read_text(encoding="utf-8")

        assert DJ_MIX_IN_TAG in full_content
        assert DJ_MIX_OUT_TAG in full_content
        assert DJ_MIX_IN_TAG in standalone_content
