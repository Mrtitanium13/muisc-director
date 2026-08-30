# tools/songwriter — source of truth for the multi-stage lyric pipeline

Edit here, then:

```bash
python tools/merge_songwriter_prompts.py
# or
python tools/merge_all.py
```

## Layout

| Path | Purpose |
|------|---------|
| `modules/` | Shared prompt sections (role, rhyme, hook, anti-AI, …) |
| `stages/` | Stage 01–12 system prompts (`{{include:…}}` supported) |
| `genres/` | Per-genre writing packs (JSON, versioned GenrePack schema) |
| `languages/` | EN / zh-Hans / zh-Hant / mixed zh-en packs |
| `genre_aliases.json` | Genre name → pack id |
| `quality_modes.json` | fast / balanced / premium / debug stage controls |
| `*.json` | Routing, rubric, forbidden phrases, output modes, arcs, manifest |

## Generated (do not hand-edit)

- `lib/core/constants/songwriter_prompts_data.dart`
- `server/app/songwriter/prompts_data.py`

See `docs/SONGWRITER_LLM_ARCHITECTURE.md`.
