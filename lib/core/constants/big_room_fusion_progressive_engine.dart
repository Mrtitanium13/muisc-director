import '../../data/models/user_input_model.dart';
import 'big_room_fusion_progressive_vocal_lyric_engine.dart';

/// Elite Big Room Fusion / Progressive House production module.
///
/// Nested dataset → weighted Block 1 seed prose, structured elite user-block,
/// and segmented arrangement architecture for Suno / Stable Audio fidelity.
class BigRoomFusionProgressiveEngine {
  BigRoomFusionProgressiveEngine._();

  static const moduleId = 'big_room_fusion_progressive_elite';

  // ── 1. CORE GENRE & ATMOSPHERE ───────────────────────────────────────────

  static const coreGenreAtmosphere = (
    primaryTags: [
      'Progressive House',
      'Big Room House',
      'Festival Anthem',
      'Mainstage EDM',
    ],
    rhythmicBlueprint: [
      '128 BPM',
      'Driving 4/4 time signature',
      'Anthemic energy curve',
    ],
    moodProfiles: [
      'Euphoric tension',
      'Uplifting',
      'Psychological honesty',
      'Emotional friction',
      'High-octane catharsis',
    ],
  );

  // ── 2. AUDIO ENGINEERING & SOUND PALETTE ─────────────────────────────────

  static const soundPalette = (
    leads: [
      'Layered supersaw leads with a sharp square wave pluck transient',
      'High-density, multi-voiced stacked festival supersaws with an ultra-wide stereo spread and aggressive detuning',
      'Saturated mid-range synth layers mixed with a high-register saw stack for maximum mainstage cutting power',
      'Detuned high-end bite',
      'Monolithic melodic lead synth cutting through dense walls',
      'Access Virus TI hypersaw oscillators',
      'Polymoog emulations, classic Roland JP-8000 supersaws',
      'Staccato lead plucks, soaring polyphonic synth brass chords',
      'Cinematic acoustic orchestral string layers (violins, cellos) doubling the main melody',
    ],
    bassArchitecture: [
      'Gritty, distorted mid-bass saw layers',
      'Heavy pumping sidechained reez bass',
      'Mono-compatible clean sub-bass sine wave sitting at 50–60 Hz',
      'FM metallic mid-bass stabs',
      'Analog Moog-style low-end foundations',
    ],
    drumKit: [
      'Hard-hitting punchy festival kick with a dominant transient click and short sub-tail',
      'Driving open hi-hats hitting exactly on the off-beats',
      'Bright, high-energy stereo ride cymbals',
      'Aggressive pre-shifted acoustic claps layered with white noise bursts',
      '909 snare drums, synthesized white-noise snare layers',
      'Heavy acoustic orchestral impact timpani, cinematic tom fills',
      'Percussive tribal rimshots, stereo shakers, tambourines',
    ],
    vocalsAndFx: [
      'Reverb-drenched human-centered commercial female lead vocal top-line',
      'Lush stereo 1/4 and 1/8 note delays',
      'Crisp white noise uplifters and sweeping downlifters',
      'Impact crash cymbals with massive hall reverb decay',
      'Sub-drops, reverse cymbals, tonal riser sweeps',
      'Laser effects, micro-edited pitch glides, multi-bar laser sub-risers',
      'Subtle crowd chant background ambience layered under builds',
    ],
  );

  // ── 3. STUDIO PRODUCTION & MIXING ────────────────────────────────────────

  static const mixingTechniques = [
    'Extreme sidechain compression',
    'Aggressive dynamic pumping effect',
    'Immersive wide stereo field expansion',
    'High-frequency breathy vocal sparkle',
    'Reverb washout automation on build-ups to maximize emotional tension',
    'Crisp, loud commercial master with high headroom clarity',
  ];

  // ── 4. ARRANGEMENT ARCHITECTURE DEFINITIONS ──────────────────────────────

  static const arrangementComponents = (
    introDj:
        '32 bars. Pure functional tool layout. Minimal percussion foundation, driving club kick, open hi-hats, offbeat bass ticks, low-passed background synth melody hinting at the main progression.',
    breakdownVerse:
        'Atmospheric ambient pads, plucking synth melody, intimate clean vocals delivery conveying immediate internal realization, subtle low-end sub-bass, orchestral string swells.',
    chorus:
        'Soaring melodic peak, full chord progression unveiled, wide vocal harmonies, building low-end presence with pads and reez bass layers.',
    buildUp:
        'Accelerating snare roll pattern, rising pitch sweeps, swelling supersaw chord pads, massive high-pass filter automation, intense reverb washout matching the exponential vocal urgency.',
    drop:
        'Explosive mainstage climax, heavy driving 4/4 kick, wall-of-sound sidechained supersaw lead melody, syncopated vocal stutter blocks, chopped mantra loops, wide stereo imaging, high-energy impact.',
    outroDj:
        '32 bars. Stripped-back mix elements. Consistent driving club kick, off-beat hi-hats, fading synth chords, structural reduction designed for seamless DJ transition out.',
  );

  /// Layer weight hints for LLM prioritization (critical → high → standard).
  static const layerWeights = (
    core: 'critical',
    kickBass: 'critical',
    leadsDrums: 'high',
    vocalsFx: 'high',
    mixing: 'high',
    arrangement: 'standard',
  );

  static bool matchesLane({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) =>
      BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );

  static bool matchesInput(UserInputModel input) => matchesLane(
        primaryGenre: input.primaryGenre,
        subGenreFusion: input.subGenreFusion,
      );

  static String _joinSemicolon(Iterable<String> items) => items.join('; ');

  /// Dense Block 1 seed (~130–150 words) — highest-weight terms first.
  static String composeBlock1Seed() {
    final c = coreGenreAtmosphere;
    final s = soundPalette;
    final m = mixingTechniques;
    return '${c.primaryTags.join(", ")} · ${c.rhythmicBlueprint.join(", ")} · '
        '${c.moodProfiles.join(", ")}: '
        '${s.leads.join(", ")}; '
        '${s.bassArchitecture.join(", ")}; '
        '${s.drumKit.join(", ")}; '
        '${s.vocalsAndFx.join(", ")}. '
        'Mix: ${_joinSemicolon(m)}.';
  }

  /// High-density tag cloud for simple-mode / weight-boost injection.
  static String composeTagCloud() {
    final c = coreGenreAtmosphere;
    final s = soundPalette;
    return [
      ...c.primaryTags,
      ...c.rhythmicBlueprint,
      ...c.moodProfiles,
      ...s.leads,
      ...s.bassArchitecture,
      ...s.drumKit,
      ...s.vocalsAndFx,
      ...mixingTechniques,
    ].join(', ');
  }

  /// Segmented arrangement block that splits based on precise semantic matching.
  static String composeArrangementArchitecture({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    final blob =
        '${primaryGenre.trim()} ${subGenreFusion.trim()}'.toLowerCase();
    final comp = arrangementComponents;

    // Lane A: "progressive big room" variants → Elite 8-Part Arc
    if (blob.contains('progressive big room') ||
        blob.contains('progressive festival house big room')) {
      return '''
PROGRESSIVE BIG ROOM HOUSE — MANDATORY 8-PART ARRANGEMENT HIGH-FIDELITY ROADMAP:
1. [Intro DJ Tool]: ${comp.introDj}
2. [Breakdown Verse]: ${comp.breakdownVerse}
3. [Chorus]: ${comp.chorus}
4. [Build-up]: ${comp.buildUp}
5. [Drop]: ${comp.drop}
6. [Breakdown Verse]: Reset arrangement back down to pads, intimate strings, and emotional vocals.
7. [Build-up]: Re-introducing accelerating snare loops and risers to peak tension.
8. [Drop]: Second high-impact climax with wall-of-sound leads.
9. [Outro DJ Tool]: ${comp.outroDj}''';
    }

    // Lane B: "big room progressive" → Accelerated Fast-Drop RoadMap
    return '''
BIG ROOM PROGRESSIVE HOUSE — MANDATORY INSTANT TENSION ARRANGEMENT ROADMAP:
1. [Intro DJ Tool]: ${comp.introDj}
2. [Build-up]: ${comp.buildUp}
3. [Drop]: ${comp.drop}
4. [Breakdown Verse]: ${comp.breakdownVerse}
5. [Build-up]: Re-introducing accelerating snare loops and risers to peak tension.
6. [Drop]: Second high-impact climax with wall-of-sound leads.
7. [Outro DJ Tool]: ${comp.outroDj}''';
  }

  /// Full elite module block appended to the LLM user message.
  static String composeEliteModuleBlock({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    final c = coreGenreAtmosphere;
    final s = soundPalette;
    final w = layerWeights;
    return '''
ELITE BIG ROOM FUSION / PROGRESSIVE HOUSE MODULE (mandatory Block 1 DNA — weave ALL layers into 130–150 word producer prose; prioritize [${w.core}] then [${w.kickBass}] layers):

▸ CORE GENRE & ATMOSPHERE [weight: ${w.core}]
Primary: ${c.primaryTags.join(" · ")}
Rhythm: ${c.rhythmicBlueprint.join(" · ")}
Mood: ${c.moodProfiles.join(" · ")}

▸ SOUND PALETTE — LEADS [weight: ${w.leadsDrums}]
${_bulletList(s.leads)}

▸ SOUND PALETTE — BASS ARCHITECTURE [weight: ${w.kickBass}]
${_bulletList(s.bassArchitecture)}

▸ SOUND PALETTE — DRUM KIT [weight: ${w.kickBass}]
${_bulletList(s.drumKit)}

▸ SOUND PALETTE — VOCALS & FX [weight: ${w.vocalsFx}]
${_bulletList(s.vocalsAndFx)}

▸ STUDIO PRODUCTION & MIXING [weight: ${w.mixing}]
${_bulletList(mixingTechniques)}

▸ ARRANGEMENT ARCHITECTURE [weight: ${w.arrangement}]
${composeArrangementArchitecture(primaryGenre: primaryGenre, subGenreFusion: subGenreFusion)}

TAG CLOUD (density boost — integrate naturally, do not list verbatim):
${composeTagCloud()}''';
  }

  static String _bulletList(List<String> items) =>
      items.map((e) => '• $e').join('\n');

  /// User-block append when lane matches (prompt generator runtime).
  static String userBlockAppendFor({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    if (!matchesLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      return '';
    }
    return composeEliteModuleBlock(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    ).trim();
  }
}
