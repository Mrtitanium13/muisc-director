import '../../data/models/song_generation_type.dart';
import '../../data/models/user_input_model.dart';

/// True when the Style-Flip / Musical Remix Engine should activate.
bool remixEngineActive(UserInputModel input) =>
    input.remixOriginalSongTitle.trim().isNotEmpty &&
    input.remixOriginalArtist.trim().isNotEmpty;

/// Dense user-block supplement for Layer 4.8 (never echo copyrighted names in output).
String remixStyleFlipUserBlockSupplement({
  required String originalSongTitle,
  required String originalArtist,
  required String targetGenre,
  required SongGenerationType generationType,
}) {
  final title = originalSongTitle.trim();
  final artist = originalArtist.trim();
  if (title.isEmpty || artist.isEmpty) return '';

  final mode = generationType == SongGenerationType.instrumental
      ? 'INSTRUMENTAL-ONLY'
      : 'FULL-SONG';

  return '''
REMIX / MUSICAL INTERPOLATION ENGINE (LAYER 4.8 — ACTIVE)
Source reference (metadata only — NEVER print song title, artist name, or album brand in Block 1 or Block 2): "$title" by "$artist"
Target genre: $targetGenre
Generation mode: $mode

MANDATORY INTERPOLATION & REMIX LAWS:
1. Deconstruct & lock foundational DNA: extract exact chord progression, topline melody intervals, core tempo, and syncopated vocal rhythm internally — do not name the source in output.
2. Harmonic skeleton (strict): do NOT change underlying harmonic structure. Target genre is an alternative instrumental layer over the original chord cadence and melody lines; keep melodic phrasing boundaries identical.
3. Override sonic textures only: strip original instrumentation; force rhythm section, instrument palette, and mix textures to match $targetGenre while new instruments play the original exact chords and hooks.
4. In [Intro], append melodic-continuity tracking codes (no brand names), e.g. [Faithful melodic interpolation, Exact original chord progression, Original vocal rhythm mapped to target instrumentation, Signature arrangement style-flip].
${generationType == SongGenerationType.instrumental ? '''
5. INSTRUMENTAL MODE: Purge ALL lyric lines, soft hums, vocal ad-libs, and singer cues from Block 2. Every [Verse], [Chorus], [Bridge], and [Outro] gets ONE dense instrumental-only staging bracket mandating instruments to mimic the original melody — e.g. [Lead synthesizer tracking the exact original vocal topline melody], [Rhythm section executing the original song's signature syncopated groove inside a jazz pocket]. No sung words in Block 2.''' : '''
5. FULL-SONG MODE: Preserve lyric sheets with phonetic/dialect tags in single comma-separated staging brackets; vocal delivery must mirror the original song's exact cadence and rhythm while lyrics stay theme-appropriate.'''}
'''.trim();
}

/// OpenRouter / post-process compact pipe token (token-saving).
String remixPostProcessCompactLine({
  required String originalSongTitle,
  required String originalArtist,
  required SongGenerationType generationType,
}) {
  final title = originalSongTitle.trim();
  final artist = originalArtist.trim();
  if (title.isEmpty || artist.isEmpty) return '';
  return 'RMX:src=$title|by=$artist|mode:${generationType.apiValue}|lock:melody+rhythm+chords';
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

/// Post-process safety net when instrumental remix mode is active.
String applyInstrumentalRemixOutput(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  var inBlock2 = false;
  var inSection = false;
  var hasStagingInSection = false;
  String? currentSectionHeader;

  void flushSectionIfNeeded() {
    if (!inSection || currentSectionHeader == null) return;
    if (!hasStagingInSection) {
      out.add(_defaultInstrumentalStaging(currentSectionHeader!));
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
    // Drop lyric / vocal leak lines in instrumental mode.
  }

  flushSectionIfNeeded();
  return out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Apply remix generation-type post-processing when the remix engine is active.
String applyRemixGenerationTypeOutput(UserInputModel input, String text) {
  if (!remixEngineActive(input)) return text;
  if (input.songGenerationType != SongGenerationType.instrumental) return text;
  return applyInstrumentalRemixOutput(text);
}
