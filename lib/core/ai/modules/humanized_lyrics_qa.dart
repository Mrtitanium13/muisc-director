import 'package:flutter/foundation.dart';

import 'genre_lyrics_emission.dart';
import 'k_genre_cliche_blacklist.dart';
import 'meaningfulness_check.dart';

/// Severity tier for a matched cliché pack.
enum ClicheSeverity {
  /// Always triggers regeneration.
  tier1,

  /// Warns on first generation, fails on retry.
  tier2,

  /// Advisory only unless [HumanizedLyricsQa.enforceHumanizedLyrics]
  /// `regenerateOnClicheHits` is enabled — or no hit.
  none,
}

/// Session counter for T2 cliché warn-then-fail policy.
class HumanizedLyricsSession {
  HumanizedLyricsSession._();

  static final Map<String, int> _counts = {};

  static int generationCount(String genre) => _counts[_key(genre)] ?? 0;

  static void recordGeneration(String genre) {
    final key = _key(genre);
    _counts[key] = (_counts[key] ?? 0) + 1;
  }

  @visibleForTesting
  static void reset() => _counts.clear();

  static String _key(String genre) => normalizeClicheGenre(genre);
}

class HumanizedLyricsQaResult {
  const HumanizedLyricsQaResult({
    required this.issues,
    required this.meaningfulnessScore,
    required this.clicheHits,
    required this.severity,
    required this.shouldRegenerate,
  });

  final List<String> issues;
  final double meaningfulnessScore;
  final List<String> clicheHits;
  final ClicheSeverity severity;
  final bool shouldRegenerate;

  bool get hasClicheHits => clicheHits.isNotEmpty;
  bool get hasMeaningfulnessIssue =>
      meaningfulnessScore < HumanizedLyricsQa.meaningfulnessThreshold;
}

/// Resolved cliché pack for a genre (cached).
class _ResolvedClichePack {
  final List<String> phrases;
  final String? key;
  final ClicheSeverity severity;

  const _ResolvedClichePack({
    required this.phrases,
    required this.key,
    required this.severity,
  });

  static const empty = _ResolvedClichePack(
    phrases: [],
    key: null,
    severity: ClicheSeverity.none,
  );
}

/// Unified humanized-lyric QA gate (meaningfulness + per-genre cliché packs).
class HumanizedLyricsQa {
  HumanizedLyricsQa._();

  static const double meaningfulnessThreshold = 0.6;

  static final Map<String, _ResolvedClichePack> _packCache = {};

  static HumanizedLyricsQaResult enforceHumanizedLyrics(
    String lyrics,
    String genre, {
    bool recordSession = true,

    /// When true, any cliché hit triggers [shouldRegenerate]
    /// — not only T1 / repeat T2 failures.
    bool regenerateOnClicheHits = false,
  }) {
    final normalizedGenre = _normalizeGenre(genre);

    if (!GenreLyricsEmission.emitsLyrics(normalizedGenre)) {
      return const HumanizedLyricsQaResult(
        issues: [],
        meaningfulnessScore: 1.0,
        clicheHits: [],
        severity: ClicheSeverity.none,
        shouldRegenerate: false,
      );
    }

    final issues = <String>[];
    var shouldRegenerate = false;
    final lowerLyrics = lyrics.toLowerCase();

    final meaningfulness = MeaningfulnessCheck();
    final mScore = meaningfulness.score(lyrics);
    final stockHits = meaningfulness.stockPhraseHits(lyrics);
    if (stockHits.isNotEmpty) {
      issues.add(
        'Lyric uses banned stock formulas (rewrite fresh for THIS brief): '
        '${stockHits.join(', ')}',
      );
      shouldRegenerate = true;
      _debug(
        'Stock phrase hits: ${stockHits.join(', ')} '
        '(genre: $normalizedGenre)',
      );
    }
    if (mScore < meaningfulnessThreshold) {
      issues.add(
        'Lyric meaningfulness score too low '
        '(${mScore.toStringAsFixed(2)} < $meaningfulnessThreshold)',
      );
      shouldRegenerate = true;
      _debug(
        'Meaningfulness score too low: ${mScore.toStringAsFixed(2)} '
        '(genre: $normalizedGenre)',
      );
    }

    final clicheResult = _scanClicheHits(lowerLyrics, normalizedGenre);
    if (clicheResult.hits.isNotEmpty) {
      issues.add(
        'Lyric contains genre-cliché phrases: ${clicheResult.hits.join(', ')}',
      );
      if (clicheResult.isFailure || regenerateOnClicheHits) {
        shouldRegenerate = true;
      }
      _debug(
        'Cliché hits (${clicheResult.packKey}): '
        '${clicheResult.hits.join(', ')}',
      );
    }

    if (recordSession) {
      HumanizedLyricsSession.recordGeneration(normalizedGenre);
    }

    return HumanizedLyricsQaResult(
      issues: issues,
      meaningfulnessScore: mScore,
      clicheHits: clicheResult.hits,
      severity: clicheResult.severity,
      shouldRegenerate: shouldRegenerate,
    );
  }

  /// Scans already-lowercased lyrics for cliché phrases.
  static ({
    List<String> hits,
    String? packKey,
    ClicheSeverity severity,
    bool isFailure,
  }) _scanClicheHits(String lowerLyrics, String normalizedGenre) {
    final pack = _resolvePack(normalizedGenre);
    if (pack.key == null || pack.phrases.isEmpty) {
      return (
        hits: const <String>[],
        packKey: null,
        severity: ClicheSeverity.none,
        isFailure: false,
      );
    }

    final hits = <String>[
      for (final phrase in pack.phrases)
        if (MeaningfulnessCheck.containsLyricPhrase(lowerLyrics, phrase))
          phrase,
    ];

    if (hits.isEmpty) {
      return (
        hits: hits,
        packKey: pack.key,
        severity: ClicheSeverity.none,
        isFailure: false,
      );
    }

    final isFailure = switch (pack.severity) {
      ClicheSeverity.tier1 => true,
      ClicheSeverity.tier2 =>
        HumanizedLyricsSession.generationCount(normalizedGenre) >= 1,
      ClicheSeverity.none => false,
    };

    return (
      hits: hits,
      packKey: pack.key,
      severity: pack.severity,
      isFailure: isFailure,
    );
  }

  /// Cached cliché pack resolver (phrases stored lowercased).
  static _ResolvedClichePack _resolvePack(String normalizedGenre) {
    return _packCache.putIfAbsent(normalizedGenre, () {
      final pack = resolveClichePack(normalizedGenre);
      if (pack == null || pack.phrases.isEmpty) {
        return _ResolvedClichePack.empty;
      }

      final phrases = pack.phrases
          .map((p) => p.trim().toLowerCase())
          .where((p) => p.isNotEmpty)
          .toList(growable: false);

      final severity = switch (pack.tier) {
        ClichePackTier.tier1 => ClicheSeverity.tier1,
        ClichePackTier.tier2 => ClicheSeverity.tier2,
      };

      return _ResolvedClichePack(
        phrases: phrases,
        key: pack.key,
        severity: severity,
      );
    });
  }

  /// Public cliche scan (for tests / diagnostics).
  static ({
    List<String> hits,
    String? packKey,
    ClicheSeverity severity,
    bool isFailure,
  }) scanClicheHits(String lyrics, String genre) {
    final normalizedGenre = _normalizeGenre(genre);
    return _scanClicheHits(lyrics.toLowerCase(), normalizedGenre);
  }

  /// Appended to the user block on a single lyric-quality retry pass.
  static String buildRegenerateSuffix(HumanizedLyricsQaResult result) {
    final buffer = StringBuffer()
      ..writeln(
        'LYRIC QUALITY RETRY — Output the full two-block reply again. '
        'Prior Block 2 failed humanized lyric QA:',
      );

    for (final issue in result.issues) {
      buffer.writeln('- $issue');
    }

    buffer
      ..writeln(
        '- Invent theme-motivated details only — no checklist bingo '
        '(clock-time + random city + kitchen props + filler "Mama said"). '
        'Prefer everyday human speech over literary body metaphor.',
      )
      ..writeln(
        '- Swap abstract / stock phrasing for concrete anchors that fit THIS '
        'vibe/theme/genre/region.',
      )
      ..writeln(
        '- Hook must be singable; verses conversational — no genre-cliché filler.',
      )
      ..writeln(
        '- Preserve Block 1 production intent; rewrite Block 2 performable lyrics.',
      )
      ..writeln('- Keep bracket scaffolding, [End], and Suno v5 syntax laws.');

    return buffer.toString().trim();
  }

  /// Picks the stronger lyric QA outcome after an auto-regenerate attempt.
  static bool isBetterResult(
    HumanizedLyricsQaResult candidate,
    HumanizedLyricsQaResult incumbent,
  ) {
    if (candidate.shouldRegenerate != incumbent.shouldRegenerate) {
      return !candidate.shouldRegenerate;
    }
    // Severity outranks hit count: one T1 hit is worse than two T2 hits.
    // Enum order is tier1(0) < tier2(1) < none(2), so higher index = milder.
    if (candidate.severity.index != incumbent.severity.index) {
      return candidate.severity.index > incumbent.severity.index;
    }
    if (candidate.clicheHits.length != incumbent.clicheHits.length) {
      return candidate.clicheHits.length < incumbent.clicheHits.length;
    }
    return candidate.meaningfulnessScore > incumbent.meaningfulnessScore;
  }

  static String _normalizeGenre(String genre) => genre.toLowerCase().trim();

  static void _debug(String message) {
    if (kDebugMode) {
      debugPrint('[HumanizedLyricsQa] $message');
    }
  }
}
