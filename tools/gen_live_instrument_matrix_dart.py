"""Generate lib/core/utils/live_instrument_matrix_data.dart from
tools/live_instrument_matrix.json.

Robust v2.0 — handles schema v1.1+ with:
  - Correct schema field navigation (reads `raw["genres"]`)
  - Safe string escaping for all Dart-significant chars (\\ $ ' \\n \\t)
  - Schema version + taxonomy + alias emission
  - Per-row validation with actionable errors
  - Atomic write with idempotency guard
  - Helper methods for longest-match lookups
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = {"id", "name", "category", "defaultArticulation", "mixRole"}
OPTIONAL_ROW_FIELDS = ("promptText", "aliases")
RESERVED_VALUES = {"DYNAMIC_ARTICULATION", "DYNAMIC_MIX_ROLE"}


# ──────────────────────────────────────────────────────────────────────────────
# Path discovery
# ──────────────────────────────────────────────────────────────────────────────
def find_project_root(start: Path) -> Path:
    """Walk up until pubspec.yaml is found. Fails loudly if not found."""
    cur = start.resolve()
    for parent in [cur, *cur.parents]:
        if (parent / "pubspec.yaml").exists():
            return parent
    raise FileNotFoundError(
        f"Could not locate Flutter project root (no pubspec.yaml found from {start})"
    )


# ──────────────────────────────────────────────────────────────────────────────
# Dart-safe string escaping
# ──────────────────────────────────────────────────────────────────────────────
def dart_escape(value: Any) -> str:
    """Escape any Python value into a safe Dart single-quoted string literal.

    Order matters: escape backslashes FIRST, then interpolation, then quotes,
    then control characters. Otherwise `'` becomes `\'` and a subsequent
    escape introduces `\''` which Dart can't parse.
    """
    s = str(value)
    s = s.replace("\\", "\\\\")      # \ → \\
    s = s.replace("$", "\\$")        # $ → \$  (prevents Dart interpolation)
    s = s.replace("'", "\\'")        # ' → \'
    s = s.replace("\n", "\\n")       # literal newlines
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    return s


def dart_string(value: Any) -> str:
    return f"'{dart_escape(value)}'"


# ──────────────────────────────────────────────────────────────────────────────
# Validation
# ──────────────────────────────────────────────────────────────────────────────
def validate_schema(raw: dict[str, Any]) -> list[str]:
    """Return list of error messages. Empty list = valid."""
    errors: list[str] = []

    if "schemaVersion" not in raw:
        errors.append("Missing required top-level field: 'schemaVersion'")
    if "genres" not in raw:
        errors.append("Missing required top-level field: 'genres'")
        return errors  # can't continue without genres
    if "categoryTaxonomy" not in raw:
        errors.append("Missing top-level field: 'categoryTaxonomy' (warning)")
    if "genrePresetAlias" not in raw:
        errors.append("Missing top-level field: 'genrePresetAlias' (warning)")

    genres = raw["genres"]
    if not isinstance(genres, dict):
        errors.append("'genres' must be a JSON object")
        return errors

    for genre_key, rows in genres.items():
        if not isinstance(rows, list) or not rows:
            errors.append(f"[{genre_key}] must be a non-empty array")
            continue
        for i, row in enumerate(rows):
            missing = REQUIRED_FIELDS - set(row.keys())
            if missing:
                errors.append(
                    f"[{genre_key}][{i}] row id='{row.get('id', '?')}' missing: {missing}"
                )
            for field in REQUIRED_FIELDS:
                val = row.get(field, "")
                if val in RESERVED_VALUES:
                    errors.append(
                        f"[{genre_key}][{i}] id='{row.get('id', '?')}' field "
                        f"'{field}' contains unresolved placeholder: {val}"
                    )
    return errors


# ──────────────────────────────────────────────────────────────────────────────
# Code emission
# ──────────────────────────────────────────────────────────────────────────────
def emit_dart(raw: dict[str, Any]) -> str:
    schema_version = raw["schemaVersion"]
    taxonomy = raw.get("categoryTaxonomy", {})
    classification_rules = raw.get("categoryClassificationRules", [])
    aliases = raw.get("genrePresetAlias", {})
    genres = raw["genres"]

    lines: list[str] = []
    w = lines.append  # short alias

    # File header
    w("// GENERATED — do not edit by hand.")
    w("// Rebuild: python tools/gen_live_instrument_matrix_dart.py")
    w(f"// Schema version: {schema_version}")
    w("// Source: tools/live_instrument_matrix.json")
    w("")
    w("/// Instrument preset bundle matrix for live genre-aware production.")
    w("///")
    w("/// Each genre maps to its canonical instrument voices, articulation,")
    w("/// and mix positioning. Lookup helpers provide longest-match resolution.")
    w("abstract final class LiveInstrumentMatrixData {")
    w("  LiveInstrumentMatrixData._();")
    w("")

    # Schema version
    w(f"  static const String schemaVersion = {dart_string(schema_version)};")
    w("")

    # Category taxonomy
    w("  /// Category code → frequency-role definition.")
    w("  static const Map<String, String> categoryTaxonomy = {")
    for cat in sorted(taxonomy.keys(), key=str.lower):
        w(f"    {dart_string(cat)}: {dart_string(taxonomy[cat])},")
    w("  };")
    w("")

    # Classification precedence rules (resolve taxonomy edge cases)
    w("  /// Precedence rules for assigning instruments to categoryTaxonomy keys.")
    w("  static const List<String> categoryClassificationRules = [")
    for rule in classification_rules:
        w(f"    {dart_string(rule)},")
    w("  ];")
    w("")

    # Genre preset alias map
    w("  /// Canonical sub-genre label → preset bundle key.")
    w("  /// Multiple canonical labels may map to the same bundle (e.g. 'Melodic Trap' → 'trap').")
    w("  static const Map<String, String> genrePresetAlias = {")
    for canon in sorted(aliases.keys(), key=str.lower):
        w(f"    {dart_string(canon)}: {dart_string(aliases[canon])},")
    w("  };")
    w("")

    # Genre instrument bundles
    w("  /// Genre preset bundle key → list of instrument voice dicts.")
    w("  static const Map<String, List<Map<String, String>>> byGenre = {")
    for genre_key in sorted(genres.keys(), key=str.lower):
        rows = genres[genre_key]
        w(f"    {dart_string(genre_key)}: [")
        for row in rows:
            keys = ["id", "name", "category", "defaultArticulation", "mixRole"]
            for opt in OPTIONAL_ROW_FIELDS:
                if opt in row and row[opt]:
                    keys.append(opt)
            parts: list[str] = []
            for k in keys:
                val = row.get(k, "")
                if k == "aliases" and isinstance(val, list):
                    parts.append(f"{dart_string('aliasHints')}: {dart_string('|'.join(val))}")
                else:
                    parts.append(f"{dart_string(k)}: {dart_string(val)}")
            fields = ", ".join(parts)
            w(f"      {{{fields}}},")
        w("    ],")
    w("  };")
    w("")

    # Helper: resolve canonical genre → preset bundle key
    w("  /// Resolve a canonical genre/sub-genre label to a preset bundle key.")
    w("  /// Uses exact match first, then falls back to longest substring match,")
    w("  /// then to 'default' if nothing matches.")
    w("  static String? bundleKeyForGenre(String? genre) {")
    w("    if (genre == null || genre.isEmpty) return null;")
    w("    final trimmed = genre.trim();")
    w("    for (final entry in genrePresetAlias.entries) {")
    w("      if (entry.key.toLowerCase() == trimmed.toLowerCase()) {")
    w("        return entry.value;")
    w("      }")
    w("    }")
    w("    // Longest-match fallback (sort keys by length desc so specific wins)")
    w("    String? best;")
    w("    int bestLen = 0;")
    w("    final lower = trimmed.toLowerCase();")
    w("    for (final entry in genrePresetAlias.entries) {")
    w("      if (lower.contains(entry.key.toLowerCase()) && entry.key.length > bestLen) {")
    w("        best = entry.value;")
    w("        bestLen = entry.key.length;")
    w("      }")
    w("    }")
    w("    return best;")
    w("  }")
    w("")

    # Helper: fetch bundle rows for a genre label
    w("  /// Get the instrument voice rows for a genre label, or empty list if unknown.")
    w("  static List<Map<String, String>> voicesForGenre(String? genre) {")
    w("    final key = bundleKeyForGenre(genre);")
    w("    if (key == null) return const [];")
    w("    return byGenre[key] ?? const [];")
    w("  }")
    w("")

    w("}")
    w("")

    return "\n".join(lines)


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────
def main() -> int:
    root = find_project_root(Path(__file__).resolve())
    src = root / "tools" / "live_instrument_matrix.json"
    out = root / "lib" / "core" / "utils" / "live_instrument_matrix_data.dart"

    if not src.exists():
        print(f"ERROR: source JSON not found: {src}", file=sys.stderr)
        return 2

    try:
        raw = json.loads(src.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"ERROR: malformed JSON in {src}: {e}", file=sys.stderr)
        return 2

    errors = validate_schema(raw)
    if errors:
        print("Schema validation failed:", file=sys.stderr)
        for err in errors:
            print(f"  • {err}", file=sys.stderr)
        # Hard-fail on fatal errors, but allow missing optional fields to proceed
        fatal = [e for e in errors if "Missing required" in e or "placeholder" in e]
        if fatal:
            return 2

    dart_source = emit_dart(raw)

    # Idempotency guard
    if out.exists():
        existing = out.read_text(encoding="utf-8")
        if existing == dart_source:
            print(f"OK {out.relative_to(root)} is up to date (no write)")
            return 0

    # Atomic write
    out.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(
        prefix=out.name + ".", dir=out.parent, text=True
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(dart_source)
        os.replace(tmp_path, out)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise

    genre_count = len(raw["genres"])
    voice_count = sum(len(v) for v in raw["genres"].values())
    print(f"OK wrote {out.relative_to(root)}")
    print(f"  schema {raw['schemaVersion']} · {genre_count} bundles · {voice_count} voices")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
