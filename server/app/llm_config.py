"""Shared LLM gateway config: LaoZhang (default) or OpenRouter."""

from __future__ import annotations

import os
from typing import Any

from app.dialect_style import is_nigerian_pidgin

LAOZHANG_BASE_URL = "https://api.laozhang.ai/v1"
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

# LaoZhang Gemini (large context for ~150k-char Suno system prompt + /analyze)
LAOZHANG_GEMINI_FLASH = "gemini-2.5-flash"
LAOZHANG_GEMINI_PRO = "gemini-2.5-pro"
LAOZHANG_GEMINI_31_PRO = "gemini-3.1-pro-preview"

# LaoZhang capability ladder (cost ↑): Luna → Terra → Sol → GPT-6 Astra
# Lyrics engine (must be humanized):
#   Astra  = multilingual draft + multilingual/Pidgin humanization + songwriter lyric stages
#   Claude = English lyrics polish / theme / English humanization
#   Sol    = songwriter creative fallback
#   Gemini 3.1 Pro = English Suno draft (structure) — not the humanization lane
#   Terra  = songwriter structure/select (legacy)
#   Luna   = mechanical compression / analyze·select only
LAOZHANG_GPT_6_ASTRA = "gpt-6-astra"
LAOZHANG_GPT_56_SOL = "gpt-5.6-sol"
LAOZHANG_GPT_56_TERRA = "gpt-5.6-terra"
LAOZHANG_GPT_56_LUNA = "gpt-5.6-luna"
# Multilingual / Pidgin draft (frontier — full capability)
LAOZHANG_PROMPT_MODEL = LAOZHANG_GPT_6_ASTRA
LAOZHANG_VISION_MODEL = LAOZHANG_PROMPT_MODEL
LAOZHANG_CLAUDE_SONNET_45 = "claude-sonnet-4-5"
LAOZHANG_LYRICS_PRIMARY_MODEL = LAOZHANG_CLAUDE_SONNET_45
LAOZHANG_LYRICS_SECONDARY_MODEL = LAOZHANG_GEMINI_PRO

# OpenRouter pipeline (see tools/pipeline_architecture.txt — RUNTIME POST-PROCESSING)
# Qwen 3.7 Plus → generate · theme · polish · compression | Mistral Large → humanization
OPENROUTER_GENERATE_MODEL = "qwen/qwen3.7-plus"
OPENROUTER_THEME_CONSISTENCY_MODEL = "qwen/qwen3.7-plus"
OPENROUTER_HUMANIZATION_MODEL = "mistralai/mistral-large"
OPENROUTER_COMPRESSION_MODEL = "qwen/qwen3.7-plus"
OPENROUTER_POLISH_MODEL = OPENROUTER_GENERATE_MODEL
OPENROUTER_PRIMARY_MODEL = OPENROUTER_GENERATE_MODEL
OPENROUTER_MULTILINGUAL_MODEL = OPENROUTER_GENERATE_MODEL
OPENROUTER_LIGHT_MODEL = "openai/gpt-4o-mini"

# LaoZhang style-only (Block 2 opt-out): Gemini Pro for full system prompt context
LAOZHANG_STYLE_ONLY_MODEL = LAOZHANG_GEMINI_PRO
# English production draft (balanced structure — Claude + Astra humanize lyrics after)
LAOZHANG_DRAFT_MODEL = LAOZHANG_GEMINI_31_PRO
# Multilingual / Pidgin draft (Astra)
LAOZHANG_DRAFT_MULTILINGUAL_MODEL = LAOZHANG_GPT_6_ASTRA
LAOZHANG_PRIMARY_MODEL = LAOZHANG_DRAFT_MODEL
LAOZHANG_MULTILINGUAL_MODEL = LAOZHANG_DRAFT_MULTILINGUAL_MODEL
LAOZHANG_LIGHT_MODEL = LAOZHANG_GEMINI_FLASH
LAOZHANG_FALLBACK_MODEL = LAOZHANG_LYRICS_SECONDARY_MODEL
LAOZHANG_POLISH_MODEL = LAOZHANG_LYRICS_PRIMARY_MODEL
# Humanization is mandatory for lyrics quality — Astra for multilingual/Pidgin/African
LAOZHANG_HUMANIZATION_MULTILINGUAL_MODEL = LAOZHANG_GPT_6_ASTRA
# English humanization stays Claude (lived-in phrasing)
LAOZHANG_HUMANIZATION_ENGLISH_MODEL = LAOZHANG_LYRICS_PRIMARY_MODEL
# Suno cap compression (mechanical — never the humanization lane)
LAOZHANG_COMPRESSION_MODEL = LAOZHANG_GPT_56_LUNA

# Theme consistency post-pass (Block 2 editorial): same tier as polish — narrative + cadence
LAOZHANG_THEME_CONSISTENCY_MODEL = LAOZHANG_LYRICS_PRIMARY_MODEL

# Audio analysis (Gemini 2.5 via LaoZhang)
LAOZHANG_ANALYSIS_MODEL = LAOZHANG_GEMINI_FLASH


def _truthy(name: str) -> bool:
    return os.getenv(name, "").strip().lower() in ("1", "true", "yes", "on")


def _env_for_openrouter(*keys: str) -> str:
    """First non-empty env value — OpenRouter routing only (must not affect LaoZhang)."""
    for key in keys:
        val = os.getenv(key, "").strip()
        if val:
            return val
    return ""


def _is_openrouter_vendor_slug(model: str) -> bool:
    """OpenRouter ids use vendor/model (e.g. qwen/qwen3.7-plus); LaoZhang uses bare ids."""
    return "/" in model


def prefer_laozhang_multilingual_humanization(
    *,
    language: str = "English",
    dialect_style_id: str = "",
) -> bool:
    """Astra humanization for non-English, Nigerian Pidgin, and African lyric contexts."""
    if is_nigerian_pidgin(dialect_style_id):
        return True
    return prefer_multilingual_primary(language)


def prefer_multilingual_primary(language: str) -> bool:
    t = (language or "").strip().lower()
    if not t:
        return False
    if t == "english":
        return False
    if t.startswith("english ") or t.startswith("english(") or t.startswith("english,"):
        return False
    return True


def normalize_llm_provider(name: str | None) -> str:
    """laozhang | openrouter (request/body override or LLM_PROVIDER env)."""
    if _truthy("OPENROUTER_ONLY"):
        return "openrouter"
    raw = (name or os.getenv("LLM_PROVIDER", "")).strip().lower()
    if raw in ("openrouter", "or", "open_router"):
        return "openrouter"
    return "laozhang"


def llm_provider(override: str | None = None) -> str:
    """laozhang | openrouter | openai (custom base URL)."""
    if override:
        return normalize_llm_provider(override)
    if _truthy("OPENROUTER_ONLY"):
        return "openrouter"
    base = os.getenv("OPENAI_BASE_URL", "").strip().lower()
    if "openrouter.ai" in base:
        return "openrouter"
    if "laozhang.ai" in base:
        return "laozhang"
    if base:
        return "openai"
    env_prov = os.getenv("LLM_PROVIDER", "").strip()
    if env_prov:
        return normalize_llm_provider(env_prov)
    return "laozhang"


def resolve_base_url() -> str:
    explicit = os.getenv("OPENAI_BASE_URL", "").strip()
    if _truthy("OPENROUTER_ONLY"):
        return explicit or OPENROUTER_BASE_URL
    if explicit:
        return explicit.rstrip("/")
    return LAOZHANG_BASE_URL


def resolve_analysis_model() -> str:
    return os.getenv("ANALYSIS_GEMINI_MODEL", "").strip() or LAOZHANG_ANALYSIS_MODEL


def analysis_gemini_enabled(
    *,
    laozhang_api_key: str | None = None,
    openrouter_api_key: str | None = None,
) -> bool:
    """Gemini 2.5 full audio analysis unless ANALYSIS_MODE=librosa."""
    mode = os.getenv("ANALYSIS_MODE", "").strip().lower()
    if mode == "librosa":
        return False
    if os.getenv("ANALYSIS_GEMINI", "").strip().lower() in ("0", "false", "no", "off"):
        return False
    if os.getenv("ANALYSIS_SEMANTIC", "").strip().lower() in ("0", "false", "no", "off"):
        return False
    return bool(
        os.getenv("OPENAI_API_KEY", "").strip()
        or os.getenv("OPENROUTER_API_KEY", "").strip()
        or (laozhang_api_key or "").strip()
        or (openrouter_api_key or "").strip()
    )


def analysis_semantic_enabled() -> bool:
    """Alias for [analysis_gemini_enabled]."""
    return analysis_gemini_enabled()


def prompt_pipeline_mode() -> str:
    """Normalized PROMPT_PIPELINE: single | hybrid | two_pass | auto."""
    mode = os.getenv("PROMPT_PIPELINE", "").strip().lower()
    if mode in ("single", "hybrid", "two_pass", "architect", "2pass"):
        if mode in ("architect", "2pass"):
            return "two_pass"
        return mode
    return "auto"


def two_pass_prompt_enabled(
    *,
    lightweight: bool = False,
    lyrics_task: bool = True,
) -> bool:
    """Architect JSON → Lyricist Block 1/2 when PROMPT_PIPELINE=two_pass (or architect)."""
    if lightweight or not lyrics_task:
        return False
    return prompt_pipeline_mode() == "two_pass"


def hybrid_prompt_enabled(
    *,
    lightweight: bool = False,
    provider: str | None = None,
    lyrics_task: bool = True,
) -> bool:
    """LaoZhang lyrics: Gemini 3.1 Pro English / Astra multilingual draft → Claude lyrics polish (default). OpenRouter: opt-in."""
    if lightweight:
        return _truthy("PROMPT_HYBRID_LIGHTWEIGHT")
    mode = prompt_pipeline_mode()
    if mode in ("single", "two_pass"):
        return False
    if mode == "hybrid":
        return True
    # auto
    prov = llm_provider(provider)
    if prov == "laozhang" and lyrics_task:
        return True
    return _truthy("PROMPT_HYBRID")


def _resolve_openrouter_tier_model(
    *, language: str, lightweight: bool, provider: str | None
) -> str:
    """OpenRouter: Qwen 3.7 generate (all languages); GPT-mini when lightweight."""
    if lightweight:
        return os.getenv("OPENAI_LIGHT_MODEL", "").strip() or OPENROUTER_LIGHT_MODEL
    return (
        os.getenv("OPENROUTER_GENERATE_MODEL", "").strip()
        or os.getenv("OPENAI_PRIMARY_MODEL", "").strip()
        or OPENROUTER_GENERATE_MODEL
    )


def _resolve_laozhang_tier_model(
    *,
    language: str,
    lightweight: bool,
    provider: str | None,
    lyrics_task: bool = True,
) -> str:
    """LaoZhang: Astra multilingual draft · Gemini 3.1 Pro English draft · Gemini 2.5 Pro style-only · Flash light."""
    if lightweight:
        return os.getenv("OPENAI_LIGHT_MODEL", "").strip() or LAOZHANG_LIGHT_MODEL
    if not lyrics_task:
        return (
            os.getenv("PROMPT_STYLE_MODEL", "").strip()
            or os.getenv("OPENAI_PRIMARY_MODEL", "").strip()
            or LAOZHANG_STYLE_ONLY_MODEL
        )
    # Explicit draft override applies to all languages (ops / A-B).
    vision = (
        os.getenv("PROMPT_VISION_MODEL", "").strip()
        or os.getenv("PROMPT_DRAFT_MODEL", "").strip()
    )
    if vision:
        return vision
    if prefer_multilingual_primary(language):
        return (
            os.getenv("OPENAI_MULTILINGUAL_MODEL", "").strip()
            or os.getenv("PROMPT_DRAFT_MULTILINGUAL_MODEL", "").strip()
            or LAOZHANG_DRAFT_MULTILINGUAL_MODEL
        )
    return (
        os.getenv("OPENAI_PRIMARY_MODEL", "").strip()
        or LAOZHANG_DRAFT_MODEL
    )


def resolve_laozhang_lyrics_secondary_model() -> str:
    """Fallback when Claude Sonnet 4.5 lyrics generation fails or returns truncated output."""
    return (
        os.getenv("PROMPT_LYRICS_FALLBACK_MODEL", "").strip()
        or os.getenv("OPENAI_FALLBACK_MODEL", "").strip()
        or LAOZHANG_LYRICS_SECONDARY_MODEL
    )


def resolve_draft_model(
    *,
    language: str,
    lightweight: bool = False,
    provider: str | None = None,
    lyrics_task: bool = True,
) -> str:
    """Primary Suno draft model (hybrid draft or single-path)."""
    explicit = os.getenv("PROMPT_DRAFT_MODEL", "").strip()
    if explicit:
        return explicit
    prov = llm_provider(provider)
    if prov == "openrouter":
        return _resolve_openrouter_tier_model(
            language=language, lightweight=lightweight, provider=provider
        )
    if prov == "laozhang":
        return _resolve_laozhang_tier_model(
            language=language,
            lightweight=lightweight,
            provider=provider,
            lyrics_task=lyrics_task,
        )
    if lightweight:
        return resolve_chat_model(language=language, lightweight=True, provider=provider)
    if prefer_multilingual_primary(language):
        return (
            os.getenv("PROMPT_DRAFT_MULTILINGUAL_MODEL", "").strip()
            or os.getenv("OPENAI_MULTILINGUAL_MODEL", "").strip()
            or LAOZHANG_DRAFT_MULTILINGUAL_MODEL
        )
    return os.getenv("OPENAI_PRIMARY_MODEL", "").strip() or LAOZHANG_DRAFT_MODEL


def resolve_polish_model(*, provider: str | None = None, lyrics_task: bool = True) -> str:
    prov = llm_provider(provider)
    if prov == "openrouter":
        or_model = _env_for_openrouter(
            "OPENROUTER_POLISH_MODEL",
            "PROMPT_POLISH_MODEL",
            "OPENROUTER_GENERATE_MODEL",
            "OPENAI_PRIMARY_MODEL",
        )
        if or_model:
            return or_model
        return OPENROUTER_POLISH_MODEL
    explicit = os.getenv("PROMPT_POLISH_MODEL", "").strip()
    if explicit and not _is_openrouter_vendor_slug(explicit):
        return explicit
    if lyrics_task:
        return (
            os.getenv("PROMPT_LYRICS_MODEL", "").strip()
            or LAOZHANG_LYRICS_PRIMARY_MODEL
        )
    return LAOZHANG_STYLE_ONLY_MODEL


def resolve_theme_consistency_model(
    *,
    language: str = "English",
    provider: str | None = None,
) -> str:
    """
    Block 2 theme-consistency pass.

    LaoZhang: Claude Sonnet 4.5. OpenRouter: Qwen 3.7 Plus.
    OpenRouter overrides: OPENROUTER_THEME_MODEL / THEME_CONSISTENCY_MODEL (ignored on LaoZhang).
    """
    if llm_provider(provider) == "openrouter":
        or_model = _env_for_openrouter(
            "OPENROUTER_THEME_MODEL",
            "THEME_CONSISTENCY_MODEL",
        )
        if or_model:
            return or_model
        return OPENROUTER_THEME_CONSISTENCY_MODEL
    if prefer_multilingual_primary(language):
        return (
            os.getenv("OPENAI_MULTILINGUAL_MODEL", "").strip()
            or LAOZHANG_THEME_CONSISTENCY_MODEL
        )
    return (
        os.getenv("PROMPT_LYRICS_MODEL", "").strip()
        or LAOZHANG_THEME_CONSISTENCY_MODEL
    )


def resolve_humanization_model(
    *,
    provider: str | None = None,
    language: str = "English",
    dialect_style_id: str = "",
) -> str:
    """
    OpenRouter: Mistral Large.
    LaoZhang lyrics engine (must be humanized):
      Claude English · GPT-6 Astra multilingual / Pidgin / African.
    """
    if llm_provider(provider) == "openrouter":
        or_model = _env_for_openrouter(
            "OPENROUTER_HUMANIZATION_MODEL",
            "HUMANIZATION_MODEL",
        )
        if or_model:
            return or_model
        return OPENROUTER_HUMANIZATION_MODEL
    if prefer_laozhang_multilingual_humanization(
        language=language, dialect_style_id=dialect_style_id
    ):
        return (
            os.getenv("HUMANIZATION_MULTILINGUAL_MODEL", "").strip()
            or LAOZHANG_HUMANIZATION_MULTILINGUAL_MODEL
        )
    return (
        os.getenv("PROMPT_LYRICS_MODEL", "").strip()
        or LAOZHANG_HUMANIZATION_ENGLISH_MODEL
    )


def resolve_compression_model(*, provider: str | None = None) -> str:
    """OpenRouter: Qwen 3.7 Plus. LaoZhang: Luna (mechanical Suno caps)."""
    if llm_provider(provider) == "openrouter":
        or_model = _env_for_openrouter(
            "OPENROUTER_COMPRESSION_MODEL",
            "SUNO_COMPRESSION_MODEL",
        )
        if or_model:
            return or_model
        return OPENROUTER_COMPRESSION_MODEL
    # LaoZhang-only override; ignore OpenRouter vendor slugs in shared env.
    explicit = os.getenv("LAOZHANG_COMPRESSION_MODEL", "").strip() or os.getenv(
        "SUNO_COMPRESSION_MODEL", ""
    ).strip()
    if explicit and not _is_openrouter_vendor_slug(explicit):
        return explicit
    return LAOZHANG_COMPRESSION_MODEL


def resolve_theme_consistency_fallback_model(*, provider: str | None = None) -> str:
    """Secondary when primary theme pass fails (LaoZhang: Gemini Pro)."""
    if llm_provider(provider) == "openrouter":
        or_fb = _env_for_openrouter("OPENROUTER_FALLBACK_MODEL", "OPENAI_FALLBACK_MODEL")
        if or_fb:
            return or_fb
        return OPENROUTER_LIGHT_MODEL
    explicit = os.getenv("THEME_CONSISTENCY_FALLBACK_MODEL", "").strip()
    if explicit:
        return explicit
    if llm_provider(provider) == "laozhang":
        return resolve_laozhang_lyrics_secondary_model()
    return os.getenv("OPENAI_FALLBACK_MODEL", "").strip() or OPENROUTER_LIGHT_MODEL


def resolve_chat_model(
    *, language: str, lightweight: bool = False, provider: str | None = None,
    lyrics_task: bool = True,
) -> str:
    explicit = os.getenv("OPENAI_MODEL", "").strip()
    if explicit:
        return explicit

    prov = llm_provider(provider)
    if prov == "openrouter":
        return _resolve_openrouter_tier_model(
            language=language, lightweight=lightweight, provider=provider
        )
    if prov == "laozhang":
        return _resolve_laozhang_tier_model(
            language=language,
            lightweight=lightweight,
            provider=provider,
            lyrics_task=lyrics_task,
        )

    # Generic OpenAI-compatible host
    if lightweight:
        return os.getenv("OPENAI_LIGHT_MODEL", "").strip() or LAOZHANG_LIGHT_MODEL
    if prefer_multilingual_primary(language):
        return (
            os.getenv("OPENAI_MULTILINGUAL_MODEL", "").strip()
            or LAOZHANG_MULTILINGUAL_MODEL
        )
    return os.getenv("OPENAI_PRIMARY_MODEL", "").strip() or resolve_draft_model(
        language=language, lightweight=False, provider=provider
    )


def resolve_api_key(
    provider: str | None,
    *,
    laozhang_api_key: str | None = None,
    openrouter_api_key: str | None = None,
) -> str:
    """Server env first, then optional keys from the Flutter app."""
    prov = llm_provider(provider)
    lz = (laozhang_api_key or "").strip()
    ork = (openrouter_api_key or "").strip()
    if prov == "openrouter":
        return (
            os.getenv("OPENROUTER_API_KEY", "").strip()
            or os.getenv("OPENAI_API_KEY", "").strip()
            or ork
        )
    return os.getenv("OPENAI_API_KEY", "").strip() or lz


def resolve_base_url_for_provider(provider: str | None) -> str:
    prov = llm_provider(provider)
    if prov == "openrouter":
        explicit = os.getenv("OPENAI_BASE_URL", "").strip()
        if explicit and "openrouter.ai" in explicit.lower():
            return explicit.rstrip("/")
        return OPENROUTER_BASE_URL
    return resolve_base_url()


def build_openai_client_kwargs_for_request(
    *,
    llm_provider_name: str | None = None,
    laozhang_api_key: str | None = None,
    openrouter_api_key: str | None = None,
) -> dict[str, Any]:
    """Build OpenAI SDK client config for one request (LaoZhang or OpenRouter)."""
    prov = llm_provider(llm_provider_name)
    key = resolve_api_key(
        prov,
        laozhang_api_key=laozhang_api_key,
        openrouter_api_key=openrouter_api_key,
    )
    base_url = resolve_base_url_for_provider(prov)
    kwargs: dict[str, Any] = {
        "api_key": key,
        "base_url": base_url,
        "timeout": prompt_llm_timeout_seconds(),
    }
    referer = os.getenv("OPENROUTER_HTTP_REFERER", "").strip()
    title = os.getenv("OPENROUTER_APP_TITLE", "").strip()
    if prov == "openrouter" or "openrouter.ai" in base_url.lower():
        if not referer:
            referer = "https://music-director.app"
        if not title:
            title = "Music Director"
        kwargs["default_headers"] = {
            **({"HTTP-Referer": referer} if referer else {}),
            **({"X-Title": title} if title else {}),
        }
    return kwargs


def missing_api_key_message(provider: str | None) -> str:
    prov = llm_provider(provider)
    if prov == "openrouter":
        return (
            "No OpenRouter API key. Set OPENROUTER_API_KEY on the server (Railway), "
            "or save an OpenRouter key in the app Settings and choose OpenRouter."
        )
    return (
        "No LaoZhang API key. Set OPENAI_API_KEY on the server (Railway/local), "
        "or save a LaoZhang key in the app Settings (api.laozhang.ai/token)."
    )


def resolve_fallback_model(*, provider: str | None = None, lyrics_task: bool = True) -> str:
    explicit = os.getenv("OPENAI_FALLBACK_MODEL", "").strip()
    if explicit:
        return explicit
    prov = llm_provider(provider)
    if prov == "openrouter":
        return os.getenv("OPENROUTER_FALLBACK_MODEL", "").strip() or "anthropic/claude-3.5-haiku"
    if lyrics_task:
        return resolve_laozhang_lyrics_secondary_model()
    return LAOZHANG_STYLE_ONLY_MODEL


def prompt_llm_timeout_seconds() -> float:
    """Per upstream chat completion (draft or polish)."""
    raw = os.getenv("PROMPT_LLM_TIMEOUT_SECONDS", "300").strip()
    try:
        return float(max(60.0, min(float(raw), 540.0)))
    except ValueError:
        return 300.0


def completion_token_kwargs(model: str, max_tokens: int) -> dict[str, int]:
    """Return the correct max-token field for the model.

    gpt-5.x / gpt-6.x / o-series reject ``max_tokens`` and require ``max_completion_tokens``.
    Sending both causes a 400 and wasted fallback calls (credits burn, no lyrics).
    """
    model_l = (model or "").strip().lower()
    # Models that reject max_tokens when max_completion_tokens is required.
    if (
        model_l.startswith("gpt-5")
        or model_l.startswith("gpt-6")
        or model_l.startswith("o1")
        or model_l.startswith("o3")
        or model_l.startswith("o4")
        or "/gpt-5" in model_l
        or "/gpt-6" in model_l
        or "gemini" in model_l
    ):
        return {"max_completion_tokens": int(max_tokens)}
    return {"max_tokens": int(max_tokens)}


def build_openai_client_kwargs() -> dict[str, Any]:
    """Default client from server environment only."""
    return build_openai_client_kwargs_for_request()
