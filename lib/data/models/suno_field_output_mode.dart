/// Maps to Suno **Custom** vs **Simple** creation flows (field size rules differ).
enum SunoFieldOutputMode {
  /// Custom Mode: Style field = producer prose (130–150 words, ≤1000 chars) + optional Lyrics.
  custom,

  /// Simple Mode: Suno’s single Description field — Block 1 targets that box; the model still outputs Block 2 for reference unless the user opts out (see `userRequestedBlock2OptOut`).
  simple,
}
