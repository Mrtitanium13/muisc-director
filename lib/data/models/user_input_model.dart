import '../../config/melody_config.dart';
import '../../core/constants/audio_environment_data.dart';
import '../../core/constants/dialect_style_data.dart';
import '../../core/constants/production_intensity_config.dart';
import '../../core/constants/suno_version.dart';
import 'melody_evolution.dart';
import 'song_generation_type.dart';
import 'suno_field_output_mode.dart';
import 'track_duration_config.dart';

class UserInputModel {
  static const Object _unset = Object();

  const UserInputModel({
    this.sunoVersion = SunoVersion.preferredValue,
    this.primaryGenre = '',
    this.subGenreFusion = '',
    this.vibe = '',
    this.bpm,
    this.keyRoot,
    this.scale,
    this.vocalSpec,
    this.vocalTone,
    this.vocalAccent,
    this.dialectStyleId = DialectStyleData.standardEnglishId,
    this.dialectVariantId = DialectStyleData.generalVariantId,
    this.audioEnvironmentModeId = AudioEnvironmentData.studioIsolatedId,
    this.referenceArtists = '',
    this.sonicTags = const [],
    this.avoid = '',
    this.language = 'English',
    this.includeAnalyzerData = false,
    this.analyzerSummary = '',
    this.trackDurationLabel,
    this.trackDuration = TrackDuration.s3_00,
    this.djIntroMixIn = false,
    this.djOutroMixOut = false,
    this.songStructurePresetId = 'flexible',
    this.songStructureCustom = '',
    this.optionalLyrics = '',
    this.remixFromAnalyzer = false,
    this.remixOriginalSongTitle = '',
    this.remixOriginalArtist = '',
    this.songGenerationType = SongGenerationType.fullSong,
    this.realInstrumentals = '',
    this.melodyStyleId = MelodyConfig.autoId,
    this.melodyCustomNotes = '',
    this.melodyEvolution = MelodyEvolution.strict,
    this.chordProgression = '',
    this.generateLyrics = false,
    this.useVibeAsLyricSource = false,
    this.lyricThemeNotes = '',
    this.activeModifierCodes = '',
    this.humanRealism = 75,
    this.productionIntensity = ProductionIntensityConfig.defaultLevel,
    this.genreFxLaneId = '',
    this.sunoFieldOutputMode = SunoFieldOutputMode.custom,
  });

  final String sunoVersion;
  final String primaryGenre;
  final String subGenreFusion;
  final String vibe;
  final String? bpm;
  final String? keyRoot;
  final String? scale;
  final String? vocalSpec;
  final String? vocalTone;

  /// Singing/rap accent or regional English delivery (e.g. West African, British) — style only.
  final String? vocalAccent;

  /// Lyric dialect mode (`standard_english` | `nigerian_pidgin`).
  final String dialectStyleId;

  /// Regional Pidgin flavor when [dialectStyleId] is Nigerian Pidgin (`general`, `ibibio`, …).
  final String dialectVariantId;

  /// `studio_isolated` (default) or `live_performance` — Block 2 crowd/studio staging.
  final String audioEnvironmentModeId;
  /// Artist names or catalog codenames for DNA translation.
  final String referenceArtists;

  /// Objective sonic production tags (direct instructions — not artist DNA).
  final List<String> sonicTags;

  final String avoid;
  final String language;
  final bool includeAnalyzerData;
  final String analyzerSummary;

  /// Human-readable length of the source audio (e.g. "3:45"), if known.
  final String? trackDurationLabel;

  /// Target length for the Suno generation (chips on the prompt form).
  final TrackDuration trackDuration;

  /// Request an extended, DJ-friendly intro (mix-in from previous track).
  final bool djIntroMixIn;

  /// Request an extended, DJ-friendly outro (mix-out to next track).
  final bool djOutroMixOut;

  /// Preset id from [SongStructureData] (`flexible`, `standard_pop`, `custom`, …).
  final String songStructurePresetId;

  /// When preset is `custom`, user-defined section order / notes.
  final String songStructureCustom;

  /// Raw lyrics supplied by the user — when non-empty, generation includes a Suno Lyrics box section.
  final String optionalLyrics;

  /// Set when the form was filled via Audio Analyzer **Remix** (genre flip).
  final bool remixFromAnalyzer;

  /// Style-Flip source song title (metadata only — never echoed in Suno output).
  final String remixOriginalSongTitle;

  /// Style-Flip source artist (metadata only — never echoed in Suno output).
  final String remixOriginalArtist;

  /// Full vocal remix vs instrumental-only arrangement flip.
  final SongGenerationType songGenerationType;

  /// Live / acoustic / mic’d instruments to foreground in SUNO STYLE (comma-separated or free text).
  final String realInstrumentals;

  /// Preset id from [MelodyConfig.directives] or [MelodyConfig.customId].
  final String melodyStyleId;

  /// Free-text when [melodyStyleId] is custom.
  final String melodyCustomNotes;

  /// Strict / progressive / high-contrast section-to-section melodic routing.
  final MelodyEvolution melodyEvolution;

  /// User-specified chord progression (Roman numerals, chord symbols, or prose).
  /// Woven into SUNO STRUCTURE (notes) and SUNO STYLE when non-empty.
  final String chordProgression;

  /// Path C: original lyrics when true and [optionalLyrics] is empty.
  final bool generateLyrics;

  /// When true, vibe detail textarea is sent as [SOURCE TEXT FOR LYRICS] prose-to-lyrics input.
  final bool useVibeAsLyricSource;

  /// Theme / POV / keywords for Path C (optional).
  final String lyricThemeNotes;

  /// Space-separated temperament tokens, e.g. "/GRIT /TENDER".
  final String activeModifierCodes;

  /// 0–100: poetic/polished (low) vs natural/imperfect human lyrics (high). Default 75.
  final int humanRealism;

  /// 1–3: genre-specific production FX intensity (Suno Prompt Builder). Default 2.
  final int productionIntensity;

  /// FX matrix lane id (`edm`, `metal`, …). Empty = auto-resolve from primary/fusion.
  final String genreFxLaneId;

  /// Suno Custom vs Simple field workflow (controls Block 1 caps and Block 2 presence).
  final SunoFieldOutputMode sunoFieldOutputMode;

  UserInputModel copyWith({
    String? sunoVersion,
    String? primaryGenre,
    String? subGenreFusion,
    String? vibe,
    String? bpm,
    String? keyRoot,
    String? scale,
    String? vocalSpec,
    String? vocalTone,
    Object? vocalAccent = _unset,
    String? dialectStyleId,
    String? dialectVariantId,
    String? audioEnvironmentModeId,
    String? referenceArtists,
    List<String>? sonicTags,
    String? avoid,
    String? language,
    bool? includeAnalyzerData,
    String? analyzerSummary,
    Object? trackDurationLabel = _unset,
    TrackDuration? trackDuration,
    bool? djIntroMixIn,
    bool? djOutroMixOut,
    String? songStructurePresetId,
    String? songStructureCustom,
    String? optionalLyrics,
    bool? remixFromAnalyzer,
    String? remixOriginalSongTitle,
    String? remixOriginalArtist,
    SongGenerationType? songGenerationType,
    String? realInstrumentals,
    String? melodyStyleId,
    String? melodyCustomNotes,
    MelodyEvolution? melodyEvolution,
    String? chordProgression,
    bool? generateLyrics,
    bool? useVibeAsLyricSource,
    String? lyricThemeNotes,
    String? activeModifierCodes,
    int? humanRealism,
    int? productionIntensity,
    String? genreFxLaneId,
    SunoFieldOutputMode? sunoFieldOutputMode,
  }) {
    return UserInputModel(
      sunoVersion: sunoVersion ?? this.sunoVersion,
      primaryGenre: primaryGenre ?? this.primaryGenre,
      subGenreFusion: subGenreFusion ?? this.subGenreFusion,
      vibe: vibe ?? this.vibe,
      bpm: bpm ?? this.bpm,
      keyRoot: keyRoot ?? this.keyRoot,
      scale: scale ?? this.scale,
      vocalSpec: vocalSpec ?? this.vocalSpec,
      vocalTone: vocalTone ?? this.vocalTone,
      vocalAccent: identical(vocalAccent, _unset)
          ? this.vocalAccent
          : vocalAccent as String?,
      dialectStyleId: dialectStyleId ?? this.dialectStyleId,
      dialectVariantId: dialectVariantId ?? this.dialectVariantId,
      audioEnvironmentModeId:
          audioEnvironmentModeId ?? this.audioEnvironmentModeId,
      referenceArtists: referenceArtists ?? this.referenceArtists,
      sonicTags: sonicTags ?? this.sonicTags,
      avoid: avoid ?? this.avoid,
      language: language ?? this.language,
      includeAnalyzerData: includeAnalyzerData ?? this.includeAnalyzerData,
      analyzerSummary: analyzerSummary ?? this.analyzerSummary,
      trackDurationLabel: identical(trackDurationLabel, _unset)
          ? this.trackDurationLabel
          : trackDurationLabel as String?,
      trackDuration: trackDuration ?? this.trackDuration,
      djIntroMixIn: djIntroMixIn ?? this.djIntroMixIn,
      djOutroMixOut: djOutroMixOut ?? this.djOutroMixOut,
      songStructurePresetId:
          songStructurePresetId ?? this.songStructurePresetId,
      songStructureCustom: songStructureCustom ?? this.songStructureCustom,
      optionalLyrics: optionalLyrics ?? this.optionalLyrics,
      remixFromAnalyzer: remixFromAnalyzer ?? this.remixFromAnalyzer,
      remixOriginalSongTitle:
          remixOriginalSongTitle ?? this.remixOriginalSongTitle,
      remixOriginalArtist: remixOriginalArtist ?? this.remixOriginalArtist,
      songGenerationType: songGenerationType ?? this.songGenerationType,
      realInstrumentals: realInstrumentals ?? this.realInstrumentals,
      melodyStyleId: melodyStyleId ?? this.melodyStyleId,
      melodyCustomNotes: melodyCustomNotes ?? this.melodyCustomNotes,
      melodyEvolution: melodyEvolution ?? this.melodyEvolution,
      chordProgression: chordProgression ?? this.chordProgression,
      generateLyrics: generateLyrics ?? this.generateLyrics,
      useVibeAsLyricSource:
          useVibeAsLyricSource ?? this.useVibeAsLyricSource,
      lyricThemeNotes: lyricThemeNotes ?? this.lyricThemeNotes,
      activeModifierCodes:
          activeModifierCodes ?? this.activeModifierCodes,
      humanRealism: humanRealism ?? this.humanRealism,
      productionIntensity: productionIntensity ?? this.productionIntensity,
      genreFxLaneId: genreFxLaneId ?? this.genreFxLaneId,
      sunoFieldOutputMode:
          sunoFieldOutputMode ?? this.sunoFieldOutputMode,
    );
  }
}
