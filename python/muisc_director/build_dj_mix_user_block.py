"""Build the user-message block for DJ mix generation requests."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DjMixRequest:
    track_title: str
    genre: str
    bpm: int
    dj_tag: str | None = None
    mood: str | None = None
    key_signature: str | None = None
    vocal_style: str | None = None
    additional_notes: str | None = None


def build_dj_mix_user_block(request: DjMixRequest) -> str:
    """Build user-message block with positive, content-first DJ mix instructions."""
    lines: list[str] = [
        "Generate a DJ-ready Suno track package for:",
        "",
        f"Track: {request.track_title}",
        f"Genre: {request.genre}",
        f"BPM: {request.bpm}",
    ]

    if request.mood:
        lines.append(f"Mood: {request.mood}")
    if request.key_signature:
        lines.append(f"Key: {request.key_signature}")
    if request.vocal_style:
        lines.append(f"Vocal style: {request.vocal_style}")
    if request.dj_tag:
        lines.append(f'DJ tag (spoken during mix-in only): "{request.dj_tag}"')
    if request.additional_notes:
        lines.append(f"Notes: {request.additional_notes}")

    lines.extend(
        [
            "",
            "STRUCTURE REQUIREMENTS (mandatory):",
            "",
            "1. Open the lyrics field with [Intro: DJ Mix-In] as the very first tag.",
            f"   • 8–16 bars of filtered, beat-driven intro material at {request.bpm} BPM",
            "   • Progressive element entry: drums → bass → melody",
            "   • Snare build in the final 4 bars before the first body section",
        ]
    )

    if request.dj_tag:
        lines.append("   • Include the DJ tag as spoken word within the mix-in section")
    else:
        lines.append("   • Keep the mix-in instrumental (no vocals)")

    lines.extend(
        [
            "",
            "2. Build the main body with at least one verse and one chorus (or drop).",
            "",
            "3. Close the lyrics field with [Outro: DJ Mix-Out] as the final body section.",
            f"   • 16–32 bars of sustained rhythm at full {request.bpm} BPM",
            "   • Strip vocals and melodic leads first; keep kick + hi-hat + bass",
            "   • Beat stays steady — no slowdown, no fade-to-silence",
            "",
            "4. End with [End] on its own line after the mix-out completes.",
            "",
            "Return the JSON package (title, style, lyrics, notes) per Section 1B.",
        ]
    )

    return "\n".join(lines)
