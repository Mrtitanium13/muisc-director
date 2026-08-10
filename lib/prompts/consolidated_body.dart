import 'dart:io';

import 'package:muisc_director/prompts/section_ids.dart';

/// Loads a prompt section from the bundled `prompts/sections/` directory.
String loadSectionContent(PromptSection section, {String? basePath}) {
  final root = basePath ?? _resolvePromptsRoot();
  final file = File('$root/sections/${section.fileName}');
  if (!file.existsSync()) {
    throw StateError('Section file not found: ${file.path}');
  }
  return file.readAsStringSync().trim();
}

String _resolvePromptsRoot() {
  final candidates = [
    'prompts',
    '../prompts',
    '../../prompts',
  ];
  for (final candidate in candidates) {
    final dir = Directory(candidate);
    if (dir.existsSync()) return candidate;
  }
  throw StateError('Could not locate prompts/ directory');
}

/// Returns Section 1F content (DJ Mix-In / Mix-Out rules).
String section1FContent({String? basePath}) =>
    loadSectionContent(PromptSection.section1F, basePath: basePath);

/// Assembles the full consolidated system prompt body from all sections.
String buildConsolidatedBody({String? basePath}) {
  final parts = <String>[];
  for (final section in allSections) {
    parts.add(loadSectionContent(section, basePath: basePath));
  }
  return parts.join('\n\n');
}

/// Standalone Section 1F module with minimal framing for DJ-mix-only use.
String buildSection1FStandalone({String? basePath}) {
  final content = section1FContent(basePath: basePath);
  return '''
DJ MIX BOOKEND MODULE (Section 1F — Standalone)

Apply these rules to every Suno track generation. This module is self-contained;
when used alone, treat it as the authoritative instruction for intro/outro structure.

$content
'''.trim();
}
