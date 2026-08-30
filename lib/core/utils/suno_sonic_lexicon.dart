/// Maps DAW-operation phrases → sonic-character phrases Suno can map onto
/// its latent space. Short, curated, idempotent.
abstract final class SunoStagingReformulator {
  SunoStagingReformulator._();

  /// Ordered: longer phrases first so prefixes are caught correctly.
  ///
  /// Replacement values must not contain other dictionary keys, or a later
  /// entry in the same pass could re-match the substituted text.
  static const Map<String, String> _dict = {
    'multi-tracked vocal doubles': 'stacked vocal doubles, layered harmonies',
    'multi-tracked vocals': 'layered vocal stack',
    'multi-tracked': 'stacked',
    'hard fill release': 'hard snare roll punctuating release',
    'hard fill': 'hard snare roll',
    'hard snare fill': 'hard snare roll accent',
  };

  /// Read-only view of the substitution dictionary (longest-first order).
  static Map<String, String> get dictionary => Map.unmodifiable(_dict);

  /// Reformulates DAW jargon into Suno-mappable sonic descriptors.
  ///
  /// The dictionary is applied in longest-first order. After substitution,
  /// duplicate commas and extra whitespace are collapsed.
  static String reformulate(String raw) {
    var out = raw;
    for (final e in _dict.entries) {
      final p = RegExp(RegExp.escape(e.key), caseSensitive: false);
      if (p.hasMatch(out)) {
        out = out.replaceAll(p, e.value);
      }
    }
    return out
        .replaceAll(RegExp(r',\s*,+'), ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+,'), ',')
        .replaceAll(RegExp(r',\s*$'), '')
        .trim();
  }

  /// True if [reformulate] would change [raw].
  static bool wouldChange(String raw) => reformulate(raw) != raw;
}
