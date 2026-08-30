"""One-shot builder: extract 1.3.0 matrix from parent transcript Dart paste → JSON."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def find_project_root(start: Path) -> Path:
    cur = start.resolve()
    for parent in [cur, *cur.parents]:
        if (parent / "pubspec.yaml").exists():
            return parent
    raise FileNotFoundError(f"No pubspec.yaml from {start}")


def _dart_to_python_map(body: str) -> str:
    """Convert Dart map literal body to JSON-parseable object literal."""
    body = re.sub(r"//[^\n]*", "", body)
    body = body.replace("'", '"')
    body = re.sub(r'\\"', "'", body)  # restore apostrophes in escaped quotes
    body = re.sub(r",\s*}", "}", body)
    body = re.sub(r",\s*]", "]", body)
    body = re.sub(r",\s*$", "", body.strip())
    return "{" + body + "}"


def _parse_map_literal(body: str) -> dict:
    py = _dart_to_python_map(body)
    return json.loads(py)


def _row_from_dart(row: dict) -> dict:
    out = {
        "id": row["id"],
        "name": row["name"],
        "category": row["category"],
        "defaultArticulation": row["defaultArticulation"],
        "mixRole": row["mixRole"],
    }
    if row.get("promptText"):
        out["promptText"] = row["promptText"]
    hints = row.get("aliasHints", "")
    if hints:
        out["aliases"] = [a.strip() for a in hints.split("|") if a.strip()]
    return out


def _parse_by_genre(body: str) -> dict[str, list[dict]]:
    """Parse byGenre block with comment section headers."""
    body = re.sub(r"//[^\n]*", "", body)
    genres: dict[str, list[dict]] = {}
    pattern = re.compile(
        r"'([a-z_]+)'\s*:\s*\[(.*?)\](?=(?:,\s*'[a-z_]+'\s*:)|,\s*$)",
        re.S,
    )
    for match in pattern.finditer(body):
        key = match.group(1)
        rows_text = match.group(2)
        rows: list[dict] = []
        for row_match in re.finditer(r"\{([^{}]+)\}", rows_text):
            chunk = row_match.group(1)
            row: dict[str, str] = {}
            for field in re.finditer(
                r"'(\w+)'\s*:\s*'((?:\\'|[^'])*)'",
                chunk,
            ):
                row[field.group(1)] = field.group(2).replace("\\'", "'")
            if row:
                rows.append(_row_from_dart(row))
        if rows:
            genres[key] = rows
    return genres


def extract_from_transcript(transcript_path: Path) -> dict:
    text = ""
    for line in transcript_path.read_text(encoding="utf-8").splitlines():
        if "Schema bumped to 1.3.0" in line:
            obj = json.loads(line)
            text = obj["message"]["content"][0]["text"]
            break
    if not text:
        raise RuntimeError("Could not find 1.3.0 paste in transcript")

    tax_m = re.search(
        r"categoryTaxonomy = \{(.*?)\};\s*/// Canonical",
        text,
        re.S,
    )
    alias_m = re.search(
        r"genrePresetAlias = \{(.*?)\};\s*/// Genre preset",
        text,
        re.S,
    )
    genre_m = re.search(
        r"byGenre = \{(.*?)\};\s*/// Resolve",
        text,
        re.S,
    )
    if not (tax_m and alias_m and genre_m):
        raise RuntimeError("Failed to extract matrix sections from paste")

    taxonomy = _parse_map_literal(tax_m.group(1))
    aliases = _parse_map_literal(alias_m.group(1))
    genres = _parse_by_genre(genre_m.group(1))

    return {
        "schemaVersion": "1.3.0",
        "categoryTaxonomy": taxonomy,
        "genrePresetAlias": aliases,
        "genres": genres,
    }


def main() -> int:
    root = find_project_root(Path(__file__).resolve())
    transcript = (
        Path.home()
        / ".cursor"
        / "projects"
        / "c-Users-tommy-Desktop-music-director"
        / "agent-transcripts"
        / "9c0290ce-c05f-4e99-ab8e-2b2e28b11ae5"
        / "9c0290ce-c05f-4e99-ab8e-2b2e28b11ae5.jsonl"
    )
    if not transcript.exists():
        print(f"ERROR: transcript not found: {transcript}", file=sys.stderr)
        return 2

    data = extract_from_transcript(transcript)
    out = root / "tools" / "live_instrument_matrix.json"
    out.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    genre_count = len(data["genres"])
    voice_count = sum(len(v) for v in data["genres"].values())
    print(f"OK wrote {out.relative_to(root)}")
    print(f"  schema {data['schemaVersion']} · {genre_count} bundles · {voice_count} voices")
    print(f"  aliases: {len(data['genrePresetAlias'])} · categories: {len(data['categoryTaxonomy'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
