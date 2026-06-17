"""Dual-genre split-DNA routing — SUNO V4 §1 Layer 3 Hybridization Law."""

from __future__ import annotations


def _fusion_active(fusion: str) -> bool:
    f = fusion.strip().lower()
    if not f:
        return False
    return f not in {"none", "n/a", "na", "-", "—"}


def genre_hybridization_user_block(primary: str, fusion: str = "") -> str:
    """Inject dominant/subordinate roles when Primary + Fusion are both set."""
    p = primary.strip()
    f = fusion.strip()
    if not p or not _fusion_active(f):
        return ""

    return "\n".join(
        [
            "DUAL-GENRE HYBRIDIZATION (mandatory — Split-DNA routing):",
            f"Genre A DOMINANT ({p}): BPM, drum architecture, structural block tags, climax grid.",
            f"Genre B SUBORDINATE ({f}): signature instruments, vocal texture, regional vocabulary — "
            "only in low-density sections (Intro, Verse 1, Breakdown).",
            "Hybridization drop rule: at [The Release], [Main Climax], [Drop], or peak chorus, "
            "subordinate acoustic/organic elements must be sidechained, filtered, delayed, or loop-mutated "
            "to lock into Genre A's kick grid — never raw acoustic fighting the electronic climax.",
            "Subordinate tag accent rule: name Genre B texture once in Intro or Verse 1 only — "
            "do not repeat acoustic/subordinate instrument labels in Verse 2, Bridge, or breaks.",
            "Amapiano primary: log drum = FM synthesized bass — never tag as live/acoustic log drum.",
            "Full law: SUNO V4 Master Production Architecture §1 Layer 3 Dual-Genre Hybridization Law.",
        ]
    )
