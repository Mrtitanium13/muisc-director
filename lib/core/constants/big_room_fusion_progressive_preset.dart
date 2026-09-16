import '../../data/models/user_input_model.dart';
import 'big_room_fusion_progressive_engine.dart';
import 'suno_version.dart';

/// Quick-start preset — delegates to [BigRoomFusionProgressiveEngine] elite module.
class BigRoomFusionProgressivePreset {
  BigRoomFusionProgressivePreset._();

  static const id = 'big_room_fusion_progressive';

  static const primaryGenre = 'Progressive House';

  static const subGenreFusion = 'Big Room House';

  /// Re-export nested dataset for tests and UI introspection.
  static const dataset = BigRoomFusionProgressiveEngine.coreGenreAtmosphere;

  static String composeVibeProse() =>
      BigRoomFusionProgressiveEngine.composeBlock1Seed();

  static String composeStructureNotes() =>
      BigRoomFusionProgressiveEngine.composeArrangementArchitecture(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );

  static String composeEliteModuleBlock() =>
      BigRoomFusionProgressiveEngine.composeEliteModuleBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );

  static const templateModel = UserInputModel(
    sunoVersion: SunoVersion.preferredValue,
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
    vibe: _vibeSeed,
    bpm: '128',
    keyRoot: 'F#',
    scale: 'Minor',
    vocalSpec: 'Female Lead',
    vocalTone:
        'reverb-drenched commercial top-line, intimate clean in verses, breathy sparkle on drops',
    referenceArtists:
        'Alesso, Martin Garrix, Swedish House Mafia, David Guetta, Tiësto, Afrojack, Nicky Romero, DubVision, Mesto',
    sonicTags: [
      'mainstage progressive-to-big-room fusion',
      'high-density supersaw euphoria',
      'sidechain pump',
    ],
    avoid:
        'dry unprocessed mix, thin low end, acoustic folk instruments, generic pop clichés, sci-fi rave lyric metaphors, muddy mono collapse',
    songStructurePresetId: 'edm_drop',
    songStructureCustom: _structureSeed,
    genreFxLaneId: 'edm',
    productionIntensity: 3,
    melodyStyleId: 'anthemic_soaring',
    generateLyrics: true,
  );

  static const _vibeSeed = _vibeSeedLiteral;

  // ignore: unused_field
  static const _vibeSeedLiteral =
      'Progressive House, Big Room House, Festival Anthem, Mainstage EDM · 128 BPM, Driving 4/4 time signature, Anthemic energy curve · Euphoric, Uplifting, Energetic, Cinematic tension, High-octane climax: Layered supersaw leads with a sharp square wave pluck transient, High-density multi-voiced stacked festival supersaws with an ultra-wide stereo spread and aggressive detuning, Saturated mid-range synth layers mixed with a high-register saw stack, Detuned high-end bite, Monolithic melodic lead synth; Gritty, distorted mid-bass saw layers, Heavy pumping sidechained reez bass, Mono-compatible clean sub-bass sine wave sitting at 50–60 Hz; Hard-hitting punchy festival kick with a dominant transient click and short sub-tail, Driving open hi-hats hitting exactly on the off-beats, Bright, high-energy stereo ride cymbals, Aggressive pre-shifted acoustic claps layered with white noise bursts; Reverb-drenched commercial female lead vocal top-line, Lush stereo 1/4 and 1/8 note delays, Crisp white noise uplifters and sweeping downlifters, Impact crash cymbals with massive hall reverb decay, Sub-drops. Mix: Extreme sidechain compression; Aggressive dynamic pumping effect; Immersive wide stereo field expansion; High-frequency breathy vocal sparkle; Reverb washout automation on build-ups; Crisp, loud commercial master with high headroom clarity.';

  static const _structureSeed = '''
BIG ROOM PROGRESSIVE HOUSE — MANDATORY INSTANT TENSION ARRANGEMENT ROADMAP:
- Intro DJ Tool: 32 bars. Pure functional tool layout. Minimal percussion foundation, driving club kick, open hi-hats, offbeat bass ticks.
- Build-Up: Accelerating snare roll pattern, rising pitch sweeps, swelling supersaw chord pads, massive high-pass filter automation.
- Drop: Explosive mainstage climax, heavy driving 4/4 kick, wall-of-sound sidechained supersaw lead melody, wide stereo imaging, high-energy impact.
- Breakdown Verse: Atmospheric ambient pads, plucking synth melody, intimate clean vocals delivery, subtle low-end sub-bass.
- Build-up: Re-introducing accelerating snare loops and risers to peak tension.
- Drop: Second high-impact climax with wall-of-sound leads.
- Outro DJ Tool: 32 bars. Stripped-back mix elements. Consistent driving club kick, off-beat hi-hats, fading synth chords.''';

  /// Generates a flexible instantiation mapping runtime inputs dynamically.
  static UserInputModel userInputModel({
    String sunoVersion = SunoVersion.preferredValue,
    String songStructurePresetId = 'edm_drop',
    String? bpm,
    String? keyRoot,
    String? scale,
    String? vocalSpec,
  }) =>
      templateModel.copyWith(
        sunoVersion: sunoVersion,
        songStructurePresetId: songStructurePresetId,
        vibe: composeVibeProse(),
        songStructureCustom: composeStructureNotes(),
        bpm: bpm ?? templateModel.bpm,
        keyRoot: keyRoot ?? templateModel.keyRoot,
        scale: scale ?? templateModel.scale,
        vocalSpec: vocalSpec ?? templateModel.vocalSpec,
      );
}
