/// Enforces the 30% structural-density budget on rendered bracket lines.
class DensityBudgetEnforcer {
  DensityBudgetEnforcer._();

  static const int v55PerBracketCap = 60;
  static const int v5PerBracketCap = 30;

  static String enforce({
    required String renderedSections,
    required int cap,
    String sunoVersion = 'v5.5',
  }) {
    if (cap <= 0) {
      return renderedSections.split('\n').map(_stripAllStaging).join('\n');
    }

    final perBracketCap = sunoVersion.trim().toLowerCase().startsWith('v5.5')
        ? v55PerBracketCap
        : v5PerBracketCap;

    var lines = renderedSections
        .split('\n')
        .map((line) => _capBracketLine(line, perBracketCap))
        .toList();
    var joined = lines.join('\n');
    if (joined.length <= cap) return joined;

    lines = _deduplicateIdenticalStaging(lines);
    joined = lines.join('\n');
    if (joined.length <= cap) return joined;

    const stripOrder = [
      'outro',
      'intro',
      'verse',
      'pre-chorus',
      'chorus',
      'hook',
      'drop',
      'build',
      'break',
      'head',
      'theme',
      'solo',
      'coda',
      'section',
    ];

    for (final key in stripOrder) {
      if (lines.join('\n').length <= cap) break;
      lines = lines.map((line) => _stripStaging(line, key)).toList();
    }

    if (lines.join('\n').length <= cap) return lines.join('\n');

    lines = lines.map(_stripAllStaging).toList();
    return lines.join('\n');
  }

  static String _capBracketLine(String line, int maxStagingChars) {
    if (!line.contains(':')) return line;
    final open = line.indexOf('[');
    final colon = line.indexOf(':');
    final close = line.lastIndexOf(']');
    if (colon < 0 || close <= colon) return line;

    final label = line.substring(open + 1, colon).trim();
    var staging = line.substring(colon + 1, close).trim();
    if (staging.length <= maxStagingChars) return line;

    while (staging.length > maxStagingChars && staging.contains(',')) {
      staging = staging.substring(0, staging.lastIndexOf(',')).trim();
    }
    if (staging.length > maxStagingChars) {
      staging = staging.substring(0, maxStagingChars).trim();
    }
    return '[$label: $staging]';
  }

  static List<String> _deduplicateIdenticalStaging(List<String> lines) {
    final seenStaging = <String>{};
    return lines.map((line) {
      if (!line.contains(':')) return line;
      final colon = line.indexOf(':');
      final close = line.lastIndexOf(']');
      if (close <= colon) return line;
      final staging = line.substring(colon + 1, close).trim().toLowerCase();
      if (staging.isEmpty) return line;
      if (seenStaging.contains(staging)) return _stripAllStaging(line);
      seenStaging.add(staging);
      return line;
    }).toList();
  }

  static String _stripStaging(String line, String key) {
    final lower = line.toLowerCase();
    if (!lower.startsWith('[$key') || !line.contains(':')) return line;
    final idx = line.indexOf(':');
    return '${line.substring(0, idx)}]';
  }

  static String _stripAllStaging(String line) {
    if (!line.contains(':')) return line;
    final idx = line.indexOf(':');
    final close = line.lastIndexOf(']');
    if (close > idx) return '${line.substring(0, idx)}]';
    return line;
  }
}
