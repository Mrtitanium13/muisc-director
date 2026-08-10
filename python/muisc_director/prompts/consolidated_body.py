"""Prompt section identifiers for the Music Director system prompt."""

from __future__ import annotations

from enum import Enum
from pathlib import Path


class PromptSection(str, Enum):
    SECTION_1A = ("1A", "section_1a.txt")
    SECTION_1B = ("1B", "section_1b.txt")
    SECTION_1C = ("1C", "section_1c.txt")
    SECTION_1D = ("1D", "section_1d.txt")
    SECTION_1E = ("1E", "section_1e.txt")
    SECTION_1F = ("1F", "section_1f.txt")

    def __new__(cls, section_id: str, file_name: str) -> PromptSection:
        obj = str.__new__(cls, section_id)
        obj._value_ = section_id
        obj.section_id = section_id
        obj.file_name = file_name
        return obj


ALL_SECTIONS: list[PromptSection] = list(PromptSection)

DJ_MIX_IN_TAG = "[Intro: DJ Mix-In]"
DJ_MIX_OUT_TAG = "[Outro: DJ Mix-Out]"
END_TAG = "[End]"


def _resolve_prompts_root(base_path: Path | None = None) -> Path:
    if base_path is not None:
        return base_path
    candidates = [
        Path("prompts"),
        Path(__file__).resolve().parent.parent.parent / "prompts",
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return candidate
    raise FileNotFoundError("Could not locate prompts/ directory")


def load_section_content(
    section: PromptSection, base_path: Path | None = None
) -> str:
    root = _resolve_prompts_root(base_path)
    path = root / "sections" / section.file_name
    if not path.is_file():
        raise FileNotFoundError(f"Section file not found: {path}")
    return path.read_text(encoding="utf-8").strip()


def section_1f_content(base_path: Path | None = None) -> str:
    return load_section_content(PromptSection.SECTION_1F, base_path=base_path)


def build_consolidated_body(base_path: Path | None = None) -> str:
    parts = [load_section_content(s, base_path=base_path) for s in ALL_SECTIONS]
    return "\n\n".join(parts)


def build_section_1f_standalone(base_path: Path | None = None) -> str:
    content = section_1f_content(base_path=base_path)
    return (
        "DJ MIX BOOKEND MODULE (Section 1F — Standalone)\n\n"
        "Apply these rules to every Suno track generation. This module is self-contained;\n"
        "when used alone, treat it as the authoritative instruction for intro/outro structure.\n\n"
        f"{content}"
    )
