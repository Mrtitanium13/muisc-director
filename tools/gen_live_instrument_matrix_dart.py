"""Generate lib/core/utils/live_instrument_matrix_data.dart from tools/live_instrument_matrix.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "tools" / "live_instrument_matrix.json"
out = root / "lib" / "core" / "utils" / "live_instrument_matrix_data.dart"

raw = json.loads(src.read_text(encoding="utf-8"))
lines = [
    "// GENERATED from tools/live_instrument_matrix.json — do not edit by hand.",
    "// Rebuild: python tools/gen_live_instrument_matrix_dart.py",
    "",
    "class LiveInstrumentMatrixData {",
    "  LiveInstrumentMatrixData._();",
    "  static const Map<String, List<Map<String, String>>> byGenre = {",
]
for genre in sorted(raw.keys(), key=lambda k: (-len(k), k)):
    rows = raw[genre]
    lines.append(f"    '{genre}': [")
    for row in rows:
        kit = str(row["id"]).replace("'", r"\'")
        name = str(row["name"]).replace("'", r"\'")
        cat = str(row.get("category", "")).replace("'", r"\'")
        art = str(row.get("defaultArticulation", "")).replace("'", r"\'")
        mix = str(row.get("mixRole", "")).replace("'", r"\'")
        lines.append(
            f"      {{'id': '{kit}', 'name': '{name}', 'category': '{cat}', "
            f"'defaultArticulation': '{art}', 'mixRole': '{mix}'}}," 
        )
    lines.append("    ],")
lines.extend(["  };", "}", ""])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {len(raw)} genres -> {out}")
