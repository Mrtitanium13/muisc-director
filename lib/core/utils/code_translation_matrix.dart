import 'code_translation_matrix_data.dart';

/// Genre-specific Power Code & Temperament production vocabulary.
class CodeTranslationMatrix {
  CodeTranslationMatrix._();

  static final RegExp _codeRe = RegExp(
    r'/(L99|UDA|BEASTMODE|GRIT|TENDER|FURY|HAZE|SWAGGER|HYMN|WIRED)\b',
    caseSensitive: false,
  );

  static String getGenreCategory(String primary, [String fusion = '']) {
    final g = '${primary.trim()} ${fusion.trim()}'
        .toLowerCase()
        .replaceAll('&', 'and');
    if (RegExp(
      r'house|techno|trance|dubstep|hardstyle|bounce|edm|garage|jersey|amapiano|vinahouse|afro house',
    ).hasMatch(g)) {
      return 'edm';
    }
    if (RegExp(r'hip hop|hiphop|rap|trap|drill|phonk|boom bap|cloud rap')
        .hasMatch(g)) {
      return 'hiphop';
    }
    if (RegExp(r'r&b|rnb|soul|gospel|worship|neo-soul|neo soul|praise')
        .hasMatch(g)) {
      return 'rnb_soul';
    }
    if (RegExp(r'rock|metal|punk|grunge|shoegaze|hardcore').hasMatch(g)) {
      return 'rock_metal';
    }
    if (RegExp(r'pop|k-pop|kpop|j-pop|mandopop|hyperpop|synth-pop|synthpop')
        .hasMatch(g)) {
      return 'pop';
    }
    return 'world_jazz_acoustic';
  }

  static List<String> extractActiveCodes(String codesBlob, [String vibe = '']) {
    final found = <String>[];
    final seen = <String>{};
    for (final blob in [codesBlob, vibe]) {
      for (final m in _codeRe.allMatches(blob)) {
        final code = m.group(1)!.toUpperCase();
        if (seen.add(code)) found.add(code);
      }
    }
    return found;
  }

  static String _normalizeVersion(String version) {
    final v = version.trim().toLowerCase();
    if (v == 'v4.5') return 'v4.5';
    if (v.startsWith('v5.5')) return 'v5.5pro';
    return 'v5';
  }

  static String _trimModifier(String modifier, String version) {
    final parts = modifier.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return modifier;
    if (version == 'v4.5') return parts.take(2).join(', ');
    if (version == 'v5') {
      final half = (parts.length / 2).ceil().clamp(1, parts.length);
      return '${parts.take(half).join(', ')}.';
    }
    return '$modifier.';
  }

  /// C_final = Map(Code_user, Category_genre) ⊕ Filter(Length_version)
  static String applyGenreSpecificCodes({
    required String genre,
    required String codesBlob,
    required String sunoVersion,
    String fusionGenre = '',
    String vibe = '',
  }) {
    final category = getGenreCategory(genre, fusionGenre);
    final v = _normalizeVersion(sunoVersion);
    final codes = extractActiveCodes(codesBlob, vibe);
    if (codes.isEmpty) return '';

    final matrix = CodeTranslationMatrixData.matrix;
    final modifiers = <String>[];
    for (final code in codes) {
      final row = matrix[code];
      final phrase = row?[category];
      if (phrase != null) modifiers.add(_trimModifier(phrase, v));
    }
    if (modifiers.isEmpty) return '';

    if (v == 'v4.5') return modifiers.join(', ');
    if (v == 'v5') return modifiers.join(' ');
    return modifiers.join(', ');
  }

  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    required String codesBlob,
    required String sunoVersion,
    String vibe = '',
  }) {
    final codes = extractActiveCodes(codesBlob, vibe);
    if (codes.isEmpty) return '';

    final category = getGenreCategory(primaryGenre, subGenreFusion);
    final v = _normalizeVersion(sunoVersion);
    final matrix = CodeTranslationMatrixData.matrix;
    final lines = <String>[];
    for (final code in codes) {
      final phrase = matrix[code]?[category];
      if (phrase == null || phrase.trim().isEmpty) continue;
      final prose = _trimModifier(phrase, v);
      if (prose.isEmpty) continue;
      lines.add(
        '[CODE TRANSLATION: /$code for $category] '
        '(Apply these specific sonic characteristics): $prose',
      );
    }
    if (lines.isEmpty) return '';
    return lines.join('\n');
  }
}
