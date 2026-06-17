"""Generate lib/core/utils/code_translation_matrix_data.dart from tools/code_translation_matrix.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "tools" / "code_translation_matrix.json"
out = root / "lib" / "core" / "utils" / "code_translation_matrix_data.dart"

raw = json.loads(src.read_text(encoding="utf-8"))
lines = [
    "// GENERATED from tools/code_translation_matrix.json — do not edit by hand.",
    "// Rebuild: python tools/gen_code_translation_matrix_dart.py",
    "",
    "class CodeTranslationMatrixData {",
    "  CodeTranslationMatrixData._();",
    "  static const Map<String, Map<String, String>> matrix = {",
]
for code in sorted(raw.keys()):
    lines.append(f"    '{code}': {{")
    for cat, val in raw[code].items():
        esc = str(val).replace("'", r"\'")
        lines.append(f"      '{cat}': '{esc}',")
    lines.append("    },")
lines.extend(["  };", "}", ""])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {len(raw)} codes -> {out}")
