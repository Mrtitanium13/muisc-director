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
    for (final route in routes) {
      if (route is! Map) continue;
      if (route['id'] == 'default') continue;
      final match = route['match'];
      if (match is! Map) continue;
      final langs = ((match['languages'] as List?) ?? const [])
          .map((e) => normalize('$e'))
          .toList();
      final genres = ((match['genres'] as List?) ?? const [])
          .map((e) => normalize('$e'))
          .toList();
      final langOk = langs.contains('*') ||
          langs.any((l) => lang.contains(l) || l.contains(lang));
      final genreOk = genres.contains('*') ||
          genres.any((x) => g.contains(x) || x.contains(g));
      if (langOk && genreOk) return Map<String, dynamic>.from(route);
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
        ((_routing['stage_preferences'] as Map?)?[stage] as List?) ?? const [];
    final primary = '${route['primary'] ?? 'gpt-6-astra'}';
    for (final m in stagePrefs) {
      if ('$m' == primary) return primary;
    }
    return primary;
  }
}
