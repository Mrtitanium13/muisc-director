import 'package:music_director/core/constants/suno_version.dart';
import 'package:music_director/core/constants/vocal_spec_tone_data.dart';

/// Dropdown / chip options for advanced prompt form fields.
class PromptFormConstants {
  const PromptFormConstants._();

  static const keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const scales = [
    'Major',
    'Minor',
    'Dorian',
    'Phrygian',
    'Lydian',
    'Mixolydian',
    'Aeolian',
    'Locrian',
    'Harmonic Minor',
    'Pentatonic Minor',
  ];

  static const vocals = VocalSpecToneData.vocalSpecs;

  static const sunoVersions = SunoVersion.uiValues;

  static const sunoVersionHints = {
    'v6':
        'Flagship (Pro/Premier) — precise, polished, rich director\'s notes. '
        'Same Block 1 prose cap (~1000 chars); deepest Block 2 staging.',
    'v6-wild':
        'Exploratory (Pro/Premier) — textured / unexpected turns within valid '
        'metatags. Same rich density as v6; refine later on flagship if needed.',
    'v6-mini':
        'Lean / free-tier — hybrid brackets ([Chorus: one descriptor]), clearer '
        'structure over dense essays. Block 1 cap unchanged (~1000 chars).',
  };
}
