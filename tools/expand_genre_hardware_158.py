"""Expand Part E v2.1 from 80 keyword clusters to 158 genre-keyed hardware profiles.

Reads genres from lib/core/constants/genre_data.dart (subGenresByCategory),
maps each to the best-matching cluster profile, and writes
tools/genre_hardware_profiles_v2_1.json (158 entries).

Run: python tools/expand_genre_hardware_158.py
Then: python tools/gen_genre_hardware_modules.py
"""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENRE_DART = ROOT / "lib" / "core" / "constants" / "genre_data.dart"
CLUSTER_JSON = ROOT / "tools" / "genre_hardware_profiles_v2_1_clusters.json"
OUT_JSON = ROOT / "tools" / "genre_hardware_profiles_v2_1.json"

_CATEGORY_SKIP = {
    "EDM",
    "Hip Hop",
    "R&B/Soul",
    "Pop",
    "Rock/Metal",
    "Country",
    "Gospel",
    "Jazz/Blues",
    "Latin",
    "Reggae/Dub",
    "Afro/World",
    "Cinematic",
}

# Explicit 1:1 overrides where substring scoring would pick the wrong cluster.
GENRE_TO_CLUSTER: dict[str, str] = {
    "House": "EDM.1",
    "Deep House": "EDM.1",
    "Soulful House": "EDM.1",
    "Tech House": "EDM.2",
    "Progressive House": "EDM.3",
    "Melodic House": "EDM.3",
    "Big Room": "EDM.4",
    "Big Room Techno": "EDM.4",
    "EDM Bounce": "EDM.4",
    "Techno": "EDM.5",
    "Hard Techno": "EDM.5",
    "Melodic Techno": "EDM.5",
    "Acid Techno": "EDM.5",
    "Trance": "EDM.6",
    "Uplifting Trance": "EDM.6",
    "Dubstep": "EDM.7",
    "Melodic Dubstep": "EDM.7",
    "Drum & Bass": "EDM.8",
    "Liquid DnB": "EDM.8",
    "Future Bass": "EDM.9",
    "Future House": "EDM.9",
    "Hardstyle": "EDM.10",
    "Rawstyle": "EDM.10",
    "Hard Bounce": "EDM.10",
    "Nu-Disco": "EDM.11",
    "Future Funk": "EDM.11",
    "Disco House": "EDM.11",
    "Vinahouse": "EDM.12",
    "Amapiano-Vinahouse": "EDM.12",
    "Amapiano": "EDM.12",
    "Afro House": "EDM.14",
    "UK Garage": "EDM.14",
    "Jersey Club": "EDM.15",
    "Hip Hop": "HH.1",
    "Boom Bap": "HH.1",
    "Trap": "HH.2",
    "Melodic Trap": "HH.2",
    "Drill": "HH.3",
    "UK Drill": "HH.3",
    "NY Drill": "HH.3",
    "Phonk": "HH.4",
    "Lo-Fi Hip Hop": "HH.6",
    "Chillhop": "HH.6",
    "Cloud Rap": "HH.2",
    "Jazz Rap": "HH.1",
    "Afro-Swing": "HH.5",
    "Afro Rap": "HH.5",
    "R&B": "R&B.1",
    "Contemporary R&B": "R&B.1",
    "90s R&B": "R&B.3",
    "New Jack Swing": "R&B.3",
    "Neo-Soul": "R&B.2",
    "Soul": "R&B.2",
    "Quiet Storm": "R&B.4",
    "Trap Soul": "R&B.5",
    "Funk": "FX.6",
    "Pop": "POP.1",
    "Mainstream Pop": "POP.1",
    "Pop / Max Martin": "POP.1",
    "Electropop": "POP.2",
    "Dance Pop": "POP.2",
    "Bedroom Pop": "POP.4",
    "Indie Pop": "POP.4",
    "K-Pop": "POP.3",
    "J-Pop": "POP.3",
    "C-Pop": "POP.3",
    "Mandopop": "ASI.1",
    "Latin Pop": "LAT.2",
    "Synth Pop": "FX.5",
    "Hyperpop": "FX.3",
    "Rock": "RCK.3",
    "Indie Rock": "RCK.1",
    "Alt Rock": "RCK.1",
    "Alternative": "RCK.1",
    "Pop Punk": "RCK.2",
    "Emo": "RCK.2",
    "Punk": "RCK.2",
    "Hard Rock": "RCK.3",
    "Classic Rock": "RCK.3",
    "Metal": "RCK.4",
    "Heavy Metal": "RCK.4",
    "Metalcore": "RCK.4",
    "Death Metal": "RCK.4",
    "Post-Rock": "RCK.5",
    "Shoegaze": "RCK.5",
    "Dream Pop": "RCK.5",
    "Country": "CTY.1",
    "Modern Country": "CTY.1",
    "Outlaw Country": "CTY.2",
    "Americana": "CTY.4",
    "Folk-Rock": "CTY.4",
    "Bluegrass": "CTY.3",
    "Indie Folk": "FOL.1",
    "Singer-Songwriter": "FOL.1",
    "Folk": "FOL.1",
    "Gospel": "GOS.1",
    "Traditional Gospel": "GOS.1",
    "Contemporary Gospel": "GOS.2",
    "Urban Gospel": "GOS.2",
    "Praise/Worship": "GOS.3",
    "Modern Worship": "GOS.3",
    "Worship Ballad": "GOS.4",
    "CCM": "GOS.5",
    "Pop Worship": "GOS.5",
    "Afro-Gospel": "GOS.6",
    "Southern Gospel": "GOS.7",
    "Country Gospel": "GOS.7",
    "Jazz": "JAZ.1",
    "Vocal Jazz": "JAZ.1",
    "Bebop": "JAZ.1",
    "Big Band": "JAZ.1",
    "Smooth Jazz": "JAZ.2",
    "Jazz Fusion": "JAZ.2",
    "Fusion": "JAZ.2",
    "Nu-Jazz": "JAZ.3",
    "Acid Jazz": "JAZ.3",
    "Blues": "BLU.1",
    "Chicago Blues": "BLU.1",
    "Delta Blues": "BLU.1",
    "Reggaeton": "LAT.1",
    "Dembow": "LAT.10",
    "Bachata": "LAT.3",
    "Salsa": "LAT.4",
    "Bossa Nova": "LAT.5",
    "Cumbia": "LAT.6",
    "Vallenato": "LAT.6",
    "Brazilian Funk": "LAT.7",
    "Sertanejo": "LAT.8",
    "Forró": "LAT.9",
    "Reggae": "CAR.1",
    "Roots Reggae": "CAR.1",
    "Dub": "CAR.1",
    "Dancehall": "CAR.2",
    "Soca": "CAR.3",
    "Afrobeats": "AFR.1",
    "Highlife": "AFR.2",
    "Fuji": "AFR.3",
    "Gqom": "AFR.4",
    "City Pop": "ASI.2",
    "Bollywood": "ASI.3",
    "Filmi": "ASI.3",
    "Punjabi": "ASI.4",
    "Bhangra": "ASI.4",
    "Middle Eastern": "ASI.3",
    "Orchestral": "FX.2",
    "Film Score": "FX.2",
    "Cinematic": "FX.2",
    "Trailer": "FX.2",
    "Ambient": "FX.1",
    "Dark Ambient": "FX.1",
    "Ambient Score": "FX.1",
    "Vaporwave": "FX.4",
    "New Wave": "FX.5",
    "Industrial": "FX.7",
    "EBM": "FX.7",
    "Synthwave": "FX.8",
    "Retrowave": "FX.8",
}


def _slug(genre: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", genre.lower()).strip("_")
    return s or "default"


def _parse_genres() -> list[str]:
    """All unique sub-genres from GenreData.subGenresByCategory (incl. Hip Hop, Pop, etc.)."""
    text = GENRE_DART.read_text(encoding="utf-8")
    marker = "static const Map<String, List<String>> subGenresByCategory"
    start = text.index(marker)
    end = text.index("  };", start)
    block = text[start:end]
    genres: list[str] = []
    for arr in re.finditer(r"\[(.*?)\]", block, re.DOTALL):
        for m in re.finditer(r"'([^']+)'", arr.group(1)):
            genres.append(m.group(1))
    seen: set[str] = set()
    out: list[str] = []
    for g in genres:
        if g not in seen:
            seen.add(g)
            out.append(g)
    return out


def _score_match(genre: str, keyword: str) -> int:
    g = genre.lower().strip()
    k = keyword.lower().strip()
    if not g or not k:
        return 0
    if g == k:
        return 1000 + len(k)
    if k in g:
        return 500 + len(k)
    if len(g) >= 4 and g in k:
        return 200 + len(g)
    return 0


def _resolve_cluster_id(genre: str, clusters: list[dict]) -> str:
    if genre in GENRE_TO_CLUSTER:
        return GENRE_TO_CLUSTER[genre]
    best_id = ""
    best_score = 0
    for cluster in clusters:
        cid = cluster["id"]
        for kw in cluster.get("keywords", []):
            score = _score_match(genre, str(kw))
            if score > best_score:
                best_score = score
                best_id = cid
    if not best_id:
        return clusters[0]["id"]
    return best_id


def _genre_style(cluster: dict, genre: str) -> str:
    base = str(cluster.get("style_descriptors", "")).strip()
    g_lower = genre.lower()
    if g_lower in base.lower():
        return base
    if base:
        return f"{genre}, {base[0].lower()}{base[1:]}"
    return f"{genre}, polished producer mix, genre-native capture, release-ready LUFS"


def main() -> None:
    if not CLUSTER_JSON.is_file():
        CLUSTER_JSON.write_text(OUT_JSON.read_text(encoding="utf-8"), encoding="utf-8")

    clusters = json.loads(CLUSTER_JSON.read_text(encoding="utf-8"))
    by_id = {c["id"]: c for c in clusters}
    default = by_id.get("DEFAULT") or clusters[0]

    genres = _parse_genres()
    if len(genres) not in (157, 158):
        raise SystemExit(
            f"Expected 157–158 unique app genres, found {len(genres)}: {genres}"
        )

    out: list[dict] = []
    for i, genre in enumerate(genres, start=1):
        cluster_id = _resolve_cluster_id(genre, clusters)
        if cluster_id not in by_id:
            raise SystemExit(f"Unknown cluster {cluster_id!r} for genre {genre!r}")
        src = deepcopy(by_id[cluster_id])
        out.append(
            {
                "id": f"HW.{i:03d}.{_slug(genre)}",
                "genre": genre,
                "cluster_id": cluster_id,
                "keywords": [genre.lower()],
                "style_descriptors": _genre_style(src, genre),
                "lead_vocal": src.get("lead_vocal", ""),
                "vocal_chain": src.get("vocal_chain", ""),
                "drums": src.get("drums", ""),
                "bass": src.get("bass", ""),
                "keys_synths": src.get("keys_synths", ""),
                "outboard": src.get("outboard", ""),
                "monitoring": src.get("monitoring", ""),
                "room": src.get("room", ""),
                "vibe": src.get("vibe", ""),
            }
        )

    OUT_JSON.write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT_JSON.relative_to(ROOT)} ({len(out)} profiles)")


if __name__ == "__main__":
    main()
