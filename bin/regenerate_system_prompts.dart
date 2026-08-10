#!/usr/bin/env dart
// Regenerates merged system prompt files from section modules.

import 'dart:io';

import 'package:muisc_director/prompts/consolidated_body.dart';

void main() {
  final repoRoot = _findRepoRoot();
  final outputDir = Directory('$repoRoot/prompts/generated');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final consolidated = buildConsolidatedBody(basePath: '$repoRoot/prompts');
  final standalone1F = buildSection1FStandalone(basePath: '$repoRoot/prompts');

  File('$repoRoot/prompts/generated/system_prompt_full.txt')
      .writeAsStringSync('$consolidated\n');
  File('$repoRoot/prompts/generated/system_prompt_1f_standalone.txt')
      .writeAsStringSync('$standalone1F\n');

  stdout.writeln('Generated: prompts/generated/system_prompt_full.txt');
  stdout.writeln('Generated: prompts/generated/system_prompt_1f_standalone.txt');
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find repo root (pubspec.yaml)');
    }
    dir = parent;
  }
}
