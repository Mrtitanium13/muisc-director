#!/usr/bin/env python3
"""Merge tools/songwriter sources → Dart + Python generated prompt modules.

Usage:
    python tools/merge_songwriter_prompts.py

Outputs:
    lib/core/constants/songwriter_prompts_data.dart
    server/app/songwriter/prompts_data.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "tools" / "songwriter"
OUT_DART = ROOT / "lib" / "core" / "constants" / "songwriter_prompts_data.dart"
OUT_PY = ROOT / "server" / "app" / "songwriter" / "prompts_data.py"

INCLUDE_RE = re.compile(r"\{\{include:([^}]+)\}\}")


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _expand_includes(text: str, base: Path, stack: list[Path] | None = None) -> str:
    stack = stack or []

    def repl(match: re.Match[str]) -> str:
        rel = match.group(1).strip().replace("\\", "/")
        target = (SRC / rel).resolve()
        if not str(target).startswith(str(SRC.resolve())):
            raise ValueError(f"Include escapes songwriter root: {rel}")
        if target in stack:
            raise ValueError(f"Circular include: {rel}")
        if not target.is_file():
            raise FileNotFoundError(f"Missing include: {rel}")
        return _expand_includes(_read(target), base, stack + [target])

    return INCLUDE_RE.sub(repl, text)


def _load_json(name: str) -> dict:
    return json.loads(_read(SRC / name))


def _dart_string(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def _collect_stages() -> dict[str, str]:
    stages: dict[str, str] = {}
    for path in sorted((SRC / "stages").glob("stage_*.txt")):
        stages[path.stem] = _expand_includes(_read(path), SRC)
    return stages


def _collect_modules() -> dict[str, str]:
    modules: dict[str, str] = {}
    for path in sorted((SRC / "modules").glob("*.txt")):
        modules[path.stem] = _read(path)
    return modules


def _collect_genres() -> dict[str, dict]:
    genres: dict[str, dict] = {}
    for path in sorted((SRC / "genres").glob("*.json")):
        genres[path.stem] = json.loads(_read(path))
    return genres


def _collect_languages() -> dict[str, dict]:
    languages: dict[str, dict] = {}
    lang_dir = SRC / "languages"
    if not lang_dir.is_dir():
        return languages
    for path in sorted(lang_dir.glob("*.json")):
        languages[path.stem] = json.loads(_read(path))
    return languages


def write_dart(
    stages: dict[str, str],
    modules: dict[str, str],
    genres: dict[str, dict],
    languages: dict[str, dict],
    configs: dict[str, dict],
) -> None:
    """Emit string maps + raw JSON blobs (parsed at runtime — keeps Dart const-safe)."""
    OUT_DART.parent.mkdir(parents=True, exist_ok=True)
    config_json = {
        name.replace(".json", ""): data for name, data in configs.items()
    }
    lines = [
        "// GENERATED FILE — do not edit by hand.",
        "// Source: tools/songwriter/ | Regenerator: tools/merge_songwriter_prompts.py",
        "",
        "import 'dart:convert';",
        "",
        "class SongwriterPromptsData {",
        "  SongwriterPromptsData._();",
        "",
        "  static const String version = '1.1.0';",
        "",
        "  static const Map<String, String> modules = {",
    ]
    for k, v in modules.items():
        lines.append(f"    {_dart_string(k)}: {_dart_string(v)},")
    lines += [
        "  };",
        "",
        "  static const Map<String, String> stages = {",
    ]
    for k, v in stages.items():
        lines.append(f"    {_dart_string(k)}: {_dart_string(v)},")
    lines += [
        "  };",
        "",
        f"  static const String genresJson = {_dart_string(json.dumps(genres, ensure_ascii=False))};",
        f"  static const String languagesJson = {_dart_string(json.dumps(languages, ensure_ascii=False))};",
        f"  static const String configsJson = {_dart_string(json.dumps(config_json, ensure_ascii=False))};",
        "",
        "  static Map<String, dynamic> get genres =>",
        "      jsonDecode(genresJson) as Map<String, dynamic>;",
        "",
        "  static Map<String, dynamic> get languages =>",
        "      jsonDecode(languagesJson) as Map<String, dynamic>;",
        "",
        "  static Map<String, dynamic> get configs =>",
        "      jsonDecode(configsJson) as Map<String, dynamic>;",
        "",
        "  static Map<String, dynamic> config(String name) =>",
        "      (configs[name] as Map?)?.cast<String, dynamic>() ?? const {};",
        "}",
        "",
    ]
    OUT_DART.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_DART.relative_to(ROOT)}")


def write_py(
    stages: dict[str, str],
    modules: dict[str, str],
    genres: dict[str, dict],
    languages: dict[str, dict],
    configs: dict[str, dict],
) -> None:
    OUT_PY.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": "1.1.0",
        "modules": modules,
        "stages": stages,
        "genres": genres,
        "languages": languages,
        **{k.replace(".json", ""): v for k, v in configs.items()},
    }
    body = (
        '"""GENERATED FILE — do not edit by hand.\n'
        "Source: tools/songwriter/ | Regenerator: tools/merge_songwriter_prompts.py\n"
        '"""\n\n'
        "from __future__ import annotations\n\n"
        f"SONGWRITER_PROMPTS = {json.dumps(payload, ensure_ascii=False, indent=2)}\n"
    )
    OUT_PY.write_text(body, encoding="utf-8")
    print(f"Wrote {OUT_PY.relative_to(ROOT)}")


def main() -> None:
    if not SRC.is_dir():
        raise SystemExit(f"Missing {SRC}")
    stages = _collect_stages()
    modules = _collect_modules()
    genres = _collect_genres()
    languages = _collect_languages()
    configs = {
        "model_routing.json": _load_json("model_routing.json"),
        "quality_rubric.json": _load_json("quality_rubric.json"),
        "forbidden_phrases.json": _load_json("forbidden_phrases.json"),
        "output_modes.json": _load_json("output_modes.json"),
        "story_arcs.json": _load_json("story_arcs.json"),
        "pipeline_manifest.json": _load_json("pipeline_manifest.json"),
        "quality_modes.json": _load_json("quality_modes.json"),
        "genre_aliases.json": _load_json("genre_aliases.json"),
    }
    write_dart(stages, modules, genres, languages, configs)
    write_py(stages, modules, genres, languages, configs)
    print(
        f"Stages: {len(stages)} | Modules: {len(modules)} | "
        f"Genres: {len(genres)} | Languages: {len(languages)}"
    )


if __name__ == "__main__":
    main()
