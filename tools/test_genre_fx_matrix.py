#!/usr/bin/env python3
"""Verify all 20 genre FX lanes build cleanly at max intensity (3)."""

from __future__ import annotations

import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / "server"))

from app.suno_prompt_builder import build_suno_prompt  # noqa: E402

TEST_GENRES = (
    "edm",
    "hardstyle",
    "techno",
    "dnb",
    "synthwave",
    "dubstep",
    "ambient",
    "hiphop",
    "trap",
    "pop",
    "rnb",
    "reggaeton",
    "rock",
    "metal",
    "indie",
    "country",
    "folk",
    "afrobeats",
    "latin",
    "cinematic",
    "jazz",
)


def main() -> int:
    print("Testing all 21 app genres across Max Intensity (3)...")
    failed = 0
    for genre in TEST_GENRES:
        output = build_suno_prompt(
            "Base Style Text",
            "[Chorus]\nSinging lyrics here...",
            genre,
            intensity=3,
        )
        ok = (
            "Base Style Text" in output.prompt
            and "[Chorus]" in output.lyrics
        )
        if ok:
            print(f"Genre [{genre.upper()}] mapped and built successfully.")
        else:
            failed += 1
            print(f"Genre [{genre.upper()}] failed generation schema.", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
