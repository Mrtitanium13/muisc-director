# Songwriter LLM — Implementation Checklist

Execute in order. Check boxes as you complete.

## Phase 0 — Package ready

- [x] `python scripts/validate_songwriter_package.py` exits 0
- [x] Read `docs/SONGWRITER_LLM_ARCHITECTURE.md`
- [x] Confirm `.cursor/rules/songwriter-llm-architecture.mdc` is present

## Phase 1 — Merge + generated artifacts

- [x] Run `python tools/merge_songwriter_prompts.py`
- [x] Confirm generated:
  - `lib/core/constants/songwriter_prompts_data.dart`
  - `server/app/songwriter/prompts_data.py`
- [x] `tools/merge_all.py` includes songwriter merge
- [ ] Run `python tools/merge_all.py` after pack edits

## Phase 2–4 — Live wiring (done in repo)

- [x] `POST /generate-lyrics` + `GET /songwriter/status` mounted in `main.py`
- [x] Real LaoZhang/OpenRouter caller via `chat_simple` + model fallbacks
- [x] Flutter `OpenAIService.generateSongwriterLyrics` + `AiRepository`
- [x] Lyrics UI: Advanced songwriter pipeline toggle + output modes + Run button
- [x] Expand genre JSON packs (≥25 packs + aliases)
- [x] Unit tests: `server/test_songwriter.py` (packs, routing, lint, emit)
- [ ] Golden fixture E2E tests against live keys
- [ ] Optional: divert Path C automatically when pipeline toggle is on

## Phase 5 — Genre + language packs

- [x] Expand `tools/songwriter/genres/*.json` for supported genres
- [x] Language packs: EN, zh-Hans, zh-Hant, zh-EN mixed
- [x] Inject existing `genre_lyrics_user_block` masters into stages 5–7 (chorus/verses/bridge)
- [x] Heavy-lane budget (gospel/EDM/hardstyle/amapiano) so masters are not truncated
- [x] Offline master-lane smoke (amapiano/gospel/hardstyle/edm) — live LLM smoke needs server API key

## Phase 6 — QA + polish

- [x] Deterministic lint hard gates after assembly (`linting.py`)
- [x] Emit modes: hooks / concepts / titles / variations
- [x] Quality modes: fast / balanced / premium / debug
- [x] RoutingDecision + stage telemetry (latency, reason codes)
- [x] Log A/B bucket via `SONGWRITER_AB_BUCKET`
- [ ] Golden fixture tests: 5 genres × 2 languages (live)

## Phase 7 — Ship

- [x] `.env.example` documents new env vars
- [x] `docs/CREATION_PIPELINE.md` updated with songwriter path
- [x] No regressions on `/generate-prompt` with flag off (unchanged path)
