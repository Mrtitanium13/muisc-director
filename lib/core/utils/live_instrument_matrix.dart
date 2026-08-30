import 'live_instrument_matrix_data.dart';

/// Genre-accurate live instrument profiles (tools/live_instrument_matrix.json).
class LiveInstrument {
  const LiveInstrument({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultArticulation,
    required this.mixRole,
    this.promptText = '',
    this.aliasHints = const [],
  });

  final String id;
  final String name;
  final String category;
  final String defaultArticulation;
  final String mixRole;

  /// LLM-facing label when set; UI keeps [name].
  final String promptText;
  final List<String> aliasHints;

  String get promptLabel {
    final p = promptText.trim();
    return p.isNotEmpty ? p : name;
  }
}

class LiveInstrumentMatrix {
  LiveInstrumentMatrix._();

  static const _defaultKey = 'default';

  static const _liveAmbienceStudioClauses = [
    'dead-room isolation',
    'close-mic studio capture',
    'dry acoustic room',
  ];

  static LiveInstrument _fromRow(Map<String, String> row) {
    final aliasRaw = row['aliasHints'] ?? '';
    return LiveInstrument(
      id: row['id']!,
      name: row['name']!,
      category: row['category']!,
      defaultArticulation: row['defaultArticulation']!,
      mixRole: row['mixRole']!,
      promptText: row['promptText'] ?? '',
      aliasHints: aliasRaw.isEmpty
          ? const []
          : aliasRaw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );
  }

  static const _legacyAliases = <String, String>{};

  /// When selection text includes "Live", reinforce studio capture (positive tokens only).
  static bool selectionImpliesLiveAmbience(String realInstrumentals) =>
      realInstrumentals.toLowerCase().contains('live');

  static String augmentAvoidClause({
    required String avoid,
    required String realInstrumentals,
  }) {
    if (!selectionImpliesLiveAmbience(realInstrumentals)) {
      return avoid.trim();
    }
    final seen = <String>{};
    final out = <String>[];
    for (final clause in [
      if (avoid.trim().isNotEmpty) avoid.trim(),
      ..._liveAmbienceStudioClauses,
    ]) {
      final key = clause.toLowerCase();
      if (seen.add(key)) out.add(clause);
    }
    return out.join(', ');
  }

  static String? _bundleForLabel(String label) {
    final key = LiveInstrumentMatrixData.bundleKeyForGenre(label);
    if (key == null || !LiveInstrumentMatrixData.byGenre.containsKey(key)) {
      return null;
    }
    return key;
  }

  static String _bestPartialAlias(String blob) {
    final key = LiveInstrumentMatrixData.bundleKeyForGenre(blob);
    if (key != null && LiveInstrumentMatrixData.byGenre.containsKey(key)) {
      return key;
    }
    return '';
  }

  static String? _legacyHit(String text, Set<String> keys) {
    final lower = text.toLowerCase();
    for (final entry in _legacyAliases.entries) {
      if (lower.contains(entry.key) && keys.contains(entry.value)) {
        return entry.value;
      }
    }
    return null;
  }

  static String resolveGenreKey(String primary, String fusion) {
    final keys = LiveInstrumentMatrixData.byGenre.keys.toSet();
    final blob = '${primary.trim()} ${fusion.trim()}'.toLowerCase();

    if (fusion.trim().isNotEmpty) {
      final primaryHit = _bundleForLabel(primary) ?? _legacyHit(primary, keys);
      if (primaryHit != null) return primaryHit;
    }

    for (final label in [primary, fusion]) {
      final hit = _bundleForLabel(label);
      if (hit != null) return hit;
    }

    final legacy = _legacyHit(blob, keys);
    if (legacy != null) return legacy;

    final partial = _bestPartialAlias(blob);
    if (partial.isNotEmpty) return partial;

    return _bestGenreKeyFromBlob(blob).ifEmpty(_defaultKey);
  }

  static String _bestGenreKeyFromBlob(String blob) {
    var best = '';
    for (final key in LiveInstrumentMatrixData.byGenre.keys) {
      final phrase = key.replaceAll('_', ' ');
      if (blob.contains(phrase) && phrase.length > best.length) {
        best = key;
      }
    }
    return best;
  }

  static List<LiveInstrument> instrumentsForGenre(
    String primary,
    String fusion,
  ) {
    final key = resolveGenreKey(primary, fusion);
    final rows = LiveInstrumentMatrixData.byGenre[key] ??
        LiveInstrumentMatrixData.byGenre[_defaultKey]!;
    return rows.map(_fromRow).toList();
  }

  static List<LiveInstrument> _allInstrumentsUnion() {
    final seen = <String>{};
    final out = <LiveInstrument>[];
    for (final rows in LiveInstrumentMatrixData.byGenre.values) {
      for (final row in rows) {
        final inst = _fromRow(row);
        if (seen.add(inst.id)) out.add(inst);
      }
    }
    return out;
  }

  static List<String> parseSelection(String raw) =>
      raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  static bool _tokenMatchesInstrument(String token, LiveInstrument inst) {
    final t = token.toLowerCase().trim();
    if (t.isEmpty) return false;
    if (inst.id.toLowerCase() == t || inst.name.toLowerCase() == t) {
      return true;
    }
    final label = inst.promptLabel.toLowerCase();
    if (label == t || t.contains(label) || label.contains(t)) {
      return true;
    }
    for (final alias in inst.aliasHints) {
      final a = alias.toLowerCase();
      if (a == t || t.contains(a) || a.contains(t)) return true;
    }
    return false;
  }

  static List<LiveInstrument> _matchSelected(
    List<LiveInstrument> available,
    List<String> tokens, {
    List<LiveInstrument>? fallbackCatalog,
  }) {
    final out = <LiveInstrument>[];
    final catalog = fallbackCatalog ?? available;
    for (final token in tokens) {
      LiveInstrument? hit;
      for (final inst in available) {
        if (_tokenMatchesInstrument(token, inst)) {
          hit = inst;
          break;
        }
      }
      if (hit == null) {
        for (final inst in catalog) {
          if (_tokenMatchesInstrument(token, inst)) {
            hit = inst;
            break;
          }
        }
      }
      if (hit != null && !out.any((x) => x.id == hit!.id)) out.add(hit);
    }
    return out;
  }

  static String _gearModifier(LiveInstrument inst, bool l99) {
    if (!l99) return '';
    switch (inst.category) {
      case 'guitar':
        return ' (vintage Fender amp, tube warmth)';
      case 'keys':
        return ' (Neve 1073 preamp, analog warmth)';
      case 'horns':
      case 'strings':
      case 'saxophones':
      case 'trumpets':
      case 'winds':
        return " (Neumann U47 close-mic'd, dry room)";
      case 'bass':
      case 'melodic_bass':
        return ' (Ampeg SVT warmth, tight DI blend)';
      default:
        return '';
    }
  }

  static String _normalizeVersion(String version) {
    final v = version.trim().toLowerCase();
    if (v == 'v4.5') return 'v4.5';
    if (v.startsWith('v5.5')) return 'v5.5pro';
    return 'v5';
  }

  static ({String styleInjection, String metaTagInjection}) generatePrompt({
    required String genre,
    required String selectionRaw,
    required String sunoVersion,
    String fusionGenre = '',
    String powerCodes = '',
  }) {
    final tokens = parseSelection(selectionRaw);
    if (tokens.isEmpty) {
      return (styleInjection: '', metaTagInjection: '');
    }
    final available = instrumentsForGenre(genre, fusionGenre);
    final catalog = _allInstrumentsUnion();
    final selected = _matchSelected(
      available,
      tokens,
      fallbackCatalog: catalog,
    );
    if (selected.isEmpty) {
      return (styleInjection: '', metaTagInjection: '');
    }

    final v = _normalizeVersion(sunoVersion);
    final l99 = powerCodes.toUpperCase().contains('/L99');

    final descriptions = selected.map((inst) {
      final label = inst.promptLabel;
      final mod = _gearModifier(inst, l99);
      final usePromptOnly = inst.promptText.trim().isNotEmpty;
      if (v == 'v4.5') {
        if (usePromptOnly) {
          return '$label, ${inst.mixRole}$mod';
        }
        return '$label, ${inst.defaultArticulation}, ${inst.mixRole}$mod';
      }
      if (v == 'v5') {
        if (usePromptOnly) {
          return 'featuring $label sitting in the ${inst.mixRole}$mod';
        }
        return 'featuring ${inst.defaultArticulation} $label sitting in the ${inst.mixRole}$mod';
      }
      if (usePromptOnly) {
        return 'driven by $label$mod, perfectly seated in the ${inst.mixRole}';
      }
      return 'driven by a ${inst.defaultArticulation} $label$mod, perfectly seated in the ${inst.mixRole}';
    }).toList();

    if (v == 'v4.5') {
      return (
        styleInjection: ', ${descriptions.join(', ')}',
        metaTagInjection: '[${selected.first.promptLabel} Feature]',
      );
    }
    if (v == 'v5') {
      return (
        styleInjection: '. ${descriptions.join(', ')}.',
        metaTagInjection:
            '[Instrumental: ${selected.map((s) => s.promptLabel).join(' and ')} interplay]',
      );
    }
    var meta =
        '[Instrumental Break: Feature ${selected.first.defaultArticulation} ${selected.first.promptLabel}, ${selected.first.mixRole}, dynamic lift, subtle tape saturation]';
    if (selected.length > 1) {
      final sec = selected[1];
      meta +=
          '\n[Bridge: Intimate interplay between ${sec.promptLabel} and vocals, ${sec.mixRole}]';
    }
    return (
      styleInjection:
          '. The arrangement is elevated by ${descriptions.join(', and ')}.',
      metaTagInjection: meta,
    );
  }

  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    required String selectionRaw,
    required String sunoVersion,
    String powerCodes = '',
  }) {
    final raw = selectionRaw.trim();
    if (raw.isEmpty) return '';

    final key = resolveGenreKey(primaryGenre, subGenreFusion);
    final catalog = _allInstrumentsUnion();
    final matched = _matchSelected(
      instrumentsForGenre(primaryGenre, subGenreFusion),
      parseSelection(raw),
      fallbackCatalog: catalog,
    );
    final prompt = generatePrompt(
      genre: primaryGenre,
      selectionRaw: raw,
      sunoVersion: sunoVersion,
      fusionGenre: subGenreFusion,
      powerCodes: powerCodes,
    );

    final lines = <String>[
      'Matrix schema: ${LiveInstrumentMatrixData.schemaVersion}',
      'Matched genre profile: [$key]',
      'User selection: $raw',
    ];
    if (matched.isNotEmpty) {
      for (final inst in matched) {
        final label = inst.promptLabel;
        lines.add(
          '• $label (${inst.name}): ${inst.defaultArticulation} | mix: ${inst.mixRole}',
        );
      }
    } else {
      lines.add(
        '• Free-text instruments — describe articulation + mix placement per protocol; '
        'frame atypical pairings as intentional fusion.',
      );
    }
    if (prompt.styleInjection.isNotEmpty) {
      lines.add(
        'Block 1 styleInjection (weave into producer prose): ${prompt.styleInjection}',
      );
    }
    if (prompt.metaTagInjection.isNotEmpty) {
      lines.add(
        'Block 2 metaTagInjection (place in timeline): ${prompt.metaTagInjection}',
      );
    }
    lines.add(
      'Never list bare instrument names. No artist names. Honor version-aware injection from REAL INSTRUMENT PROTOCOL.',
    );

    final body = lines.join('\n');
    return '[REAL INSTRUMENT ACCOMPANIMENT] (MANDATORY: Feature the following '
        'instruments prominently. Emphasize their natural, acoustic character and '
        'the specified articulations. This is a production requirement, not a '
        'suggestion.):\n$body';
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
