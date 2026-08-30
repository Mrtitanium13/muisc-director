import '../../data/models/user_input_model.dart';
import 'big_room_hardstyle_cinematic_hybrid_engine.dart';

/// Quick-start preset — Pure Mainstage Euphoric & Raw Hardstyle with dynamic parameters.
///
/// Vocal DNA forces thick, weighty, humanized lead presence that cuts through
/// 150 BPM hardstyle kicks and hypersaw stacks.
class BigRoomHardstyleCinematicHybridPreset {
  BigRoomHardstyleCinematicHybridPreset._();

  static const id = BigRoomHardstyleCinematicHybridEngine.id;

  static const primaryGenre = BigRoomHardstyleCinematicHybridEngine.primaryGenre;

  static const subGenreFusion =
      BigRoomHardstyleCinematicHybridEngine.subGenreFusion;

  static String composeVibeProse() =>
      BigRoomHardstyleCinematicHybridEngine.composeBlock1Seed();

  static String composeStructureNotes() =>
      BigRoomHardstyleCinematicHybridEngine.composeArrangementArchitecture(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );

  static String composeEliteModuleBlock() =>
      BigRoomHardstyleCinematicHybridEngine.composeEliteModuleBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );

  /// Baseline fallback template settings.
  static const templateModel = UserInputModel(
    sunoVersion: 'v5.5',
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
    vibe: _vibeSeed,
    bpm: '150',
    keyRoot: 'F#',
    scale: 'Minor',
    vocalSpec: 'Male Lead',
    vocalTone:
        'ultra-vulnerable close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics; deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency; build into hyper-expanding 100% wet hall reverb washout then brick-wall vacuum before drop; climax mantra with dedicated 250Hz vocal warmth pocket, dynamic low-mid separation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers',
    referenceArtists:
        'Headhunterz, Wildstylez, Noisecontrollers, Brennan Heart, Coone, D-Sturb',
    sonicTags: [
      'euphoric hardstyle',
      'rawstyle',
      'mainstage hard dance',
      '150 bpm distorted kick',
      'ultra-vulnerable close-mic intimateness',
      'heavy throat texture proximity effect',
      '1176-slammed mouth clicks breathing dynamics',
      'thick masculine sub-harmonics',
      'chest-vibrating fundamental grit',
      '250Hz vocal warmth pocket',
      'hyper-expanding cathedral vocal washout',
      'high-tension vacuum drop before impact',
      'pristine high-end air boost through hypersaws',
    ],
    avoid:
        'thin distant washed-out vocals, buried lead under kick or supersaw stacks, karaoke reverb floods that erase proximity, soft pop breathiness without chest weight, big room house, progressive house elements, instant cold start, vocals in intro or mid-intro, soft pop ballad, acoustic folk, thin kick, lo-fi bedroom mix, generic club hands-up filler, sci-fi rave lyric metaphors, losing 150 BPM hard dance drive between sections',
    songStructurePresetId: 'edm_drop',
    songStructureCustom: _structureSeed,
    genreFxLaneId: 'edm',
    productionIntensity: 3,
    melodyStyleId: 'anthemic_soaring',
    generateLyrics: true,
    djIntroMixIn: true,
    djOutroMixOut: true,
    lyricThemeNotes:
        'Dark late-night street-racing narrative — melancholy breakdown vulnerability to defiant survival on builds to explosive mainstage release; keep vocals thick, humanized, and pocketed above the hard dance wall',
  );

  static const _vibeSeed =
      'Authentic Hardstyle intro tool, rolling bass runway, 150 BPM hard dance foundations, DJ ready. '
      'Hardstyle, Euphoric Hardstyle, Rawstyle, Mainstage Hard Dance · 150 BPM, Driving 4/4 hard dance time signature, Relentless festival power curve · Defiant victory, Cinematic melancholy, Uplifting mainstage euphoria, High-octane aggression · Defiant mainstage festival hard dance: Synths — Stacked hypersaw lead oscillators with ultra-wide stereo detuning and high-end air boost, Piercing square-wave pluck layer for transient sharpness and punch on melodic note starts, Access Virus TI emulated raw wave leads combined with classic Roland JP-8000 supersaw arrays, Saturated mid-range synth brass and polyphonic chord layers for massive sonic thickness, Dissonant, tearing rave screeches generated via aggressive pitch-envelope modulation and cross-modulation; Cinematic breakdown — Ethereal high-density orchestral string section layouts, ultra-vulnerable close-mic intimateness with heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics, deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency, Vulnerable acoustic piano chord layers with softened high-frequency profile, Cinematic orchestral horn swells and sub-bass brass markers, Deep sustained atmospheric sub-bass beds; Mid-Intro engine & drums — Distorted rawstyle gated kicks with heavy hollow front-end tok transients and sweeping sub tails, Pitched euphoric mainstage climax kicks tracking basslines note-for-note, Pounding rolling reverse bass kicks with syncopated off-beat low-end rebounds, Crisp TR-909 open hi-hats on the off-beats, Aggressive wide stereo claps layered with white noise bursts and pre-shifted impact transients, Heavy acoustic orchestral impact timpani, taiko drums, cinematic tom fills, High-energy stereo ride and crash cymbals with massive decay; Climax drops — Pitched euphoric mainstage climax kicks, Massive pitch-shifted euphoric hardstyle kicks with prominent hollow tok transient, Wall-of-sound detuned screaming lead synths playing a driving heroic melody, weighty anthemic vocal mantra held in a dedicated 250Hz vocal warmth pocket with dynamic low-mid separation, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers, Bright stereo ride cymbals layered with high-energy crowd fx chant loops; FX/transitions — Accelerating high-pass filtered kick punches into 32nd-note rolls, Crisp 150 BPM acoustic snare rolls with rising pitch-shifted white noise sweeps, Laser-style tonal pitch risers, automated sub-drops, reverse crash sweeps, Tonal multi-bar riser chords matched to drop key, hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, high-tension vacuum drop, absolute structural sound vacuum before impact. '
      'Mix: Aggressive sidechain ducking tuned explicitly to fast 150 BPM kick envelopes on all lead and pad groups while preserving vocal proximity weight; Brick-wall limited loud master retaining heavy low-end distortion headroom without digital clipping; Wide stereo expansion on screaming leads, mono-locked phase-coherent kick bass engine beneath 120 Hz; Precise surgical mid-range EQ cuts carving a dedicated 250Hz vocal warmth pocket and pristine high-end air boost so the lead never gets swallowed by hypersaw stacks; Distortion multi-band saturation on raw kicks to split low-end rumble and mid-range tok independently. '
      'Authentic Hardstyle outro tool, percussive outro pocket, clean mix-out fade to complete silence.';

  static const _structureSeed = '''
EUPHORIC HARDSTYLE — CANONICAL MAIN STAGE ARRANGEMENT ROADMAP (150 BPM mandatory):
- [Intro] (extended DJ mix intro — REQUIRED): 32 bars. Pure functional DJ mixing runway. Rolling hardstyle kick-and-bass pattern, sharp percussion running, creeping background drive; instrumental only. Use compact template bookend exactly.
- [Mid-Intro]: 32 bars. Heavy instrumental power section. Distorted gated raw kicks, screech patterns, driving percussive layers without melodic leads; no vocals.
- [Breakdown]: Cinematic breakdown. Kicks stop completely. Lush orchestral strings, soft piano, and intimate emotional vocal narrative with ultra-vulnerable close-mic intimateness, heavy throat texture, high-compression proximity effect, detailed chest resonance, gravelly conversational delivery, 1176-slammed mouth clicks and raw breathing dynamics; thicken with deep formant-shifted vocal backing doubles, thick masculine sub-harmonics, chest-vibrating fundamental grit, organic F# minor pitch consistency.
- [Build-up]: Accelerating hardstyle snare roll patterns, sweeping pitch risers, rising vocal lines holding open vowels into hyper-expanding 100% wet hall reverb washout, massive cathedral vocal diffusion swell, automated echo tail expansion, sudden brick-wall silence gap, high-tension vacuum drop, absolute structural sound vacuum before impact.
- [Climax Drop]: Mainstage payoff. Epic melodic chord progression driving massive pitch-shifted euphoric kicks and stacked screaming synth leads; weighty anthemic mantra with dedicated 250Hz vocal warmth pocket, dynamic low-mid separation, heavy sidechain ducking on spatial effects, sharp transient isolation, pristine high-end air boost cutting through dense 150 BPM hypersaw layers.
- [Outro] + [End] (extended DJ mix outro — REQUIRED): 32 bars. Functional DJ mix-out runway. Lead melodies vanish, stripping layers back down to rolling percussive kicks for flawless crossfading. Clean percussive fade to complete silence. Use compact template outro/end bookends exactly.

COMPACT LYRIC TEMPLATE (MANDATORY Hardstyle Arrangement Boundaries — Replicate Exactly):
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
[Percussive fade out, final low-end hit, complete silence]''';

  /// Factory constructor providing absolute structural runtime customization.
  static UserInputModel userInputModel({
    String sunoVersion = 'v5.5',
    String songStructurePresetId = 'edm_drop',
    String keyRoot = 'F#',
    String scale = 'Minor',
    String vocalSpec = 'Male Lead',
    String bpm = '150',
  }) =>
      templateModel.copyWith(
        sunoVersion: sunoVersion,
        songStructurePresetId: songStructurePresetId,
        keyRoot: keyRoot,
        scale: scale,
        vocalSpec: vocalSpec,
        bpm: bpm,
        vibe: composeVibeProse(),
        songStructureCustom: composeStructureNotes(),
      );
}
