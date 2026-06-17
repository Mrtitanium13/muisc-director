"""Generate Dart genre hardware resolver from tools/genre_hardware_profiles_v2_1.json.

Run: python tools/gen_genre_hardware_modules.py
"""

from __future__ import annotations

import json
import pathlib

root = pathlib.Path(__file__).resolve().parents[1]
src = root / "tools" / "genre_hardware_profiles_v2_1.json"
dart_out = root / "lib" / "core" / "constants" / "genre_hardware_profiles_data.dart"


def _dart_str(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def main() -> None:
    rows = json.loads(src.read_text(encoding="utf-8"))
    buf = [
        "// ignore_for_file: lines_longer_than_80_chars",
        "//",
        "// **Generated** — do not edit by hand.",
        "// Source: tools/genre_hardware_profiles_v2_1.json",
        "// Rebuild: python tools/gen_genre_hardware_modules.py",
        "//",
        "class GenreHardwareProfilesData {",
        "  GenreHardwareProfilesData._();",
        "",
        "  static const List<Map<String, dynamic>> profiles = [",
    ]
    for row in rows:
        kw = ", ".join(_dart_str(k) for k in row.get("keywords", []))
        buf.append("    {")
        buf.append(f"      'id': {_dart_str(row['id'])},")
        buf.append(f"      'keywords': <String>[{kw}],")
        for key in (
            "style_descriptors",
            "lead_vocal",
            "vocal_chain",
            "drums",
            "bass",
            "keys_synths",
            "outboard",
            "monitoring",
            "room",
            "vibe",
        ):
            buf.append(f"      {_dart_str(key)}: {_dart_str(str(row.get(key, '')))},")
        buf.append("    },")
    buf.extend(
        [
            "  ];",
            "}",
            "",
        ]
    )
    dart_out.write_text("\n".join(buf), encoding="utf-8")
    print(f"Wrote {dart_out.relative_to(root)} ({len(rows)} profiles)")


if __name__ == "__main__":
    main()
