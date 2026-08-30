#!/usr/bin/env python3
"""Merge tools/dynamic_structural_engine.txt into generated/runtime targets.

Targets:
  1. server/app/suno_system_prompt_v2.py (DSE spec constant)
  2. tools/suno_v2_block2_*.txt (Block 2 protocol docs)

Also verifies Dart + Python runtime modules expose required symbols.
Idempotent: replaces content between BEGIN/END markers on re-runs.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC = ROOT / "tools" / "dynamic_structural_engine.txt"
DSE_PY = ROOT / "server" / "app" / "dynamic_structural_engine.py"
DSE_DART = ROOT / "lib" / "core" / "utils" / "dynamic_structural_engine.dart"
DART_UTILS = ROOT / "lib" / "core" / "utils"
SYSTEM_PROMPT = ROOT / "server" / "app" / "suno_system_prompt_v2.py"
CANDIDATE_DART = ROOT / "lib" / "core" / "constants" / "suno_system_prompt_v2_candidate.dart"

BEGIN_MARKER = "# BEGIN_DYNAMIC_STRUCTURAL_ENGINE"
END_MARKER = "# END_DYNAMIC_STRUCTURAL_ENGINE"
DART_BEGIN = "// BEGIN_DYNAMIC_STRUCTURAL_ENGINE"
DART_END = "// END_DYNAMIC_STRUCTURAL_ENGINE"


def read_spec() -> str:
    """Read spec body, stripping optional YAML frontmatter."""
    raw = SPEC.read_text(encoding="utf-8")
    if raw.startswith("---"):
        parts = raw.split("---", 2)
        if len(parts) >= 3:
            return parts[2].strip()
    return raw.strip()


def _inject_between_markers(
    content: str,
    injection: str,
    begin: str,
    end: str,
) -> str:
    if begin in content:
        return re.sub(
            rf"{re.escape(begin)}.*?{re.escape(end)}",
            injection.strip(),
            content,
            flags=re.DOTALL,
        )
    return content.rstrip() + "\n\n" + injection.strip() + "\n"


def merge_python_system_prompt() -> None:
    body = read_spec()
    injection = (
        f"\n{BEGIN_MARKER}\n"
        f'"""Dynamic Structural Engine (merged from tools spec)"""\n'
        f"DYNAMIC_STRUCTURAL_ENGINE_SPEC = r\"\"\"\n{body}\n\"\"\"\n"
        f"{END_MARKER}\n"
    )
    if not SYSTEM_PROMPT.exists():
        print(f"[skip] {SYSTEM_PROMPT} missing")
        return
    content = SYSTEM_PROMPT.read_text(encoding="utf-8")
    content = _inject_between_markers(content, injection, BEGIN_MARKER, END_MARKER)
    SYSTEM_PROMPT.write_text(content, encoding="utf-8")
    print(f"[ok] merged into {SYSTEM_PROMPT.relative_to(ROOT)}")


def merge_flutter_candidate() -> None:
    body = read_spec()
    escaped = body.replace("\\", "r\\").replace('"""', r"\"\"\"")
    injection = (
        f"\n{DART_BEGIN}\n"
        f"const String dynamicStructuralEngineSpec = r'''\n{escaped}\n''';\n"
        f"{DART_END}\n"
    )
    if not CANDIDATE_DART.exists():
        print(f"[skip] {CANDIDATE_DART} missing")
        return
    content = CANDIDATE_DART.read_text(encoding="utf-8")
    content = _inject_between_markers(content, injection, DART_BEGIN, DART_END)
    CANDIDATE_DART.write_text(content, encoding="utf-8")
    print(f"[ok] merged into {CANDIDATE_DART.relative_to(ROOT)}")


def merge_block2_txt() -> None:
    """Append spec to every suno_v2_block2_*.txt tool file (once)."""
    tools = sorted((ROOT / "tools").glob("suno_v2_block2_*.txt"))
    body = read_spec()
    for path in tools:
        content = path.read_text(encoding="utf-8")
        if "Dynamic Structural Engine" in content and BEGIN_MARKER not in content:
            print(f"[skip] {path.name} already references DSE")
            continue
        marker = f"\n\n--- Dynamic Structural Engine (merged) ---\n{body}\n"
        if marker.strip() in content:
            print(f"[skip] {path.name} already contains full DSE body")
            continue
        with path.open("a", encoding="utf-8") as f:
            f.write(marker)
        print(f"[ok] appended to {path.name}")


def verify_dart_runtime() -> None:
    """Check Dart module tree exposes key DSE symbols."""
    if not DSE_DART.exists():
        print(f"[missing] {DSE_DART}")
        return
    dart_files = [
        DSE_DART,
        DART_UTILS / "structural_family_resolver.dart",
        DART_UTILS / "final_chorus_mutation_rule.dart",
        DART_UTILS / "structure_assembler.dart",
        DART_UTILS / "suno_syntax_renderer.dart",
    ]
    symbols = {
        "StructuralFamily": "structural_family_resolver.dart",
        "FinalChorusMutation": "final_chorus_mutation_rule.dart",
        "DensityBudgetEnforcer": "dynamic_structural_engine.dart",
        "SunoSyntaxRenderer": "suno_syntax_renderer.dart",
        "StructureAssembler": "structure_assembler.dart",
        "DynamicStructuralEngine": "dynamic_structural_engine.dart",
    }
    contents = {
        p.name: p.read_text(encoding="utf-8")
        for p in dart_files
        if p.exists()
    }
    for symbol, expected_file in symbols.items():
        blob = contents.get(expected_file, "")
        if symbol in blob:
            print(f"[ok] {symbol} present in {expected_file}")
        else:
            print(f"[warn] {expected_file} missing {symbol}")


def verify_python_runtime() -> None:
    """Check Python runtime exposes key functions/classes."""
    if not DSE_PY.exists():
        print(f"[missing] {DSE_PY}")
        return
    content = DSE_PY.read_text(encoding="utf-8").lower()
    for name in (
        "structuralfamily",
        "resolve_structural_family",
        "assemble_sections",
        "mutation_for",
        "enforce_density_budget",
        "user_block_directive",
        "dynamic_structural_user_block",
    ):
        if name not in content:
            print(f"[warn] {DSE_PY.name} missing {name}")
        else:
            print(f"[ok] {name} present in {DSE_PY.name}")


def main() -> None:
    if not SPEC.is_file():
        print(f"[error] missing spec: {SPEC}", file=sys.stderr)
        raise SystemExit(1)
    print("=== Dynamic Structural Engine merge ===")
    merge_python_system_prompt()
    merge_flutter_candidate()
    merge_block2_txt()
    verify_dart_runtime()
    verify_python_runtime()
    print("=== DSE merge complete ===")


if __name__ == "__main__":
    main()
