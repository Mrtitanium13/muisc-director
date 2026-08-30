import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/constants/production_intensity_config.dart';
import 'package:music_director/core/constants/song_structure_data.dart';
import 'package:music_director/core/utils/genre_fx_matrix_data.dart';
import 'package:music_director/data/models/user_input_model.dart';

/// Explains how macro structure (roadmap) and micro FX tags coexist in Block 2.
class StructuralHierarchyDirective {
  StructuralHierarchyDirective._();

  static const String _directive =
      '[STRUCTURAL HIERARCHY] (MANDATORY INSTRUCTION: You will receive two forms of '
      'structural guidance. '
      '1. A high-level STRUCTURE_LOCK or a full section-by-section roadmap. This is the '
      'primary authority for the song\'s overall flow and sequence. '
      '2. Bracketed production tags [like this] inside the lyrics. These are micro-level events. '
      'YOUR TASK: Place the micro-level production tags within their logical parent section '
      'from the high-level roadmap. The roadmap\'s sequence is non-negotiable.)';

  static bool hasMacroStructure({
    required String presetId,
    required String customNotes,
  }) {
    final id = presetId.trim();
    if (id == SongStructureData.customId) {
      return customNotes.trim().isNotEmpty;
    }
    return id.isNotEmpty && id != SongStructureData.flexibleId;
  }

  static bool hasMicroStructure({
    required String genreFxLaneId,
    required String primaryGenre,
    required String fusionGenre,
    required int productionIntensity,
  }) {
    if (ProductionIntensityConfig.clampLevel(productionIntensity) <= 1) {
      return false;
    }
    final lane = GenresConfig.effectiveLaneId(
      genreFxLaneId: genreFxLaneId,
      primaryGenre: primaryGenre,
      fusionGenre: fusionGenre,
    );
    final fx = GenreFxMatrixData.getFx(
      family: lane,
      tier: '${ProductionIntensityConfig.clampLevel(productionIntensity)}',
    );
    return fx.lyrics.trim().isNotEmpty;
  }

  static bool shouldInject(UserInputModel input) {
    return hasMacroStructure(
          presetId: input.songStructurePresetId,
          customNotes: input.songStructureCustom,
        ) &&
        hasMicroStructure(
          genreFxLaneId: input.genreFxLaneId,
          primaryGenre: input.primaryGenre,
          fusionGenre: input.subGenreFusion,
          productionIntensity: input.productionIntensity,
        );
  }

  static String? userBlockDirective(UserInputModel input) {
    if (!shouldInject(input)) return null;
    return _directive;
  }
}
