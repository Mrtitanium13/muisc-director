"""Multi-stage songwriter pipeline.

Feature flag: SONGWRITER_PIPELINE=1
"""

from __future__ import annotations

import json
import os
import re
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from app.songwriter.linting import lint_lyrics, parse_sections, scrub_forbidden
from app.songwriter.packs import resolve_genre_pack, resolve_language_pack
from app.songwriter.genre_engines import resolve_genre_lyric_engine, stage_user_context
from app.songwriter.router import decide_route, resolve_logical_model

_ROOT = Path(__file__).resolve().parents[3]
_SRC = _ROOT / "tools" / "songwriter"

PROMPT_FAMILY = "songwriter"
PROMPT_VERSION = "1.1.0"


def _truthy(name: str) -> bool:
    return os.getenv(name, "").strip().lower() in ("1", "true", "yes", "on")


def pipeline_enabled() -> bool:
    return _truthy("SONGWRITER_PIPELINE")


def _load_json(name: str) -> dict[str, Any]:
    path = _SRC / name
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        key = name.replace(".json", "")
        return SONGWRITER_PROMPTS.get(key) or {}
    except Exception:
        return {}


def _stage_prompt(stage_file: str) -> str:
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        stem = Path(stage_file).stem
        stages = SONGWRITER_PROMPTS.get("stages") or {}
        if stem in stages:
            return stages[stem]
        for k, v in stages.items():
            if stage_file.endswith(k + ".txt") or k in stage_file:
                return v
    except Exception:
        pass
    path = _SRC / stage_file
    if path.is_file():
        return path.read_text(encoding="utf-8")
    return ""


@dataclass
class SongBriefInput:
    genre: str = "pop"
    subgenre: str = ""
    mood: str = ""
    theme: str = ""
    story: str = ""
    language: str = "English"
    energy: int = 50
    perspective: str = "I"
    mode: str = "full_song"
    quality_mode: str = "balanced"
    allow_cliches: bool = False
    input_lyrics: str = ""
    emotional_arc: list[str] = field(default_factory=list)
    vocal_style: str = ""
    audience: str = ""
    bpm: str = ""
    content_rating: str = "clean"
    hook_style: str = ""
    variation_count: int = 3
    artist_inspiration: list[str] = field(default_factory=list)
    constraints: list[str] = field(default_factory=list)
    code_switching: dict[str, Any] = field(default_factory=dict)
    extra: dict[str, Any] = field(default_factory=dict)


# Injected by host: (system, user, model_slug, temperature) -> assistant text
LlmCaller = Callable[[str, str, str, float], str]


def _extract_json(text: str) -> dict[str, Any] | None:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    try:
        data = json.loads(text)
        return data if isinstance(data, dict) else None
    except json.JSONDecodeError:
        m = re.search(r"\{[\s\S]*\}", text)
        if not m:
            return None
        try:
            data = json.loads(m.group(0))
            return data if isinstance(data, dict) else None
        except json.JSONDecodeError:
            return None


def _mode_config(modes: dict[str, Any], mode_id: str) -> dict[str, Any]:
    for m in modes.get("modes") or []:
        if m.get("id") == mode_id:
            return m
    return {"id": mode_id, "stages": []}


def _quality_config(quality_mode: str) -> dict[str, Any]:
    cfg = _load_json("quality_modes.json")
    modes = cfg.get("modes") or {}
    key = (quality_mode or cfg.get("default") or "balanced").strip().lower()
    return modes.get(key) or modes.get("balanced") or {}


def _artist_traits(names: list[str]) -> list[str]:
    """Convert living-artist references into abstract traits (no imitation)."""
    traits: list[str] = []
    for raw in names:
        name = (raw or "").strip()
        if not name:
            continue
        traits.append(
            f"Influence '{name}' → abstract only: intimacy, rhythmic density, "
            "vocal register, narrative distance, production era — never imitate distinctive style."
        )
    return traits


def _assemble_lyrics(context: dict[str, Any]) -> str:
    lyrics = str(context.get("lyrics") or "")
    if lyrics.strip():
        return lyrics
    parts = context.get("assembled_parts")
    if not isinstance(parts, dict):
        return ""
    chunks: list[str] = []
    if parts.get("verse1"):
        chunks += ["[Verse 1]", str(parts["verse1"]).strip()]
    if parts.get("pre"):
        chunks += ["[Pre-Chorus]", str(parts["pre"]).strip()]
    if parts.get("chorus"):
        chunks += ["[Chorus]", str(parts["chorus"]).strip()]
    if parts.get("verse2"):
        chunks += ["[Verse 2]", str(parts["verse2"]).strip()]
    if parts.get("bridge"):
        chunks += ["[Bridge]", str(parts["bridge"]).strip()]
    if parts.get("chorus"):
        chunks += ["[Final Chorus]", str(parts["chorus"]).strip()]
    return "\n\n".join(chunks)


def _emit_ideas(emit: str, context: dict[str, Any], lyrics: str) -> list[str]:
    ideas: list[str] = []
    if emit == "hooks_list":
        chorus = context.get("chorus") if isinstance(context.get("chorus"), dict) else {}
        for c in chorus.get("hook_candidates") or []:
            if isinstance(c, dict) and c.get("text"):
                ideas.append(str(c["text"]))
            elif isinstance(c, str):
                ideas.append(c)
        if chorus.get("selected_hook"):
            ideas.insert(0, str(chorus["selected_hook"]))
        if not ideas and lyrics.strip():
            ideas = [lyrics.strip()]
    elif emit == "concepts_list":
        concepts = context.get("concepts") if isinstance(context.get("concepts"), dict) else {}
        for c in concepts.get("concepts") or []:
            if not isinstance(c, dict):
                continue
            logline = c.get("logline") or c.get("hook_seed") or ""
            titles = c.get("title_ideas") or []
            title = titles[0] if titles else c.get("id") or "concept"
            ideas.append(f"{title}: {logline}".strip(": "))
    elif emit == "titles_list":
        concepts = context.get("concepts") if isinstance(context.get("concepts"), dict) else {}
        for c in concepts.get("concepts") or []:
            if isinstance(c, dict):
                for t in c.get("title_ideas") or []:
                    if t:
                        ideas.append(str(t))
        chorus = context.get("chorus") if isinstance(context.get("chorus"), dict) else {}
        if chorus.get("title"):
            ideas.insert(0, str(chorus["title"]))
    elif emit == "variations":
        # Prefer explicit variations array; else return assembled lyrics as single variation
        polish = context.get("polish") if isinstance(context.get("polish"), dict) else {}
        for v in polish.get("variations") or context.get("variations") or []:
            if isinstance(v, str) and v.strip():
                ideas.append(v.strip())
            elif isinstance(v, dict) and v.get("lyrics"):
                ideas.append(str(v["lyrics"]))
        if not ideas and lyrics.strip():
            ideas = [lyrics.strip()]
    # de-dupe preserve order
    seen: set[str] = set()
    out: list[str] = []
    for x in ideas:
        k = x.strip()
        if k and k not in seen:
            seen.add(k)
            out.append(k)
    return out


class SongwriterPipeline:
    """Runs manifest stages. Pass an llm_caller that hits LaoZhang/OpenRouter."""

    def __init__(self, llm_caller: LlmCaller):
        self.llm_caller = llm_caller
        self.manifest = _load_json("pipeline_manifest.json")
        self.modes = _load_json("output_modes.json")
        self.rubric = _load_json("quality_rubric.json")

    def _mode_stages(self, mode_id: str, quality_mode: str) -> list[str]:
        cfg = _mode_config(self.modes, mode_id)
        stages = list(cfg.get("stages") or [])
        if not stages:
            stages = [s["id"] for s in self.manifest.get("stages") or []]
        q = _quality_config(quality_mode)
        skip = set(q.get("stage_skip") or [])
        if skip:
            stages = [s for s in stages if s not in skip]
        return stages

    def run(
        self,
        brief: SongBriefInput,
        *,
        deadline_monotonic: float | None = None,
    ) -> dict[str, Any]:
        generation_id = str(uuid.uuid4())
        started = time.monotonic()
        mode_cfg = _mode_config(self.modes, brief.mode)
        quality_cfg = _quality_config(brief.quality_mode)
        stage_ids = self._mode_stages(brief.mode, brief.quality_mode)
        manifest_stages = {s["id"]: s for s in self.manifest.get("stages") or []}

        genre_pack = resolve_genre_pack(brief.genre, brief.subgenre)
        language_pack = resolve_language_pack(brief.language)
        ab_bucket = os.getenv(
            "SONGWRITER_AB_BUCKET",
            str(self.manifest.get("ab_default_bucket") or "control"),
        )

        context: dict[str, Any] = {
            "brief_input": {
                "genre": brief.genre,
                "subgenre": brief.subgenre,
                "mood": brief.mood,
                "theme": brief.theme,
                "story": brief.story,
                "language": brief.language,
                "energy": brief.energy,
                "perspective": brief.perspective,
                "mode": brief.mode,
                "quality_mode": brief.quality_mode,
                "emotional_arc": brief.emotional_arc,
                "vocal_style": brief.vocal_style,
                "audience": brief.audience,
                "bpm": brief.bpm,
                "content_rating": brief.content_rating,
                "hook_style": brief.hook_style,
                "variation_count": brief.variation_count,
                "constraints": brief.constraints,
                "code_switching": brief.code_switching,
            },
            "extra": brief.extra,
            "allow_cliches": brief.allow_cliches,
            "genre_rules": genre_pack,
            "language_rules": language_pack,
            "artist_traits": _artist_traits(brief.artist_inspiration),
            "quality_threshold": float(self.rubric.get("ship_threshold") or 90),
            "quality_mode_config": {
                "min_hook_candidates": quality_cfg.get("min_hook_candidates"),
                "min_concepts": quality_cfg.get("min_concepts"),
                "deeper_revision": quality_cfg.get("deeper_revision", False),
            },
            "prompt_meta": {
                "family": PROMPT_FAMILY,
                "version": PROMPT_VERSION,
                "ab_bucket": ab_bucket,
            },
        }
        if brief.input_lyrics:
            context["input_lyrics"] = brief.input_lyrics

        genre_engine = resolve_genre_lyric_engine(
            genre=brief.genre,
            subgenre=brief.subgenre,
            mood=brief.mood,
            theme=brief.theme,
            story=brief.story,
            vocal_style=brief.vocal_style,
            bpm=brief.bpm,
            extra=brief.extra,
        )

        results: list[dict[str, Any]] = []
        routing_log: list[dict[str, Any]] = []
        provider = os.getenv("LLM_PROVIDER", "laozhang")
        timed_out = False

        for sid in stage_ids:
            if deadline_monotonic is not None and time.monotonic() >= deadline_monotonic:
                timed_out = True
                results.append({"stage_id": sid, "error": "deadline_exceeded", "parsed": None})
                break
            meta = manifest_stages.get(sid) or {}
            prompt_rel = meta.get("prompt") or ""
            system = _stage_prompt(prompt_rel)
            if not system.strip():
                results.append(
                    {"stage_id": sid, "error": f"missing prompt for stage {sid}", "parsed": None}
                )
                continue

            decision = decide_route(
                genre=brief.genre,
                language=brief.language,
                stage=sid,
                provider=provider,
                experiment_id=ab_bucket,
            )
            routing_log.append(decision.to_dict())
            system = f"[songwriter_stage={sid}]\n{system}"
            logical, slug = decision.primary.logical, decision.primary.slug
            stage_ctx = stage_user_context(
                context, stage_id=sid, genre_engine=genre_engine
            )
            user = json.dumps(stage_ctx, ensure_ascii=False, indent=2)
            temp = float(meta.get("temperature") or 0.5)
            stage_t0 = time.monotonic()
            raw = self.llm_caller(system, user, slug, temp)
            stage_ms = int((time.monotonic() - stage_t0) * 1000)
            parsed = _extract_json(raw)
            if parsed:
                context[sid] = parsed
                if "lyrics" in parsed and parsed["lyrics"]:
                    context["lyrics"] = parsed["lyrics"]
                if sid == "chorus" and parsed.get("chorus_lyrics"):
                    context.setdefault("assembled_parts", {})
                    context["assembled_parts"]["chorus"] = parsed.get("chorus_lyrics")
                    if parsed.get("pre_chorus_optional"):
                        context["assembled_parts"]["pre"] = parsed["pre_chorus_optional"]
                if sid == "verses":
                    context.setdefault("assembled_parts", {})
                    context["assembled_parts"]["verse1"] = parsed.get("verse1")
                    context["assembled_parts"]["verse2"] = parsed.get("verse2")
                if sid == "bridge":
                    context.setdefault("assembled_parts", {})
                    context["assembled_parts"]["bridge"] = parsed.get("bridge")
            results.append(
                {
                    "stage_id": sid,
                    "model_logical": logical,
                    "model_slug": slug,
                    "parsed": parsed,
                    "latency_ms": stage_ms,
                    "routing": {
                        "route_id": decision.route_id,
                        "reason_codes": decision.reason_codes,
                        "policy_version": decision.policy_version,
                    },
                    "raw_preview": raw[:500],
                }
            )

        lyrics = _assemble_lyrics(context)
        lyrics, hits = scrub_forbidden(lyrics, brief.allow_cliches)
        emit = str(mode_cfg.get("emit") or "")
        ideas = _emit_ideas(emit, context, lyrics) if emit else []

        # For idea-only modes, lyrics may be empty by design
        if emit in ("hooks_list", "concepts_list", "titles_list") and ideas:
            if not lyrics.strip():
                lyrics = "\n".join(f"- {x}" for x in ideas)

        if emit == "variations" and ideas:
            lyrics = ideas[0]
            context["variation_lyrics"] = ideas

        lint = lint_lyrics(
            lyrics,
            mode=brief.mode,
            language=brief.language,
            allow_cliches=brief.allow_cliches,
            language_pack_id=str(language_pack.get("_resolved_id") or "en"),
        )
        # Merge scrub hits into lint
        if hits and not lint.get("forbidden_hits"):
            lint["forbidden_hits"] = hits

        judged = context.get("polish") if isinstance(context.get("polish"), dict) else {}
        threshold = float(
            os.getenv("SONGWRITER_SHIP_THRESHOLD", "")
            or self.rubric.get("ship_threshold")
            or 90
        )
        degraded_floor = float(
            os.getenv("SONGWRITER_DEGRADED_FLOOR", "")
            or self.rubric.get("degraded_floor")
            or 70
        )
        weighted = float(judged.get("weighted_total") or 0)
        hard_fails = list(lint.get("hard_fails") or [])
        if hits and "forbidden_phrase_hit_without_user_override" not in hard_fails:
            hard_fails.append("forbidden_phrase_hit_without_user_override")

        ship = (
            bool(judged.get("ship"))
            and weighted >= threshold
            and not hard_fails
            and bool(lyrics.strip() or ideas)
        )
        if not ship and weighted >= threshold and not hard_fails and lyrics.strip():
            ship = True

        quality_status = "passed" if ship else "degraded"
        if not ship and (weighted < degraded_floor or (not lyrics.strip() and not ideas)):
            quality_status = "failed"

        # Idea modes: ship if we got ideas and no hard structural fails beyond empty
        if emit and ideas and not hits:
            hard_fails = [h for h in hard_fails if h != "empty_lyrics"]
            if not hard_fails:
                ship = True
                quality_status = "passed"

        primary_route = routing_log[0] if routing_log else decide_route(
            genre=brief.genre, language=brief.language, provider=provider
        ).to_dict()

        sections = parse_sections(lyrics)
        include_artifacts = bool(quality_cfg.get("include_stage_artifacts")) or brief.quality_mode == "debug"

        response: dict[str, Any] = {
            "id": generation_id,
            "generation_id": generation_id,
            "lyrics": lyrics,
            "title": judged.get("title")
            or (context.get("chorus") or {}).get("title")
            or (context.get("select") or {}).get("title_working"),
            "ideas": ideas,
            "sections": sections,
            "scores": judged.get("scores") or {},
            "weighted_total": weighted,
            "ship": ship,
            "quality_status": quality_status,
            "forbidden_hits": lint.get("forbidden_hits") or hits,
            "lint": {
                "hard_fails": hard_fails,
                "soft_warnings": lint.get("soft_warnings") or [],
            },
            "stages": results if include_artifacts else [
                {
                    "stage_id": r.get("stage_id"),
                    "model_logical": r.get("model_logical"),
                    "model_slug": r.get("model_slug"),
                    "latency_ms": r.get("latency_ms"),
                    "error": r.get("error"),
                    "routing": r.get("routing"),
                }
                for r in results
            ],
            "mode": brief.mode,
            "quality_mode": brief.quality_mode,
            "threshold": threshold,
            "degraded_floor": degraded_floor,
            "timed_out": timed_out,
            "partial": timed_out and bool(lyrics.strip() or ideas),
            "language": brief.language,
            "metadata": {
                "modelAlias": (primary_route.get("primary") or {}).get("logical")
                or resolve_logical_model(
                    genre=brief.genre, language=brief.language, provider=provider
                )[0],
                "promptVersion": PROMPT_VERSION,
                "promptFamily": PROMPT_FAMILY,
                "routingPolicyVersion": primary_route.get("policy_version"),
                "genrePackId": genre_pack.get("_resolved_id"),
                "genrePackVersion": genre_pack.get("version"),
                "languagePackId": language_pack.get("_resolved_id"),
                "languagePackVersion": language_pack.get("version"),
                "genreLyricEngineInjected": bool(genre_engine.get("text")),
                "genreLyricEngineChars": genre_engine.get("char_count") or 0,
                "genreLyricEngineRawChars": genre_engine.get("raw_char_count") or 0,
                "genreLyricEngineTruncated": bool(genre_engine.get("truncated")),
                "genreLyricMasterLane": genre_engine.get("master_lane") or "generic",
                "qualityStatus": quality_status,
                "generationId": generation_id,
                "abBucket": ab_bucket,
                "totalLatencyMs": int((time.monotonic() - started) * 1000),
                "emit": emit or None,
            },
            "routing": primary_route,
        }
        if emit == "variations":
            response["variations"] = ideas
        return response
