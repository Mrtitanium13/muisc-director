"""Dual-genre split-DNA routing — GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX PART 1."""

from __future__ import annotations


def fusion_active(fusion: str) -> bool:
    f = fusion.strip().lower()
    if not f:
        return False
    return f not in {"none", "n/a", "na", "-", "—"}


def genre_hybridization_user_block(primary: str, fusion: str = "") -> str:
    """Inject dominant/subordinate roles when Primary + Fusion are both set."""
    p = primary.strip()
    f = fusion.strip()
    if not p or not fusion_active(f):
        return ""

    return "\n".join(
        [
            "GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX — PART 1 (Split-DNA; _fusionActive=true):",
            f"Genre A DOMINANT primaryGenre={p}: global BPM, drum grid, structural block tags, "
            "line symmetry, main climax grid (Section II + Section IV).",
            f"Genre B SUBORDINATE subGenreFusion={f}: signature instruments, vocal texture, "
            "dialect/patois, regional vocabulary — Intro, Verse 1, Breakdown only.",
            "Subordinate tag accent rule: name Genre B texture exactly once in Intro OR Verse 1 — "
            "never repeat in later sections.",
            "Hybridization drop rule: at [The Release], [Main Climax], [Drop], or peak chorus, "
            "sidechain/filter/delay/loop-mutate subordinate organic elements into Genre A kick grid — "
            "never raw acoustic competing with electronic climax.",
            "Amapiano primary exception: log drum = FM synthesized bass — never live/acoustic/organic.",
            "Lyric imagery: apply PART 2 Anti-Repetition + Regional Daily Life matrix for West African lanes.",
            "Full law: SUNO V4 Master Production Architecture Layer 3 + GENRE HUMANIZATION ENGINE § SECTION V.",
        ]
    )
