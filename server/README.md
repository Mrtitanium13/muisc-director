# Music Director API (Railway / Docker)

Unified backend for:

- `POST /analyze` — multipart `file` (audio). **Default:** Gemini 2.5 Flash via LaoZhang. Librosa fallback if Gemini is unavailable.
- `POST /generate-prompt` — JSON body. **LaoZhang default:** single Gemini 2.5 Flash call (avoids hybrid truncation). Set `PROMPT_PIPELINE=hybrid` to enable draft + polish.
- `GET /health`

## Local run

Use **Python 3.11** (or 3.12) for native installs. On Windows, **Python 3.14+** may fail on `scipy` (no wheel); use `py -3.11 -m venv .venv` or run via **Docker** below.

```bash
cd server
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
set OPENAI_API_KEY=your-laozhang-key
set PORT=8080
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080 --timeout-keep-alive 300 --timeout-graceful-shutdown 120
```

Test: open `http://localhost:8080/health`

## Railway

1. Create a project → **Deploy from GitHub** (or **Empty project** → **Dockerfile**).
2. Set root directory to `server` if the repo root is the Flutter app.
3. **Variables (LaoZhang default)**:
   - `OPENAI_API_KEY` — **required** for `/generate-prompt` and Gemini `/analyze`. Use a key from [api.laozhang.ai/token](https://api.laozhang.ai/token).
   - `OPENAI_BASE_URL` — optional; defaults to `https://api.laozhang.ai/v1` when unset.
   - `PROMPT_PIPELINE` — `hybrid` (default on LaoZhang lyrics: GPT-6 Astra / Gemini 3.1 Pro draft → Claude lyrics + expression), `two_pass` / `architect` (Pass 1 JSON blueprint → Pass 2 Block 1/2), or `single` (one model).
   - `PROMPT_VISION_MODEL` / `PROMPT_DRAFT_MODEL` — overrides; defaults are Gemini 3.1 Pro English (`gemini-3.1-pro-preview`) and Astra multilingual (`gpt-6-astra`).
   - `PROMPT_LYRICS_MODEL` / `PROMPT_POLISH_MODEL` — LaoZhang lyrics + artistic expression default `claude-sonnet-4-5`.
   - `PROMPT_LYRICS_FALLBACK_MODEL` — last-resort fallback `gemini-2.5-pro`.
   - `HUMANIZATION_PASS=true` — mandatory for lyrics quality (Claude for English · GPT-6 Astra for multilingual/Pidgin).
   - `HUMANIZATION_MULTILINGUAL_MODEL` — optional override (default `gpt-6-astra`).
   - `LAOZHANG_COMPRESSION_MODEL` / bare `SUNO_COMPRESSION_MODEL` — LaoZhang default `gpt-5.6-luna` (OpenRouter vendor slugs ignored on LaoZhang).
   - `PROMPT_STYLE_MODEL` — Block 2 opt-out / style-only default `gemini-2.5-pro`.
   - LaoZhang routing is unchanged when OpenRouter vars are set (provider-scoped resolvers).
   - `OPENAI_MODEL` — if set, forces one model for **single** mode only.
   - `prefer_lightweight_model` in JSON — skips hybrid (Regenerate uses single Flash).
   - `ANALYSIS_MODE=librosa` — skip Gemini; librosa heuristics only.
   - `ANALYSIS_GEMINI=false` — disable Gemini (alias: `ANALYSIS_SEMANTIC=false`).
   - `USE_SUNO_PROMPT_V2` — V2 master prompt is **on by default**. Set `false` for legacy prompt. Rebuild prompt text from repo root: `python tools/merge_suno_v2_prompt.py` (see `tools/README.md`).
   - `CORS_ORIGINS` — optional; default `*`
   - `REQUEST_TIMEOUT_SECONDS` — optional; default `360` (6 min cap per request; hybrid generate)
   - `PROMPT_LLM_TIMEOUT_SECONDS` — optional; default `300` (per upstream LLM call)

   **OpenRouter (optional)** — isolated from LaoZhang defaults:

   - `OPENROUTER_ONLY=true`
   - `OPENROUTER_API_KEY` or `OPENAI_API_KEY` — OpenRouter key
   - `OPENAI_BASE_URL=https://openrouter.ai/api/v1` (implied when `OPENROUTER_ONLY` is on)
   - **Stage 1–2:** `OPENROUTER_GENERATE_MODEL=qwen/qwen3.7-plus`, `THEME_CONSISTENCY_MODEL=qwen/qwen3.7-plus`
   - **Stage 3:** `HUMANIZATION_MODEL=mistralai/mistral-large`
   - **Stage 4–5:** `PROMPT_POLISH_MODEL=qwen/qwen3.7-plus`, `SUNO_COMPRESSION_MODEL=qwen/qwen3.7-plus`
   - `OPENROUTER_HTTP_REFERER` / `OPENROUTER_APP_TITLE` — attribution headers

4. Railway URL → Flutter `.env`:

```env
MD_API_BASE_URL=https://your-service.up.railway.app
```

One variable drives **Gemini audio analysis + server-side Suno prompt generation** (Gemini Pro on LaoZhang, Qwen on OpenRouter).

## Docker (any host)

```bash
cd server
docker build -t music-director-api .
docker run -p 8080:8080 -e OPENAI_API_KEY=your-key -e PORT=8080 music-director-api
```

## Monorepo layout note

If Railway builds from the **repository root**, set **Dockerfile path** to `server/Dockerfile` and **context** to `server`.
