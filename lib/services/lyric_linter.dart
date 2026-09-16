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
    String belowThousand(int value) {
      if (value < 20) return _smallNums[value];
      if (value < 100) {
        final rem = value % 10;
        return _tens[value ~/ 10] + (rem != 0 ? '-${_smallNums[rem]}' : '');
      }
      final rem = value % 100;
      return '${_smallNums[value ~/ 100]} hundred'
          '${rem != 0 ? ' ${belowThousand(rem)}' : ''}';
    }

    const scales = [
      '',
      'thousand',
      'million',
      'billion',
      'trillion',
      'quadrillion',
      'quintillion',
    ];

    final raw = n.toString();
    final negative = raw.startsWith('-');
    final digits = negative ? raw.substring(1) : raw;
    final parts = <String>[];
    var end = digits.length;
    var scale = 0;
    while (end > 0) {
      final start = end > 3 ? end - 3 : 0;
      final value = int.parse(digits.substring(start, end));
      if (value != 0) {
        final suffix = scales[scale];
        parts.insert(
          0,
          '${belowThousand(value)}${suffix.isEmpty ? '' : ' $suffix'}',
        );
      }
      end = start;
      scale++;
    }
    final words = parts.isEmpty ? 'zero' : parts.join(' ');
    return negative ? 'minus $words' : words;
  }

  static String normalizeLyrics(String text) {
    String normalizeText(String value) {
      var out = value
          .replaceAll('\u201c', '"')
          .replaceAll('\u201d', '"')
          .replaceAll('\u2018', "'")
          .replaceAll('\u2019', "'")
          .replaceAll('\u2014', '-')
          .replaceAll('\u2013', '-')
          .replaceAll('\u2026', '...');

      EngineConfig.expandSymbols.forEach((sym, word) {
        out = out.replaceAll(sym, ' $word ');
      });

      EngineConfig.expandAbbreviations.forEach((abbr, word) {
        final escaped = RegExp.escape(abbr);
        out = out.replaceAllMapped(
          RegExp(
            r'(?<![\p{L}\p{M}\p{N}_])' + escaped + r'(?![\p{L}\p{M}\p{N}_])',
            caseSensitive: false,
            unicode: true,
          ),
          (_) => word,
        );
      });

      // Skip decimals, times, and grouped numbers so "3.14" or "1,000"
      // are not corrupted into "three.fourteen" / "one,zero zero zero".
      out = out.replaceAllMapped(
        RegExp(
          r'(?<![\p{L}\p{M}\p{N}_.,:/+\-])'
          r'-?\d+'
          r'(?![\p{L}\p{M}\p{N}_:/]|[.,]\d)',
          unicode: true,
        ),
        (m) {
          final value = int.tryParse(m.group(0)!);
          return value == null ? m.group(0)! : numberToWords(value);
        },
      );

      return out.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    }

    // Bracketed staging tags are protected: their contents pass through
    // verbatim (bar counts, modifiers) — only sung text is normalized.
    final bracketRe = RegExp(r'\[[^\]\r\n]*\]');
    return text.split('\n').map((line) {
      final buffer = StringBuffer();
      var cursor = 0;
      for (final match in bracketRe.allMatches(line)) {
        buffer.write(normalizeText(line.substring(cursor, match.start)));
        buffer.write(match.group(0)!);
        cursor = match.end;
      }
      buffer.write(normalizeText(line.substring(cursor)));
      return buffer.toString();
    }).join('\n');
  }

  static int countSyllables(String word) {
    final tokens = word.toLowerCase().split(RegExp(r'[-‐-—]'));
    var total = 0;
    for (final token in tokens) {
      final w = token.replaceAll(RegExp(r'[^a-z]'), '');
      if (w.isEmpty) continue;
      if (w.length <= 3) {
        total++;
        continue;
      }
      var count = RegExp(r'[aeiouy]+').allMatches(w).length;
      if (w.startsWith('y') && RegExp(r'^y[aeiou]').hasMatch(w)) count--;
      if (w.endsWith('ed')) {
        if (!RegExp(r'[td]ed$').hasMatch(w) &&
            RegExp(r'[^aeiouy]ed$').hasMatch(w)) {
          count--;
        }
      } else if (w.endsWith('es')) {
        if (!RegExp(r'(?:[sxz]|[cs]h|[cg]|[^aeiouy]l)es$').hasMatch(w)) {
          count--;
        }
      } else if (w.endsWith('e') &&
          !RegExp(r'[^aeiouy]le$').hasMatch(w) &&
          !RegExp(r'[aeiouy]e$').hasMatch(w)) {
        count--;
      }
      total += count > 0 ? count : 1;
    }
    return total;
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
    final sectionRe = RegExp(
      r'^\[(?:intro|outro|verse|(?:pre[- ]?|post[- ]?)chorus|'
      r'chorus|bridge|hook|refrain|breakdown|break|interlude|'
      r'instrumental|solo|drop|build(?:[- ]?up)?|end)\b',
      caseSensitive: false,
    );
    final elongationRe = RegExp(r'([a-z])\1{2,}', caseSensitive: false);

    var consecutiveLyricLines = 0;
    var lastBracketLine = -1;
    var lastBracketWasEmpty = false;
    var sawEndTag = false;
    var sawAnyBracket = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (bracketRe.hasMatch(line)) {
        if (line.toLowerCase() == '[end]') sawEndTag = true;

        // Only true section headers open/close lyric sections — staging and
        // performance tags ([warm whisper], [crowd chant]) must not.
        if (sectionRe.hasMatch(line)) {
          sawAnyBracket = true;
          consecutiveLyricLines = 0;

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

          lastBracketLine = i;
          lastBracketWasEmpty = true;
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

        continue;
      }

      if (line.isEmpty) {
        // A blank line satisfies the LONG_RUN "insert a break" guidance.
        consecutiveLyricLines = 0;
        continue;
      }
      lastBracketWasEmpty = false;
      // Lyrics after [End] are unreachable — re-arm the missing-end check.
      sawEndTag = false;

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
