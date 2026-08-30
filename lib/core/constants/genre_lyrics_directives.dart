import '../utils/advanced_thematic_variator.dart';
import 'dont_call_me_lonely_master.dart';
import 'genre_lyric_engines_data.dart';
import 'genre_lyric_engines_resolver.dart';
import 'secret_inside_your_chest_template.dart';

/// Genre-specific Block 2 lyric direction — runtime user-block overrides.
class GenreLyricsDirectives {
  GenreLyricsDirectives._();

  static const _hardstyleLanes = [
    'hardstyle',
    'rawstyle',
    'euphoric hardstyle',
    'hard bounce',
    'edm bounce',
  ];

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

  static String _genreBlob(String primary, String fusion) =>
      '${primary.trim()} ${fusion.trim()}'.toLowerCase();

  static bool isHardstyleLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _hardstyleLanes.any(blob.contains);
  }

  static bool isAmapianoLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _amapianoLanes.any(blob.contains);
  }

  static const _secretInsideMarkers = [
    'secret inside your chest',
    'secret inside',
  ];

  static const _dontCallMeLonelyMarkers = [
    'don\'t call me lonely',
    'dont call me lonely',
    'call me outside',
  ];

  static bool _matchesSecretInsideChest({
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final blob = '${vibe.trim()} ${lyricThemeNotes.trim()}'.toLowerCase();
    return _secretInsideMarkers.any(blob.contains);
  }

  static bool _matchesDontCallMeLonely({
    String vibe = '',
    String lyricThemeNotes = '',
  }) {
    final blob = '${vibe.trim()} ${lyricThemeNotes.trim()}'.toLowerCase();
    return _dontCallMeLonelyMarkers.any(blob.contains);
  }

  static String userBlockDirective({
    String primaryGenre = '',
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
    final parts = <String>[GenreLyricEnginesData.globalGuardrail];

    final engine = GenreLyricEnginesResolver.resolvePrimaryEngine(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
      vocalSpec: vocalSpec,
      vocalTone: vocalTone,
      melodyStyleId: melodyStyleId,
      melodyCustomNotes: melodyCustomNotes,
      bpmHint: bpmHint,
      genreFxLaneId: genreFxLaneId,
    );
    if (engine.isNotEmpty) parts.add(engine);

    final thematic = advancedThematicVariatorBlock(
      primary: primaryGenre,
      fusion: subGenreFusion,
      vibe: vibe,
    );
    if (thematic.isNotEmpty) {
      parts.add(thematic);
    }

    if (_matchesSecretInsideChest(
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      parts.add(kSecretInsideYourChestTemplate);
    }

    if (_matchesDontCallMeLonely(
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {
      parts.add(kDontCallMeLonelyMaster);
    }

    return parts.join('\n\n');
  }
}
