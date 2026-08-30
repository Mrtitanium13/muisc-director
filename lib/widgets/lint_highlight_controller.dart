// Custom TextEditingController with line-level lint highlighting.

import 'package:flutter/material.dart';

import '../services/lyric_linter.dart';

class LintHighlightController extends TextEditingController {
  List<LintIssue> issues = [];

  LintHighlightController({super.text});

  void updateIssues(List<LintIssue> newIssues) {
    issues = newIssues;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');

    final severityByLine = <int, LintSeverity>{};
    for (final issue in issues) {
      final existing = severityByLine[issue.line];
      if (existing == null || issue.severity == LintSeverity.error) {
        severityByLine[issue.line] = issue.severity;
      }
    }

    final children = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final sev = severityByLine[i];
      final lineStyle = switch (sev) {
        LintSeverity.error => (style ?? const TextStyle()).copyWith(
            backgroundColor: Colors.red.withValues(alpha: 0.22),
            decoration: TextDecoration.underline,
            decorationColor: Colors.redAccent,
            decorationStyle: TextDecorationStyle.wavy,
          ),
        LintSeverity.warning => (style ?? const TextStyle()).copyWith(
            backgroundColor: Colors.amber.withValues(alpha: 0.18),
          ),
        null => style,
      };
      children.add(TextSpan(
        text: i < lines.length - 1 ? '${lines[i]}\n' : lines[i],
        style: lineStyle,
      ));
    }

    return TextSpan(style: style, children: children);
  }
}
