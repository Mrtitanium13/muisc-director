"""Elite Hardstyle Production Module (150 BPM)."""

from __future__ import annotations

MODULE_ID = "hardstyle_production_elite"

CORE_META = {
    "primary_tags": [
        "Hardstyle",
        "Euphoric Hardstyle",
        "Rawstyle",
        "Mainstage Hard Dance",
    ],
    "rhythmic_blueprint": [
        "150 BPM",
        "Driving 4/4 hard dance time signature",
        "Relentless festival power curve",
    ],
    "mood_profiles": [
        "Defiant victory",
        "Cinematic melancholy",
        "Uplifting mainstage euphoria",
        "High-octane aggression",
    ],
    "aesthetic": "Defiant mainstage festival hard dance",
}

HYBRID_SOUND_PALETTE = {
    "synth_instrumentation": [
        "Stacked hypersaw lead oscillators with ultra-wide stereo detuning and high-end air boost",
        "Piercing square-wave pluck layer for transient sharpness and punch on melodic note starts",
        "Access Virus TI emulated raw wave leads combined with classic Roland JP-8000 supersaw arrays",
        "Saturated mid-range synth brass and polyphonic chord layers for massive sonic thickness",
        "Dissonant, tearing rave screeches generated via aggressive pitch-envelope modulation and cross-modulation",
    ],
    "cinematic_verse_breakdown": [
        "Ethereal, high-density orchestral string section layouts (staccato and legato violins, cellos)",
        "Ultra-vulnerable, close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics",
        "Deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency",
        "Vulnerable acoustic piano chord layers with an intentionally softened high-frequency profile",
        "Cinematic orchestral horn swells and sub-bass brass markers providing organic grandeur",
        "Deep, sustained atmospheric sub-bass beds anchoring the acoustic instrumentation",
    ],
    "drum_and_percussion_kit": [
        "Distorted rawstyle gated kicks with heavy, hollow front-end tok transients and sweeping sub tails",
        "Pitched euphoric mainstage climax kicks designed to track basslines note-for-note across scales",
        "Pounding rolling reverse bass kicks with distinct syncopated off-beat low-end rebounds",
        "Crisp TR-909 open hi-hats sitting hard on the off-beats with tight decay control",
        "Aggressive, wide stereo claps layered with white noise bursts and high-frequency pre-shifted impact transients",
        "Heavy acoustic orchestral impact timpani, taiko drums, and cinematic tom fills for structural transitions",
        "High-energy stereo ride cymbals, crash cymbals with massive decay, and acoustic tambourine loops",
    ],
    "fx_transitions_sound_design": [
        "Accelerating high-pass filtered kick punches speeding from quarter notes into 32nd-note rolls",
        "Crisp 150 BPM acoustic snare rolls layered with rising pitch-shifted white noise sweeps",
        "Laser-style tonal pitch risers, automated sub-drops, and reverse crash cymbal sweeps",
        "Tonal multi-bar riser chords matched to the upcoming drop key signature",
        "Hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion",
        "Sudden brick-wall silence gap, high-tension vacuum drop, absolute structural sound vacuum before impact",
        "Subtle background festival crowd chant ambience and cheer fx sheets layered beneath breakdowns",
    ],
}

MIXING_DIRECTIONS = [
    "Aggressive sidechain ducking tuned explicitly to fast 150 BPM kick envelopes on all lead and pad groups while preserving vocal proximity weight",
    "Dynamic low-mid separation with a dedicated 250Hz vocal warmth pocket so the lead never gets swallowed by hypersaw stacks",
    "Heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers",
    "Brick-wall limited loud master retaining heavy low-end distortion headroom without causing digital clipping",
    "Wide stereo expansion on screaming leads, mono-locked phase-coherent kick bass engine beneath 120 Hz",
    "Precise surgical mid-range EQ cuts to make space for tearing lead frequencies and thick humanized vocal presence",
    "Distortion multi-band saturation on raw kicks to split and process low-end rumble and mid-range tok independently",
]

LYRIC_STRUCTURE_MAPPING = {
    "dj_intro_runway": (
        "32 bars. Pure functional DJ mixing runway. Rolling hardstyle kick-and-bass pattern, "
        "sharp percussion running, creeping background drive; instrumental only."
    ),
    "mid_intro": (
        "32 bars. Heavy instrumental power section. Distorted gated raw kicks, screech patterns, "
        "driving percussive layers without melodic leads; no vocals."
    ),
    "breakdown_verse": (
        "Cinematic breakdown. Kicks stop completely. Lush orchestral strings, soft piano, "
        "and ultra-vulnerable close-mic intimateness with heavy throat texture, high-compression "
        "proximity effect, detailed chest resonance, gravelly conversational delivery, "
        "1176-slammed mouth clicks and raw breathing dynamics; thicken with deep formant-shifted "
        "vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, "
        "organic F# minor pitch consistency."
    ),
    "build_up": (
        "Accelerating hardstyle snare roll patterns, sweeping pitch risers, rising vocal lines "
        "holding open vowels into hyper-expanding 100% wet hall reverb washout, massive cathedral "
        "vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, "
        "high-tension vacuum drop, absolute structural sound vacuum before impact."
    ),
    "climax_drop": (
        "Mainstage payoff. Epic melodic chord progression driving massive pitch-shifted "
        "euphoric kicks and stacked screaming synth leads; weighty anthemic vocal mantra held in "
        "a dedicated 250Hz vocal warmth pocket with dynamic low-mid separation, heavy sidechain "
        "ducking on spatial effects, sharp transient isolation, pristine high-end air boost "
        "cutting through dense 150 BPM hypersaw layers."
    ),
    "dj_outro_runway": (
        "32 bars. Functional DJ mix-out runway. Lead melodies vanish, stripping layers back down "
        "to rolling percussive kicks for flawless crossfading."
    ),
}

LAYER_WEIGHTS = {
    "core": "critical",
    "cinematic": "critical",
    "mid_intro_engine": "critical",
    "climax_drop": "critical",
    "mixing": "high",
    "narrative_mapping": "standard",
}

EXTENDED_DJ_INTRO_BLOCK1_TAGS = (
    "Authentic Hardstyle intro tool, rolling bass runway, "
    "150 BPM hard dance foundations, DJ ready."
)

EXTENDED_DJ_OUTRO_BLOCK1_TAGS = (
    "Authentic Hardstyle outro tool, percussive outro pocket, "
    "clean mix-out fade to complete silence."
)

COMPACT_LYRIC_TEMPLATE = """COMPACT LYRIC TEMPLATE (MANDATORY Hardstyle Arrangement Boundaries — Replicate Exactly):

[Intro]
[DJ intro tool layout, rolling hardstyle kick-and-bass pattern, sharp running percussion]
<instrumental mixing runway only — NO vocals>

[Mid-Intro]
[Heavy instrumental power section, distorted raw kicks, screech patterns, driving rhythms]
<instrumental only — NO lyrics>

[Breakdown]
[Cinematic breakdown, kicks cut out completely, lush orchestral strings; ultra-vulnerable close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics]

[Build-up]
[Accelerating snare rolls, pitch sweeps, rising open-vowel urgency into hyper-expanding 100% wet hall reverb washout, cathedral vocal diffusion swell, sudden brick-wall silence gap / vacuum drop before impact]

[Climax Drop]
[Mainstage payoff, epic melodic chord progression, massive pitch-shifted euphoric kicks, stacked screaming synths; thick humanized mantra in 250Hz warmth pocket with pristine high-end air boost through hypersaws]

[Outro]
[DJ outro tool runway, lead synths cut completely, stripping layers back down to pure percussive kicks]

[End]
[Percussive fade out, final low-end hit, complete silence]"""

_LANE_MARKERS = (
    "hardstyle",
    "euphoric hardstyle",
    "rawstyle",
    "hard dance",
    "hybrid hardstyle",
)


def _genre_blob(primary: str, fusion: str) -> str:
    return f"{primary.strip()} {fusion.strip()}".lower()


def matches_lane(*, primary_genre: str = "", sub_genre_fusion: str = "") -> bool:
    blob = _genre_blob(primary_genre, sub_genre_fusion)
    if not blob.strip():
        return False
    return any(marker in blob for marker in _LANE_MARKERS)


def compose_block1_seed() -> str:
    c = CORE_META
    p = HYBRID_SOUND_PALETTE
    return (
        f"{EXTENDED_DJ_INTRO_BLOCK1_TAGS} "
        f"{', '.join(c['primary_tags'])} · "
        f"{', '.join(c['rhythmic_blueprint'])} · "
        f"{', '.join(c['mood_profiles'])} · {c['aesthetic']}: "
        f"Synths — {', '.join(p['synth_instrumentation'])}; "
        f"Cinematic breakdown — {', '.join(p['cinematic_verse_breakdown'])}; "
        f"Mid-Intro engine & drums — {', '.join(p['drum_and_percussion_kit'])}; "
        f"Climax leads — {', '.join(p['synth_instrumentation'])}; "
        f"FX/transitions — {', '.join(p['fx_transitions_sound_design'])}. "
        f"Mix: {'; '.join(MIXING_DIRECTIONS)}. "
        f"{EXTENDED_DJ_OUTRO_BLOCK1_TAGS}"
    )


def compose_dj_mix_enforcement_block() -> str:
    return f"""DJ MIX ENFORCEMENT (Elite Hardstyle — MANDATORY):
- DJ intro (mix-in) = REQUIRED. 32-bar instrumental runway BEFORE any vocals. Rolling hardstyle kick-and-bass, sharp running percussion.
- Mid-Intro = REQUIRED instrumental power section — NO vocals until [Breakdown].
- DJ outro (mix-out) = REQUIRED. 32-bar mix-out runway AFTER climax. Strip leads; sustain percussive kicks; fade to complete silence.
- Block 1 MUST open with: "{EXTENDED_DJ_INTRO_BLOCK1_TAGS}"
- Block 1 MUST close with: "{EXTENDED_DJ_OUTRO_BLOCK1_TAGS}"
- Block 2 [Intro] + [Mid-Intro] = instrumental only — NO lyric lines until [Breakdown].
- NEVER skip, shorten, or cold-cut the DJ intro/outro bookends for this lane."""


def compose_arrangement_architecture(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    blob = f"{primary_genre.strip()} {sub_genre_fusion.strip()}".lower()
    m = LYRIC_STRUCTURE_MAPPING

    if "progressive" in blob:
        return f"""PROGRESSIVE EUPHORIC HARDSTYLE — MANDATORY 8-PART HARD DANCE ARC:
1. [Intro DJ Tool]: {m['dj_intro_runway']}
2. [Mid-Intro]: {m['mid_intro']}
3. [Breakdown Verse]: {m['breakdown_verse']}
4. [Build-up]: {m['build_up']}
5. [Climax Drop]: {m['climax_drop']}
6. [Breakdown Verse]: Emotional mid-track reset back down to orchestral strings, soft piano, ambient layers, and narrative vocals.
7. [Build-up]: Re-accelerating high-pass filters and snare loops to force maximal peak energy.
8. [Climax Drop]: Final monumental payoff with altered melody patterns and driving euphoric kicks.
9. [Outro DJ Tool]: {m['dj_outro_runway']}"""

    return f"""EUPHORIC HARDSTYLE — CANONICAL MAIN STAGE ARRANGEMENT ROADMAP:
1. [Intro DJ Tool]: {m['dj_intro_runway']}
2. [Mid-Intro]: {m['mid_intro']}
3. [Breakdown Verse]: {m['breakdown_verse']}
4. [Build-up]: {m['build_up']}
5. [Climax Drop]: {m['climax_drop']}
6. [Outro DJ Tool]: {m['dj_outro_runway']}"""


def compose_structural_constraints_block() -> str:
    return f"""STRUCTURAL CONSTRAINTS — HARDSTYLE ARRANGEMENT EXPECTATIONS (mandatory for Block 1 + Block 2):
1. No House Structures: The arrangement must follow the Hardstyle mid-intro to climax transition timeline.
2. Instrumental Intros/Mid-Intros: Vocals are strictly barred from entering until the primary [Breakdown] section.
3. Kicks are elements of tone: Climax drops must use pitched euphoric kicks shifting pitch alongside the chord melody.

{COMPACT_LYRIC_TEMPLATE}"""


def _bullet_list(items: list[str]) -> str:
    return "\n".join(f"• {item}" for item in items)


def compose_elite_module_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    c = CORE_META
    p = HYBRID_SOUND_PALETTE
    w = LAYER_WEIGHTS
    arrangement = compose_arrangement_architecture(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    return f"""ELITE HARDSTYLE ARRANGEMENT MODULE (150 BPM — mandatory Block 1 DNA + Block 2 structural boundaries; weave ALL layers into 130–150 word producer prose):

▸ CORE SYSTEM META & VIBE [weight: {w['core']}]
Primary: {' · '.join(c['primary_tags'])}
Rhythm: {' · '.join(c['rhythmic_blueprint'])}
Mood: {' · '.join(c['mood_profiles'])}
Aesthetic: {c['aesthetic']}

▸ SYNTH LEAD INSTRUMENTATION [weight: {w['climax_drop']}]
{_bullet_list(p['synth_instrumentation'])}

▸ HARDSTYLE MID-INTRO & DRUM KIT PALETTE [weight: {w['mid_intro_engine']}]
{_bullet_list(p['drum_and_percussion_kit'])}

▸ CINEMATIC BREAKDOWN PALETTE [weight: {w['cinematic']}]
{_bullet_list(p['cinematic_verse_breakdown'])}

▸ FX & TRANSITIONS SOUND DESIGN [weight: {w['mid_intro_engine']}]
{_bullet_list(p['fx_transitions_sound_design'])}

▸ PRODUCTION & MIXING STAGE [weight: {w['mixing']}]
{_bullet_list(MIXING_DIRECTIONS)}

{compose_structural_constraints_block()}

▸ ARRANGEMENT ARC
{arrangement.strip()}"""


def user_block_append_for(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    if not matches_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ):
        return ""
    return compose_elite_module_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    ).strip()
