import '../config/melody_config.dart';
import '../core/constants/genre_data.dart';
import '../data/models/melody_directive.dart';
import '../data/models/melody_evolution.dart';

class MelodyCompositionResult {
  final List<String> stylePromptTokens;
  final String melodyStyleToken;
  final String modifiedLyrics;
  final List<String> userNotices;

  const MelodyCompositionResult({
    this.stylePromptTokens = const [],
    this.melodyStyleToken = '',
    required this.modifiedLyrics,
    this.userNotices = const [],
  });
}

class MelodyComposerService {
  MelodyComposerService._();

  static MelodyCompositionResult compose({
    required String melodyDirectiveId,
    required MelodyEvolution evolution,
    String? customMelodyNotes,
    required String originalLyrics,
    String? primaryGenre,
    String? subGenreFusion,
  }) {
    var directive = MelodyConfig.getDirectiveById(melodyDirectiveId);
    final notices = <String>[];
    var lyrics = originalLyrics;
    var melodyToken = '';

    if (directive.id == MelodyConfig.autoId) {
      melodyToken = getAutoMelodyToken(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      final autoDirectiveId =
          GenreData.defaultMelodyDirectiveIdForLabel(primaryGenre);
      directive = MelodyConfig.getDirectiveById(autoDirectiveId);
      notices.add('Auto-selected "${directive.label}" style based on genre.');
    } else {
      melodyToken = _resolveStyleToken(
        directive: directive,
        customMelodyNotes: customMelodyNotes,
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
    }

    switch (directive.placement) {
      case MelodyPlacement.stylePrompt:
        break;
      case MelodyPlacement.structural:
        if (directive.id == 'call_and_response') {
          lyrics = _applyCallAndResponse(lyrics, directive.tokens);
          notices.add(
              'Applied Call & Response structure to lyrics. Check the parenthetical hints.');
        }
        break;
      case MelodyPlacement.bracketModifier:
        break;
    }

    lyrics = _applyEvolution(lyrics, evolution);

    if (evolution == MelodyEvolution.strict) {
      notices.add(MelodyConfig.evolutionDescriptions[MelodyEvolution.strict]!);
    }

    final tokens = melodyToken.trim().isEmpty ? <String>[] : [melodyToken.trim()];

    return MelodyCompositionResult(
      stylePromptTokens: tokens,
      melodyStyleToken: melodyToken.trim(),
      modifiedLyrics: lyrics,
      userNotices: notices,
    );
  }

  /// Data-driven auto melody token from genre metadata + genre-family token map.
  static String getAutoMelodyToken({
    String? primaryGenre,
    String? subGenreFusion,
  }) {
    final genreInfo = GenreData.infoForLabel(primaryGenre);
    final directive = MelodyConfig.getDirectiveById(genreInfo.defaultMelodyDirectiveId);
    final family = MelodyConfig.resolveMelodyGenreFamily(
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
    );
    return directive.getTokenForGenre(family);
  }

  static String _resolveStyleToken({
    required MelodyDirective directive,
    String? customMelodyNotes,
    String? primaryGenre,
    String? subGenreFusion,
  }) {
    if (directive.id == MelodyConfig.customId) {
      if (customMelodyNotes == null || customMelodyNotes.trim().isEmpty) {
        return '';
      }
      return customMelodyNotes
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    if (directive.placement != MelodyPlacement.stylePrompt) {
      return '';
    }

    final family = MelodyConfig.resolveMelodyGenreFamily(
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
    );
    return directive.getTokenForGenre(family);
  }

  /// Progressive: lift the final hook section (chorus, drop, or hook).
  /// High contrast: shift the bridge / breakdown / interlude (or Verse 2).
  /// Anchors cover song-form and EDM/hip-hop roadmaps so every genre works.
  static String _applyEvolution(String lyrics, MelodyEvolution evolution) {
    if (evolution == MelodyEvolution.strict || lyrics.trim().isEmpty) {
      return lyrics;
    }

    final lines = lyrics.split('\n');

    if (evolution == MelodyEvolution.progressive) {
      const suffix = ': high energy, layered harmonies]';
      final primary = RegExp(
        r'\[(final chorus|final drop|last chorus|chorus 3|drop 3)([^\]]*)\]',
        caseSensitive: false,
      );
      final fallback = RegExp(
        r'\[(chorus|drop|hook|main drop)([^\]]*)\]',
        caseSensitive: false,
      );

      for (var i = 0; i < lines.length; i++) {
        if (primary.hasMatch(lines[i])) {
          lines[i] = lines[i].replaceFirst(RegExp(r'\]'), suffix);
          return lines.join('\n');
        }
      }
      // No explicit final section — lift the LAST hook-type section instead.
      for (var i = lines.length - 1; i >= 0; i--) {
        if (fallback.hasMatch(lines[i])) {
          lines[i] = lines[i].replaceFirst(RegExp(r'\]'), suffix);
          return lines.join('\n');
        }
      }
      return lines.join('\n');
    }

    // High contrast: first matching contrast section wins.
    const contrastSuffix = ': new melodic motif, stripped back]';
    final contrastAnchors = [
      RegExp(r'\[bridge([^\]]*)\]', caseSensitive: false),
      RegExp(r'\[breakdown([^\]]*)\]', caseSensitive: false),
      RegExp(r'\[interlude([^\]]*)\]', caseSensitive: false),
      RegExp(r'\[atmospheric break([^\]]*)\]', caseSensitive: false),
      RegExp(r'\[verse 2([^\]]*)\]', caseSensitive: false),
    ];
    for (final anchor in contrastAnchors) {
      for (var i = 0; i < lines.length; i++) {
        if (anchor.hasMatch(lines[i])) {
          lines[i] = lines[i].replaceFirst(RegExp(r'\]'), contrastSuffix);
          return lines.join('\n');
        }
      }
    }
    return lines.join('\n');
  }

  static String _applyCallAndResponse(String lyrics, List<String> tokens) {
    if (tokens.length < 2) return lyrics;
    final callToken = tokens[0];
    final responseToken = tokens[1];
    var isCall = true;

    return lyrics.split('\n').map((line) {
      if (line.trim().isEmpty || line.trim().startsWith('[')) {
        isCall = true;
        return line;
      }
      final token = isCall ? callToken : responseToken;
      isCall = !isCall;
      return '$line $token';
    }).join('\n');
  }
}
