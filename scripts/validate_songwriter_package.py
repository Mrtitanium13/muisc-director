#!/usr/bin/env python3
"""Validate the songwriter implementation package is complete."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "tools" / "songwriter"

REQUIRED_FILES = [
    "model_routing.json",
    "quality_rubric.json",
    "forbidden_phrases.json",
    "output_modes.json",
    "story_arcs.json",
    "pipeline_manifest.json",
]

REQUIRED_MODULES = [
    "01_role.txt",
    "02_principles.txt",
    "03_hook_engine.txt",
    "04_rhyme_engine.txt",
    "05_forbidden_anti_ai.txt",
    "06_output_format.txt",
    "07_language_rules.txt",
]

REQUIRED_STAGES = [f"stage_{i:02d}_" for i in range(1, 13)]

REQUIRED_DOCS = [
    "docs/SONGWRITER_LLM_ARCHITECTURE.md",
    "docs/SONGWRITER_IMPLEMENTATION_CHECKLIST.md",
    ".cursor/rules/songwriter-llm-architecture.mdc",
]


def main() -> int:
    errors: list[str] = []

    for rel in REQUIRED_DOCS:
        if not (ROOT / rel).is_file():
            errors.append(f"missing doc/rule: {rel}")

    for name in REQUIRED_FILES:
        path = SRC / name
        if not path.is_file():
            errors.append(f"missing config: {name}")
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"invalid JSON {name}: {e}")

    for name in REQUIRED_MODULES:
        if not (SRC / "modules" / name).is_file():
            errors.append(f"missing module: {name}")

    stage_files = list((SRC / "stages").glob("stage_*.txt"))
    if len(stage_files) < 12:
        errors.append(f"expected ≥12 stage prompts, found {len(stage_files)}")
    for prefix in REQUIRED_STAGES:
        if not any(p.name.startswith(prefix) for p in stage_files):
            errors.append(f"missing stage starting with {prefix}")

    genres = list((SRC / "genres").glob("*.json"))
    if len(genres) < 20:
        errors.append(f"expected ≥20 genre packs, found {len(genres)}")

    languages = list((SRC / "languages").glob("*.json")) if (SRC / "languages").is_dir() else []
    if len(languages) < 4:
        errors.append(f"expected ≥4 language packs, found {len(languages)}")

    for extra in ("quality_modes.json", "genre_aliases.json"):
        if not (SRC / extra).is_file():
            errors.append(f"missing config: {extra}")

    merge = ROOT / "tools" / "merge_songwriter_prompts.py"
    if not merge.is_file():
        errors.append("missing tools/merge_songwriter_prompts.py")

    if errors:
        print("FAIL — songwriter package incomplete:")
        for e in errors:
            print(f"  - {e}")
        return 1

    print("OK — songwriter package ready")
    print(f"  configs: {len(REQUIRED_FILES)} + quality_modes + genre_aliases")
    print(f"  modules: {len(REQUIRED_MODULES)}")
    print(f"  stages:  {len(stage_files)}")
    print(f"  genres:  {len(genres)}")
    print(f"  languages: {len(languages)}")
    print("Next: python tools/merge_songwriter_prompts.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
