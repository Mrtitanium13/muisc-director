"""Genre and language pack resolution for the songwriter pipeline."""

from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path
from typing import Any

_ROOT = Path(__file__).resolve().parents[3]
_SRC = _ROOT / "tools" / "songwriter"


def _load_json_file(path: Path) -> dict[str, Any]:
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


@lru_cache(maxsize=1)
def _aliases() -> dict[str, str]:
    data = _load_json_file(_SRC / "genre_aliases.json")
    if data.get("aliases"):
        return {str(k).lower(): str(v) for k, v in data["aliases"].items()}
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        raw = (SONGWRITER_PROMPTS.get("genre_aliases") or {}).get("aliases") or {}
        return {str(k).lower(): str(v) for k, v in raw.items()}
    except Exception:
        return {}


@lru_cache(maxsize=1)
def _all_genres() -> dict[str, dict[str, Any]]:
    genres: dict[str, dict[str, Any]] = {}
    gdir = _SRC / "genres"
    if gdir.is_dir():
        for path in gdir.glob("*.json"):
            genres[path.stem] = json.loads(path.read_text(encoding="utf-8"))
    if genres:
        return genres
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        return dict(SONGWRITER_PROMPTS.get("genres") or {})
    except Exception:
        return {}


@lru_cache(maxsize=1)
def _all_languages() -> dict[str, dict[str, Any]]:
    langs: dict[str, dict[str, Any]] = {}
    ldir = _SRC / "languages"
    if ldir.is_dir():
        for path in ldir.glob("*.json"):
            data = json.loads(path.read_text(encoding="utf-8"))
            langs[path.stem] = data
            lid = str(data.get("id") or path.stem)
            langs[lid.lower()] = data
    if langs:
        return langs
    try:
        from app.songwriter.prompts_data import SONGWRITER_PROMPTS

        for stem, data in (SONGWRITER_PROMPTS.get("languages") or {}).items():
            langs[stem] = data
            lid = str((data or {}).get("id") or stem)
            langs[lid.lower()] = data
        return langs
    except Exception:
        return {}


def _norm_genre(genre: str) -> str:
    g = (genre or "").strip().lower()
    g = re.sub(r"\s+", " ", g)
    return g


def resolve_genre_pack_id(genre: str, subgenre: str = "") -> str:
    aliases = _aliases()
    for candidate in (_norm_genre(subgenre), _norm_genre(genre)):
        if not candidate:
            continue
        if candidate in aliases:
            return aliases[candidate]
        compact = candidate.replace(" ", "").replace("-", "").replace("&", "")
        for key, pack_id in aliases.items():
            k2 = key.replace(" ", "").replace("-", "").replace("&", "")
            if compact == k2 or compact in k2 or k2 in compact:
                return pack_id
    genres = _all_genres()
    compact = _norm_genre(genre).replace(" ", "").replace("-", "")
    if compact:
        for pack_id in genres:
            pid = pack_id.replace("_", "")
            if pid in compact or compact in pid:
                return pack_id
    return "pop"


def resolve_genre_pack(genre: str, subgenre: str = "") -> dict[str, Any]:
    pack_id = resolve_genre_pack_id(genre, subgenre)
    genres = _all_genres()
    pack = genres.get(pack_id) or genres.get("pop") or {}
    out = dict(pack)
    out["_resolved_id"] = pack_id
    return out


def resolve_language_pack_id(language: str) -> str:
    lang = (language or "English").strip().lower()
    if any(x in lang for x in ("zh-en", "mixed", "code-switch", "code switch")):
        return "mixed_zh_en"
    if ("zh" in lang or "chinese" in lang or "mandarin" in lang) and (
        "en" in lang or "english" in lang
    ):
        return "mixed_zh_en"
    if "hant" in lang or "traditional" in lang or "cantonese" in lang or "粵" in lang:
        return "zh_hant"
    if "hans" in lang or "simplified" in lang or "chinese" in lang or "zh" in lang or "mandarin" in lang:
        return "zh_hans"
    return "en"


def resolve_language_pack(language: str) -> dict[str, Any]:
    pack_id = resolve_language_pack_id(language)
    langs = _all_languages()
    pack = langs.get(pack_id) or langs.get("en") or {}
    out = dict(pack)
    out["_resolved_id"] = pack_id
    return out


def list_genre_pack_ids() -> list[str]:
    return sorted(_all_genres().keys())
