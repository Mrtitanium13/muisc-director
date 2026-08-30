"""Generate Dart genre hardware data from tools/genre_hardware_profiles_v2_1.json.

Run: python tools/gen_genre_hardware_modules.py

Emits real Unicode (including &) via json.dumps(ensure_ascii=False) — never HTML
entities. Index keys are diacritic-folded so Forró / forro resolve the same.
"""

from __future__ import annotations

import json
import pathlib
import re
import unicodedata

root = pathlib.Path(__file__).resolve().parents[1]
src = root / "tools" / "genre_hardware_profiles_v2_1.json"
dart_out = root / "lib" / "data" / "generated" / "genre_hardware_profiles_data.dart"

_WS_RE = re.compile(r"\s+")
_PUNCT_RE = re.compile(r"[^\w\s&]+", re.UNICODE)


def _decode_entities(s: str) -> str:
    """Undo accidental HTML entity encoding in source strings."""
    out = s
    # Decode repeatedly in case of double-encoding (&amp;amp;).
    for _ in range(3):
        nxt = out.replace("&amp;", "&").replace("&AMP;", "&")
        if nxt == out:
            break
        out = nxt
    return out


def _dart_str(s: str) -> str:
    """Dart string literal with real &, accents, etc. (never &amp;)."""
    return json.dumps(_decode_entities(s), ensure_ascii=False)


def _norm_genre(genre: str) -> str:
    """Lowercase, decode entities, strip diacritics, collapse punctuation."""
    s = _decode_entities(genre).lower().strip()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = _PUNCT_RE.sub(" ", s)
    return _WS_RE.sub(" ", s).strip()


def main() -> None:
    rows = json.loads(src.read_text(encoding="utf-8"))
    by_genre: dict[str, int] = {}
    for i, row in enumerate(rows):
        genre = str(row.get("genre", "")).strip()
        if genre:
            by_genre[_norm_genre(genre)] = i

    dart_out.parent.mkdir(parents=True, exist_ok=True)

    buf = [
        "// ignore_for_file: lines_longer_than_80_chars",
        "//",
        "// **Generated** — do not edit by hand.",
        "// Source: tools/genre_hardware_profiles_v2_1.json",
        "// Rebuild: python tools/expand_genre_hardware_158.py && python tools/gen_genre_hardware_modules.py",
        "// Consumer: lib/services/genre_hardware_profiles.dart",
        "//",
        "class GenreHardwareProfilesData {",
        "  GenreHardwareProfilesData._();",
        "",
        f"  /// One hardware profile per app genre ({len(rows)} entries).",
        "  static const List<Map<String, dynamic>> profiles = [",
    ]
    for row in rows:
        kw = ", ".join(_dart_str(k) for k in row.get("keywords", []))
        buf.append("    {")
        buf.append(f"      'id': {_dart_str(row['id'])},")
        if row.get("genre"):
            buf.append(f"      'genre': {_dart_str(str(row['genre']))},")
        if row.get("cluster_id"):
            buf.append(
                f"      'cluster_id': {_dart_str(str(row['cluster_id']))},"
            )
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
            # Prefer single-quoted map keys; values via json.dumps for safe escapes.
            buf.append(f"      '{key}': {_dart_str(str(row.get(key, '')))},")
        buf.append("    },")
    buf.append("  ];")
    buf.append("")
    buf.append(
        "  /// Diacritic-folded genre label → index in [profiles] "
        "(matches GenreHardwareProfiles.normalizeGenre)."
    )
    buf.append("  static const Map<String, int> profileIndexByGenre = {")
    for genre, idx in sorted(by_genre.items(), key=lambda e: e[1]):
        buf.append(f"    {_dart_str(genre)}: {idx},")
    buf.append("  };")
    buf.extend(["}", ""])
    dart_out.write_text("\n".join(buf), encoding="utf-8")
    print(f"Wrote {dart_out.relative_to(root)} ({len(rows)} profiles)")


if __name__ == "__main__":
    main()
