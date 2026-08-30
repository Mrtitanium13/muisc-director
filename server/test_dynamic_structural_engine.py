"""Python tests for Dynamic Structural Engine (mirrors Dart test suite)."""

from __future__ import annotations

import unittest

from app.dynamic_structural_engine import (
    FinalChorusMutation,
    SongIntent,
    SongSection,
    StructuralFamily,
    assemble_sections,
    dynamic_structural_user_block,
    enforce_density_budget,
    mutation_for,
    resolve_structural_family,
    user_block_directive,
)


class TestStructuralFamilyResolver(unittest.TestCase):
    def test_worship(self) -> None:
        self.assertEqual(
            resolve_structural_family(primary="Praise/Worship"),
            StructuralFamily.WORSHIP,
        )

    def test_amapiano(self) -> None:
        self.assertEqual(
            resolve_structural_family(primary="Amapiano"),
            StructuralFamily.AMAPIANO,
        )

    def test_trap_before_hiphop(self) -> None:
        self.assertEqual(
            resolve_structural_family(primary="Melodic Trap"),
            StructuralFamily.TRAP,
        )

    def test_fusion_fallback(self) -> None:
        self.assertEqual(
            resolve_structural_family(primary="misc", fusion="Amapiano"),
            StructuralFamily.AMAPIANO,
        )


class TestAssembly(unittest.TestCase):
    def test_every_family_ends_with_end(self) -> None:
        for family in StructuralFamily:
            sections = assemble_sections(family, suno_version="v5.5")
            self.assertEqual(sections[-1].label, "End", family)

    def test_worship_congregational_modules(self) -> None:
        sections = assemble_sections(
            StructuralFamily.WORSHIP,
            intent=SongIntent.CONGREGATIONAL,
        )
        kinds = {s.kind for s in sections}
        self.assertIn("vamp", kinds)
        self.assertIn("spontaneousFlow", kinds)

    def test_folk_no_drop(self) -> None:
        sections = assemble_sections(StructuralFamily.FOLK)
        self.assertNotIn("drop", {s.kind for s in sections})

    def test_edm_progressive_house_has_drop_a_and_drop_b(self) -> None:
        sections = assemble_sections(StructuralFamily.EDM_PROGRESSIVE_HOUSE)
        kinds = {s.kind for s in sections}
        self.assertIn("dropA", kinds)
        self.assertIn("dropB", kinds)


class TestUserBlockDirective(unittest.TestCase):
    def test_deterministic(self) -> None:
        a = user_block_directive(primary_genre="Amapiano", suno_version="v5.5")
        b = user_block_directive(primary_genre="Amapiano", suno_version="v5.5")
        self.assertEqual(a, b)

    def test_contains_end(self) -> None:
        out = dynamic_structural_user_block("EDM", suno_version="v5.5")
        self.assertIn("[End]", out)

    def test_user_defined_roadmap(self) -> None:
        sections = [
            SongSection("intro", "Intro", "vinyl crackle"),
            SongSection("end", "End"),
        ]
        out = user_block_directive(
            suno_version="v5.5",
            user_sections=sections,
        )
        self.assertIn("[USER-DEFINED ROADMAP]", out)
        self.assertIn("[Intro", out)

    def test_v45_no_colon_brackets(self) -> None:
        out = user_block_directive(primary_genre="Pop", suno_version="v4.5")
        for line in out.splitlines():
            if line.strip().startswith("[") and "]" in line:
                self.assertNotIn(":", line, line)

    def test_density_budget(self) -> None:
        long_block = "\n".join(
            f"[Verse {i}: very long staging note repeated many times]" for i in range(40)
        )
        pruned = enforce_density_budget(long_block, cap=200)
        self.assertLessEqual(len(pruned), len(long_block))


class TestMutation(unittest.TestCase):
    def test_edm_beat_switch(self) -> None:
        self.assertEqual(
            mutation_for(StructuralFamily.EDM_PROGRESSIVE_HOUSE),
            FinalChorusMutation.BEAT_SWITCH_VARIATION,
        )


if __name__ == "__main__":
    unittest.main()
