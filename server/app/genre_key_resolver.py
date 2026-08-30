"""Shared primary+fusion genre key resolution — aliases, primary-first, boundary matching."""

from __future__ import annotations

import re
from typing import Iterable

# Longest phrases first when expanding (handled via sort at apply time).
_GENRE_ALIASES: tuple[tuple[str, str], ...] = (
    ("alternative rock", "rock / alternative"),
    ("contemporary gospel", "praise and worship"),
    ("contemporary r&b", "contemporary r&b"),
    ("lo-fi hip hop", "boom bap"),
    ("praise and worship", "praise and worship"),
    ("praise/worship", "praise and worship"),
    ("melodic techno", "deep house"),
    ("progressive house", "progressive house"),
    ("modern country", "modern country"),
    ("soulful house", "deep house"),
    ("indie rock", "rock / alternative"),
    ("heavy metal", "rock / alternative"),
    ("tech house", "deep house"),
    ("liquid dnb", "drum and bass"),
    ("jazz rap", "jazz"),
    ("uk drill", "trap"),
    ("vinahouse", "amapiano"),
    ("reggaeton", "afrobeats"),
    ("shoegaze", "rock / alternative"),
    ("neurofunk", "drum and bass"),
    ("neo-soul", "neo-soul"),
    ("drill", "trap"),
    ("rnb", "contemporary r&b"),
    ("punk", "rock / alternative"),
    ("soul", "neo-soul"),
)


def normalize_genre_blob(
    primary: str,
    fusion: str = "",
    *,
    extra_replacements: tuple[tuple[str, str], ...] = (),
    apply_default_aliases: bool = True,
) -> str:
    # Normalize R&B → rnb before '&' → 'and' so "R&B" / "90s R&B" hit the rnb lane.
    blob = f"{primary} {fusion}".lower().strip()
    blob = re.sub(r"r\s*&\s*b", "rnb", blob)
    blob = blob.replace("&", "and")
    # Longest-first + word-boundary so "dub" does not rewrite "dubstep", etc.
    for old, new in sorted(extra_replacements, key=lambda pair: -len(pair[0])):
        pattern = rf"(?<![a-z0-9]){re.escape(old)}(?![a-z0-9])"
        blob = re.sub(pattern, new, blob)
    if apply_default_aliases:
        for alias, target in sorted(_GENRE_ALIASES, key=lambda pair: -len(pair[0])):
            if alias in blob:
                blob = f"{blob} {target}"
    return " ".join(blob.split())


def key_matches_blob(key: str, blob: str) -> bool:
    pattern = rf"(?<![a-z0-9]){re.escape(key)}(?![a-z0-9])"
    return bool(re.search(pattern, blob))


def _best_key(keys: Iterable[str], blob: str) -> str:
    best = ""
    for key in keys:
        if key_matches_blob(key, blob) and len(key) > len(best):
            best = key
    return best


def resolve_genre_key(
    keys: Iterable[str],
    primary: str,
    fusion: str = "",
    *,
    default: str,
    extra_replacements: tuple[tuple[str, str], ...] = (),
    apply_default_aliases: bool = True,
) -> str:
    key_set = set(keys)
    if fusion.strip():
        primary_hit = _best_key(
            key_set,
            normalize_genre_blob(
                primary,
                "",
                extra_replacements=extra_replacements,
                apply_default_aliases=apply_default_aliases,
            ),
        )
        if primary_hit:
            return primary_hit
    return (
        _best_key(
            key_set,
            normalize_genre_blob(
                primary,
                fusion,
                extra_replacements=extra_replacements,
                apply_default_aliases=apply_default_aliases,
            ),
        )
        or default
    )
