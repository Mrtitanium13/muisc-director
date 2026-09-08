# Songwriter LLM Architecture — Implementation Package

> **Purpose:** Everything required to redesign Music Director’s lyric system into a world-class multi-stage songwriter AI — without breaking the existing Suno Block 1+2 pipeline.

> **Status:** Scaffold + source-of-truth configs ready. Wire runtime, run merge, then iterate stage-by-stage.

---

## 1. What already exists (do not reinvent)

| Asset | Location | Reuse how |
|-------|----------|-----------|
| Suno monolith system prompt | `tools/` → `merge_suno_v2_prompt.py` | Keep for Block 1+2 style generation |
| Genre lyric engines | `tools/genre_lyric_routing.json`, masters | Inject into stages 5–7 & 10 |
| Hybrid draft→polish | `server/app/prompt_pipeline.py` | Pattern for multi-call stages |
| Architect JSON pass | `server/app/architect_pass.py` | Pattern for stage contracts |
| Humanization / theme / compression | `*_post_process.py` | Fold into stages 10–12 |
| Heuristic QA | `humanized_lyrics_qa.dart`, `meaningfulness_check.dart` | Deterministic gate after LLM judge |
| Stage1/2 regional routing | `lib/core/routing/*` | Extend, don’t fork |
| Merge convention | `tools/merge_all.py` | Add `merge_songwriter_prompts.py` |

---

## 2. Target architecture

```
User brief (genre, mood, theme, language, …)
        │
        ▼
┌───────────────────┐
│ Songwriter Router │  ← tools/songwriter/model_routing.json
└─────────┬─────────┘
          │
   Stage 1 Analyze brief          → JSON SongBrief
   Stage 2 Generate concepts      → N concepts + scores
   Stage 3 Select concept         → locked Concept
   Stage 4 Emotional arc          → Arc template
   Stage 5 Chorus / hook engine   → ≥10 hooks → pick best
   Stage 6 Verses                 → Verse draft
   Stage 7 Bridge                 → Bridge draft
   Stage 8 Transitions            → Full draft
   Stage 9 Rhyme engine           → Rhyme-optimized draft
   Stage 10 Anti-AI rewrite         → Cleaned draft
   Stage 11 Singability           → Performance draft
   Stage 12 Final polish + judge  → Score ≥ threshold → ship
        │
        ▼
Output mode adapter (full / chorus / rewrite / …)
        │
        ├── /generate-lyrics  (lyrics-only API)
        └── Optional: inject Block 2 into existing /generate-prompt
```

**Backward compatibility:** Default product path remains Suno Block 1+2. New path is opt-in via `SONGWRITER_PIPELINE=1` or UI “Advanced songwriter pipeline”.

---

## 3. Package inventory (this deliverable)

### Config (source of truth)

| File | Role |
|------|------|
| `tools/songwriter/model_routing.json` | Tier 1/2 models + genre/language → model map |
| `tools/songwriter/quality_rubric.json` | Score dimensions + ship threshold |
| `tools/songwriter/forbidden_phrases.json` | AI cliché blacklist |
| `tools/songwriter/output_modes.json` | 12 output modes |
| `tools/songwriter/story_arcs.json` | Emotional progression templates |
| `tools/songwriter/pipeline_manifest.json` | Stage order, contracts, A/B versions |

### Modular prompts

| Path | Role |
|------|------|
| `tools/songwriter/modules/*.txt` | Shared: role, principles, forbidden, rhyme, hook, format |
| `tools/songwriter/stages/stage_*.txt` | Per-stage system prompts |
| `tools/songwriter/genres/*.json` | Per-genre writing rules (extendable) |

### Code scaffolding

| Path | Role |
|------|------|
| `tools/merge_songwriter_prompts.py` | Merge → Dart + Python generated modules |
| `server/app/songwriter/` | Pipeline, router, stages, API route |
| `lib/songwriter/` | Models, pipeline client, QA bridge |
| `scripts/validate_songwriter_package.py` | Sanity-check package completeness |

### Agent guidance

| Path | Role |
|------|------|
| `.cursor/rules/songwriter-llm-architecture.mdc` | Mandatory conventions for implementing agents |
| `docs/SONGWRITER_IMPLEMENTATION_CHECKLIST.md` | Ordered implementation checklist |

---

## 4. Model routing (summary)

| Signal | Preferred model (LaoZhang / OpenRouter slug) |
|--------|-----------------------------------------------|
| English Pop / EDM / Afrobeats | GPT-6 Astra |
| Country / Rock / Metal / Gospel | Claude Opus / Sonnet |
| Mandopop / Chinese ballads | Kimi |
| Chinese Rap | DeepSeek |
| Mixed ZH+EN | Qwen |
| Fallback | Gemini 2.5 Pro |
| Tier 2 pool | Kimi, DeepSeek, Qwen, GLM, ERNIE |

Exact IDs live in `model_routing.json` (provider-aware).

---

## 5. How to implement (ordered)

1. **Validate package:** `python scripts/validate_songwriter_package.py`
2. **Merge prompts:** `python tools/merge_songwriter_prompts.py` then wire into `merge_all.py`
3. **Extend `llm_config.py`:** `resolve_songwriter_model(stage, genre, language, provider)`
4. **Implement server pipeline:** `songwriter_pipeline.py` stage loop + JSON schema validation
5. **Add route:** `POST /generate-lyrics` in `main.py`
6. **Dart client:** `SongwriterService` + optional UI toggle in `lyrics_section.dart`
7. **QA gate:** LLM judge JSON → merge with `HumanizedLyricsQa` / threshold from `quality_rubric.json`
8. **A/B:** Use `pipeline_manifest.json` `version` + `ab_bucket` env
9. **Do not** bloat the 150k Suno system prompt with all 12 stages — keep lyric stages separate

---

## 6. Success criteria

- [ ] English Pop lyrics pass internal score ≥ 90 without forbidden-phrase hits
- [ ] Mandopop routes to Kimi (when key/provider available) else Qwen/GLM fallback
- [ ] Chorus-first path produces locked hook before verses
- [ ] Output modes 1–12 work via API
- [ ] Existing `/generate-prompt` unchanged when songwriter pipeline is off
- [ ] `python tools/merge_all.py` regenerates songwriter artifacts

---

## 7. Non-goals (v1)

- Training / fine-tuning new weights
- Replacing Suno Block 1 style generation
- Native Anthropic/OpenAI SDKs (stay OpenAI-compatible via LaoZhang / OpenRouter)
