"""Generate lib/core/utils/genre_fx_matrix_data.dart from tools/genre_fx_matrix.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "tools" / "genre_fx_matrix.json"
out = root / "lib" / "core" / "utils" / "genre_fx_matrix_data.dart"

raw = json.loads(src.read_text(encoding="utf-8"))
lines = [
    "// GENERATED from tools/genre_fx_matrix.json — do not edit by hand.",
    "// Rebuild: python tools/gen_genre_fx_matrix_dart.py",
    "",
    "class GenreFxMatrixData {",
    "  GenreFxMatrixData._();",
    "  static const Map<String, Map<String, Map<String, String>>> profiles = {",
]
for genre in sorted(raw.keys()):
    levels = raw[genre]
    lines.append(f"    '{genre}': {{")
    for level in ("1", "2", "3"):
        row = levels[level]
        style = json.dumps(row.get("style", ""), ensure_ascii=False)
        lyrics = json.dumps(row.get("lyrics", ""), ensure_ascii=False)
        lines.append(f"      '{level}': {{'style': {style}, 'lyrics': {lyrics}}},")
    lines.append("    },")
lines.extend(
    [
        "  };",
        "}",
        "",
    ]
)
out.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {len(raw)} genres -> {out}")
