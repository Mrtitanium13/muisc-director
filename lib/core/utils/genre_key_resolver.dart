/// Shared primary+fusion genre key resolution — primary-first, boundary matching.
class GenreKeyResolver {
  GenreKeyResolver._();

  static String normalizeBlob(
    String primary,
    String fusion, {
    List<(String, String)> extraReplacements = const [],
  }) {
    var blob = '${primary.trim()} ${fusion.trim()}'.toLowerCase();
    // Normalize R&B → rnb before '&' → 'and' so "R&B" / "90s R&B" hit the rnb lane.
    blob = blob.replaceAll(RegExp(r'r\s*&\s*b'), 'rnb');
    blob = blob.replaceAll('&', 'and');

    final replacements = extraReplacements.toList()
      ..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final pair in replacements) {
      final pattern = RegExp(
        '(?<![a-z0-9])${RegExp.escape(pair.$1)}(?![a-z0-9])',
      );
      if (pattern.hasMatch(blob)) {
        blob = blob.replaceAll(pattern, pair.$2);
      }
    }

    return blob.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool keyMatchesBlob(String key, String blob) {
    final pattern = RegExp(
      '(?<![a-z0-9])${RegExp.escape(key)}(?![a-z0-9])',
    );
    return pattern.hasMatch(blob);
  }

  static String _bestKey(Iterable<String> keys, String blob) {
    var best = '';
    for (final key in keys) {
      if (keyMatchesBlob(key, blob) && key.length > best.length) {
        best = key;
      }
    }
    return best;
  }

  static String resolveKey(
    Iterable<String> keys,
    String primary,
    String fusion, {
    required String defaultKey,
    List<(String, String)> extraReplacements = const [],
  }) {
    final keySet = keys.toSet();
    if (fusion.trim().isNotEmpty) {
      final primaryHit = _bestKey(
        keySet,
        normalizeBlob(primary, '', extraReplacements: extraReplacements),
      );
      if (primaryHit.isNotEmpty) return primaryHit;
    }
    return _bestKey(
      keySet,
      normalizeBlob(
        primary,
        fusion,
        extraReplacements: extraReplacements,
      ),
    ).ifEmpty(defaultKey);
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
