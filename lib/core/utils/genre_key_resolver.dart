/// Shared primary+fusion genre key resolution — aliases, primary-first, boundary matching.
class GenreKeyResolver {
  GenreKeyResolver._();

  static const _genreAliases = <String, String>{
    'alternative rock': 'rock / alternative',
    'contemporary gospel': 'praise and worship',
    'contemporary r&b': 'contemporary r&b',
    'lo-fi hip hop': 'boom bap',
    'praise and worship': 'praise and worship',
    'praise/worship': 'praise and worship',
    'melodic techno': 'deep house',
    'progressive house': 'progressive house',
    'modern country': 'modern country',
    'soulful house': 'deep house',
    'indie rock': 'rock / alternative',
    'heavy metal': 'rock / alternative',
    'tech house': 'deep house',
    'liquid dnb': 'drum and bass',
    'jazz rap': 'jazz',
    'uk drill': 'trap',
    'vinahouse': 'amapiano',
    'reggaeton': 'afrobeats',
    'shoegaze': 'rock / alternative',
    'neurofunk': 'drum and bass',
    'neo-soul': 'neo-soul',
    'drill': 'trap',
    'rnb': 'contemporary r&b',
    'punk': 'rock / alternative',
    'soul': 'neo-soul',
  };

  static String normalizeBlob(
    String primary,
    String fusion, {
    List<(String, String)> extraReplacements = const [],
    bool applyDefaultAliases = true,
  }) {
    var blob = '${primary.trim()} ${fusion.trim()}'.toLowerCase().replaceAll('&', 'and');
    for (final pair in extraReplacements) {
      blob = blob.replaceAll(pair.$1, pair.$2);
    }
    blob = blob.replaceAll('drum & bass', 'drum and bass');
    if (applyDefaultAliases) {
      final aliases = _genreAliases.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));
      for (final entry in aliases) {
        if (blob.contains(entry.key)) {
          blob = '$blob ${entry.value}';
        }
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
    bool applyDefaultAliases = true,
  }) {
    final keySet = keys.toSet();
    if (fusion.trim().isNotEmpty) {
      final primaryHit = _bestKey(
        keySet,
        normalizeBlob(
          primary,
          '',
          extraReplacements: extraReplacements,
          applyDefaultAliases: applyDefaultAliases,
        ),
      );
      if (primaryHit.isNotEmpty) return primaryHit;
    }
    return _bestKey(
      keySet,
      normalizeBlob(
        primary,
        fusion,
        extraReplacements: extraReplacements,
        applyDefaultAliases: applyDefaultAliases,
      ),
    ).ifEmpty(defaultKey);
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
