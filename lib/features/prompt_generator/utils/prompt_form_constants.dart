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

  static const sunoVersions = ['v4.5', 'v5.0', 'v5.5'];

  static const sunoVersionHints = {
    'v4.5':
        'Minimal brackets — [Verse], [Chorus], [End] only. Best for dense / heavy '
        'genres. Same Block 1 prose cap (~1000 chars) as other versions.',
    'v5.0':
        'Hybrid brackets — [Chorus: wide harmonies]. Balanced staging + lyric depth. '
        'Block 1 prose cap unchanged (~1000 chars).',
    'v5.5':
        'Preferred — rich director\'s notes in brackets, full ~4-min arc, deepest '
        'lyric/structure budgets (Block 2 up to ~2500 chars).',
  };
}
