/// Resolved remix path for a generate request — mutually exclusive modes.
enum RemixMode {
  none,
  interpolation,
  analyzerGenreFlip,
}

/// Result of [resolveRemixMode].
class RemixResolution {
  const RemixResolution(
    this.mode, {
    this.nearActivation = false,
  });

  final RemixMode mode;

  /// Exactly one of title/artist is filled — show UI hint, engine stays off.
  final bool nearActivation;

  bool get isActive => mode != RemixMode.none;
}

/// Block version stamped into logs / fixtures (Layer 4.8 user supplement).
const String remixBlockVersion = '1.3';

/// Marker used for idempotent injection (user block already present).
const String remixBlockMarker = 'REMIX / MUSICAL INTERPOLATION ENGINE';

const String remixAnalyzerBlockMarker = 'REMIX / GENRE-FLIP';

/// Single resolver — analyzer genre-flip and interpolation never both inject.
///
/// Precedence when both flags are somehow set: [RemixMode.analyzerGenreFlip]
/// wins (UI should clear the other path on edit; this is the safety net).
RemixResolution resolveRemixMode({
  required String remixOriginalSongTitle,
  required String remixOriginalArtist,
  required bool remixFromAnalyzer,
}) {
  final title = remixOriginalSongTitle.trim();
  final artist = remixOriginalArtist.trim();
  final hasTitle = title.length >= 2;
  final hasArtist = artist.length >= 2;
  final near = hasTitle != hasArtist;

  if (remixFromAnalyzer) {
    return RemixResolution(
      RemixMode.analyzerGenreFlip,
      nearActivation: near,
    );
  }
  if (hasTitle && hasArtist) {
    return const RemixResolution(RemixMode.interpolation);
  }
  return RemixResolution(RemixMode.none, nearActivation: near);
}

RemixResolution resolveRemixModeFromInput({
  required String remixOriginalSongTitle,
  required String remixOriginalArtist,
  required bool remixFromAnalyzer,
}) =>
    resolveRemixMode(
      remixOriginalSongTitle: remixOriginalSongTitle,
      remixOriginalArtist: remixOriginalArtist,
      remixFromAnalyzer: remixFromAnalyzer,
    );
