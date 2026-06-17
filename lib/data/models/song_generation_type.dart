/// Remix engine output mode: full vocal song vs instrumental-only flip.
enum SongGenerationType {
  fullSong,
  instrumental;

  String get label => switch (this) {
        SongGenerationType.fullSong => 'Full song',
        SongGenerationType.instrumental => 'Instrumental',
      };

  String get apiValue => switch (this) {
        SongGenerationType.fullSong => 'full_song',
        SongGenerationType.instrumental => 'instrumental',
      };

  static SongGenerationType fromApi(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == 'instrumental') return SongGenerationType.instrumental;
    return SongGenerationType.fullSong;
  }
}
