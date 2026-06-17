import '../../data/models/user_input_model.dart';

/// Canonical primary sub-genre label for commercial pop / “Melodic Math” lane.
const String hitmakerMaxMartinGenreLabel = 'Pop / Max Martin';

/// True when the user picked Hitmaker / Max Martin lane on primary or fusion.
bool userRequestedHitmakerMode(UserInputModel i) {
  final blob =
      '${i.primaryGenre} ${i.subGenreFusion}'.toLowerCase();
  return blob.contains('max martin') ||
      blob.contains('hitmaker mode') ||
      blob.contains('melodic math');
}

/// Strong user-message copy so the model bakes Hitmaker doctrine into **Block 1** prose.
String buildHitmakerModeUserBlock({required bool v2UnifiedOutput}) {
  final impl = v2UnifiedOutput
      ? 'Implementation: satisfy **Block 1** only inside the 130–150 word / ≤1000 character paragraph — '
          'weave the keywords as flowing producer language, not a comma-tag dump. '
          'Echo melodic layout and ear-candy pacing in **Block 2** section tags where helpful.'
      : 'Implementation: weave thae same intent into **SUNO STYLE** as dense producer prose; '
          'mirror melodic arc and motion in **SUNO STRUCTURE** section notes.';

  return '''
HITMAKER MODE — COMMERCIAL POP (“MELODIC MATH”) — USER SELECTED; NON-OPTIONAL FOR THIS GENERATION

Melodic Math principles (honor in Block 1 + arrangement):
• Melodic symmetry (A–A–B–A): one memorable phrase, repeat, slight twist on the third line, resolve on the fourth — “addictive” familiarity without boredom.
• Rhythmic verse vs legato chorus: if the verse is wordy and percussive, the chorus opens up — long vowel shapes (A, E, O) for lift and singalong.
• Vocal comping & stacking: lead doubles/triples; harmonies stacked wide — aim for a “super-vocal” locked dead-center in the mix.
• Rule of three (motion): do not let more than ~8 seconds pass without a new ear-candy moment (synth zap, ad-lib, fill, or texture shift).

POWER KEYWORDS — must appear naturally in Block 1 producer prose (not as a naked list):
Melodic Math · 1176 FET Compression · Vocal Stacking · Sidechained Pulsing Bass · −8 LUFS target

$impl
'''.trim();
}
