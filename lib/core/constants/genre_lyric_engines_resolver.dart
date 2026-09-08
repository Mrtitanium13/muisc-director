import '../constants/genres_config.dart';
import '../utils/genre_fx_matrix_data.dart';
import 'big_room_fusion_progressive_vocal_lyric_engine.dart';
import 'big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine.dart';
import 'edm_breakdown_vocal_lyric_engine.dart';
import 'genre_lyric_engines_data.dart';
import 'hardstyle_vocal_lyric_engine.dart';
import 'master_country_lyric_engine.dart';
import 'master_edm_lyric_engine.dart';
import 'master_gospel_lyric_engine.dart';
import 'master_hardstyle_lyric_engine.dart';
import 'master_hiphop_lyric_engine.dart';
import 'master_pop_lyric_engine.dart';
import 'master_progressive_big_room_house_lyric_engine.dart';
import 'master_rnb_lyric_engine.dart';
import 'master_rock_lyric_engine.dart';
import 'southern_gospel_country_lyric_engine.dart';
import '../utils/advanced_thematic_variator.dart';

/// Resolves genre-specific lyric engine prose from JSON + specialized composers.
class GenreLyricEnginesResolver {
  GenreLyricEnginesResolver._();

  static const _amapianoLanes = [
    'amapiano',
    'private school amapiano',
    'private school',
    'yanos',
    'piano amapiano',
    'organic amapiano',
    'afro house',
    'amapiano-vinahouse',
  ];

  static bool _isAmapianoLane(String primary, String fusion) {
    final blob = '${primary.trim()} ${fusion.trim()}'.toLowerCase();
    return _amapianoLanes.any(blob.contains);
  }

  static const _engineHeader = '[GENRE-SPECIFIC LYRIC ENGINE]';

  static String _format(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith(_engineHeader)) return trimmed;
    return '$_engineHeader:\n$trimmed';
  }

  static String _laneFallback({
    required String genreFxLaneId,
    required String primaryGenre,
    required String fusionGenre,
  }) {
    final lane = GenresConfig.effectiveLaneId(
      genreFxLaneId: genreFxLaneId,
      primaryGenre: primaryGenre,
      fusionGenre: fusionGenre,
    );
    return GenreFxMatrixData.getLyricEngineDirectives(family: lane);
  }

  static String resolvePrimaryEngine({
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String melodyStyleId = '',
    String melodyCustomNotes = '',
    String? bpmHint,
    String genreFxLaneId = '',
  }) {
    if (MasterGospelLyricEngine.isGospelLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final block = MasterGospelLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (SouthernGospelCountryLyricEngine.isLane(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
      )) {
        final ui = SouthernGospelCountryLyricEngine.uiDirectiveAppend(
          vocalSpec: vocalSpec,
          vocalTone: vocalTone,
          vibe: vibe,
          melodyStyleId: melodyStyleId,
          melodyCustomNotes: melodyCustomNotes,
        );
        if (ui.isNotEmpty) {
          return _format('$block\n\n$ui');
        }
      }
      return _format(block);
    }

    if (SouthernGospelCountryLyricEngine.isLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final parts = <String>[SouthernGospelCountryLyricEngine.coreArchitecture];
      final ui = SouthernGospelCountryLyricEngine.uiDirectiveAppend(
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        vibe: vibe,
        melodyStyleId: melodyStyleId,
        melodyCustomNotes: melodyCustomNotes,
      );
      if (ui.isNotEmpty) parts.add(ui);
      return _format(parts.join('\n\n'));
    }

    if (BigRoomHardstyleCinematicHybridVocalLyricEngine.isHybridLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      final composed =
          BigRoomHardstyleCinematicHybridVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (composed.isNotEmpty) return _format(composed);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['big_room_hardstyle_hybrid'] ??
            '',
      );
    }

    if (MasterHardstyleLyricEngine.isHardstyleLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterHardstyleLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
      // Legacy specialty fallback if master composer returns empty.
      final legacy = HardstyleVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (legacy.isNotEmpty) return _format(legacy);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['hardstyle_vocal'] ?? '',
      );
    }

    if (isFutureHouseLane(primaryGenre, subGenreFusion)) {
      return _format(
        GenreLyricEnginesData.inlineDirectives['future_house'] ?? '',
      );
    }

    if (MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed =
          MasterProgressiveBigRoomHouseLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
      final legacy =
          BigRoomFusionProgressiveVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (legacy.isNotEmpty) return _format(legacy);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['big_room_fusion_progressive'] ??
            '',
      );
    }

    if (BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      final composed =
          BigRoomFusionProgressiveVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (composed.isNotEmpty) return _format(composed);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['big_room_fusion_progressive'] ??
            '',
      );
    }

    // Catch-all for remaining EDM family lanes after more specific masters.
    if (MasterEdmLyricEngine.isEdmLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterEdmLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (_isAmapianoLane(primaryGenre, subGenreFusion)) {
        // Amapiano lanes always carry the dedicated inline directive
        // (log-drum laws, commercial arrangement order, theme fit) —
        // appended after the EDM master block when it composes one.
        final amapiano =
            GenreLyricEnginesData.inlineDirectives['amapiano'] ?? '';
        if (amapiano.isNotEmpty) {
          return _format(
            composed.isNotEmpty ? '$composed\n\n$amapiano' : amapiano,
          );
        }
      }
      if (composed.isNotEmpty) return _format(composed);
      final edmLegacy = EdmBreakdownVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (edmLegacy.isNotEmpty) return _format(edmLegacy);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['edm_breakdown_vocal'] ?? '',
      );
    }

    if (_isAmapianoLane(primaryGenre, subGenreFusion)) {
      return _format(GenreLyricEnginesData.inlineDirectives['amapiano'] ?? '');
    }

    if (EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    )) {
      final composed = EdmBreakdownVocalLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
      );
      if (composed.isNotEmpty) return _format(composed);
      return _format(
        GenreLyricEnginesData.fileEngineBodies['edm_breakdown_vocal'] ?? '',
      );
    }

    // Core commercial lanes (after EDM/gospel specialists).
    // Order: R&B before Hip-Hop (trap soul), Country before Pop (country pop),
    // Rock before Pop (pop punk / indie rock).
    if (MasterRnbLyricEngine.isRnbLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterRnbLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
    }

    if (MasterHipHopLyricEngine.isHipHopLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterHipHopLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
    }

    if (MasterCountryLyricEngine.isCountryLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterCountryLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
    }

    if (MasterRockLyricEngine.isRockLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterRockLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
    }

    if (MasterPopLyricEngine.isPopLane(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      final composed = MasterPopLyricEngine.composeUserBlock(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
        vocalSpec: vocalSpec,
        vocalTone: vocalTone,
        bpmHint: bpmHint,
      );
      if (composed.isNotEmpty) return _format(composed);
    }

    final fallback = _laneFallback(
      genreFxLaneId: genreFxLaneId,
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
    );
    return _format(fallback);
  }
}
