"""Studio-isolated vs live-arena Block 2 staging (user-selected)."""

from __future__ import annotations

from enum import Enum

STUDIO_ISOLATED_ID = "studio_isolated"
LIVE_PERFORMANCE_ID = "live_performance"


class AudioEnvironmentMode(str, Enum):
    STUDIO_ISOLATED = "studio_isolated"
    LIVE_PERFORMANCE = "live_performance"


_OPTIONS: dict[str, tuple[str, str, AudioEnvironmentMode]] = {
    STUDIO_ISOLATED_ID: (
        "Pristine Studio (No Crowd)",
        'CRITICAL DIRECTIVE: Enforce strict studio isolation. In Block 1 and Block 2 '
        'use only positive engineering tokens: "Dead-room isolation, Pristine studio '
        'environment, Close-mic vocal tracking, Dry acoustic room, Focused studio room". '
        'For vocal stacks use "Isolated multi-tracked vocal doubles" or "Tight '
        'double-tracked vocal stacks". '
        'INTERNAL (do not write in Suno output): never use the words crowd, cheer, '
        'applause, audience, stadium, ovation, or live — Suno treats them as triggers '
        'even inside bans.',
        AudioEnvironmentMode.STUDIO_ISOLATED,
    ),
    LIVE_PERFORMANCE_ID: (
        "Live Arena (Crowd & Cheers)",
        'CRITICAL DIRECTIVE: Simulate an epic, high-energy live stadium concert. '
        'Force heavy crowd participation using words like "Thunderous stadium crowd cheering, '
        'Loud audience applause, Large outdoor stage reverb, Crowd singing along loudly" '
        "inside the bracket layers.",
        AudioEnvironmentMode.LIVE_PERFORMANCE,
    ),
}

_COMPACT: dict[str, str] = {
    STUDIO_ISOLATED_ID: "ENV:studio|dead-room isolation|close-mic tracking|dry acoustic room",
    LIVE_PERFORMANCE_ID: (
        "ENV:live-arena|stadium crowd cheering|chorus sing-along|ovation outro"
    ),
}


def coerce_audio_environment_mode(mode_id: str | None) -> str:
    raw = (mode_id or "").strip()
    return raw if raw in _OPTIONS else STUDIO_ISOLATED_ID


def is_live_performance_mode(mode_id: str | None) -> bool:
    return coerce_audio_environment_mode(mode_id) == LIVE_PERFORMANCE_ID


def is_studio_isolated_mode(mode_id: str | None) -> bool:
    return not is_live_performance_mode(mode_id)


def mode_for_id(mode_id: str | None) -> AudioEnvironmentMode:
    coerced = coerce_audio_environment_mode(mode_id)
    return _OPTIONS[coerced][2]


def audio_environment_prompt_directive(mode_id: str | None) -> str:
    _, directive, _ = _OPTIONS[coerce_audio_environment_mode(mode_id)]
    return directive


def audio_environment_user_block(mode_id: str | None) -> str:
    mode = coerce_audio_environment_mode(mode_id)
    label, directive, _ = _OPTIONS[mode]
    return f"AUDIO ENVIRONMENT ({label}):\n{directive}"


def audio_environment_post_process_context_line(mode_id: str | None) -> str:
    return audio_environment_prompt_directive(mode_id)


def audio_environment_post_process_compact_line(mode_id: str | None) -> str:
    return _COMPACT[coerce_audio_environment_mode(mode_id)]
