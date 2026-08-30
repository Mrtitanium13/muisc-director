import 'package:music_director/data/models/user_input_model.dart';

/// Defines precedence when multiple lyric craft directives are active.
class LyricCraftHierarchyDirective {
  LyricCraftHierarchyDirective._();

  static const String _directive =
      '[LYRIC CRAFT HIERARCHY] (MANDATORY INSTRUCTION: Apply directives in this '
      'strict order of authority: '
      '1. PRIMARY AUTHORITY: The [SOURCE TEXT FOR LYRICS] if present. This is the '
      'foundational story/theme. '
      '2. USER OVERRIDE: The user\'s explicit [LYRIC THEME NOTES] act as a lens to '
      'interpret the source text. '
      '3. GENRE LENS: The [GENRE-SPECIFIC LYRIC ENGINE] defines genre conventions. '
      '4. HUMANISM STYLE: The [HUMAN REALISM] setting dictates the final performance '
      'style. '
      '5. EMOTIONAL MODIFIER: The [LYRIC TEMPERAMENT] codes add the final emotional '
      'color. '
      'ANTI-PARROT (all genres): Never reuse stock kits — 3 AM on cold tile, '
      'unmotivated Lagos, bleach/scrubbing floors, bent receipt/kettle, '
      'Mama said… count grace before receipts. Details must fit THIS brief only.)';

  static bool isComplexLyricPath(UserInputModel input) {
    return input.generateLyrics ||
        input.useVibeAsLyricSource ||
        input.optionalLyrics.trim().isNotEmpty;
  }

  static String? userBlockDirective(UserInputModel input) {
    if (!isComplexLyricPath(input)) return null;
    return _directive;
  }
}
