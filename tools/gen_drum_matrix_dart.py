"""Generate lib/core/utils/drum_matrix_data.dart from tools/drum_matrix.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "tools" / "drum_matrix.json"
out = root / "lib" / "core" / "utils" / "drum_matrix_data.dart"

raw = json.loads(src.read_text(encoding="utf-8"))
lines = [
    "// GENERATED from tools/drum_matrix.json — do not edit by hand.",
    "// Rebuild: python tools/gen_drum_matrix_dart.py",
    "",
    "class DrumMatrixData {",
    "  DrumMatrixData._();",
    "  static const Map<String, Map<String, String>> profiles = {",
]
for key in sorted(raw.keys(), key=lambda k: (-len(k), k)):
    p = raw[key]
    kit = p["kit"].replace("'", r"\'")
    pattern = p["pattern"].replace("'", r"\'")
    mix = p["mix"].replace("'", r"\'")
    negative = p["negative"].replace("'", r"\'")
    lines.append(
        f"    '{key}': {{"
        f"'kit': '{kit}', "
        f"'pattern': '{pattern}', "
        f"'mix': '{mix}', "
        f"'negative': '{negative}'"
        f"}},"
    )
lines.extend(["  };", "}", ""])
out.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {len(raw)} profiles -> {out}")
