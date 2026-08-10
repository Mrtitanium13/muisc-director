#!/usr/bin/env python3
"""Regenerate merged system prompt files from section modules."""

from __future__ import annotations

from pathlib import Path

from muisc_director.prompts.consolidated_body import (
    build_consolidated_body,
    build_section_1f_standalone,
)


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent.parent
    output_dir = repo_root / "prompts" / "generated"
    output_dir.mkdir(parents=True, exist_ok=True)

    prompts_root = repo_root / "prompts"
    consolidated = build_consolidated_body(base_path=prompts_root)
    standalone_1f = build_section_1f_standalone(base_path=prompts_root)

    (output_dir / "system_prompt_full.txt").write_text(
        consolidated + "\n", encoding="utf-8"
    )
    (output_dir / "system_prompt_1f_standalone.txt").write_text(
        standalone_1f + "\n", encoding="utf-8"
    )

    print("Generated: prompts/generated/system_prompt_full.txt")
    print("Generated: prompts/generated/system_prompt_1f_standalone.txt")


if __name__ == "__main__":
    main()
