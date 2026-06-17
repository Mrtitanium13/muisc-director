import 'genre_key_resolver.dart';
import 'live_instrument_matrix_data.dart';

/// Genre-accurate live instrument profiles (tools/live_instrument_matrix.json).
class LiveInstrument {
  const LiveInstrument({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultArticulation,
    required this.mixRole,
  });

  final String id;
  final String name;
  final String category;
  final String defaultArticulation;
  final String mixRole;
}

class LiveInstrumentMatrix {
  LiveInstrumentMatrix._();

  static const _defaultKey = 'pop';

  static LiveInstrument _fromRow(Map<String, String> row) => LiveInstrument(
        id: row['id']!,
        name: row['name']!,
        category: row['category']!,
        defaultArticulation: row['defaultArticulation']!,
        mixRole: row['mixRole']!,
      );

  static String resolveGenreKey(String primary, String fusion) {
    return GenreKeyResolver.resolveKey(
      LiveInstrumentMatrixData.byGenre.keys,
      primary,
      fusion,
      defaultKey: _defaultKey,
    );
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

  static List<String> parseSelection(String raw) =>
      raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  static List<LiveInstrument> _matchSelected(
    List<LiveInstrument> available,
    List<String> tokens,
  ) {
    final out = <LiveInstrument>[];
    String norm(String s) => s.toLowerCase().trim();
    for (final token in tokens) {
      final t = norm(token);
      LiveInstrument? hit;
      for (final inst in available) {
        if (norm(inst.id) == t || norm(inst.name) == t) {
          hit = inst;
          break;
        }
      }
      if (hit == null) {
        for (final inst in available) {
          final n = norm(inst.name);
          if (t.contains(n) || n.contains(t)) {
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
        return " (Neumann U47 close-mic'd, dry room)";
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
    final selected = _matchSelected(available, tokens);
    if (selected.isEmpty) {
      return (styleInjection: '', metaTagInjection: '');
    }

    final v = _normalizeVersion(sunoVersion);
    final l99 = powerCodes.toUpperCase().contains('/L99');

    final descriptions = selected.map((inst) {
      final mod = _gearModifier(inst, l99);
      if (v == 'v4.5') {
        return '${inst.name}, ${inst.defaultArticulation}, ${inst.mixRole}$mod';
      }
      if (v == 'v5') {
        return 'featuring ${inst.defaultArticulation} ${inst.name} sitting in the ${inst.mixRole}$mod';
      }
      return 'driven by a ${inst.defaultArticulation} ${inst.name}$mod, perfectly seated in the ${inst.mixRole}';
    }).toList();

    if (v == 'v4.5') {
      return (
        styleInjection: ', ${descriptions.join(', ')}',
        metaTagInjection: '[${selected.first.name} Feature]',
      );
    }
    if (v == 'v5') {
      return (
        styleInjection: '. ${descriptions.join(', ')}.',
        metaTagInjection:
            '[Instrumental: ${selected.map((s) => s.name).join(' and ')} interplay]',
      );
    }
    var meta =
        '[Instrumental Break: Feature ${selected.first.defaultArticulation} ${selected.first.name}, ${selected.first.mixRole}, dynamic lift, subtle tape saturation]';
    if (selected.length > 1) {
      final sec = selected[1];
      meta +=
          '\n[Bridge: Intimate interplay between ${sec.name} and vocals, ${sec.mixRole}]';
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
    final matched = _matchSelected(
      instrumentsForGenre(primaryGenre, subGenreFusion),
      parseSelection(raw),
    );
    final prompt = generatePrompt(
      genre: primaryGenre,
      selectionRaw: raw,
      sunoVersion: sunoVersion,
      fusionGenre: subGenreFusion,
      powerCodes: powerCodes,
    );

    final lines = <String>[
      'LIVE INSTRUMENT ACCOMPANIMENT (LIVE INSTRUMENT PROTOCOL — Block 1 prose + Block 2 meta-tags):',
      'Matched genre profile: [$key]',
      'User selection: $raw',
    ];
    if (matched.isNotEmpty) {
      for (final inst in matched) {
        lines.add(
          '• ${inst.name}: ${inst.defaultArticulation} | mix: ${inst.mixRole}',
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
      'Never list bare instrument names. No artist names. Honor version-aware injection from LIVE INSTRUMENT PROTOCOL.',
    );
    return lines.join('\n');
  }
}
