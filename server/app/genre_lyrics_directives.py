"""Genre-specific Block 2 lyric direction — runtime user-block overrides before generation."""

from __future__ import annotations

_HARDSTYLE_LANES = (
    "hardstyle",
    "rawstyle",
    "euphoric hardstyle",
    "hard bounce",
)


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary} {fusion}".lower()


def _blob_contains_any(blob: str, needles: tuple[str, ...]) -> bool:
    return any(kw in blob for kw in needles)


def is_hardstyle_lane(primary: str, fusion: str = "") -> bool:
    return _blob_contains_any(_genre_blob(primary, fusion), _HARDSTYLE_LANES)


def hardstyle_lyrics_user_block() -> str:
    return (
        "CRITICAL DIRECTION FOR HARDSTYLE LYRICS:\n"
        "1. BAN all mundane, cozy, or intimate bedroom/pop imagery "
        "(no coffee, lighters, group chats, or soft romance).\n"
        "2. ENFORCE an epic, cinematic, aggressive, or dystopian tone "
        "(destiny, fire, power, fury, revolution, breaking chains, eternity — "
        "allowed in this lane even when generic anti-AI bans apply).\n"
        "3. [Monologue] blocks must read like an epic movie trailer voiceover, "
        "not a poem or domestic diary entry.\n"
        "4. The line immediately before any [Drop] must be ONE high-impact shout "
        "phrase (4 words max) as the pre-drop hype trigger; keep [Drop] instrumental "
        "unless genre FX tags require vocal chops only."
    )


def genre_lyrics_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    """Runtime lyric overrides keyed to primary/fusion genre."""
    if is_hardstyle_lane(primary_genre, sub_genre_fusion):
        return hardstyle_lyrics_user_block()
    return ""
