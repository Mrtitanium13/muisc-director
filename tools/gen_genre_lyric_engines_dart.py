"""Generate lib/core/constants/genre_lyric_engines_data.dart from tools/genre_lyric_routing.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
routing_path = root / "tools" / "genre_lyric_routing.json"
out = root / "lib" / "core" / "constants" / "genre_lyric_engines_data.dart"


def emit(raw: dict) -> str:
    guardrail = json.dumps(raw["global_guardrail"].strip(), ensure_ascii=False)
    inline = raw.get("inline_directives", {})
    inline_lines = ["  static const Map<String, String> inlineDirectives = {"]
    for key in sorted(inline.keys()):
        inline_lines.append(
            f"    {json.dumps(key)}: {json.dumps(inline[key].strip(), ensure_ascii=False)},"
        )
    inline_lines.append("  };")

    engines = raw.get("file_engines", {})
    engine_lines = ["  static const Map<String, String> fileEngineBodies = {"]
    for key in sorted(engines.keys()):
        rel = engines[key]
        body = (root / rel).read_text(encoding="utf-8").strip()
        engine_lines.append(
            f"    {json.dumps(key)}: {json.dumps(body, ensure_ascii=False)},"
        )
    engine_lines.append("  };")

    route_lines = ["  static const List<Map<String, dynamic>> routes = ["]
    for route in sorted(raw.get("routes", []), key=lambda r: r.get("priority", 99)):
        route_lines.append(f"    {json.dumps(route, ensure_ascii=False)},")
    route_lines.append("  ];")

    return "\n".join(
        [
            "// GENERATED from tools/genre_lyric_routing.json — do not edit by hand.",
            "// Rebuild: python tools/gen_genre_lyric_engines_dart.py",
            "",
            "class GenreLyricEnginesData {",
            "  GenreLyricEnginesData._();",
            f"  static const String globalGuardrail = {guardrail};",
            *inline_lines,
            *engine_lines,
            *route_lines,
            "}",
            "",
        ]
    )


def main() -> None:
    raw = json.loads(routing_path.read_text(encoding="utf-8"))
    out.write_text(emit(raw), encoding="utf-8")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
