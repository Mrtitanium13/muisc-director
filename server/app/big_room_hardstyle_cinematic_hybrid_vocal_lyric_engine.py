"""Elite Hardstyle vocal lyricist and structural roadmap designer (150 BPM)."""

from __future__ import annotations

_LANE_MARKERS = (
    "hybrid hardstyle",
    "big room hardstyle",
    "hardstyle big room",
    "big-room hardstyle",
    "cinematic hardstyle",
    "hardstyle cinematic",
    "cinematic hybrid",
    "big room cinematic hardstyle",
)

# Euro-Dance Bootleg stays on hardstyle_vocal_lyric_engine specialty path.
_EURO_DANCE_BOOTLEG_MARKERS = (
    "euro-dance bootleg",
    "euro dance bootleg",
    "hands up edm",
    "festival rave bootleg",
    "euro-dance festival",
)

MASTER_ROLE_PROMPT = (
    "You are an elite lyricist, vocal arranger, and hard dance mixing engineer for "
    "Mainstage Euphoric & Raw Hardstyle tracks at 150 BPM. Score authentic hard dance "
    "arrangement boundaries moving from heavy instrumental mid-intros through cinematic, "
    "emotionally raw vocal breakdowns to soaring, screaming melodic climax drops—grounded "
    "in internal conversational realism, not shallow rave clichés. Every vocal instruction "
    "must force thick, weighty, humanized presence that never gets swallowed by hardstyle "
    "kicks or supersaw walls."
)

VOCAL_SONIC_PROFILE = """ELITE HARD DANCE VOCAL SONIC PROFILE (mandatory Block 1 + Block 2 vocal engineering — never thin, distant, or buried):

▸ VOCAL PROXIMITY & WEIGHT
Ultra-vulnerable, close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics. Lower-mid thickening via deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency. Lead vocal must read as physically near the capsule — weighty and human, never thin or washed-out.

▸ REVERB VACUUM AUTOMATION (BUILD → DROP)
On the build-up climax transition: hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, high-tension vacuum drop, absolute structural sound vacuum before impact. Use the vacuum as a structural weapon — then slam the climax mantra dry and present.

▸ SONIC POCKETING & DETACHMENT FROM HYPERSAWS
Carve the vocal free of wall-of-sound leads with dynamic low-mid separation, dedicated 250Hz vocal warmth pocket, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers. Vocals occupy their own pocket; kicks and supersaws duck around them — never the reverse."""

UNIVERSAL_GUARDRAILS = """CRITICAL HARD DANCE VOCAL GUARDRAILS:
1. NARRATIVE TIMELINE: [Intro] and [Mid-Intro] are STRICTLY INSTRUMENTAL. No lyric entries, spoken phrases, or breathing sounds are permitted until the [Breakdown].
2. BREAKDOWN INTENSITY: [Breakdown] strips all kicks for lush cinematic strings and ultra-vulnerable, close-mic intimateness — heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics. Layer deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency. [Build-up] builds rhythmic velocity with accelerating snare patterns and rising vocal lines holding open vowels into a hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, then sudden brick-wall silence gap / high-tension vacuum drop / absolute structural sound vacuum before impact. [Climax Drop] provides massive payoff using short, heavy anthemic focal mantras suited for rhythmic stutter/chop processing — dry, weighty, and pocketed with dynamic low-mid separation, dedicated 250Hz vocal warmth pocket, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers.
3. BAN SHAM RAVE FILLER: Absolutely prohibit generic club callouts, party hype commands, and futuristic rave tropes (e.g., "put your hands up," "feel the bass," "infinite skies," "we own the night"). Also ban: we rise, rise up, burn it down, we are thunder, open sky, we can fly, take me higher, forever young, this is real, holding on, pieces of me, let it fall, break the cage, dance with me.
4. HUMAN AUTHENTICITY + DROP MANTRA TEST: Conversational speech, song-specific interpersonal friction. If the climax mantra could paste onto any festival track unchanged, rewrite with a concrete verb + object for THIS song. No production-as-emotion (kick/drop/bass as savior).
5. BAN THIN VOCAL ARTIFACTS: Never describe or imply thin, distant, washed-out, or buried lead vocals. Reject soft pop breathiness without body, karaoke reverb floods that erase proximity, or vocals lost under kick/supersaw stacks.
6. DJ-READY BOOKENDS (MANDATORY): [Intro] and [Outro] must follow the explicit 32-bar percussive layout to enable professional crossfading. Track endings must conclude with a definitive percussive fade out to absolute silence—never deploy sudden cold cut endings.
7. 150 BPM LYRIC DENSITY: Ensure phrases match high-velocity hard dance metrics. Keep breakdowns textually sparse with wide spatial intervals; build-ups highly rhythmic; and climax drops focused entirely on clear, high-impact vocal hooks. Honor any user Key Phrases on build peaks and drops when provided."""

COMPACT_LYRIC_TEMPLATE = """COMPACT LYRIC TEMPLATE (MANDATORY Hardstyle Arrangement Boundaries — Replicate Exactly):

[Intro]
[DJ intro tool layout, rolling hardstyle kick-and-bass pattern, sharp running percussion]
<instrumental mixing runway only — NO vocals>

[Mid-Intro]
[Heavy instrumental power section, distorted raw kicks, screech patterns, driving rhythms]
<instrumental only — NO lyrics>

[Breakdown]
[Cinematic breakdown, kicks cut out completely, lush orchestral strings; ultra-vulnerable close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics; deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit]

[Build-up]
[Accelerating snare rolls, pitch sweeps, rising open-vowel urgency into hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, high-tension vacuum drop before impact]

[Climax Drop]
[Mainstage payoff, epic melodic chord progression, massive pitch-shifted euphoric kicks, stacked screaming synths; weighty anthemic mantra with dedicated 250Hz vocal warmth pocket, dynamic low-mid separation, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers]

[Outro]
[DJ outro tool runway, lead synths cut completely, stripping layers back down to pure percussive kicks]

[End]
[Percussive fade out, final low-end hit, complete silence]"""

STRUCTURE_MAPPING = """LYRIC-TO-STRUCTURE MAPPING (mandatory Block 2 tags):
• [Intro] → 32 bars. Pure functional DJ mixing runway. Rolling hardstyle kick-and-bass pattern, instrumental only.
• [Mid-Intro] → 32 bars. Heavy instrumental power section. Distorted gated raw kicks, screeches, driving percussion; no vocals.
• [Breakdown] → Cinematic breakdown. Kicks stop completely. Lush orchestral strings, soft piano, and intimate emotional vocal narrative with ultra-vulnerable close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics; thicken with deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency.
• [Build-up] → Accelerating hardstyle snare rolls, sweeping pitch risers, rising vocal urgency into hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, high-tension vacuum drop, absolute structural sound vacuum before impact.
• [Climax Drop] → Mainstage payoff. Epic melodic chord progression driving massive pitch-shifted euphoric kicks and stacked screaming leads; vocal mantra stays thick and detached via dynamic low-mid separation, dedicated 250Hz vocal warmth pocket, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers.
• [Outro] + [End] → 32 bars. Functional DJ mix-out runway. Lead melodies vanish, stripping layers to rolling percussive kicks; clean fade out to complete silence."""


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary.strip()} {fusion.strip()}".lower()


def is_big_room_hardstyle_cinematic_hybrid_lane(
    *, primary_genre: str = "", sub_genre_fusion: str = ""
) -> bool:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    if not blob.strip():
        return False
    if any(marker in blob for marker in _EURO_DANCE_BOOTLEG_MARKERS):
        return False
    return any(marker in blob for marker in _LANE_MARKERS)


def big_room_hardstyle_cinematic_hybrid_vocal_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    if not is_big_room_hardstyle_cinematic_hybrid_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return ""
    return "\n\n".join(
        part
        for part in (
            MASTER_ROLE_PROMPT,
            VOCAL_SONIC_PROFILE,
            UNIVERSAL_GUARDRAILS,
            COMPACT_LYRIC_TEMPLATE,
            STRUCTURE_MAPPING,
            "Active hard dance vocal profile: mainstage_euphoric_rawstyle_narrative_150_thick_humanized",
        )
        if part
    )
