/// Genre-specific Block 2 lyric direction — runtime user-block overrides before generation.
class GenreLyricsDirectives {
  GenreLyricsDirectives._();

  static const _hardstyleLanes = [
    'hardstyle',
    'rawstyle',
    'euphoric hardstyle',
    'hard bounce',
  ];

  static String _genreBlob(String primary, String fusion) =>
      '${primary.trim()} ${fusion.trim()}'.toLowerCase();

  static bool isHardstyleLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _hardstyleLanes.any(blob.contains);
  }

  static String hardstyleLyricsDirective() => '''
CRITICAL DIRECTION FOR HARDSTYLE LYRICS:
1. BAN all mundane, cozy, or intimate bedroom/pop imagery (no coffee, lighters, group chats, or soft romance).
2. ENFORCE an epic, cinematic, aggressive, or dystopian tone (destiny, fire, power, fury, revolution, breaking chains, eternity — allowed in this lane even when generic anti-AI bans apply).
3. [Monologue] blocks must read like an epic movie trailer voiceover, not a poem or domestic diary entry.
4. The line immediately before any [Drop] must be ONE high-impact shout phrase (4 words max) as the pre-drop hype trigger; keep [Drop] instrumental unless genre FX tags require vocal chops only.''';

  static String userBlockDirective({
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    if (isHardstyleLane(primaryGenre, subGenreFusion)) {
      return hardstyleLyricsDirective();
    }
    return '';
  }
}
