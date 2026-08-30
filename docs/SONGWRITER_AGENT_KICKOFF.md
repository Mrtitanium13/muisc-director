# Agent kickoff prompt — Songwriter LLM architecture

Copy-paste this into a new Cursor agent chat to continue implementation:

---

Implement the Music Director multi-stage songwriter lyric system using the package already in the repo.

**Read first:**
1. `docs/SONGWRITER_LLM_ARCHITECTURE.md`
2. `docs/SONGWRITER_IMPLEMENTATION_CHECKLIST.md`
3. `.cursor/rules/songwriter-llm-architecture.mdc`

**Validate:**
```bash
python scripts/validate_songwriter_package.py
python tools/merge_songwriter_prompts.py
```

**Do this next (Phase 2–4):**
1. Wire `resolve_logical_model` into `server/app/llm_config.py` (or call `app.songwriter.router` from there).
2. Implement a real LLM caller for `SongwriterPipeline` using the existing LaoZhang/OpenRouter chat path in `prompt_pipeline.py`.
3. Mount `app.songwriter.routes.router` in `main.py` behind `SONGWRITER_PIPELINE=1`.
4. Connect `lib/songwriter/services/songwriter_service.dart` to the app HTTP client.
5. Add UI toggle + output mode selector in `lyrics_section.dart` (opt-in; default path unchanged).
6. Keep `/generate-prompt` working with the flag off.
7. After any `tools/songwriter/**` edit, run merge.

**Do not** dump the 12 stages into the Suno 150k system prompt.

---
