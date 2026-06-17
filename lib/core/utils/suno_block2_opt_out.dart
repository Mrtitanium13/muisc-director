import '../../data/models/user_input_model.dart';

/// True when free-text fields include an explicit “Block 1 only” style request.
///
/// Matched case-insensitively as substrings: `style only`, `no lyrics`,
/// `no song structure`, `block 1 only`.
bool userRequestedBlock2OptOut(UserInputModel input) {
  final blob = [
    input.vibe,
    input.optionalLyrics,
    input.lyricThemeNotes,
    input.songStructureCustom,
    input.avoid,
  ].join(' ').toLowerCase();
  return blob.contains('style only') ||
      blob.contains('no lyrics') ||
      blob.contains('no song structure') ||
      blob.contains('block 1 only');
}
