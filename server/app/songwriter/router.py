"""Songwriter model router — loads tools/songwriter/model_routing.json."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any

_ROOT = Path(__file__).resolve().parents[3]
_ROUTING_PATH = _ROOT / "tools" / "songwriter" / "model_routing.json"
_POLICY_VERSION = "songwriter-routing-1.0.0"


@dataclass
class ModelTarget:
    logical: str
    slug: str
    provider: str


@dataclass
class RoutingDecision:
    primary: ModelTarget
    fallbacks: list[ModelTarget] = field(default_factory=list)
    reason_codes: list[str] = field(default_factory=list)
    policy_version: str = _POLICY_VERSION
    experiment_id: str | None = None
    constraints: dict[str, Any] = field(default_factory=dict)
    route_id: str = "default"
    stage: str = "polish"

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        return d


@lru_cache(maxsize=1)
def load_routing() -> dict[str, Any]:
    if _ROUTING_PATH.is_file():
        return json.loads(_ROUTING_PATH.read_text(encoding="utf-8"))
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        return SONGWRITER_PROMPTS.get("model_routing", {})
    except Exception:
        return {}


def _norm(s: str) -> str:
    return (s or "").strip().lower()


def match_route(genre: str, language: str) -> dict[str, Any]:
    data = load_routing()
    routes = data.get("routes") or []
    g = _norm(genre)
    lang = _norm(language)
    for route in routes:
        if route.get("id") == "default":
            continue
        match = route.get("match") or {}
        langs = [_norm(x) for x in match.get("languages") or []]
        genres = [_norm(x) for x in match.get("genres") or []]
        lang_ok = "*" in langs or any(l in lang or lang in l for l in langs)
        if "zh-en" in langs or "mixed" in langs or "code-switch" in langs:
            if ("zh" in lang or "chinese" in lang) and ("en" in lang or "english" in lang):
                lang_ok = True
        genre_ok = "*" in genres or any(x in g or g in x for x in genres)
        if lang_ok and genre_ok:
            return route
    for route in routes:
        if route.get("id") == "default":
            return route
    return {"id": "default", "primary": "gpt-6-astra", "secondary": "claude-sonnet"}


def _slug_for(logical: str, provider: str) -> str:
    data = load_routing()
    logical_models = data.get("logical_models") or {}
    entry = logical_models.get(logical) or {}
    prov = "openrouter" if provider == "openrouter" else "laozhang"
    return entry.get(prov) or entry.get("laozhang") or logical


def decide_route(
    *,
    genre: str,
    language: str,
    stage: str = "polish",
    provider: str = "laozhang",
    experiment_id: str | None = None,
    max_latency_ms: int | None = None,
    max_estimated_cost: float | None = None,
) -> RoutingDecision:
    data = load_routing()
    route = match_route(genre, language)
    stage_prefs = (data.get("stage_preferences") or {}).get(stage) or []
    primary_logical = route.get("primary") or "gpt-6-astra"
    secondary_logical = route.get("secondary") or "claude-sonnet"

    # Stage list wins first (select/rhyme/arc/transitions), then genre route, then fallbacks.
    ordered: list[str] = []
    ordered.extend(stage_prefs)
    ordered.extend([primary_logical, secondary_logical])
    ordered.extend(data.get("fallback_chain") or [])

    seen: set[str] = set()
    logicals: list[str] = []
    for m in ordered:
        if m and m not in seen:
            seen.add(m)
            logicals.append(m)

    if not logicals:
        logicals = ["gpt-6-astra"]

    prov = "openrouter" if provider == "openrouter" else "laozhang"
    primary = ModelTarget(
        logical=logicals[0],
        slug=_slug_for(logicals[0], prov),
        provider=prov,
    )
    fallbacks = [
        ModelTarget(logical=m, slug=_slug_for(m, prov), provider=prov)
        for m in logicals[1:]
    ]

    reasons = [
        f"route:{route.get('id') or 'default'}",
        f"stage:{stage}",
        f"primary:{primary.logical}",
    ]
    if stage_prefs:
        reasons.append(f"stage_prefs:{','.join(stage_prefs[:3])}")

    constraints: dict[str, Any] = {}
    if max_latency_ms is not None:
        constraints["maxLatencyMs"] = max_latency_ms
    if max_estimated_cost is not None:
        constraints["maxEstimatedCost"] = max_estimated_cost

    return RoutingDecision(
        primary=primary,
        fallbacks=fallbacks,
        reason_codes=reasons,
        policy_version=str(data.get("version") or _POLICY_VERSION),
        experiment_id=experiment_id,
        constraints=constraints,
        route_id=str(route.get("id") or "default"),
        stage=stage,
    )


def resolve_logical_model(
    *,
    genre: str,
    language: str,
    stage: str = "polish",
    provider: str = "laozhang",
) -> tuple[str, str]:
    """Return (logical_model_id, provider_slug)."""
    decision = decide_route(
        genre=genre, language=language, stage=stage, provider=provider
    )
    return decision.primary.logical, decision.primary.slug


def list_fallback_slugs(provider: str = "laozhang") -> list[str]:
    data = load_routing()
    prov = "openrouter" if provider == "openrouter" else "laozhang"
    out: list[str] = []
    logical_models = data.get("logical_models") or {}
    for logical in data.get("fallback_chain") or []:
        entry = logical_models.get(logical) or {}
        slug = entry.get(prov)
        if slug:
            out.append(slug)
    return out
