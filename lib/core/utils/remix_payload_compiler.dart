import 'package:music_director/data/models/song_generation_type.dart';
import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/features/remix/application/source_leak_guard.dart';
import 'package:music_director/features/remix/application/remix_telemetry.dart';
import 'package:music_director/features/remix/domain/remix_descriptors.dart';
import 'package:music_director/features/remix/domain/remix_mode.dart';

export 'package:music_director/features/remix/domain/remix_descriptors.dart';
export 'package:music_director/features/remix/domain/remix_mode.dart';

/// True when Layer 4.8 interpolation should activate (not analyzer genre-flip).
bool remixEngineActive(UserInputModel input) =>
    resolveRemixModeFromInput(
      remixOriginalSongTitle: input.remixOriginalSongTitle,
      remixOriginalArtist: input.remixOriginalArtist,
      remixFromAnalyzer: input.remixFromAnalyzer,
    ).mode ==
    RemixMode.interpolation;

RemixResolution remixResolutionFor(UserInputModel input) =>
    resolveRemixModeFromInput(
      remixOriginalSongTitle: input.remixOriginalSongTitle,
      remixOriginalArtist: input.remixOriginalArtist,
      remixFromAnalyzer: input.remixFromAnalyzer,
    );

/// Dense user-block supplement for Layer 4.8 — descriptor-only (no title/artist in LLM text).
/// Idempotent: returns empty if [existingUserBlock] already contains the marker.
String remixStyleFlipUserBlockSupplement({
  required String originalSongTitle,
  required String originalArtist,
  required String targetGenre,
  required SongGenerationType generationType,
  String bpm = '',
  String keyRoot = '',
  String scale = '',
  String vibe = '',
  String? existingUserBlock,
}) {
  if (existingUserBlock != null &&
      existingUserBlock.contains(remixBlockMarker)) {
    return '';
  }
  final title = originalSongTitle.trim();
  final artist = originalArtist.trim();
  if (title.length < 2 || artist.length < 2) return '';

  final descriptors = RemixDescriptors.resolve(
    title: title,
    artist: artist,
    targetGenre: targetGenre,
    bpm: bpm,
    keyRoot: keyRoot,
    scale: scale,
    vibe: vibe,
  );

  final mode = generationType == SongGenerationType.instrumental
      ? 'INSTRUMENTAL-ONLY'
      : 'FULL-SONG';
  final genre = descriptors.targetGenre;

  return '''
$remixBlockMarker (LAYER 4.8 · v$remixBlockVersion — ACTIVE · DESCRIPTOR-ONLY)
Generation mode: $mode
${descriptors.toUserBlockDna()}

MANDATORY INTERPOLATION & REMIX LAWS:
1. Treat REFERENCE DNA as the locked melodic/harmonic brief. Do not invent a catalog title or artist.
2. Harmonic skeleton (strict): do NOT change underlying harmonic structure. Target genre ($genre) is an alternative instrumental layer over the locked chord cadence and melody lines; keep melodic phrasing boundaries identical.
3. Override sonic textures only: strip prior instrumentation; force rhythm section, instrument palette, and mix textures to match $genre while new instruments play the locked chords and hooks.
4. In [Intro], append melodic-continuity tracking codes (no brand names), e.g. [Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip].
5. Never print song titles, artist names, album brands, or “in the style of …” imitation language.
${generationType == SongGenerationType.instrumental ? '''
6. INSTRUMENTAL MODE (compose directly — do NOT draft sung lyrics then delete them):
   Emit Block 2 as section headers + ONE dense instrumental staging bracket per section only.
   Never generate lyric lines, soft hums, vocal ad-libs, or singer cues.
   Staging must mandate instruments tracking the locked topline melody and syncopated groove.''' : '''
6. FULL-SONG MODE: Preserve lyric sheets with phonetic/dialect tags in single comma-separated staging brackets; vocal delivery must mirror the locked reference cadence and rhythm while lyrics stay theme-appropriate.'''}
'''.trim();
}

/// Out-of-band compact token for post-process (NO source title/artist).
String remixPostProcessCompactLine({
  required String originalSongTitle,
  required String originalArtist,
  required SongGenerationType generationType,
}) {
  final title = originalSongTitle.trim();
  final artist = originalArtist.trim();
  if (title.length < 2 || artist.length < 2) return '';
  final fp = RemixDescriptors.fingerprint(title, artist);
  return 'RMX:mode:${generationType.apiValue}|lock:melody+rhythm+chords|v=$remixBlockVersion|fp=$fp';
}

final _block2Marker = RegExp(
  r'BLOCK\s*2|PASTE\s+INTO\s+SUNO:\s*LYRICS',
  caseSensitive: false,
);

final _sectionHeader = RegExp(
  r'^\[(Intro|Verse\s*\d*|Chorus|Final\s+Chorus|Bridge|Pre-Chorus|Drop|Build|Outro|Instrumental|End)\b',
  caseSensitive: false,
);

bool _isStagingBracketLine(String trimmed) {
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return false;
  return !_sectionHeader.hasMatch(trimmed);
}

String _defaultInstrumentalStaging(String header) {
  final h = header.toLowerCase();
  if (h.startsWith('[intro')) {
    return '[Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip]';
  }
  if (h.contains('chorus')) {
    return '[Lead synthesizer tracking the exact original vocal topline melody, Full ensemble hook lift over locked harmonic skeleton]';
  }
  if (h.contains('bridge')) {
    return '[Harmonic pivot on original chord cadence, Expressive solo tracking original topline intervals]';
  }
  if (h.contains('outro')) {
    return '[Gradual arrangement decay on original progression, Trailing motif fade preserving melodic contour]';
  }
  if (h.contains('verse')) {
    return '[Melodic lead tracking exact original topline, Rhythm section executing signature syncopated groove in target genre pocket]';
  }
  return '[Instrumental progression locked to original chord and melody skeleton]';
}

/// Safety-net post-process when instrumental remix mode is active (LLM should emit instrumental-first).
({String text, int strippedLyricLines, int stagingInjected})
    applyInstrumentalRemixOutputDetailed(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  var inBlock2 = false;
  var inSection = false;
  var hasStagingInSection = false;
  var strippedLyricLines = 0;
  var stagingInjected = 0;
  String? currentSectionHeader;

  void flushSectionIfNeeded() {
    if (!inSection || currentSectionHeader == null) return;
    if (!hasStagingInSection) {
      out.add(_defaultInstrumentalStaging(currentSectionHeader!));
      stagingInjected++;
    }
    inSection = false;
    hasStagingInSection = false;
    currentSectionHeader = null;
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (_block2Marker.hasMatch(trimmed)) {
      inBlock2 = true;
      out.add(line);
      continue;
    }
    if (!inBlock2) {
      out.add(line);
      continue;
    }
    if (trimmed.isEmpty) {
      flushSectionIfNeeded();
      out.add(line);
      continue;
    }
    if (_sectionHeader.hasMatch(trimmed)) {
      flushSectionIfNeeded();
      out.add(line);
      inSection = true;
      currentSectionHeader = trimmed;
      continue;
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      if (_isStagingBracketLine(trimmed)) {
        out.add(trimmed);
        hasStagingInSection = true;
      }
      continue;
    }
    strippedLyricLines++;
  }

  flushSectionIfNeeded();
  return (
    text: out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim(),
    strippedLyricLines: strippedLyricLines,
    stagingInjected: stagingInjected,
  );
}

/// Safety-net post-process when instrumental remix mode is active.
String applyInstrumentalRemixOutput(String text) =>
    applyInstrumentalRemixOutputDetailed(text).text;

/// Apply remix post-processing (instrumental strip + leak guard) when active.
String applyRemixGenerationTypeOutput(UserInputModel input, String text) {
  final resolution = remixResolutionFor(input);
  var out = text;
  var stripped = 0;
  var staging = 0;
  var leakHit = false;

  if (resolution.mode == RemixMode.interpolation &&
      input.songGenerationType == SongGenerationType.instrumental) {
    final detail = applyInstrumentalRemixOutputDetailed(out);
    out = detail.text;
    stripped = detail.strippedLyricLines;
    staging = detail.stagingInjected;
  }
  if (resolution.mode == RemixMode.interpolation) {
    final guarded = sourceLeakGuard(
      output: out,
      title: input.remixOriginalSongTitle,
      artist: input.remixOriginalArtist,
    );
    out = guarded.text;
    leakHit = guarded.leaked;
  }

  if (resolution.isActive || resolution.nearActivation) {
    RemixTelemetry.postProcess(
      mode: resolution.mode,
      songGenerationType: input.songGenerationType.apiValue,
      strippedLyricLines: stripped,
      stagingInjected: staging,
      leakHit: leakHit,
      title: input.remixOriginalSongTitle,
      artist: input.remixOriginalArtist,
    );
  }
  return out;
}
