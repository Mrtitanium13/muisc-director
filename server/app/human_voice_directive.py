"""Cross-genre human-voice directive + stock-phrase detector (Dart parity).

Prompt text stays principles-only. Pattern lists grow HERE (and in Dart
MeaningfulnessCheck) — not in the injected directive — so models stop
copying ban examples.
"""

from __future__ import annotations

HUMAN_VOICE_DIRECTIVE = """
HUMAN VOICE DIRECTIVE v2.0 (non-negotiable — violations are rejected and retried)

0. ANTI-PARROT (highest priority): NEVER reuse prompt examples, pool
   exemplars, or prior-run stock scenes. Every concrete detail must be
   MOTIVATED by this brief's theme, genre, region, and narrator. If a
   detail could swap into an unrelated song unchanged, delete it.
   Do not assemble checklist bingo (clock-time + random city + kitchen
   prop + "Mama said"). Banned stock kits are enforced by runtime QA.

1. SENSORY ANCHOR: ≥2 lines carry a sensory detail earned by the scene
   (sight / sound / touch / taste / smell). No kitchen-prop padding.
   Invent fresh details — never copy examples from this directive.

2. GROUNDING (when natural): at most one grounded cue — name, place, brand,
   year, workplace — that fits THIS story. Never force a city name.

3. NUMBER / TIME (optional): a specific number only when it serves the
   story. No default clock-time crutch.

4. DIALOGUE (optional): quoted speech only when someone in the story
   actually speaks. No filler "Mama said…" beats.

5. EMOTIONAL THROUGHLINE: the song orbits ONE primary emotion matching the
   brief. Choose one; stay in it.

6. SHOW, DON'T TELL — but stay human. Prefer everyday idiom over literary
   body metaphor (e.g. "song in my heart", not ornate chest/lungs poetry).
   Kitchen-table test: if you wouldn't say it to a friend, rewrite.

7. NO EQUALITY LINES: every line must be true of THIS narrator and THIS
   addressee. If it could fit any song ever written, rewrite it.

8. NARRATOR MEMORY (internal craft): before writing, fix one specific
   memory that colors ≥2 lines. Don't print the narrator's name unless it
   serves the song. Speak like a person, not a greeting card.
""".strip()

# Exact genre labels treated as instrumental-first (no human-voice inject).
# Short tokens use exact match so "melodic techno" still gets the directive.
_INSTRUMENTAL_EXACT = frozenset(
    {
        "orchestral",
        "ambient",
        "dark ambient",
        "ambient score",
        "post-rock",
        "post rock",
        "dub",
        "techno",
        "minimal",
        "film score",
        "instrumental",
    }
)

_INSTRUMENTAL_PHRASES = (
    "ambient score",
    "dark ambient",
    "post-rock",
    "post rock",
    "film score",
)

STOCK_PHRASE_PATTERNS = (
    "cold tile",
    "on cold tile",
    "tile in lagos",
    "cold tile in lagos",
    "3 am on cold",
    "at 3 am on",
    "bleach on my hands",
    "scrubbing the floor",
    "scrubbing floors",
    "bent receipt",
    "receipt lay curled",
    "by the kettle",
    "count grace before receipts",
    "kept my score till i could not count",
    "song in my chest",
    "rhythm in my chest",
    "breath fills my lungs",
    "fills my lungs",
    "borrowed and holy",
)


def emits_lyrics(genre: str) -> bool:
    """True when human-voice directive should inject for this genre label."""
    g = (genre or "").lower().strip()
    if not g:
        return True
    if g in _INSTRUMENTAL_EXACT:
        return False
    return not any(p in g for p in _INSTRUMENTAL_PHRASES)


def stock_phrase_hits(text: str) -> list[str]:
    lower = (text or "").lower()
    return [p for p in STOCK_PHRASE_PATTERNS if p in lower]


def build_stock_retry_suffix(hits: list[str]) -> str:
    """Retry prompt — principles only (do not re-list stock phrases to copy)."""
    joined = ", ".join(hits) if hits else "stock concrete kit"
    return (
        "LYRIC QUALITY RETRY — Output the full two-block reply again. "
        f"Prior Block 2 hit banned stock formulas ({joined}). "
        "Invent theme-motivated details only; every concrete detail must be "
        "earned by THIS brief. Prefer everyday human speech over literary "
        "body metaphor. Preserve Block 1; rewrite Block 2 performable lyrics "
        "through [End]."
    )
