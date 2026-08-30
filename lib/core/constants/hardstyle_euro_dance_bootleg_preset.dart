import '../../data/models/user_input_model.dart';

/// Premium preset for Hardstyle / Euro-Dance Festival Bootleg rave crossover.
/// Sonic reference lane: early-2000s Euro-dance topline × distorted hardstyle kick bootleg.
class HardstyleEuroDanceBootlegPreset {
  HardstyleEuroDanceBootlegPreset._();

  static const id = 'hardstyle_euro_dance_bootleg';

  static const primaryGenre = 'Hardstyle';

  static const subGenreFusion = 'Euro-Dance Bootleg';

  static const genreTags = [
    'Hardstyle',
    'Euro-Dance Bootleg',
    'Hands Up EDM',
    'Mainstage Festival Rave',
  ];

  static const moodTags = [
    'Nostalgic',
    'High-energy euphoria',
    'Aggressive rave energy',
    'Intense dancefloor anthemic lift',
    'Fast-paced 150 BPM',
    'Driving 4/4 hard dance rhythm',
  ];

  static const vibeProse =
      'Hardstyle, Euro-Dance Bootleg, Hands Up EDM, Mainstage Festival Rave at '
      'nostalgic high-energy euphoria, aggressive rave energy, intense dancefloor anthemic lift, '
      'fast-paced 150 BPM, driving 4/4 hard dance rhythm: '
      'heavy distorted hardstyle kick with massive pitch-shifted hollow front-end tok and long saturated bass tail; '
      'classic early-2000s detuned supersaw lead, bright high-register Euro-dance synthesizer melody, '
      'sharp piercing rave plucks with fast attack; off-beat reverse bass in driving sections, '
      'thick distorted mid-bass layer syncing with kick transient; crisp TR-909 open hi-hats, '
      'aggressive 16th-note pre-shifted claps, fast hyper-accelerating snare rolls on build-ups; '
      'pitch-shifted commercial male/female vocal topline, massive sidechained vocal chops, '
      'screaming rave screeches, long white-noise sweeps, explosive sub-drops and impact crashes. '
      'Mix: heavy sidechain compression to the kick, wall-of-sound mixing, super-wide stereo imaging on supersaw leads, '
      'reverb washout automation into drops, gated reverb vocal effects, loud compressed brickwall-limited festival master, −7 LUFS mainstage intent.';

  static const structureNotes = '''
HARDSTYLE / EURO-DANCE FESTIVAL BOOTLEG ARRANGEMENT (mandatory arc):
- Intro / Club Mix: driving 4/4 club beat, minimal reverse bass, core Euro-dance synth melody riff introduced dry then widening.
- Verse / Breakdown: drums cut out, lush ambient pads swell, melodic Euro-dance lead synth softly plays hook fragment, emotionally charged dry filtered vocals center stage.
- Build-Up: vocal repeats and chops accelerate bar-over-bar, aggressive pitch-rising snare rolls, high-pass filters cutting low end, massive reverb washout building peak tension, rave screech teases optional.
- Hardstyle Drop: explosive energy release — monolithic distorted hardstyle kick pounding every downbeat, hyper-melodic detuned supersaw playing anthemic Euro-dance hook, ultra-wide stereo rave aesthetics, off-beat reverse bass stabs, sub-drop impacts, impact crashes with long decay.
- Second cycle: strip to breakdown vocal intimacy before repeat build/drop per edm_drop roadmap.''';

  static String composeVibeProse() => vibeProse;

  static String composeStructureNotes() => structureNotes;

  static const templateModel = UserInputModel(
    sunoVersion: 'v5.5',
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
    vibe: vibeProse,
    bpm: '150',
    keyRoot: 'B',
    scale: 'Minor',
    vocalSpec: 'Male Lead',
    vocalTone:
        'pitch-shifted, commercial Euro-dance topline, dry filtered in breakdown, sidechained chops in build',
    referenceArtists: 'Headhunterz, Brennan Heart, Showtek early era',
    sonicTags: [
      'early-2000s Euro-dance × hardstyle bootleg crossover',
      'Darklight-style festival rave',
      'reverse bass',
      'golden era hardstyle 2008–2012',
    ],
    avoid:
        'weak soft kick, thin supersaw, lo-fi bedroom mix, acoustic folk instruments, generic pop ballad, muddy low end, under-compressed master',
    songStructurePresetId: 'edm_drop',
    songStructureCustom: structureNotes,
    genreFxLaneId: 'edm',
    productionIntensity: 3,
    melodyStyleId: 'anthemic_soaring',
    generateLyrics: true,
  );

  static UserInputModel userInputModel({
    String sunoVersion = 'v5.5',
    String songStructurePresetId = 'edm_drop',
  }) =>
      templateModel.copyWith(
        sunoVersion: sunoVersion,
        songStructurePresetId: songStructurePresetId,
      );
}
