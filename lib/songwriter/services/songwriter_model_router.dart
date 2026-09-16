import '../../core/constants/songwriter_prompts_data.dart';

/// Client-side mirror of tools/songwriter/model_routing.json
class SongwriterModelRouter {
  SongwriterModelRouter._();

  static Map<String, dynamic> get _routing =>
      SongwriterPromptsData.config('model_routing');

  static String normalize(String s) => s.trim().toLowerCase();

  static Map<String, dynamic> matchRoute({
    required String genre,
    required String language,
  }) {
    final routes = (_routing['routes'] as List?) ?? const [];
    final g = normalize(genre);
    final lang = normalize(language);

    // Exact normalized membership — substring matching made empty inputs
    // match everything and codes like "en" match "french".
    bool matches(Object? values, String value) {
      final allowed = ((values as List?) ?? const [])
          .map((e) => normalize('$e'))
          .toList();
      return allowed.contains('*') ||
          (value.isNotEmpty && allowed.contains(value));
    }

    for (final route in routes) {
      if (route is! Map) continue;
      if (route['id'] == 'default') continue;
      final match = route['match'];
      if (match is! Map) continue;
      if (matches(match['languages'], lang) && matches(match['genres'], g)) {
        return Map<String, dynamic>.from(route);
      }
    }
    for (final route in routes) {
      if (route is Map && route['id'] == 'default') {
        return Map<String, dynamic>.from(route);
      }
    }
    return {'primary': 'gpt-6-astra', 'secondary': 'claude-sonnet'};
  }

  static String preferredLogical({
    required String genre,
    required String language,
    String stage = 'polish',
  }) {
    final route = matchRoute(genre: genre, language: language);
    final stagePrefs =
        ((_routing['stage_preferences'] as Map?)?[normalize(stage)] as List?) ??
            const [];
    final primary = '${route['primary'] ?? 'gpt-6-astra'}';
    // Stage list wins first (select/rhyme/arc/transitions), else genre primary.
    if (stagePrefs.isNotEmpty) {
      return '${stagePrefs.first}';
    }
    return primary;
  }
}
