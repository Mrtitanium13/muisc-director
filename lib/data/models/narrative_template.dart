/// Genre-specific lyric narrative scaffold with placeholder substitution.
class NarrativeTemplate {
  const NarrativeTemplate(this.description);

  final String description;

  /// Replaces `${mood}` and `${themes}` with runtime values.
  String build({required String mood, required List<String> themes}) {
    final themeText = themes.isEmpty
        ? 'everyday emotion and connection'
        : themes.join(' and ');
    return description
        .replaceAll(r'${mood}', mood)
        .replaceAll(r'${themes}', themeText)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
