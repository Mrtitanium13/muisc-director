import 'package:music_director/core/constants/suno_version.dart';
import 'package:music_director/data/generated/genre_hardware_profiles_data.dart';

/// Strongly-typed view of one hardware profile row.
class HardwareProfile {
  final String id;
  final String genre;
  final String clusterId;
  final String styleDescriptors;
  final String leadVocal;
  final String vocalChain;
  final String drums;
  final String bass;
  final String keysSynths;
  final String outboard;
  final String monitoring;
  final String room;
  final String vibe;

  const HardwareProfile({
    required this.id,
    required this.genre,
    required this.clusterId,
    required this.styleDescriptors,
    required this.leadVocal,
    required this.vocalChain,
    required this.drums,
    required this.bass,
    required this.keysSynths,
    required this.outboard,
    required this.monitoring,
    required this.room,
    required this.vibe,
  });

  static const HardwareProfile fallback = HardwareProfile(
    id: 'DEFAULT',
    genre: 'Unknown',
    clusterId: 'UNKNOWN',
    styleDescriptors: 'polished producer mix, genre-appropriate LUFS',
    leadVocal: 'Neumann U87 or SM7B',
    vocalChain: '1073 -> 1176 -> LA-2A -> plate',
    drums: 'genre-appropriate kit',
    bass: 'DI + amp',
    keysSynths: 'Rhodes, piano, pads',
    outboard: 'SSL G bus glue',
    monitoring: 'studio monitors',
    room: 'controlled studio',
    vibe: 'release-ready, −9 to −11 LUFS',
  );

  factory HardwareProfile.fromMap(Map<dynamic, dynamic> raw) {
    String s(String key, String defaultValue) {
      final v = raw[key];
      if (v == null) return defaultValue;
      final t = v.toString().trim();
      return t.isEmpty ? defaultValue : t;
    }

    return HardwareProfile(
      id: s('id', 'DEFAULT'),
      genre: s('genre', 'Unknown'),
      clusterId: s('cluster_id', 'UNKNOWN'),
      styleDescriptors: s('style_descriptors', 'genre-appropriate mix'),
      leadVocal: s('lead_vocal', 'Neumann U87 or SM7B'),
      vocalChain: s('vocal_chain', '1073 -> 1176 -> LA-2A -> plate'),
      drums: s('drums', 'genre-appropriate kit'),
      bass: s('bass', 'DI + amp'),
      keysSynths: s('keys_synths', 'Rhodes, piano, pads'),
      outboard: s('outboard', 'SSL G bus glue'),
      monitoring: s('monitoring', 'studio monitors'),
      room: s('room', 'controlled studio'),
      vibe: s('vibe', 'release-ready, −9 to −11 LUFS'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HardwareProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _KeywordMatch {
  final String keyword;
  final HardwareProfile profile;
  const _KeywordMatch(this.keyword, this.profile);
}

class HardwareResolution {
  final HardwareProfile profile;
  /// `exact`, `keyword`, or `fallback`.
  final String source;
  /// 0.0–1.0 heuristic confidence for keyword matches.
  final double confidence;

  const HardwareResolution(this.profile, this.source, this.confidence);

  bool get isFallback => source == 'fallback';
}

/// Part E v2.1 genre-specific hardware defaults for Block 1 injection.
///
/// Scope: hardware + sonic vocabulary ONLY. DJ phrasing is handled by
/// `buildDjMixUserBlock` in `suno_dj_mix_directives.dart`.
///
/// Generated data: [GenreHardwareProfilesData] in
/// `lib/data/generated/genre_hardware_profiles_data.dart`.
class GenreHardwareProfiles {
  GenreHardwareProfiles._();

  // ---------------------------------------------------------------------------
  // Precomputed lookups
  // ---------------------------------------------------------------------------

  /// Always same length as [GenreHardwareProfilesData.profiles] so keyword
  /// index rows never drift.
  static final List<HardwareProfile> _allProfiles = [
    for (final raw in GenreHardwareProfilesData.profiles)
      HardwareProfile.fromMap(raw),
  ];

  static final Map<String, int> _directIndex = {
    for (final entry in GenreHardwareProfilesData.profileIndexByGenre.entries)
      normalizeGenre(entry.key): entry.value,
  };

  /// Longest-keyword-first fallback index. Built once.
  static final List<_KeywordMatch> _keywordIndex = _buildKeywordIndex();

  static List<_KeywordMatch> _buildKeywordIndex() {
    final matches = <_KeywordMatch>[];
    for (var i = 0; i < GenreHardwareProfilesData.profiles.length; i++) {
      final raw = GenreHardwareProfilesData.profiles[i];

      final keywords = raw['keywords'];
      if (keywords is! List) continue;

      final profile = _allProfiles[i];
      for (final kw in keywords) {
        final normalized = normalizeGenre(kw?.toString() ?? '');
        if (normalized.isNotEmpty) {
          matches.add(_KeywordMatch(normalized, profile));
        }
      }
    }
    matches.sort((a, b) {
      final byLen = b.keyword.length.compareTo(a.keyword.length);
      if (byLen != 0) return byLen;
      return a.keyword.compareTo(b.keyword);
    });
    return matches;
  }

  // ---------------------------------------------------------------------------
  // Version routing (shared [SunoVersion] — do not redefine)
  // ---------------------------------------------------------------------------

  static SunoVersion parseVersion(String sunoVersion) {
    final v = sunoVersion.trim().toLowerCase();
    if (v == 'v4.5') return SunoVersion.v4_5;
    if (v.startsWith('v5.5')) return SunoVersion.v5_5;
    if (v.startsWith('v5')) return SunoVersion.v5;
    return SunoVersion.preferred;
  }

  // ---------------------------------------------------------------------------
  // Profile resolution
  // ---------------------------------------------------------------------------

  static HardwareResolution resolve(String primary, String fusion) {
    final direct = _directIndex[normalizeGenre(primary)];
    if (direct != null && direct >= 0 && direct < _allProfiles.length) {
      return HardwareResolution(_allProfiles[direct], 'exact', 1.0);
    }

    final blob = normalizeGenre('$primary $fusion');
    if (blob.isNotEmpty) {
      for (final match in _keywordIndex) {
        if (blob.contains(match.keyword)) {
          final denom = blob.isEmpty ? 1 : blob.length;
          return HardwareResolution(
            match.profile,
            'keyword',
            (match.keyword.length / denom).clamp(0.0, 1.0),
          );
        }
      }
    }

    return const HardwareResolution(
      HardwareProfile.fallback,
      'fallback',
      0.0,
    );
  }

  /// Matched profile (never null — unknown genres return [HardwareProfile.fallback]).
  static HardwareProfile resolveProfile(String primary, String fusion) =>
      resolve(primary, fusion).profile;

  static String resolveProfileId(String primary, String fusion) =>
      resolveProfile(primary, fusion).id;

  static bool hasProfile(String primary, String fusion) =>
      !resolve(primary, fusion).isFallback;

  /// When primary and fusion resolve to different profiles, returns both.
  /// Useful for fusions like "Afro House + R&B".
  static List<HardwareProfile> resolveAllProfiles(
    String primary,
    String fusion,
  ) {
    final byId = <String, HardwareProfile>{};

    void add(HardwareResolution result) {
      if (result.isFallback) return;
      byId.putIfAbsent(result.profile.id, () => result.profile);
    }

    add(resolve(primary, ''));
    if (fusion.trim().isNotEmpty) {
      add(resolve(fusion, ''));
      add(resolve(primary, fusion));
    }

    return byId.values.toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Composition
  // ---------------------------------------------------------------------------

  /// Builds the hardware user-block.
  ///
  /// Keep [includeFusionProfiles] false by default so Block 1 stays short;
  /// set true when a fusion path should blend multiple hardware intents.
  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    required String sunoVersion,
    bool includeFusionProfiles = false,
  }) {
    final result = resolve(primaryGenre, subGenreFusion);
    final profiles = includeFusionProfiles && subGenreFusion.trim().isNotEmpty
        ? resolveAllProfiles(primaryGenre, subGenreFusion)
        : [result.profile];

    final list = profiles.isEmpty ? [HardwareProfile.fallback] : profiles;

    return switch (parseVersion(sunoVersion)) {
      SunoVersion.v4_5 => _compactV45(list),
      SunoVersion.v5 => _compactV5(list),
      SunoVersion.v5_5 => _fullV55(list),
    };
  }

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  static String _compactV45(List<HardwareProfile> profiles) {
    final p = profiles.first;
    return _capLength(
      'Production intent: ${_firstClause(p.vibe, 48)}; '
      'lead: ${_firstClause(p.leadVocal, 36)}; '
      'chain: ${_firstClause(p.vocalChain, 32)}; '
      'drums: ${_firstClause(p.drums, 32)}; '
      'true-peak ceiling −1.0 dBTP.',
      200,
    );
  }

  static String _compactV5(List<HardwareProfile> profiles) {
    if (profiles.length == 1) {
      final p = profiles.first;
      return _capLength(
        'Hardware intent [${p.id}]: ${_firstClause(p.styleDescriptors, 80)}. '
        'Vocal: ${p.leadVocal}, chain ${p.vocalChain}. '
        'Drums: ${p.drums}; bass: ${p.bass}. '
        'Loudness: ${p.vibe}, −1.0 dBTP true-peak ceiling.',
        600,
      );
    }

    final ids = profiles.map((p) => p.id).join('/');
    final styles =
        profiles.map((p) => _firstClause(p.styleDescriptors, 40)).join(' + ');
    return _capLength(
      'Hardware intent [$ids]: $styles. '
      'Vocal: ${profiles.first.leadVocal}. '
      'Loudness: ${profiles.first.vibe}, −1.0 dBTP true-peak ceiling.',
      600,
    );
  }

  static String _fullV55(List<HardwareProfile> profiles) {
    if (profiles.length == 1) return _fullV55Single(profiles.first);

    // Guaranteed loudness floor when the body is truncated.
    const suffix = 'release-ready, −1.0 dBTP true-peak ceiling.';
    const maxTotal = 500;
    final budget = maxTotal - suffix.length - 1;

    final ids = profiles.map((p) => p.id).join(' + ');
    final lead = profiles.first.leadVocal;
    final chain = profiles.first.vocalChain;
    final drums = profiles.map((p) => p.drums).join(' / ');
    final bass = profiles.map((p) => p.bass).join(' / ');
    final keys = profiles.map((p) => p.keysSynths).join(' / ');
    final outboard = profiles.map((p) => p.outboard).join(' / ');
    final room = profiles.first.room;
    final vibe = profiles.first.vibe;

    final body = 'Hardware / production intent ([$ids]): '
        'vocal: $lead -> $chain | '
        'drums: $drums | bass: $bass | keys: $keys | '
        'outboard: $outboard | room: $room | '
        'loudness target: $vibe, ';

    if (budget <= 0) return suffix;
    return '${_capLength(body, budget)} $suffix';
  }

  static String _fullV55Single(HardwareProfile p) {
    const suffix = 'release-ready, −1.0 dBTP true-peak ceiling.';
    const maxTotal = 500;
    final budget = maxTotal - suffix.length - 1;

    final body = 'Hardware / production intent ([${p.id}]): '
        'style: ${p.styleDescriptors} | '
        'vocal: ${p.leadVocal} -> ${p.vocalChain} | '
        'drums: ${p.drums} | bass: ${p.bass} | keys: ${p.keysSynths} | '
        'outboard: ${p.outboard} | room: ${p.room} | '
        'loudness target: ${p.vibe}, ';

    if (budget <= 0) return suffix;
    return '${_capLength(body, budget)} $suffix';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Decodes stray HTML entities, lowercases, strips diacritics (Forró → forro),
  /// keeps `&` (R&B), and collapses punctuation/whitespace.
  static String normalizeGenre(String input) {
    var s = input.toLowerCase();
    for (var i = 0; i < 3; i++) {
      final next = s.replaceAll('&amp;', '&');
      if (next == s) break;
      s = next;
    }
    s = _stripDiacritics(s);
    return s
        .replaceAll(RegExp(r'[^\w\s&]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _stripDiacritics(String input) {
    final buf = StringBuffer();
    for (final unit in input.runes) {
      buf.write(_foldDiacriticChar(String.fromCharCode(unit)));
    }
    return buf.toString();
  }

  static String _foldDiacriticChar(String ch) {
    const map = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ç': 'c', 'ñ': 'n',
      'ø': 'o', 'æ': 'ae', 'œ': 'oe',
    };
    return map[ch] ?? ch;
  }

  static String _firstClause(String s, int maxLen) {
    final text = s.trim();
    var stop = -1;
    for (final ch in [';', '.', '—']) {
      final i = text.indexOf(ch);
      if (i >= 0 && (stop < 0 || i < stop)) stop = i;
    }
    final chunk = stop >= 0 ? text.substring(0, stop).trim() : text;
    return chunk.length <= maxLen ? chunk : _capLength(chunk, maxLen);
  }

  static String _capLength(String s, int max) {
    if (max <= 0 || s.length <= max) return s;
    final limit = max - 1;
    final cut = s.substring(0, limit);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > max ~/ 2) return '${cut.substring(0, lastSpace)}…';
    return '${cut.substring(0, limit)}…';
  }
}
