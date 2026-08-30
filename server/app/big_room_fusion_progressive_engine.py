"""Elite Big Room Fusion / Progressive House production module."""

from __future__ import annotations

from app.big_room_fusion_progressive_vocal_lyric_engine import is_big_room_fusion_lane

MODULE_ID = "big_room_fusion_progressive_elite"

CORE_GENRE_ATMOSPHERE = {
    "primary_tags": [
        "Progressive House",
        "Big Room House",
        "Festival Anthem",
        "Mainstage EDM",
    ],
    "rhythmic_blueprint": [
        "128 BPM",
        "Driving 4/4 time signature",
        "Anthemic energy curve",
    ],
    "mood_profiles": [
        "Euphoric tension",
        "Uplifting",
        "Psychological honesty",
        "Emotional friction",
        "High-octane catharsis",
    ],
}

SOUND_PALETTE = {
    "leads": [
        "Layered supersaw leads with a sharp square wave pluck transient",
        "High-density, multi-voiced stacked festival supersaws with an ultra-wide stereo spread and aggressive detuning",
        "Saturated mid-range synth layers mixed with a high-register saw stack for maximum mainstage cutting power",
        "Detuned high-end bite",
        "Monolithic melodic lead synth cutting through dense walls",
        "Access Virus TI hypersaw oscillators",
        "Polymoog emulations, classic Roland JP-8000 supersaws",
        "Staccato lead plucks, soaring polyphonic synth brass chords",
        "Cinematic acoustic orchestral string layers (violins, cellos) doubling the main melody",
    ],
    "bass_architecture": [
        "Gritty, distorted mid-bass saw layers",
        "Heavy pumping sidechained reez bass",
        "Mono-compatible clean sub-bass sine wave sitting at 50–60 Hz",
        "FM metallic mid-bass stabs",
        "Analog Moog-style low-end foundations",
    ],
    "drum_kit": [
        "Hard-hitting punchy festival kick with a dominant transient click and short sub-tail",
        "Driving open hi-hats hitting exactly on the off-beats",
        "Bright, high-energy stereo ride cymbals",
        "Aggressive pre-shifted acoustic claps layered with white noise bursts",
        "909 snare drums, synthesized white-noise snare layers",
        "Heavy acoustic orchestral impact timpani, cinematic tom fills",
        "Percussive tribal rimshots, stereo shakers, tambourines",
    ],
    "vocals_and_fx": [
        "Reverb-drenched human-centered commercial female lead vocal top-line",
        "Lush stereo 1/4 and 1/8 note delays",
        "Crisp white noise uplifters and sweeping downlifters",
        "Impact crash cymbals with massive hall reverb decay",
        "Sub-drops, reverse cymbals, tonal riser sweeps",
        "Laser effects, micro-edited pitch glides, multi-bar laser sub-risers",
        "Subtle crowd chant background ambience layered under builds",
    ],
}

MIXING_TECHNIQUES = [
    "Extreme sidechain compression",
    "Aggressive dynamic pumping effect",
    "Immersive wide stereo field expansion",
    "High-frequency breathy vocal sparkle",
    "Reverb washout automation on build-ups to maximize emotional tension",
    "Crisp, loud commercial master with high headroom clarity",
]

ARRANGEMENT_COMPONENTS = {
    "intro_dj": (
        "32 bars. Pure functional tool layout. Minimal percussion foundation, driving club kick, "
        "open hi-hats, offbeat bass ticks, low-passed background synth melody hinting at the main progression."
    ),
    "breakdown_verse": (
        "Atmospheric ambient pads, plucking synth melody, intimate clean vocals delivery conveying "
        "immediate internal realization, subtle low-end sub-bass, orchestral string swells."
    ),
    "chorus": (
        "Soaring melodic peak, full chord progression unveiled, wide vocal harmonies, "
        "building low-end presence with pads and reez bass layers."
    ),
    "build_up": (
        "Accelerating snare roll pattern, rising pitch sweeps, swelling supersaw chord pads, "
        "massive high-pass filter automation, intense reverb washout matching the exponential vocal urgency."
    ),
    "drop": (
        "Explosive mainstage climax, heavy driving 4/4 kick, wall-of-sound sidechained supersaw lead melody, "
        "syncopated vocal stutter blocks, chopped mantra loops, wide stereo imaging, high-energy impact."
    ),
    "outro_dj": (
        "32 bars. Stripped-back mix elements. Consistent driving club kick, off-beat hi-hats, "
        "fading synth chords, structural reduction designed for seamless DJ transition out."
    ),
}

LAYER_WEIGHTS = {
    "core": "critical",
    "kick_bass": "critical",
    "leads_drums": "high",
    "vocals_fx": "high",
    "mixing": "high",
    "arrangement": "standard",
}


def matches_lane(*, primary_genre: str = "", sub_genre_fusion: str = "") -> bool:
    return is_big_room_fusion_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )


def compose_block1_seed() -> str:
    c = CORE_GENRE_ATMOSPHERE
    s = SOUND_PALETTE
    return (
        f"{', '.join(c['primary_tags'])} · "
        f"{', '.join(c['rhythmic_blueprint'])} · "
        f"{', '.join(c['mood_profiles'])}: "
        f"{', '.join(s['leads'])}; "
        f"{', '.join(s['bass_architecture'])}; "
        f"{', '.join(s['drum_kit'])}; "
        f"{', '.join(s['vocals_and_fx'])}. "
        f"Mix: {'; '.join(MIXING_TECHNIQUES)}."
    )


def compose_tag_cloud() -> str:
    c = CORE_GENRE_ATMOSPHERE
    s = SOUND_PALETTE
    parts = (
        c["primary_tags"]
        + c["rhythmic_blueprint"]
        + c["mood_profiles"]
        + s["leads"]
        + s["bass_architecture"]
        + s["drum_kit"]
        + s["vocals_and_fx"]
        + MIXING_TECHNIQUES
    )
    return ", ".join(parts)


def compose_arrangement_architecture(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    blob = f"{primary_genre.strip()} {sub_genre_fusion.strip()}".lower()
    comp = ARRANGEMENT_COMPONENTS

    # Lane A: "progressive big room" variants → Elite 8-Part Arc
    if "progressive big room" in blob or "progressive festival house big room" in blob:
        return f"""PROGRESSIVE BIG ROOM HOUSE — MANDATORY 8-PART ARRANGEMENT HIGH-FIDELITY ROADMAP:
1. [Intro DJ Tool]: {comp['intro_dj']}
2. [Breakdown Verse]: {comp['breakdown_verse']}
3. [Chorus]: {comp['chorus']}
4. [Build-up]: {comp['build_up']}
5. [Drop]: {comp['drop']}
6. [Breakdown Verse]: Reset arrangement back down to pads, intimate strings, and emotional vocals.
7. [Build-up]: Re-introducing accelerating snare loops and risers to peak tension.
8. [Drop]: Second high-impact climax with wall-of-sound leads.
9. [Outro DJ Tool]: {comp['outro_dj']}"""

    # Lane B: "big room progressive" → Accelerated Fast-Drop RoadMap
    return f"""BIG ROOM PROGRESSIVE HOUSE — MANDATORY INSTANT TENSION ARRANGEMENT ROADMAP:
1. [Intro DJ Tool]: {comp['intro_dj']}
2. [Build-up]: {comp['build_up']}
3. [Drop]: {comp['drop']}
4. [Breakdown Verse]: {comp['breakdown_verse']}
5. [Build-up]: Re-introducing accelerating snare loops and risers to peak tension.
6. [Drop]: Second high-impact climax with wall-of-sound leads.
7. [Outro DJ Tool]: {comp['outro_dj']}"""


def _bullet_list(items: list[str]) -> str:
    return "\n".join(f"• {item}" for item in items)


def compose_elite_module_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    c = CORE_GENRE_ATMOSPHERE
    s = SOUND_PALETTE
    w = LAYER_WEIGHTS
    arrangement = compose_arrangement_architecture(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    return f"""ELITE BIG ROOM FUSION / PROGRESSIVE HOUSE MODULE (mandatory Block 1 DNA — weave ALL layers into 130–150 word producer prose; prioritize [{w['core']}] then [{w['kick_bass']}] layers):

▸ CORE GENRE & ATMOSPHERE [weight: {w['core']}]
Primary: {' · '.join(c['primary_tags'])}
Rhythm: {' · '.join(c['rhythmic_blueprint'])}
Mood: {' · '.join(c['mood_profiles'])}

▸ SOUND PALETTE — LEADS [weight: {w['leads_drums']}]
{_bullet_list(s['leads'])}

▸ SOUND PALETTE — BASS ARCHITECTURE [weight: {w['kick_bass']}]
{_bullet_list(s['bass_architecture'])}

▸ SOUND PALETTE — DRUM KIT [weight: {w['kick_bass']}]
{_bullet_list(s['drum_kit'])}

▸ SOUND PALETTE — VOCALS & FX [weight: {w['vocals_fx']}]
{_bullet_list(s['vocals_and_fx'])}

▸ STUDIO PRODUCTION & MIXING [weight: {w['mixing']}]
{_bullet_list(MIXING_TECHNIQUES)}

▸ ARRANGEMENT ARCHITECTURE [weight: {w['arrangement']}]
{arrangement}

TAG CLOUD (density boost — integrate naturally, do not list verbatim):
{compose_tag_cloud()}"""


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
