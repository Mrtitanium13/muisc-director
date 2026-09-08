"""Suno prompt pipeline: single | hybrid draft→polish | two-pass Architect→Lyricist."""

from __future__ import annotations

import logging
from typing import Any, NamedTuple

from app.architect_pass import (
    ARCHITECT_SYSTEM,
    architect_max_tokens,
    blueprint_to_json,
    inject_blueprint_into_user,
    parse_architect_blueprint,
)
from app.llm_config import (
    hybrid_prompt_enabled,
    llm_provider,
    resolve_draft_model,
    resolve_laozhang_lyrics_secondary_model,
    resolve_polish_model,
    two_pass_prompt_enabled,
)
from app.suno_compact_retry import COMPACT_LYRICS_SYSTEM
from app.suno_output_qa import (
    block1_probably_truncated,
    build_format_retry_suffix,
    unified_block2_missing,
)

logger = logging.getLogger(__name__)


class SunoPromptResult(NamedTuple):
    text: str
    pipeline: str
    architect_blueprint: str | None = None

# Polish must be able to return the full draft (Block 1 + Block 2); a low cap truncates output.
_POLISH_MAX_TOKENS_CAP = 8192
_COMPLETION_MAX_TOKENS_CAP = 8192


def _polish_max_tokens(max_tokens: int) -> int:
    return min(max(max_tokens, 3200), _POLISH_MAX_TOKENS_CAP)


def _completion_max_tokens(max_tokens: int) -> int:
    return min(max(int(max_tokens * 1.5), 4200), _COMPLETION_MAX_TOKENS_CAP)


_POLISH_SYSTEM = """You are a senior Suno creative editor (Claude). You receive a GPT-6 Astra / Terra multilingual prompt draft.

YOUR FOCUS — LYRICS & ARTISTIC EXPRESSION:
- Hooks, storytelling, vocal personality, singable choruses, concrete imagery, genre-fit cadence, poetic/cinematic expression.
- Nigerian Pidgin and African-language lyric intent: preserve authentic grammar and flow (`dey`, `na`, `wahala`, `e don set`, `small small`) — never normalize to stiff English.
- Refine Block 1 prose for artistic expression while keeping genre fusion, production concepts, sound design, musical direction, and artist-reference sonic translation (no names in output).

POLISH ONLY — do not change the user's creative intent, genre, BPM, key, or lyric story.

**Human Authenticity Engine (apply before return):**
- Replace generic emotion ("holding on", "broken inside", "lost in the dark") with concrete images invented for THIS song. Never default to kettle / receipt / bleach / "3 AM on cold tile" / unmotivated Lagos place-drops.
- Chorus: one memorable hook + one plain emotional line; repeatable; no verbatim verse phrases.
- Festival/trance/melodic techno: simple singable choruses; breakdowns more intimate than drops.
- ZERO artist/producer/song names — translate to sonic character.
- Block 1: tighten; if near 150 words / 1000 chars, compress with engineer shorthand; keep arrangement + production intent.
- Block 1: respect 130–150 words / ≤1000 characters (Simple mode: one vivid line ≤1000 chars).
- Keep headers: "BLOCK 1 — PASTE INTO SUNO: STYLE" and when lyrics exist "BLOCK 2 — PASTE INTO SUNO: LYRICS".
- Keep all Block 2 bracket tags exactly ([Intro], [Verse], [Chorus], [Break], [Stripped Back], [Fade Out], [End], production cue lines in brackets).
- On lyric lines: Elite Human Lyricist → Human Authenticity specificity pass → genre humanization → Human Songwriter v3.0; honor Human Realism level.
- Fix formatting, weak filler, AI clichés; preserve analyzer facts.
- Final internal QA: human authenticity, chorus memory, genre fit, Suno caps, zero names.
- Output ONLY the final polished Suno reply — no commentary or meta text."""


def _completion_user_message(*, partial: str, original_user: str) -> str:
    return f"""Your previous Suno reply was **incomplete** (Block 1 stopped early and/or Block 2 is missing).

Rewrite the **complete** two-block output from scratch in **one** reply:
- **BLOCK 1 — PASTE INTO SUNO: STYLE** → 130–150 words of finished producer prose (every sentence complete).
- **BLOCK 2 — PASTE INTO SUNO: LYRICS** → full bracket structure through **[End]**.

ORIGINAL USER REQUEST (honor genre, BPM, key, vibe):
---
{original_user.strip()}
---

INCOMPLETE DRAFT (do not copy this length — expand fully):
---
{partial.strip()}
---

Output ONLY the final complete two-block Suno reply. No preamble."""


def _polish_user_message(*, draft: str, original_user: str) -> str:
    return f"""DRAFT SUNO OUTPUT (polish into final paste-ready form):
---
{draft.strip()}
---

ORIGINAL USER REQUEST (do not contradict):
---
{original_user.strip()}
---

Return the polished full Suno reply only."""


def _chat(
    client: Any,
    *,
    model: str,
    messages: list[dict[str, str]],
    temperature: float,
    max_tokens: int,
) -> tuple[str, str | None]:
    from app.llm_config import completion_token_kwargs

    kwargs: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        **completion_token_kwargs(model, max_tokens),
    }
    resp = client.chat.completions.create(**kwargs)
    choice = resp.choices[0]
    msg = choice.message
    text = (msg.content or "").strip()
    if not text:
        refusal = getattr(msg, "refusal", None)
        logger.warning(
            "empty model response model=%s finish=%s refusal=%s system_chars=%s",
            model,
            getattr(choice, "finish_reason", None),
            bool(refusal),
            sum(len(m.get("content") or "") for m in messages if m.get("role") == "system"),
        )
        if refusal:
            raise ValueError(f"Model refusal: {refusal}")
        raise ValueError("Empty model response")
    finish = getattr(choice, "finish_reason", None)
    return text, finish


def _chat_simple(
    client: Any,
    *,
    model: str,
    system: str,
    user: str,
    temperature: float,
    max_tokens: int,
    chat_prefix_turns: list[dict[str, str]] | None = None,
) -> tuple[str, str | None]:
    messages: list[dict[str, str]] = [{"role": "system", "content": system}]
    if chat_prefix_turns:
        messages.extend(chat_prefix_turns)
    messages.append({"role": "user", "content": user})
    return _chat(
        client,
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )


def _output_incomplete(text: str) -> bool:
    return unified_block2_missing(text) or block1_probably_truncated(text)


def _is_better_suno_output(candidate: str, current: str) -> bool:
    """Prefer complete Block 2 / longer Block 1 over a worse prior reply."""
    cand_bad = _output_incomplete(candidate)
    cur_bad = _output_incomplete(current)
    if cand_bad != cur_bad:
        return not cand_bad
    if unified_block2_missing(current) and not unified_block2_missing(candidate):
        return True
    return len(candidate) > len(current)


def _should_try_laozhang_lyrics_secondary(
    *,
    provider: str | None,
    lyrics_task: bool,
    primary_model: str,
    text: str,
    finish: str | None,
    error: Exception | None = None,
) -> bool:
    if not lyrics_task or llm_provider(provider) != "laozhang":
        return False
    secondary = resolve_laozhang_lyrics_secondary_model()
    if primary_model == secondary:
        return False
    if error is not None:
        return True
    return finish == "length" or _output_incomplete(text)


def _single_chat_with_laozhang_fallback(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    temperature: float,
    provider: str | None,
    lyrics_task: bool,
    user_suffix: str | None = None,
    draft_model_override: str | None = None,
    chat_prefix_turns: list[dict[str, str]] | None = None,
) -> tuple[str, str]:
    user = user_content
    if user_suffix and user_suffix.strip():
        user = f"{user_content.strip()}\n\n{user_suffix.strip()}"
    primary = draft_model_override or resolve_draft_model(
        language=language,
        lightweight=lightweight,
        provider=provider,
        lyrics_task=lyrics_task,
    )
    secondary = resolve_laozhang_lyrics_secondary_model()
    compact = COMPACT_LYRICS_SYSTEM
    is_laozhang_lyrics = llm_provider(provider) == "laozhang" and lyrics_task

    def _try(model: str, system: str, temp: float, label: str) -> tuple[str, str] | None:
        tok = _completion_max_tokens(max_tokens)
        try:
            out, fin = _chat_simple(
                client,
                model=model,
                system=system,
                user=user,
                temperature=temp,
                max_tokens=tok,
                chat_prefix_turns=chat_prefix_turns,
            )
            if fin == "length":
                logger.warning(
                    "single-path model=%s label=%s hit max_tokens (%s)",
                    model,
                    label,
                    tok,
                )
            return out, f"single:{model}:{label}"
        except Exception as exc:  # noqa: BLE001
            logger.warning("single-path %s model=%s failed (%s)", label, model, exc)
            return None

    # OpenRouter path: one call with the full V2 system prompt.
    if not is_laozhang_lyrics:
        text, finish = _chat_simple(
            client,
            model=primary,
            system=system_prompt,
            user=user,
            temperature=temperature,
            max_tokens=max_tokens,
            chat_prefix_turns=chat_prefix_turns,
        )
        if finish == "length":
            logger.warning("single-path model=%s hit max_tokens (%s)", primary, max_tokens)
        return text, f"single:{primary}"

    # LaoZhang lyrics: same as OpenRouter (full system first), then secondary, then compact fallback.
    lyrics_model = resolve_polish_model(provider=provider, lyrics_task=True)
    full_attempts: list[tuple[str, str, float, str]] = [
        (primary, system_prompt, temperature, "primary-full"),
        (lyrics_model, system_prompt, temperature, "lyrics-full"),
        (secondary, system_prompt, temperature, "secondary-full"),
        (primary, system_prompt, 0.35, "primary-full-retry"),
    ]
    compact_attempts: list[tuple[str, str, float, str]] = [
        (lyrics_model, compact, temperature, "lyrics-compact"),
        (primary, compact, temperature, "primary-compact"),
        (secondary, compact, temperature, "secondary-compact"),
    ]
    best: tuple[str, str] | None = None
    for model, system, temp, label in full_attempts + compact_attempts:
        hit = _try(model, system, temp, label)
        if hit is None:
            continue
        text, pipeline = hit
        if not _output_incomplete(text):
            return text, pipeline
        if best is None or _is_better_suno_output(text, best[0]):
            best = (text, pipeline)
    if best is not None:
        return best
    raise ValueError("All LaoZhang lyrics model attempts failed")


def generate_prompt_completion(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    partial: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    provider: str | None = None,
    lyrics_task: bool = True,
    draft_model_override: str | None = None,
) -> tuple[str, str]:
    """Multi-turn completion when a single call returns truncated Block 1 / missing Block 2."""
    model = draft_model_override or resolve_draft_model(
        language=language,
        lightweight=lightweight,
        provider=provider,
        lyrics_task=lyrics_task,
    )
    completion_tok = _completion_max_tokens(max_tokens)
    logger.info("completion pass model=%s max_tokens=%s", model, completion_tok)
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_content},
        {"role": "assistant", "content": partial},
        {
            "role": "user",
            "content": _completion_user_message(
                partial=partial, original_user=user_content
            ),
        },
    ]
    try:
        text, finish = _chat(
            client,
            model=model,
            messages=messages,
            temperature=0.35,
            max_tokens=completion_tok,
        )
    except Exception as exc:  # noqa: BLE001
        secondary = resolve_laozhang_lyrics_secondary_model()
        if lyrics_task and llm_provider(provider) == "laozhang" and model != secondary:
            logger.warning("completion primary failed (%s); trying %s", exc, secondary)
            text, finish = _chat(
                client,
                model=secondary,
                messages=messages,
                temperature=0.35,
                max_tokens=completion_tok,
            )
            return text, f"single:{secondary}:completion-fallback"
        raise
    if finish == "length":
        logger.warning(
            "completion pass model=%s hit max_tokens (%s)", model, completion_tok
        )
    if _should_try_laozhang_lyrics_secondary(
        provider=provider,
        lyrics_task=lyrics_task,
        primary_model=model,
        text=text,
        finish=finish,
    ):
        secondary = resolve_laozhang_lyrics_secondary_model()
        try:
            alt, _ = _chat(
                client,
                model=secondary,
                messages=messages,
                temperature=0.35,
                max_tokens=completion_tok,
            )
            if len(alt) > len(text) or (_output_incomplete(text) and not _output_incomplete(alt)):
                return alt, f"single:{secondary}:completion-fallback"
        except Exception as exc:  # noqa: BLE001
            logger.warning("completion secondary failed: %s", exc)
    return text, f"single:{model}:completion"


def generate_prompt_hybrid(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    draft_temperature: float = 0.85,
    provider: str | None = None,
    lyrics_task: bool = True,
    draft_model_override: str | None = None,
    polish_model_override: str | None = None,
    chat_prefix_turns: list[dict[str, str]] | None = None,
) -> tuple[str, str]:
    """
    LaoZhang: Terra English / Astra multilingual draft → Claude polish → Astra/Claude humanization (mandatory).
    Returns (final_text, pipeline_label).
    """
    draft_model = draft_model_override or resolve_draft_model(
        language=language,
        lightweight=lightweight,
        provider=provider,
        lyrics_task=lyrics_task,
    )
    polish_model = polish_model_override or resolve_polish_model(
        provider=provider, lyrics_task=lyrics_task
    )

    logger.info("hybrid draft model=%s", draft_model)
    draft, draft_finish = _chat_simple(
        client,
        model=draft_model,
        system=system_prompt,
        user=user_content,
        temperature=draft_temperature,
        max_tokens=max_tokens,
        chat_prefix_turns=chat_prefix_turns,
    )
    if draft_finish == "length":
        logger.warning("hybrid draft hit max_tokens (%s); output may be incomplete", max_tokens)

    try:
        logger.info("hybrid polish model=%s", polish_model)
        polished, polish_finish = _chat_simple(
            client,
            model=polish_model,
            system=_POLISH_SYSTEM,
            user=_polish_user_message(draft=draft, original_user=user_content),
            temperature=0.4,
            max_tokens=_polish_max_tokens(max_tokens),
        )
        if polish_finish == "length":
            logger.warning("hybrid polish truncated (length); using draft")
            return draft, f"hybrid:{draft_model}:draft-only"
        label = f"hybrid:{draft_model}"
        return polished, label
    except Exception as e:  # noqa: BLE001
        logger.warning("polish pass failed, using draft: %s", e)
        return draft, "hybrid:draft-only"


def generate_prompt_single(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    temperature: float = 0.85,
    provider: str | None = None,
    user_suffix: str | None = None,
    lyrics_task: bool = True,
    draft_model_override: str | None = None,
    chat_prefix_turns: list[dict[str, str]] | None = None,
) -> tuple[str, str]:
    return _single_chat_with_laozhang_fallback(
        client,
        system_prompt=system_prompt,
        user_content=user_content,
        language=language,
        lightweight=lightweight,
        max_tokens=max_tokens,
        temperature=temperature,
        provider=provider,
        lyrics_task=lyrics_task,
        user_suffix=user_suffix,
        draft_model_override=draft_model_override,
        chat_prefix_turns=chat_prefix_turns,
    )


def generate_prompt_two_pass(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    temperature: float = 0.85,
    provider: str | None = None,
    user_suffix: str | None = None,
    lyrics_task: bool = True,
    draft_model_override: str | None = None,
    polish_model_override: str | None = None,
    chat_prefix_turns: list[dict[str, str]] | None = None,
    architect_blueprint: str | None = None,
) -> SunoPromptResult:
    """
    Pass 1 Architect (JSON blueprint) → Pass 2 Lyricist (Block 1 + Block 2).

    If [architect_blueprint] is provided (format retry), Pass 1 is skipped.
    On Pass 1 parse failure, falls back to a single full-prompt generation.
    """
    architect_model = draft_model_override or resolve_draft_model(
        language=language,
        lightweight=lightweight,
        provider=provider,
        lyrics_task=lyrics_task,
    )
    lyricist_model = polish_model_override or resolve_polish_model(
        provider=provider, lyrics_task=lyrics_task
    )

    blueprint_json = (architect_blueprint or "").strip() or None
    if blueprint_json is None:
        logger.info("two-pass architect model=%s", architect_model)
        try:
            raw_bp, bp_finish = _chat_simple(
                client,
                model=architect_model,
                system=ARCHITECT_SYSTEM,
                user=user_content,
                temperature=0.4,
                max_tokens=architect_max_tokens(),
            )
            if bp_finish == "length":
                logger.warning(
                    "architect pass hit max_tokens (%s)", architect_max_tokens()
                )
            parsed = parse_architect_blueprint(raw_bp)
            blueprint_json = blueprint_to_json(parsed)
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "architect pass failed (%s); falling back to single-path", exc
            )
            text, pipeline = generate_prompt_single(
                client,
                system_prompt=system_prompt,
                user_content=user_content,
                language=language,
                lightweight=lightweight,
                max_tokens=max_tokens,
                temperature=temperature,
                provider=provider,
                user_suffix=user_suffix,
                lyrics_task=lyrics_task,
                draft_model_override=draft_model_override,
                chat_prefix_turns=chat_prefix_turns,
            )
            return SunoPromptResult(text, f"{pipeline}:two-pass-fallback", None)

    pass2_user = inject_blueprint_into_user(
        user_content, blueprint_json, user_suffix=user_suffix
    )
    logger.info("two-pass lyricist model=%s", lyricist_model)
    try:
        text, finish = _chat_simple(
            client,
            model=lyricist_model,
            system=system_prompt,
            user=pass2_user,
            temperature=temperature,
            max_tokens=max_tokens,
            chat_prefix_turns=chat_prefix_turns,
        )
        if finish == "length":
            logger.warning(
                "lyricist pass model=%s hit max_tokens (%s)",
                lyricist_model,
                max_tokens,
            )
        label = f"two-pass:{architect_model}->{lyricist_model}"
        return SunoPromptResult(text, label, blueprint_json)
    except Exception as exc:  # noqa: BLE001
        # LaoZhang: try draft model as lyricist fallback
        if lyricist_model != architect_model:
            logger.warning(
                "lyricist model=%s failed (%s); retrying with %s",
                lyricist_model,
                exc,
                architect_model,
            )
            text, finish = _chat_simple(
                client,
                model=architect_model,
                system=system_prompt,
                user=pass2_user,
                temperature=temperature,
                max_tokens=max_tokens,
                chat_prefix_turns=chat_prefix_turns,
            )
            if finish == "length":
                logger.warning(
                    "lyricist fallback model=%s hit max_tokens (%s)",
                    architect_model,
                    max_tokens,
                )
            return SunoPromptResult(
                text,
                f"two-pass:{architect_model}->{architect_model}:fallback",
                blueprint_json,
            )
        raise


def generate_suno_prompt(
    client: Any,
    *,
    system_prompt: str,
    user_content: str,
    language: str,
    lightweight: bool,
    max_tokens: int,
    temperature: float = 0.85,
    provider: str | None = None,
    user_suffix: str | None = None,
    lyrics_task: bool = True,
    draft_model_override: str | None = None,
    polish_model_override: str | None = None,
    chat_prefix_turns: list[dict[str, str]] | None = None,
    architect_blueprint: str | None = None,
) -> SunoPromptResult:
    """Entry: two-pass, hybrid, or single-model generation."""
    if two_pass_prompt_enabled(lightweight=lightweight, lyrics_task=lyrics_task):
        return generate_prompt_two_pass(
            client,
            system_prompt=system_prompt,
            user_content=user_content,
            language=language,
            lightweight=lightweight,
            max_tokens=max_tokens,
            temperature=temperature,
            provider=provider,
            user_suffix=user_suffix,
            lyrics_task=lyrics_task,
            draft_model_override=draft_model_override,
            polish_model_override=polish_model_override,
            chat_prefix_turns=chat_prefix_turns,
            architect_blueprint=architect_blueprint,
        )
    if hybrid_prompt_enabled(
        lightweight=lightweight, provider=provider, lyrics_task=lyrics_task
    ):
        text, pipeline = generate_prompt_hybrid(
            client,
            system_prompt=system_prompt,
            user_content=user_content,
            language=language,
            lightweight=lightweight,
            max_tokens=max_tokens,
            draft_temperature=temperature,
            provider=provider,
            lyrics_task=lyrics_task,
            draft_model_override=draft_model_override,
            polish_model_override=polish_model_override,
            chat_prefix_turns=chat_prefix_turns,
        )
        return SunoPromptResult(text, pipeline, None)
    text, pipeline = generate_prompt_single(
        client,
        system_prompt=system_prompt,
        user_content=user_content,
        language=language,
        lightweight=lightweight,
        max_tokens=max_tokens,
        temperature=temperature,
        provider=provider,
        user_suffix=user_suffix,
        lyrics_task=lyrics_task,
        draft_model_override=draft_model_override,
        chat_prefix_turns=chat_prefix_turns,
    )
    return SunoPromptResult(text, pipeline, None)


def completion_suffix_for(partial: str) -> str:
    """Strict user-block suffix for a format-retry pass."""
    return build_format_retry_suffix(
        block2_missing=unified_block2_missing(partial),
        block1_short=block1_probably_truncated(partial),
    )
