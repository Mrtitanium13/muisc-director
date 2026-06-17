/// Optional temperament codes for Path C generation and Path A inference.
/// Optimized using Dart 3 features for safe lookup performance.
enum LyricTemperament {
  grit('/GRIT', 'Grit'),
  tender('/TENDER', 'Tender'),
  fury('/FURY', 'Fury'),
  haze('/HAZE', 'Haze'),
  swagger('/SWAGGER', 'Swagger'),
  hymn('/HYMN', 'Hymn'),
  wired('/WIRED', 'Wired'),
  elevated('/ELEVATED', 'Elevated'),
  chill('/CHILL', 'Chill'),
  bounce('/BOUNCE', 'Bounce'),
  custom('__custom__', 'Custom');

  final String code;
  final String label;

  const LyricTemperament(this.code, this.label);

  /// Fast lookup map caching the codes for maximum O(1) matching efficiency.
  static final Map<String, LyricTemperament> _codeMap = {
    for (final t in LyricTemperament.values) t.code.toLowerCase(): t
  };

  /// Returns the enum matching the raw string code with safe validation.
  static LyricTemperament fromCode(String? rawCode) {
    if (rawCode == null) return LyricTemperament.custom;
    final clean = rawCode.trim().toLowerCase();
    return _codeMap[clean] ?? LyricTemperament.custom;
  }
}

/// Backward-compatible interface utility mapping static presets to UI elements.
class LyricTemperamentData {
  LyricTemperamentData._();

  /// Temperament chip codes for the prompt form (excludes [LyricTemperament.custom]).
  static List<String> get codes => LyricTemperament.values
      .where((t) => t != LyricTemperament.custom)
      .map((t) => t.code)
      .toList();

  /// Resolves a readable display label for a given temperament token.
  /// Safely passes unrecognized strings straight through as fallbacks.
  static String labelFor(String code) {
    final clean = code.trim();
    final matched = LyricTemperament.fromCode(clean);

    if (matched == LyricTemperament.custom &&
        clean.toLowerCase() != LyricTemperament.custom.code) {
      return clean;
    }
    return matched.label;
  }
}
