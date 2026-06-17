# Music Director

Flutter app + optional FastAPI server (`server/`) for Suno prompt generation.

## Environment

Copy [`.env.example`](.env.example) to `.env`. **V2 master prompt** (Path A/B/C, Human Songwriter Engine, genre appendix) is the default; set `USE_SUNO_PROMPT_V2=false` to use the legacy word-budget system prompt.

Creation pipeline (User Input → Artist DNA → … → Suno prompt): [`docs/CREATION_PIPELINE.md`](docs/CREATION_PIPELINE.md).

Edit prompt sources under `tools/` (see [`tools/README.md`](tools/README.md)), then rebuild embedded copies:

```bash
python tools/merge_all.py
```

Server deploy notes: [`server/README.md`](server/README.md).
