/// Canonical Suno model targets for prompt routing and UI defaults.
enum SunoVersion {
  v4_5('v4.5'),
  v5('v5.0'),
  v5_5('v5.5');

  const SunoVersion(this.value);

  final String value;

  /// Preferred default for new projects (cinematic director's notes tier).
  static const SunoVersion preferred = SunoVersion.v5_5;

  static const String preferredValue = 'v5.5';

  static SunoVersion? tryParse(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'v4.5') return SunoVersion.v4_5;
    if (v == 'v5.0' || v == 'v5') return SunoVersion.v5;
    if (v.startsWith('v5.5')) return SunoVersion.v5_5;
    return null;
  }
}
