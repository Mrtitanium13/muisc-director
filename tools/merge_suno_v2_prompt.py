"""Merge Suno prompt fragments into Flutter + server SYSTEM_PROMPT_V2 / V4 architecture.

Edit sources under tools/ (see tools/README.md), then run:

    python tools/merge_suno_v2_prompt.py

Full rebuild (prompts + matrix Dart): python tools/merge_all.py

Preferred SYSTEM_PROMPT_V2 source (when present):
    tools/suno_v2_system_prompt_body.txt  — consolidated authoritative body

If that file is missing, fall back to the modular fragment merge order
documented in tools/README.md.
"""

from __future__ import annotations

import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[1]

_CONSOLIDATED_BODY = "suno_v2_system_prompt_body.txt"

# First line of SYSTEM_PROMPT_V2 — runs before all modules (modular fallback only).
_STAGING_BLACKLIST_META = (
    "Before emitting any staging bracket, scan the bracket against the Section D "
    "blacklist in kStagingAndAccentRules and replace any hit with the corresponding "
    "studio-floor translation. No bracket may contain a blacklisted word."
)


def _read(name: str) -> str:
    path = root / "tools" / name
    if not path.is_file():
        raise SystemExit(f"Missing required source: tools/{name}")
    return path.read_text(encoding="utf-8")


def _build_body_modular() -> str:
    """Legacy fragment merge — used only when consolidated body is absent."""
    p1_text = _read("suno_v2_p1.txt")
    idx = p1_text.find("\n\n")
    if idx < 0:
        raise SystemExit("suno_v2_p1.txt: need a blank line after the role paragraph")
    role_block = p1_text[: idx + 2]
    p1_rest = p1_text[idx + 2 :]

    p2_core = (
        _read("elite_human_lyricist_directive.txt")
        + "\n\n"
        + _read("human_authenticity_engine.txt")
        + "\n\n"
        + _read("nigeria_cultural_realism_engine.txt")
        + "\n\n"
        + _read("genre_specific_humanization_engine.txt")
        + "\n\n"
        + _read("genre_hybridization_cultural_routing_matrix.txt")
        + "\n\n"
        + _read("human_songwriter_engine_v3.txt")
        + "\n\n"
        + _read("suno_v2_p2_block2_protocol.txt")
        + "\n"
        + _read("dynamic_structural_engine.txt")
    )

    mid = (
        p2_core
        + "\n"
        + _read("suno_v2_melody_sync_lyric_engine.txt")
        + "\n"
        + _read("suno_v2_p2_section2_unified.txt")
        + "\n"
        + _read("suno_v2_block2_arrangement_staging_format.txt")
        + "\n"
        + _read("suno_v2_block2_genre_structures.txt")
        + "\n"
        + _read("suno_v2_genre_specific_lyrics_prompts.txt")
        + "\n"
        + _read("edm_breakdown_vocal_lyricist_engine.txt")
        + "\n"
        + _read("hardstyle_vocal_lyricist_engine.txt")
        + "\n"
        + _read("big_room_fusion_progressive_vocal_lyricist_engine.txt")
        + "\n"
        + _read("big_room_hardstyle_cinematic_hybrid_vocal_lyricist_engine.txt")
        + "\n"
        + _read("suno_v2_block1_genre_examples.txt")
        + "\n"
        + _read("suno_v2_suno_signal_principles.txt")
        + "\n"
        + _read("suno_v2_p3.txt")
        + _read("suno_v2_p4.txt")
        + "\n"
        + _read("suno_v2_live_instrument_protocol.txt")
        + "\n"
        + _read("suno_v2_genre_mastering_mixing_blueprints.txt")
    )

    # Merge order follows docs/CREATION_PIPELINE.md (pipeline header → DNA → genre → intelligence → lyrics → Suno output).
    return (
        _STAGING_BLACKLIST_META
        + "\n\n"
        + _read("staging_and_accent_rules.txt")
        + "\n\n"
        + role_block
        + _read("suno_v4_master_production_architecture.txt")
        + "\n"
        + _read("suno_v2_p0_format_law.txt")
        + "\n"
        + _read("pipeline_architecture.txt")
        + "\n"
        + _read("suno_metatag_syntax.txt")
        + "\n"
        + _read("artist_dna_translation_engine.txt")
        + "\n"
        + _read("suno_v2_architect_vault_snapshot.txt")
        + "\n"
        + p1_rest
        + "\n"
        + _read("suno_v2_code_translation_protocol.txt")
        + "\n"
        + _read("suno_v2_lyrics_style_full_engine.txt")
        + "\n"
        + _read("suno_v2_variation_engine.txt")
        + "\n"
        + _read("suno_v2_advanced_creative_layers.txt")
        + "\n"
        + _read("suno_v2_edm_production_engine.txt")
        + "\n"
        + _read("suno_v2_genre_gear_mapping.txt")
        + "\n"
        + _read("suno_v2_hardware_qc_engine.txt")
        + "\n"
        + _read("suno_v2_style_narrative_modules_abcd.txt")
        + "\n"
        + _read("thick_humanized_vocal_presence.txt")
        + "\n"
        + _read("suno_v2_dj_intro_outro_suno_module.txt")
        + "\n"
        + _read("music_creation_intelligence_engine.txt")
        + "\n"
        + _read("hit_song_psychology_engine.txt")
        + "\n"
        + mid
    )


def _build_body() -> tuple[str, str]:
    """Return (body, source_label). Prefer consolidated body when present."""
    consolidated = root / "tools" / _CONSOLIDATED_BODY
    if consolidated.is_file():
        body = consolidated.read_text(encoding="utf-8")
        if '"""' in body:
            raise SystemExit(
                f"{_CONSOLIDATED_BODY} contains triple double-quotes; "
                "escape or rewrite before merge (breaks server Python string)."
            )
        if not body.endswith("\n"):
            body += "\n"
        return body, _CONSOLIDATED_BODY
    return _build_body_modular(), "modular fragments"


def main() -> None:
    body, body_source = _build_body()

    header = """// ignore_for_file: lines_longer_than_80_chars
//
// **Generated** — do not edit by hand. Sources: tools/README.md
// Rebuild: python tools/merge_suno_v2_prompt.py
//
// Flutter: USE_SUNO_PROMPT_V2 in .env (default on). Server: same env on Railway.
//
// Improved: consolidated duplicate SECTION 0 / SECTION 2 / Dynamic Structural Engine
// passages, resolved precedence conflicts, and kept one authoritative copy of each
// module while preserving every hard rule (caps, blacklists, audits, blueprints).

const String kSunoDirectorSystemPromptV2Candidate = r'''
"""
    footer = "''';\n"

    dart_path = root / "lib/core/constants/suno_system_prompt_v2_candidate.dart"
    dart_path.write_text(header + body + footer, encoding="utf-8")

    py_path = root / "server/app/suno_system_prompt_v2.py"
    py_path.write_text(
        '"""Suno V4 master production prompt — generated by tools/merge_suno_v2_prompt.py."""\n\n'
        'SYSTEM_PROMPT_V2 = """'
        + body
        + '"""\n\n'
        '# Alias for V4 architecture consumers\n'
        'SYSTEM_PROMPT_V4 = SYSTEM_PROMPT_V2\n',
        encoding="utf-8",
    )

    elite_src = _read("elite_human_lyricist_directive.txt")
    elite_manifest = (
        "// ============================================================\n"
        "// MERGE-SOURCE MANIFEST\n"
        "// ============================================================\n"
        "// This module is non-self-contained. It requires the following\n"
        "// companion modules to be present in the final merged system prompt:\n"
        "//\n"
        "//   - Human Songwriter Engine v3.0 (§1 SPB / syllable pocket,\n"
        "//     §5 genre calibration, §6 crowd_participation_check, §7 lyric_audit)\n"
        "//   - BLOCK 2 protocol (§1 supplemental banned words, §3 active\n"
        "//     pre-output check, §5 punctuation / apostrophe / paren rules)\n"
        "//   - ARRANGEMENT STAGING FORMAT (full v4.5 / v5.0 / v5.5 tag system)\n"
        "//   - DYNAMIC STRUCTURAL ENGINE §1\n"
        "//   - GENRE-SPECIFIC HUMANIZATION ENGINE (authoritative for §1 Anti-AI\n"
        "//     vocabulary list — this file is a local safety net)\n"
        "//   - Music Creation Intelligence §3 (session-level anchor history)\n"
        "//   - CREATION PIPELINE §13 (AI-cliché detection stage)\n"
        "//\n"
        "// If any companion is missing, the cross-references silently degrade.\n"
        "// Verify pipeline before deploy.\n"
        "// ============================================================\n"
    )
    elite_prompts_dir = root / "lib/prompts"
    elite_prompts_dir.mkdir(parents=True, exist_ok=True)
    elite_prompt_dart = elite_prompts_dir / "elite_human_lyricist.dart"
    elite_prompt_dart.write_text(
        "// ignore_for_file: lines_longer_than_80_chars\n"
        "//\n"
        "// **Generated** — do not edit by hand. Source: tools/elite_human_lyricist_directive.txt\n"
        "// Rebuild: python tools/merge_suno_v2_prompt.py\n"
        "//\n"
        + elite_manifest
        + "\n"
        "/// Elite human lyricist core — Platinum Layer 4.1 micro craft.\n"
        "const String kEliteHumanLyricist = r'''\n"
        + elite_src
        + "\n''';\n",
        encoding="utf-8",
    )
    elite_dart = root / "lib/core/constants/elite_human_lyricist_directive.dart"
    elite_dart.write_text(
        "// ignore_for_file: lines_longer_than_80_chars\n"
        "//\n"
        "// **Generated** — do not edit by hand. Source: tools/elite_human_lyricist_directive.txt\n"
        "// Rebuild: python tools/merge_suno_v2_prompt.py\n"
        "\n"
        "import '../../prompts/elite_human_lyricist.dart';\n"
        "import 'dialect_style_data.dart';\n"
        "\n"
        "/// Elite human lyricist core — Block 2 authenticity.\n"
        "class EliteHumanLyricistDirective {\n"
        "  EliteHumanLyricistDirective._();\n"
        "\n"
        "  /// Back-compat alias for [kEliteHumanLyricist].\n"
        "  static const String directive = kEliteHumanLyricist;\n"
        "\n"
        "  /// Runtime phonetic rule — dialect-aware (injected into user block).\n"
        "  static String buildPhoneticIntegrityRule({String? dialectStyleId}) {\n"
        "    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {\n"
        "      return 'PHONETIC INTEGRITY (runtime): User LYRIC DIALECT is Nigerian Pidgin. '\n"
        "          'DO NOT normalize lyric lines back to standard English. Preserve words like '\n"
        "          \"dey, na, wahala, e don set, small small exactly as intended by the story.\";\n"
        "    }\n"
        "    return 'PHONETIC INTEGRITY (runtime): Do not use trailing apostrophes to simulate '\n"
        "        'loose casual speech (write breathing not breathin, going to not gonna) unless '\n"
        "        'genre/dialect explicitly permits (Reggae/Dub patois, Hip Hop AAVE). '\n"
        "        'Ensures clean phoneme mapping in downstream vocal synthesis.';\n"
        "  }\n"
        "\n"
        "  static String userBlockPrefix({String? dialectStyleId}) {\n"
        "    final phonetic = buildPhoneticIntegrityRule(dialectStyleId: dialectStyleId);\n"
        "    return 'ELITE HUMAN LYRICIST (Block 2 — mandatory craft layer; '\n"
        "        'maintain genre conventions):\\n$directive\\n\\n$phonetic';\n"
        "  }\n"
        "}\n",
        encoding="utf-8",
    )

    # Only elite_human_lyricist.dart is imported at runtime (via elite_human_lyricist_directive.dart).
    # Other prompt fragments (MELODY-SYNC, staging, genre humanization, etc.) live solely inside
    # the merged SYSTEM_PROMPT_V2 body — no separate lib/prompts extract modules.

    print(
        f"Wrote {dart_path.relative_to(root)}, {py_path.relative_to(root)}, "
        f"{elite_dart.relative_to(root)}, {elite_prompt_dart.relative_to(root)} "
        f"from {body_source} ({len(body)} chars, {len(body.splitlines())} lines)"
    )


if __name__ == "__main__":
    main()
    sys.exit(0)
