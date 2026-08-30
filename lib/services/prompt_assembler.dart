// Prompt Assembler — builds the style prompt + exclude-styles string.

import '../config/engine_config.dart';

class AssemblerInput {
  final String modelVersion;
  final List<String> genres;
  final String tempo;
  final String vocal;
  final String? mood;
  final List<String> customTokens;

  const AssemblerInput({
    required this.modelVersion,
    required this.genres,
    required this.tempo,
    required this.vocal,
    this.mood,
    this.customTokens = const [],
  });

  AssemblerInput copyWith({
    String? modelVersion,
    List<String>? genres,
    String? tempo,
    String? vocal,
    String? Function()? mood,
    List<String>? customTokens,
  }) =>
      AssemblerInput(
        modelVersion: modelVersion ?? this.modelVersion,
        genres: genres ?? this.genres,
        tempo: tempo ?? this.tempo,
        vocal: vocal ?? this.vocal,
        mood: mood != null ? mood() : this.mood,
        customTokens: customTokens ?? this.customTokens,
      );

  Map<String, dynamic> toJson() => {
        'modelVersion': modelVersion,
        'genres': genres,
        'tempo': tempo,
        'vocal': vocal,
        'mood': mood,
        'customTokens': customTokens,
      };

  factory AssemblerInput.fromJson(Map<String, dynamic> j) => AssemblerInput(
        modelVersion: j['modelVersion'] as String,
        genres: List<String>.from(j['genres'] as List),
        tempo: j['tempo'] as String,
        vocal: j['vocal'] as String,
        mood: j['mood'] as String?,
        customTokens: List<String>.from(j['customTokens'] as List? ?? []),
      );
}

class AssemblerOutput {
  final String stylePrompt;
  final String excludeStyles;
  final int tokenCount;
  final int budgetMin;
  final int budgetMax;
  final List<String> warnings;
  final List<String> droppedTokens;
  final bool isInstrumental;
  final int syllableCap;

  const AssemblerOutput({
    required this.stylePrompt,
    required this.excludeStyles,
    required this.tokenCount,
    required this.budgetMin,
    required this.budgetMax,
    required this.warnings,
    required this.droppedTokens,
    required this.isInstrumental,
    required this.syllableCap,
  });
}

class _TaggedToken {
  final String group;
  final String token;
  const _TaggedToken(this.group, this.token);
}

class PromptAssembler {
  static String? cleanToken(String token, List<String> warnings) {
    final lower = token.toLowerCase().trim();

    for (final safe in EngineConfig.whitelistPhrases) {
      if (lower.contains(safe)) return token;
    }
    for (final banned in EngineConfig.hardBanned) {
      if (lower.contains(banned)) {
        warnings.add("Removed hard-banned token: '$token'");
        return null;
      }
    }
    final entries = EngineConfig.replacementMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final e in entries) {
      final re = RegExp(r'\b' + RegExp.escape(e.key) + r'\b', caseSensitive: false);
      if (re.hasMatch(token)) {
        final replaced = token.replaceAll(re, e.value);
        warnings.add("Replaced artifact-prone token with: '$replaced'");
        return replaced;
      }
    }
    return token;
  }

  static List<_TaggedToken> _dedupeByStem(
      List<_TaggedToken> tokens, List<String> dropped) {
    final seen = <String>{};
    final kept = <_TaggedToken>[];

    for (final t in tokens) {
      final words = t.token.toLowerCase().split(RegExp(r'\s+'));
      String? repeatedStem;
      for (final w in words) {
        if (EngineConfig.dedupeStems.contains(w) && seen.contains(w)) {
          repeatedStem = w;
          break;
        }
      }
      if (repeatedStem != null) {
        final trimmed = t.token
            .split(RegExp(r'\s+'))
            .where((w) => w.toLowerCase() != repeatedStem)
            .join(' ')
            .trim();
        if (trimmed.isNotEmpty && trimmed != t.token) {
          kept.add(_TaggedToken(t.group, trimmed));
        } else {
          dropped.add(t.token);
        }
        continue;
      }
      for (final w in words) {
        if (EngineConfig.dedupeStems.contains(w)) seen.add(w);
      }
      kept.add(t);
    }
    return kept;
  }

  /// Renders final tokens according to the model's preferred prompt mode.
  static String _renderPrompt(List<_TaggedToken> tagged, PromptMode mode) {
    if (mode == PromptMode.tagList) {
      return tagged.map((t) => t.token).join(', ');
    }

    String pick(String group) => tagged
        .where((t) => t.group == group)
        .map((t) => t.token)
        .join(', ');

    final genre = pick('genre');
    final tempo = pick('tempo');
    final vocal = pick('vocal');
    final mood = pick('mood');
    final custom = pick('custom');
    final fidelity = pick('fidelity');

    final parts = <String>[
      if (genre.isNotEmpty) 'A $genre track',
      if (mood.isNotEmpty) 'with a $mood feel',
      if (tempo.isNotEmpty) 'at $tempo',
      if (vocal.isNotEmpty) 'featuring $vocal',
      if (custom.isNotEmpty) custom,
      if (fidelity.isNotEmpty) '$fidelity production',
    ];
    return '${parts.join(', ')}.';
  }

  static bool _hasHumanizingToken(List<String> customTokens) {
    for (final token in customTokens) {
      final lower = token.toLowerCase();
      for (final h in EngineConfig.humanizingTokens) {
        if (lower.contains(h.toLowerCase())) return true;
      }
    }
    return false;
  }

  static AssemblerOutput assemble(AssemblerInput input) {
    final warnings = <String>[];
    final dropped = <String>[];
    final profile = EngineConfig.modelProfiles[input.modelVersion]!;
    final maxGenres = EngineConfig.maxGenresByModel[input.modelVersion] ??
        EngineConfig.maxGenreTokens;

    var genres = input.genres.take(maxGenres).toList();
    if (input.genres.length > maxGenres) {
      warnings.add('Max $maxGenres genres. Extras dropped.');
    }
    if (genres.length >= 2) {
      final pair = [...genres]..sort();
      final risky = EngineConfig.riskyPairs.any((p) {
        final sorted = [...p]..sort();
        return sorted[0] == pair[0] && sorted[1] == pair[1];
      });
      if (risky) warnings.add(EngineConfig.riskyFusionWarning);
    }

    final tempoDef = EngineConfig.tempoEnergy[input.tempo]!;
    if (!tempoDef.compatibleGenres.contains('all')) {
      for (final g in genres) {
        if (!tempoDef.compatibleGenres.contains(g)) {
          warnings.add(
              "Tempo '${input.tempo}' is unusual for '$g' — mismatches force low-confidence generation.");
        }
      }
    }

    final vocalDef = EngineConfig.vocalProfiles[input.vocal]!;
    final isInstrumental = vocalDef.usePlatformToggle;

    var tagged = <_TaggedToken>[
      for (final g in genres)
        for (final t in EngineConfig.genreFamilies[g]!.tokens) _TaggedToken('genre', t),
      for (final t in EngineConfig.fidelityTags) _TaggedToken('fidelity', t),
      for (final t in tempoDef.tokens) _TaggedToken('tempo', t),
      if (!isInstrumental)
        for (final t in vocalDef.tokens) _TaggedToken('vocal', t),
      if (input.mood != null && input.mood!.isNotEmpty)
        _TaggedToken('mood', input.mood!),
      for (final raw in input.customTokens)
        ...() {
          final cleaned = cleanToken(raw, warnings);
          if (cleaned == null) return <_TaggedToken>[];
          return [_TaggedToken('custom', cleaned)];
        }(),
    ];

    tagged = _dedupeByStem(tagged, dropped);

    if (tagged.length > profile.tokenBudgetMax) {
      final dropOrder = EngineConfig.priorityOnOverflow.reversed.toList();
      for (final groupName in dropOrder) {
        while (tagged.length > profile.tokenBudgetMax) {
          final idx = tagged.lastIndexWhere((t) => t.group == groupName);
          if (idx == -1) break;
          dropped.add(tagged[idx].token);
          tagged.removeAt(idx);
        }
        if (tagged.length <= profile.tokenBudgetMax) break;
      }
      warnings.add('Over budget — dropped: ${dropped.join(", ")}');
    }
    if (tagged.length < profile.tokenBudgetMin) {
      warnings.add(
          'Only ${tagged.length} tags — thin prompts under ${profile.tokenBudgetMin} can produce generic output. Consider adding a mood.');
    }

    final isV5Era = profile.promptMode == PromptMode.naturalLanguage;
    if (isV5Era) {
      tagged.removeWhere((t) => t.group == 'fidelity');
      tagged.add(const _TaggedToken('fidelity', 'clean, balanced'));
      if (!_hasHumanizingToken(input.customTokens)) {
        warnings.add(EngineConfig.v5SheenTip);
      }
    }

    final rendered = _renderPrompt(tagged, profile.promptMode);
    if (rendered.length > profile.maxStyleChars) {
      warnings.add(
          'Prompt exceeds ${profile.maxStyleChars} chars for this model — Suno truncates silently, which corrupts the tail tokens.');
    }

    final exclusions = <String>{...EngineConfig.excludeUniversal};
    for (final g in genres) {
      exclusions.addAll(EngineConfig.excludePerGenre[g] ?? const []);
    }
    exclusions.addAll(EngineConfig.excludePerVocal[input.vocal] ?? const []);
    var excludeList = exclusions.toList();
    if (excludeList.length > EngineConfig.maxExclusions) {
      excludeList = excludeList.sublist(0, EngineConfig.maxExclusions);
      warnings.add(EngineConfig.overExclusionWarning);
    }

    final syllableBonus =
        EngineConfig.syllableCapBonus[input.modelVersion] ?? 0;
    final syllableCap =
        (vocalDef.syllableCapOverride ?? tempoDef.syllableCap) + syllableBonus;

    return AssemblerOutput(
      stylePrompt: rendered,
      excludeStyles: excludeList.join(', '),
      tokenCount: tagged.length,
      budgetMin: profile.tokenBudgetMin,
      budgetMax: profile.tokenBudgetMax,
      warnings: warnings,
      droppedTokens: dropped,
      isInstrumental: isInstrumental,
      syllableCap: syllableCap,
    );
  }
}
