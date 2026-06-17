"""Studio-isolated vs live-arena Block 2 staging (user-selected)."""

from __future__ import annotations

STUDIO_ISOLATED_ID = "studio_isolated"
LIVE_PERFORMANCE_ID = "live_performance"

_OPTIONS: dict[str, tuple[str, str]] = {
    STUDIO_ISOLATED_ID: (
        "Pristine Studio (No Crowd)",
        'CRITICAL DIRECTIVE: Enforce strict studio isolation. Utilize words like '
        '"Dead-room isolation, Pristine studio environment, Zero audience noise". '
        "Strictly ban any live applause or crowd sounds.",
    ),
    LIVE_PERFORMANCE_ID: (
        "Live Arena (Crowd & Cheers)",
        'CRITICAL DIRECTIVE: Simulate an epic, high-energy live stadium concert. '
        'Force heavy crowd participation using words like "Thunderous stadium crowd cheering, '
        'Loud audience applause, Large outdoor stage reverb, Crowd singing along loudly" '
        "inside the bracket layers.",
    ),
}


def coerce_audio_environment_mode(mode_id: str | None) -> str:
    raw = (mode_id or "").strip()
    if raw == LIVE_PERFORMANCE_ID:
        return LIVE_PERFORMANCE_ID
    return STUDIO_ISOLATED_ID


def is_live_performance_mode(mode_id: str | None) -> bool:
    return coerce_audio_environment_mode(mode_id) == LIVE_PERFORMANCE_ID


def audio_environment_prompt_directive(mode_id: str | None) -> str:
    _, directive = _OPTIONS[coerce_audio_environment_mode(mode_id)]
    return directive


def audio_environment_user_block(mode_id: str | None) -> str:
    mode = coerce_audio_environment_mode(mode_id)
    label, directive = _OPTIONS[mode]
    return f"AUDIO ENVIRONMENT ({label}):\n{directive}"


def audio_environment_post_process_context_line(mode_id: str | None) -> str:
    return audio_environment_prompt_directive(mode_id)


_COMPACT: dict[str, str] = {
    STUDIO_ISOLATED_ID: "ENV:studio|dead-room isolation|zero crowd/applause",
    LIVE_PERFORMANCE_ID: (
        "ENV:live-arena|stadium crowd cheering|chorus sing-along|ovation outro"
    ),
}


def audio_environment_post_process_compact_line(mode_id: str | None) -> str:
    return _COMPACT[coerce_audio_environment_mode(mode_id)]
