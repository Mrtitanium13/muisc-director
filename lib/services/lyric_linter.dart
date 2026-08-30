// Lyric Linter — attacks the #1 artifact source: the lyrics box.

import '../config/engine_config.dart';

enum LintSeverity { error, warning }

class LintIssue {
  final int line;
  final LintSeverity severity;
  final String code;
  final String message;
  final String? fix;
  const LintIssue({
    required this.line,
    required this.severity,
    required this.code,
    required this.message,
    this.fix,
  });
}

class LyricLinter {
  static const _smallNums = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
    'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
    'seventeen', 'eighteen', 'nineteen',
  ];
  static const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

  static String numberToWords(int n) {
    if (n < 20) return _smallNums[n];
    if (n < 100) {
      final rem = n % 10;
      return _tens[n ~/ 10] + (rem != 0 ? '-${_smallNums[rem]}' : '');
    }
    if (n < 1000) {
      final rem = n % 100;
      return '${_smallNums[n ~/ 100]} hundred${rem != 0 ? ' ${numberToWords(rem)}' : ''}';
    }
    return '$n';
  }

  static String normalizeLyrics(String text) {
    var out = text;

    out = out
        .replaceAll('\u201c', '')
        .replaceAll('\u201d', '')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2026', '');

    EngineConfig.expandSymbols.forEach((sym, word) {
      out = out.replaceAll(sym, ' $word ');
    });

    EngineConfig.expandAbbreviations.forEach((abbr, word) {
      final escaped = RegExp.escape(abbr);
      out = out.replaceAllMapped(
        RegExp(r'\b' + escaped, caseSensitive: false),
        (_) => word,
      );
    });

    out = out.split('\n').map((line) {
      if (line.trimLeft().startsWith('[')) return line;
      return line.replaceAllMapped(
        RegExp(r'\b\d{1,3}\b'),
        (m) => numberToWords(int.parse(m.group(0)!)),
      );
    }).join('\n');

    out = out.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return out;
  }

  static int countSyllables(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return 0;
    if (w.length <= 3) return 1;
    var s = w
        .replaceAll(RegExp(r'(?:[^laeiouy]es|ed|[^laeiouy]e)$'), '')
        .replaceAll(RegExp(r'^y'), '');
    final groups = RegExp(r'[aeiouy]{1,2}').allMatches(s).length;
    return groups > 0 ? groups : 1;
  }

  static int lineSyllables(String line) => line
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .fold(0, (sum, w) => sum + countSyllables(w));

  static int _sibilanceCount(String line) =>
      RegExp(r's|sh|ch|z|ce|ci').allMatches(line.toLowerCase()).length;

  static List<LintIssue> lint(String text, {required int syllableCap}) {
    final issues = <LintIssue>[];
    final lines = text.split('\n');
    final bracketRe = RegExp(r'^\[.+\]$');
    final elongationRe = RegExp(r'([a-z])\1{2,}', caseSensitive: false);

    var consecutiveLyricLines = 0;
    var lastBracketLine = -1;
    var lastBracketWasEmpty = false;
    var sawEndTag = false;
    var sawAnyBracket = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (bracketRe.hasMatch(line)) {
        sawAnyBracket = true;
        consecutiveLyricLines = 0;

        if (line.toLowerCase() == '[end]') sawEndTag = true;

        if (lastBracketWasEmpty && lastBracketLine >= 0) {
          final prev = lines[lastBracketLine].trim().toLowerCase();
          final exempt = prev == '[intro]' ||
              prev == '[outro]' ||
              prev == '[end]' ||
              prev.contains('instrumental');
          if (!exempt) {
            issues.add(LintIssue(
              line: lastBracketLine,
              severity: LintSeverity.warning,
              code: 'EMPTY_SECTION',
              message:
                  "Empty section causes hallucinated ad-libs ('yeah', 'oh'). Add lyrics or change to [Instrumental Break].",
              fix: '[Instrumental Break]',
            ));
          }
        }

        final modMatch = RegExp(r'^\[[^\-\]]+-\s*(.+)\]$').firstMatch(line);
        if (modMatch != null) {
          final wordCount = modMatch.group(1)!.trim().split(RegExp(r'\s+')).length;
          if (wordCount > EngineConfig.maxModifierWords) {
            issues.add(LintIssue(
              line: i,
              severity: LintSeverity.warning,
              code: 'VERBOSE_BRACKET',
              message:
                  'Bracket modifiers over ${EngineConfig.maxModifierWords} words risk being sung as lyrics. Shorten it.',
            ));
          }
        }

        lastBracketLine = i;
        lastBracketWasEmpty = true;
        continue;
      }

      if (line.isEmpty) continue;
      lastBracketWasEmpty = false;

      if (!sawAnyBracket) {
        issues.add(LintIssue(
          line: i,
          severity: LintSeverity.error,
          code: 'ORPHAN_LINE',
          message:
              'Lyrics before the first bracket get sung unpredictably. Add a section tag above this line.',
        ));
      }

      final syl = lineSyllables(line);
      if (syl > syllableCap) {
        issues.add(LintIssue(
          line: i,
          severity: LintSeverity.warning,
          code: 'SYLLABLE_OVERFLOW',
          message:
              '$syl syllables (cap: $syllableCap at this tempo). Overpacked lines cause rushed, garbled delivery. Split this line.',
        ));
      }

      consecutiveLyricLines++;
      if (consecutiveLyricLines == EngineConfig.maxConsecutiveLinesWithoutBreak + 1) {
        issues.add(LintIssue(
          line: i,
          severity: LintSeverity.warning,
          code: 'LONG_RUN',
          message:
              'More than ${EngineConfig.maxConsecutiveLinesWithoutBreak} lines without a section break degrades delivery. Insert a bracket or blank line.',
        ));
      }

      for (final h in EngineConfig.homographs) {
        if (RegExp(r'\b' + h + r'\b', caseSensitive: false).hasMatch(line)) {
          issues.add(LintIssue(
            line: i,
            severity: LintSeverity.warning,
            code: 'HOMOGRAPH',
            message: "'$h': ${EngineConfig.homographMessage}",
          ));
        }
      }

      if (_sibilanceCount(line) >= EngineConfig.sibilanceThreshold) {
        issues.add(LintIssue(
          line: i,
          severity: LintSeverity.warning,
          code: 'SIBILANCE',
          message: EngineConfig.sibilanceMessage,
        ));
      }

      if (elongationRe.hasMatch(line)) {
        issues.add(LintIssue(
          line: i,
          severity: LintSeverity.warning,
          code: 'ELONGATION',
          message: EngineConfig.elongationMessage,
          fix: line.replaceAllMapped(elongationRe, (m) => m.group(1)!),
        ));
      }

      for (final m in RegExp(r'\(([^)]+)\)').allMatches(line)) {
        final words = m.group(1)!.trim().split(RegExp(r'\s+')).length;
        if (words > EngineConfig.maxWordsInParentheticals) {
          issues.add(LintIssue(
            line: i,
            severity: LintSeverity.warning,
            code: 'LONG_PARENTHETICAL',
            message:
                'Keep background-vocal parentheticals to ${EngineConfig.maxWordsInParentheticals} words or fewer.',
          ));
        }
      }
    }

    if (!sawEndTag) {
      issues.add(LintIssue(
        line: lines.isEmpty ? 0 : lines.length - 1,
        severity: LintSeverity.error,
        code: 'MISSING_END',
        message:
            'No [End] tag. Without it, outros commonly degrade into garbled runaway audio. Auto-appending is recommended.',
        fix: '[End]',
      ));
    }

    return issues;
  }

  static String autoFix(String text) {
    var out = normalizeLyrics(text);
    if (!RegExp(r'\[end\]\s*$', caseSensitive: false).hasMatch(out.trimRight())) {
      out = '${out.trimRight()}\n\n[End]';
    }
    return out;
  }
}
