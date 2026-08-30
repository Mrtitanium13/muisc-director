# Suno V2 system prompt — source files

**Do not edit** `lib/core/constants/suno_system_prompt_v2_candidate.dart`, `lib/core/constants/elite_human_lyricist_directive.dart`, or `server/app/suno_system_prompt_v2.py` by hand. They are **generated**.

**Architecture:** [`docs/CREATION_PIPELINE.md`](../docs/CREATION_PIPELINE.md) — canonical stage order.

## Rebuild (required after any edit below)

```bash
python tools/merge_all.py
```

Prompt-only: `python tools/merge_suno_v2_prompt.py`

Outputs:

- `lib/core/constants/suno_system_prompt_v2_candidate.dart`
- `lib/core/constants/elite_human_lyricist_directive.dart`
- `lib/prompts/elite_human_lyricist.dart` (imported by elite directive wrapper)
- `server/app/suno_system_prompt_v2.py`

All other prompt fragments (MELODY-SYNC, staging rules, genre humanization, etc.) are embedded only in the merged V2 system prompt — not emitted as separate `lib/prompts/*.dart` extract files.

## Preferred SYSTEM_PROMPT_V2 source

When present, merge uses this single consolidated body instead of stitching fragments:

| File | Role |
|------|------|
| `suno_v2_system_prompt_body.txt` | Authoritative full SYSTEM_PROMPT_V2 body (deduped SECTION 0/2 / DSE) |

Edit that file for V2 system-prompt changes, then run `python tools/merge_suno_v2_prompt.py`.
`elite_human_lyricist_directive.txt` still regenerates the elite Dart extracts separately.

If `suno_v2_system_prompt_body.txt` is absent, merge falls back to the modular order below.

## Modular merge order (fallback — aligned to creation pipeline)

| Order | File | Role |
|------:|------|------|
| 0 | *(meta line)* | Section D blacklist scan mandate (first line of prompt) |
| 0b | `staging_and_accent_rules.txt` | Staging coherence · accent routing · genre hygiene · Section D blacklist |
| 1 | `suno_v2_p1.txt` | Role paragraph (before `GLOBAL`) |
| 2 | `suno_v4_master_production_architecture.txt` | V4 role · Platinum layers · audit schema |
| 3 | `suno_v2_p0_format_law.txt` | SECTION 0B — caps, precedence, opt-out |
| 4 | `pipeline_architecture.txt` | Two-pass stages 1–17 (Pass 1 Architect → Pass 2 Lyricist → External QA) |
| 4b | `suno_metatag_syntax.txt` | Pass 2 section-stem whitelist (embed/sync into consolidated body) |
| 5 | `artist_dna_translation_engine.txt` | Artist DNA analysis |
| 6 | `suno_v2_architect_vault_snapshot.txt` | Genre vault |
| 7 | `suno_v2_p1.txt` (rest) | Power codes / temperament |
| 8 | `suno_v2_code_translation_protocol.txt` | Power-code translation (runtime matrix companion) |
| 9 | `suno_v2_lyrics_style_full_engine.txt` | SECTION 1A |
| 10 | `suno_v2_variation_engine.txt` | SECTION 1B — genre production vault (canonical catalog) |
| 11 | `suno_v2_advanced_creative_layers.txt` | SECTION 1C |
| 12 | `suno_v2_edm_production_engine.txt` | SECTION 1D |
| 13 | `suno_v2_genre_gear_mapping.txt` | SECTION 1E |
| 14 | `suno_v2_hardware_qc_engine.txt` | Parts F–I hardware QC |
| 15 | `suno_v2_style_narrative_modules_abcd.txt` | Parts A–D narrative modules |
| 16 | `suno_v2_dj_intro_outro_suno_module.txt` | SECTION 1F |
| 17 | `music_creation_intelligence_engine.txt` | Layer 1 extended · `<master_blueprint>` |
| 18 | `hit_song_psychology_engine.txt` | Layer 2 extended · `<psychology_audit>` |
| 19 | `elite_human_lyricist_directive.txt` | Platinum Layer 4.1 micro craft |
| 20 | `human_authenticity_engine.txt` | Authenticity, compression, DJ outro |
| 21 | `nigeria_cultural_realism_engine.txt` | Layer 3.5 · Nigerian cultural realism (before genre lanes) |
| 22 | `genre_specific_humanization_engine.txt` | Layer 3 · genre humanization lanes |
| 22b | `genre_hybridization_cultural_routing_matrix.txt` | Hybrid Split-DNA (PART 1) + anti-repetition cultural routing (PART 2) |
| 23 | `human_songwriter_engine_v3.txt` | Platinum Layer 4 macro · `<lyric_audit>` gate |
| 24 | `suno_v2_p2_block2_protocol.txt` | BLOCK 2 supplementary bans + structure |
| 24b | `dynamic_structural_engine.txt` | Dynamic Structural Engine — version-routed Block 2 assembly |
| 25 | `suno_v2_melody_sync_lyric_engine.txt` | MELODY-SYNC syllable routing |
| 26 | `suno_v2_p2_section2_unified.txt` | SECTION 2 output skeleton |
| 27 | `suno_v2_block2_arrangement_staging_format.txt` | Arrangement staging authority |
| 28 | `suno_v2_block2_genre_structures.txt` | Genre section roadmaps |
| 29 | `suno_v2_genre_specific_lyrics_prompts.txt` | Genre-specific Block 2 prompts |
| 30 | `suno_v2_block1_genre_examples.txt` | Block 1 genre examples |
| 31 | `suno_v2_suno_signal_principles.txt` | Suno Block 1 signal |
| 32 | `suno_v2_p3.txt` | Path dispatch, checklists |
| 33 | `suno_v2_p4.txt` | Genre appendix + artist lexicon (translation only) |
| 34 | `suno_v2_live_instrument_protocol.txt` | Live instrument matrix companion |
| 35 | `suno_v2_genre_mastering_mixing_blueprints.txt` | LUFS / mastering |

## Runtime-only (not merged into SYSTEM_PROMPT_V2)

| File | Used by |
|------|---------|
| `theme_consistency_pass.txt` | OpenRouter / LaoZhang theme pass |
| `humanization_pass.txt` | OpenRouter + LaoZhang humanization pass |
| `suno_compression_pass.txt` | OpenRouter Qwen compression |
| `genre_fx_matrix.json` | Suno Prompt Builder — genre FX by intensity (runtime) |
| `lib/core/constants/suno_polish_system_prompt.dart` | Optional hybrid polish |
| `lib/core/constants/suno_system_prompt.dart` | Legacy v1 (`USE_SUNO_PROMPT_V2=false`) |
| `server/app/suno_output_qa.py` | Server format retry |
| `lib/core/utils/suno_format_validation.dart` | Client quality score + retry |
| `lib/core/utils/suno_internal_output_strip.dart` | Strips internal cognition XML from output |

## Matrix JSON sources (runtime user-block injection)

| JSON | Generator | Runtime |
|------|-----------|---------|
| `drum_matrix.json` | `gen_drum_matrix_dart.py` | `drum_matrix.dart` / `drum_matrix.py` |
| `live_instrument_matrix.json` | `gen_live_instrument_matrix_dart.py` | `live_instrument_matrix.*` |
| `code_translation_matrix.json` | `gen_code_translation_matrix_dart.py` | `code_translation_matrix.*` |
| `genre_hardware_profiles_v2_1.json` | `expand_genre_hardware_158.py` then `gen_genre_hardware_modules.py` | `lib/data/generated/genre_hardware_profiles_data.dart` + `lib/services/genre_hardware_profiles.dart` / `genre_hardware_profiles.py` |
| `genre_fx_matrix.json` | `gen_genre_fx_matrix_dart.py` | `suno_prompt_builder.dart` / `suno_prompt_builder.py` |

## Removed (do not restore)

- `suno_v2_p2.txt` — replaced by `human_songwriter_engine_v3.txt` + `suno_v2_p2_block2_protocol.txt`
- `extract_v2_prompt.py` — superseded by `merge_suno_v2_prompt.py`
- `suno_v2_master_prompt.txt` — duplicate of merged body
- Root `amapianoDataset.json`, `hardstyleDataset.json`, `futureHouseDataset.json` — duplicates of `tools/lyrics_training/*`; use tools path only
- `advancedThematicVariator.js` — superseded by `server/app/advanced_thematic_variator.py` + `lib/core/utils/advanced_thematic_variator.dart`
- `lib/presentation/screens/prompt/prompt_generator_screen.dart` — re-export shim; router uses `lib/features/prompt_generator/screens/prompt_generator_screen.dart`
- `lib/prompts/{melody_sync,genre_humanization_engine,arrangement_staging_format,staging_and_accent_rules,genre_hybridization_cultural_routing}.dart` — unused V2 extract duplicates; content lives in merged SYSTEM_PROMPT_V2 only
- `tools/lyrics_training/universalLyricStructureTemplate.txt` — superseded by `tools/dynamic_structural_engine.txt`
- `tools/accent_routing_engine.txt` — superseded by `tools/staging_and_accent_rules.txt` (Section B)
