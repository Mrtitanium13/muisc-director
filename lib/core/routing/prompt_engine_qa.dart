import 'package:flutter/foundation.dart';

import '../ai/modules/humanized_lyrics_qa.dart';
import '../utils/suno_output_split.dart';
import 'genre_scaffold_map.dart';
import 'stage2_model_router.dart';

/// Post-generation QA — mirrors kStagingAndAccentRules Section D (subset).
class PromptEngineQa {
  PromptEngineQa._();

  static const bannedWords = [
    'immersive',
    'captivating',
    'mesmerizing',
    'tapestry',
    'mosaic',
    'seamless',
    'ethereal',
    'haunting',
    'lush',
    'vibrant',
    'plush',
    'transcendent',
    'otherworldly',
    'rich',
    'dynamic',
    'intricate',
  ];

  /// Section D subset for compact Suno natural-language style_prompt contract.
  static const stylePromptBannedWords = [
    'immersive',
    'captivating',
    'ethereal',
    'haunting',
    'tapestry',
    'lush',
    'seamless',
    'mesmerizing',
    'intricate',
    'transcendent',
  ];

  static const stylePromptSoftLimit = 200;
  static const stylePromptHardLimit = 240;

  /// Whole-word match — "rich" must not flag "Richard", "lush" not "plush".
  static List<String> _bannedWordHits(String text, List<String> words) =>
      words.where((word) {
        final pattern = RegExp(
          r'(?<![\p{L}\p{M}\p{N}_])' +
              RegExp.escape(word) +
              r'(?![\p{L}\p{M}\p{N}_])',
          caseSensitive: false,
          unicode: true,
        );
        return pattern.hasMatch(text);
      }).toList();

  static List<String> blacklistScan(String text) =>
      _bannedWordHits(text, bannedWords);

  static List<String> blacklistViolation(String stylePrompt) =>
      _bannedWordHits(stylePrompt, stylePromptBannedWords);

  static List<String> qaCheckStylePromptContract(String stylePrompt) {
    final issues = <String>[];
    final violations = blacklistViolation(stylePrompt);
    if (violations.isNotEmpty) {
      issues.add(
        'style_prompt blacklist violation: ${violations.join(", ")}',
      );
      logStylePromptQaIssues(stylePrompt, violations: violations);
    }
    if (stylePrompt.length > stylePromptHardLimit) {
      issues.add(
        'style_prompt exceeds $stylePromptHardLimit-char hard limit '
        '(${stylePrompt.length})',
      );
    } else if (stylePrompt.length > stylePromptSoftLimit) {
      issues.add(
        'style_prompt exceeds $stylePromptSoftLimit-char soft limit '
        '(${stylePrompt.length})',
      );
    }
    if (_looksLikeLegacyCommaTagList(stylePrompt)) {
      issues.add(
        'style_prompt appears to be legacy comma-tag list — use natural-language tags',
      );
    }
    return issues;
  }

  /// Debug/production guard — call after [qaCheckStylePromptContract].
  static void assertStylePromptHardLimit(String stylePrompt) {
    assert(
      stylePrompt.length <= stylePromptHardLimit,
      'style_prompt exceeds 240-char hard limit',
    );
  }

  static List<String> qaCheckStylePromptFromSunoOutput(String raw) {
    final style = parseSunoOutput(raw).styleBody?.trim() ?? '';
    if (style.isEmpty) return const [];
    // Compact legacy style field (≤240 chars) — full Block 1 prose uses word caps elsewhere.
    if (style.length > stylePromptHardLimit) {
      final hits = blacklistScan(style);
      if (hits.isEmpty) return const [];
      return ['Block 1 contains banned words: ${hits.join(", ")}'];
    }
    return qaCheckStylePromptContract(style);
  }

  static bool _looksLikeLegacyCommaTagList(String stylePrompt) {
    final parts = stylePrompt
        .trim()
        .split(',')
        .map((part) => part.trim())
        .toList(growable: false);
    if (parts.length < 4 || parts.any((part) => part.isEmpty)) return false;
    // A natural-language prompt has multi-word phrases; a legacy tag list is
    // all single-word tags (spaces after commas must not bypass detection).
    return parts.every((part) => !RegExp(r'\s').hasMatch(part));
  }

  static List<String> qaCheckSunoOutput(String text) {
    final issues = <String>[];
    final hits = blacklistScan(text);
    if (hits.isNotEmpty) {
      issues.add('output contains banned words: ${hits.join(", ")}');
    }
    if (!RegExp(r'\[[A-Za-z][^\]]+\]').hasMatch(text)) {
      issues.add('output contains no bracketed structural markers');
    }
    return issues;
  }

  /// Post-polish humanized lyric QA (meaningfulness + genre cliché packs).
  static List<String> qaCheckHumanizedLyrics(
    String lyrics,
    String genre,
  ) {
    final result = HumanizedLyricsQa.enforceHumanizedLyrics(lyrics, genre);
    return result.issues;
  }

  static void logStylePromptQaIssues(
    String stylePrompt, {
    List<String>? violations,
  }) {
    final v = violations ?? blacklistViolation(stylePrompt);
    if (v.isEmpty) return;
    debugPrint(
      '[PromptEngineQa] Blacklist violation in style_prompt: ${v.join(", ")}',
    );
  }
}

/// Ibibio lyric QA — post-polish marker retention checks.
class IbibioLyricQa {
  IbibioLyricQa._();

  static const markerTokens = [
    'abasi',
    'esie',
    'kpa',
    'edinen',
    'mmo',
    'idaha',
    'nno',
  ];

  static const lagosBanned = Stage2ModelRouter.lagosPidginBannedInIbibio;

  static int markerCount(String lyrics) {
    final lower = lyrics.toLowerCase();
    var count = 0;
    for (final m in markerTokens) {
      if (lower.contains(m)) count++;
    }
    return count;
  }

  static List<String> lagosHits(String lyrics) {
    final lower = lyrics.toLowerCase();
    return lagosBanned.where(lower.contains).toList();
  }

  static bool passesPostPolishQa(String lyrics) =>
      markerCount(lyrics) >= 3 && lagosHits(lyrics).isEmpty;
}

/// Rule A6 intro/outro bar consistency checks (post-generation soft QA).
class IntroOutroScaffoldQa {
  IntroOutroScaffoldQa._();

  static List<String> checkIntroOutroConsistency(
    String lyrics, {
    required String dominantGenre,
    String? vibeHint,
  }) {
    final issues = <String>[];
    final lower = lyrics.toLowerCase();
    final spec = GenreScaffoldMap.specFor(dominantGenre, vibeHint: vibeHint);

    switch (spec.type) {
      case ScaffoldType.clubExtended:
        if (!lower.contains('${spec.introBars} bars') &&
            !lower.contains('32 bars')) {
          issues.add(
            'club-extended genre "$dominantGenre" missing '
            '${spec.introBars}-bar DJ intro marker',
          );
          _logWarning(
            'club-extended genre "$dominantGenre" missing '
            '${spec.introBars}-bar DJ intro marker',
          );
        }
        break;
      case ScaffoldType.radioShort:
        if (lower.contains('32 bars') || lower.contains('24 bars')) {
          issues.add(
            'radio-short genre "$dominantGenre" has club bar marker — '
            'template contamination',
          );
          _logWarning(
            'radio-short genre "$dominantGenre" has club bar marker — '
            'template contamination',
          );
        }
        break;
      case ScaffoldType.ambientLong:
        if (!RegExp(r'(16|24|32) bars').hasMatch(lower)) {
          issues.add(
            'ambient-long genre "$dominantGenre" missing extended-bar marker',
          );
          _logWarning(
            'ambient-long genre "$dominantGenre" missing extended-bar marker',
          );
        }
        break;
      default:
        if (!RegExp(r'\d+ bars').hasMatch(lower)) {
          issues.add('no explicit bar-count marker found in lyrics');
          _logWarning('no explicit bar-count marker found in lyrics');
        }
    }
    return issues;
  }

  static void _logWarning(String message) {
    debugPrint('[IntroOutroScaffoldQa] WARNING: $message');
  }
}
