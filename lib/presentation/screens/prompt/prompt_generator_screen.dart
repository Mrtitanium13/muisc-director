import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/chord_progression_data.dart';
import '../../../core/constants/genre_data.dart';
import '../../../core/constants/negative_style_descriptors.dart';
import '../../../core/constants/genres_config.dart';
import '../../../core/constants/production_intensity_config.dart';
import '../../../core/constants/human_realism_config.dart';
import '../../../core/constants/lyric_temperament_data.dart';
import '../../../core/constants/power_code_data.dart';
import '../../../core/constants/prompt_flow_data.dart';
import '../../../core/constants/melody_style_data.dart';
import '../../../core/constants/real_instruments_data.dart';
import '../../../core/constants/song_structure_data.dart';
import '../../../core/constants/suno_structure_bracket_example.dart';
import '../../../core/constants/audio_environment_data.dart';
import '../../../core/constants/dialect_style_data.dart';
import '../../../core/constants/vocal_accent_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/suno_prompt_builder.dart';
import '../../../data/models/melody_variation_mode.dart';
import '../../../data/models/song_generation_type.dart';
import '../../../data/models/suno_field_output_mode.dart';
import '../../../data/models/track_duration_config.dart';
import '../../../data/models/user_input_model.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/feature_tool_card.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/recent_prompts_pro_tip_section.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/md_text_field.dart';
import '../../widgets/remix_form_widget.dart';
import '../../widgets/shell/main_shell.dart';

class PromptGeneratorScreen extends ConsumerStatefulWidget {
  const PromptGeneratorScreen({super.key});

  @override
  ConsumerState<PromptGeneratorScreen> createState() =>
      _PromptGeneratorScreenState();
}

class _PromptGeneratorScreenState extends ConsumerState<PromptGeneratorScreen> {
  final _vibe = TextEditingController();
  final _bpm = TextEditingController();
  final _refArtists = TextEditingController();
  final _avoid = TextEditingController();
  final _language = TextEditingController(text: 'English');
  final _vocalTone = TextEditingController();
  final _structureCustom = TextEditingController();
  final _lyrics = TextEditingController();
  final _realInstrumentals = TextEditingController();
  final _melodyCustom = TextEditingController();
  final _chordProgression = TextEditingController();
  final _lyricTheme = TextEditingController();
  final _remixSongTitle = TextEditingController();
  final _remixArtist = TextEditingController();

  String? _category;
  String? _primarySub;
  String? _fusionSub;
  String? _vocalChoice;
  String? _vocalAccent;
  String _dialectStyleId = DialectStyleData.standardEnglishId;
  String _dialectVariantId = DialectStyleData.generalVariantId;
  String _audioEnvironmentModeId = AudioEnvironmentData.studioIsolatedId;
  String? _keyRoot;
  String? _scale;
  bool _advanced = false;
  bool _analyserExpanded = true;

  /// `null` = show deduped list from all commercial genre buckets.
  String? _realInstrumentGenreFilter;

  String _melodyStyleId = MelodyStyleData.autoId;
  MelodyVariationMode _melodyVariationMode = MelodyVariationMode.none;

  TrackDuration _trackDuration = TrackDuration.s3_00;
  final _customDuration = TextEditingController();

  bool _generateLyrics = false;
  final Set<String> _temperamentPick = {};
  int _humanRealism = HumanRealismConfig.defaultLevel;
  int _productionIntensity = ProductionIntensityConfig.defaultLevel;
  String _genreFxLaneId = GenresConfig.autoLaneId;

  String? _moodTone;
  String? _eraScene;
  String? _grooveFeel;
  String? _vocalTonePreset;
  String? _languagePreset;
  String? _bpmPreset;
  SongGenerationType _songGenerationType = SongGenerationType.fullSong;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final form = ref.read(promptFormProvider);
      _hydrateFlowFieldsFromForm(form);
      _bpm.text = form.bpm ?? '';
      _refArtists.text = form.referenceArtists;
      _avoid.text = form.avoid;
      _hydrateLanguageField(form.language);
      _hydrateVocalToneField(form.vocalTone);
      _vocalChoice = form.vocalSpec;
      _vocalAccent = VocalAccentData.coerceStored(form.vocalAccent);
      _dialectStyleId = DialectStyleData.coerceId(form.dialectStyleId);
      _dialectVariantId = DialectStyleData.coerceVariantId(form.dialectVariantId);
      _audioEnvironmentModeId =
          AudioEnvironmentData.coerceId(form.audioEnvironmentModeId);
      _keyRoot = form.keyRoot;
      _scale = form.scale;
      if (form.primaryGenre.isNotEmpty) {
        _primarySub = form.primaryGenre;
      }
      _structureCustom.text = form.songStructureCustom;
      _lyrics.text = form.optionalLyrics;
      _realInstrumentals.text = form.realInstrumentals;
      _melodyStyleId = form.melodyStyleId.isEmpty
          ? MelodyStyleData.autoId
          : form.melodyStyleId;
      _melodyCustom.text = form.melodyCustomNotes;
      _melodyVariationMode = form.melodyVariationMode;
      _chordProgression.text = form.chordProgression;
      _generateLyrics = form.generateLyrics;
      _lyricTheme.text = form.lyricThemeNotes;
      _temperamentPick
        ..clear()
        ..addAll(_temperamentCodesFromString(form.lyricTemperamentCodes));
      _humanRealism = form.humanRealism;
      _productionIntensity = form.productionIntensity;
      _genreFxLaneId = form.genreFxLaneId;
      _remixSongTitle.text = form.remixOriginalSongTitle;
      _remixArtist.text = form.remixOriginalArtist;
      _songGenerationType = form.songGenerationType;
      if (form.sunoFieldOutputMode == SunoFieldOutputMode.simple) {
        _generateLyrics = false;
        _lyrics.clear();
      }
      _trackDuration = form.trackDuration;
      _customDuration.text = form.trackDuration == TrackDuration.custom
          ? (form.trackDurationLabel ?? '')
          : '';
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vibe.dispose();
    _bpm.dispose();
    _refArtists.dispose();
    _avoid.dispose();
    _language.dispose();
    _vocalTone.dispose();
    _structureCustom.dispose();
    _lyrics.dispose();
    _realInstrumentals.dispose();
    _melodyCustom.dispose();
    _chordProgression.dispose();
    _lyricTheme.dispose();
    _remixSongTitle.dispose();
    _remixArtist.dispose();
    _customDuration.dispose();
    super.dispose();
  }

  Set<String> _temperamentCodesFromString(String raw) {
    return {
      for (final p in raw.split(RegExp(r'\s+')))
        if (p.startsWith('/')) p,
    };
  }

  String _temperamentLine() {
    final ordered = [
      for (final c in PowerCodeData.codes)
        if (_temperamentPick.contains(c)) c,
      for (final c in LyricTemperamentData.codes)
        if (_temperamentPick.contains(c)) c,
    ];
    return ordered.join(' ');
  }

  void _toggleTemperament(String code) {
    hapticLight();
    setState(() {
      if (_temperamentPick.contains(code)) {
        _temperamentPick.remove(code);
      } else {
        _temperamentPick.add(code);
      }
    });
    ref
        .read(promptFormProvider.notifier)
        .setLyricTemperamentCodes(_temperamentLine());
  }

  Widget _buildHumanRealismSlider() {
    final level = HumanRealismConfig.clampLevel(_humanRealism);
    final band = HumanRealismConfig.bandLabel(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'HUMAN REALISM',
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$level',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          HumanRealismConfig.helperText,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accentPrimary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.accentPrimary,
            overlayColor: AppColors.accentPrimary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: level.toDouble(),
            min: HumanRealismConfig.minLevel.toDouble(),
            max: HumanRealismConfig.maxLevel.toDouble(),
            divisions: HumanRealismConfig.maxLevel,
            label: '$level',
            onChanged: (v) {
              final next = v.round();
              setState(() => _humanRealism = next);
              ref.read(promptFormProvider.notifier).setHumanRealism(next);
            },
          ),
        ),
        Text(
          band,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGenreFxSection() {
    final form = ref.watch(promptFormProvider);
    final level = ProductionIntensityConfig.clampLevel(_productionIntensity);
    final lane = GenresConfig.effectiveLaneId(
      genreFxLaneId: _genreFxLaneId,
      primaryGenre: form.primaryGenre.isNotEmpty
          ? form.primaryGenre
          : (_primarySub ?? ''),
      fusionGenre: form.subGenreFusion,
    );
    final laneMeta = GenresConfig.byId(lane);
    final laneLabel = _genreFxLaneId.isEmpty
        ? 'Auto → ${laneMeta?.label ?? lane}'
        : (GenresConfig.byId(_genreFxLaneId)?.label ?? _genreFxLaneId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENRE FX & ARRANGEMENT',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a production lane and FX intensity. Structural bracket tags are injected into your lyrics box so you can see the layout before generation.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _genreFxLaneId.isEmpty
                    ? GenresConfig.autoLaneId
                    : _genreFxLaneId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'FX genre lane',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                dropdownColor: AppColors.surfaceElevated,
                items: [
                  DropdownMenuItem(
                    value: GenresConfig.autoLaneId,
                    child: Text(
                      'Auto (match genre)',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  ...GenresConfig.appSupportedGenres.map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        g.label,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final next = v ?? GenresConfig.autoLaneId;
                  setState(() => _genreFxLaneId = next);
                  ref
                      .read(promptFormProvider.notifier)
                      .setGenreFxLaneId(next);
                  _applyFxLayoutToLyricsField();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'FX INTENSITY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$level',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accentPrimary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.accentPrimary,
                      overlayColor:
                          AppColors.accentPrimary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: level.toDouble(),
                      min: ProductionIntensityConfig.minLevel.toDouble(),
                      max: ProductionIntensityConfig.maxLevel.toDouble(),
                      divisions: ProductionIntensityConfig.maxLevel -
                          ProductionIntensityConfig.minLevel,
                      label: ProductionIntensityConfig.levelLabel(level),
                      onChanged: (v) {
                        final next = v.round();
                        setState(() => _productionIntensity = next);
                        ref
                            .read(promptFormProvider.notifier)
                            .setProductionIntensity(next);
                        _applyFxLayoutToLyricsField();
                      },
                    ),
                  ),
                  Text(
                    ProductionIntensityConfig.levelLabel(level),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Active lane: $laneLabel',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        if (lane == 'hardstyle' && level >= 2) ...[
          const SizedBox(height: 4),
          Text(
            level >= 3
                ? 'High FX injects [Monologue] cinematic openers + reverse-bass drop scaffolding.'
                : 'Hardstyle FX favors spoken [Monologue] manifestos over sung verses.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.accentPrimary.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  void _applyFxLayoutToLyricsField({bool syncProvider = true}) {
    if (ref.read(promptFormProvider).sunoFieldOutputMode ==
        SunoFieldOutputMode.simple) {
      return;
    }
    final form = ref.read(promptFormProvider);
    final lane = GenresConfig.effectiveLaneId(
      genreFxLaneId: _genreFxLaneId,
      primaryGenre: form.primaryGenre.isNotEmpty
          ? form.primaryGenre
          : (_primarySub ?? ''),
      fusionGenre: form.subGenreFusion,
    );
    final core = SunoPromptBuilder.stripFxLayout(_lyrics.text);
    final anchor = GenresConfig.fxLyricsAnchor(lane);
    final built = SunoPromptBuilder.buildSunoPrompt(
      baseStyle: '',
      baseLyrics: core.isEmpty ? anchor : core,
      primaryGenre: lane,
      intensity: _productionIntensity,
    );
    if (core.isEmpty && built.lyrics.trim() == anchor.trim()) {
      if (_lyrics.text.isNotEmpty) {
        _lyrics.clear();
        if (syncProvider) {
          ref.read(promptFormProvider.notifier).setOptionalLyrics('');
        }
      }
      return;
    }
    if (built.lyrics == core) return;
    _lyrics.text = built.lyrics;
    if (syncProvider) {
      ref.read(promptFormProvider.notifier).setOptionalLyrics(built.lyrics);
    }
  }

  void _appendChordSnippet(String insert) {
    final ins = insert.trim();
    if (ins.isEmpty) return;
    final cur = _chordProgression.text.trim();
    if (cur.contains(ins)) return;
    final next = cur.isEmpty ? ins : '$cur · $ins';
    _chordProgression.text = next;
    _chordProgression.selection =
        TextSelection.collapsed(offset: next.length);
    ref.read(promptFormProvider.notifier).setChordProgression(next);
    setState(() {});
  }

  void _appendRealInstrument(String label) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final nLabel = norm(label);
    final cur = _realInstrumentals.text.trim();
    final existing = cur
        .split(',')
        .map(norm)
        .where((e) => e.isNotEmpty)
        .toList();
    if (existing.any(
      (e) =>
          e == nLabel ||
          (e.contains(nLabel) && nLabel.length > 4) ||
          (nLabel.contains(e) && e.length > 4),
    )) {
      return;
    }
    final next = cur.isEmpty ? label : '$cur, $label';
    _realInstrumentals.text = next;
    _realInstrumentals.selection = TextSelection.collapsed(offset: next.length);
    ref.read(promptFormProvider.notifier).setRealInstrumentals(next);
    setState(() {});
  }

  void _syncGenreToNotifier() {
    final primary = _primarySub ?? '';
    final fusion = _fusionSub ?? '';
    ref.read(promptFormProvider.notifier).setGenreSelection(
          primary,
          fusion: fusion,
        );
  }

  String _presetIdOrFlexible(String id) {
    return SongStructureData.presetById(id) != null
        ? id
        : SongStructureData.flexibleId;
  }

  String _composedVibe() => PromptFlowData.composeVibe(
        mood: _moodTone,
        era: _eraScene,
        groove: _grooveFeel,
        detail: _vibe.text,
      );

  void _hydrateFlowFieldsFromForm(UserInputModel form) {
    final parsed = PromptFlowData.parseStoredVibe(form.vibe);
    _moodTone = parsed.mood;
    _eraScene = parsed.era;
    _grooveFeel = parsed.groove;
    _vibe.text = parsed.detail;
    _syncBpmPresetFromText(form.bpm);
  }

  void _hydrateVocalToneField(String? raw) {
    final coerced = PromptFlowData.coerceVocalTone(raw);
    if (coerced == PromptFlowData.customOption) {
      _vocalTonePreset = PromptFlowData.customOption;
      _vocalTone.text = raw ?? '';
    } else if (coerced != null) {
      _vocalTonePreset = coerced;
      _vocalTone.text = '';
    } else {
      _vocalTonePreset = null;
      _vocalTone.text = '';
    }
  }

  void _hydrateLanguageField(String raw) {
    final coerced = PromptFlowData.coerceLanguage(raw);
    if (coerced == PromptFlowData.customOption) {
      _languagePreset = PromptFlowData.customOption;
      _language.text = raw;
    } else {
      _languagePreset = coerced;
      _language.text = coerced ?? 'English';
    }
  }

  void _syncBpmPresetFromText(String? bpm) {
    final t = bpm?.trim() ?? '';
    if (t.isEmpty) {
      _bpmPreset = null;
      return;
    }
    final suggestions = PromptFlowData.bpmSuggestionsForGenre(
      _primarySub ?? _category,
    );
    if (suggestions.any((n) => n.toString() == t)) {
      _bpmPreset = t;
    } else {
      _bpmPreset = PromptFlowData.customOption;
    }
  }

  List<DropdownMenuItem<String>> _bpmDropdownItems() {
    final presets = PromptFlowData.bpmSuggestionsForGenre(
      _primarySub ?? _category,
    );
    return [
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Not set — model picks'),
      ),
      for (final n in presets)
        DropdownMenuItem<String>(
          value: n.toString(),
          child: Text('$n BPM'),
        ),
      const DropdownMenuItem<String>(
        value: PromptFlowData.customOption,
        child: Text('Custom…'),
      ),
    ];
  }

  /// Writes all controllers into [promptFormProvider] (used before navigate & generate).
  void _commitFormToProvider() {
    _syncGenreToNotifier();
    final n = ref.read(promptFormProvider.notifier);
    n.setTrackDuration(_trackDuration);
    String? resolvedLabel;
    if (_trackDuration == TrackDuration.custom) {
      final raw = _customDuration.text.trim();
      if (raw.isEmpty) {
        resolvedLabel = null;
      } else {
        final p = parseFlexibleDurationMinutes(raw);
        resolvedLabel = p != null ? formatMinutesToMmSs(p) : raw;
      }
    } else {
      resolvedLabel = _trackDuration.label;
    }
    n.setTrackDurationLabel(resolvedLabel);
    n.setVibe(_composedVibe());
    n.setBpm(_bpm.text.trim().isEmpty ? null : _bpm.text.trim());
    n.setKeyScale(root: _keyRoot, scale: _scale);
    final tone = PromptFlowData.vocalToneForCommit(
      preset: _vocalTonePreset,
      customText: _vocalTone.text,
    );
    n.setVocal(
      spec: _vocalChoice,
      tone: tone.isEmpty ? null : tone,
    );
    final instrumental =
        _vocalChoice == null || _vocalChoice == 'Instrumental Only';
    n.setVocalAccent(instrumental ? null : _vocalAccent);
    n.setDialectStyleId(
      instrumental ? DialectStyleData.standardEnglishId : _dialectStyleId,
    );
    n.setDialectVariantId(
      instrumental || !DialectStyleData.isNigerianPidgin(_dialectStyleId)
          ? DialectStyleData.generalVariantId
          : _dialectVariantId,
    );
    n.setAudioEnvironmentModeId(
      instrumental
          ? AudioEnvironmentData.studioIsolatedId
          : _audioEnvironmentModeId,
    );
    n.setReferenceArtists(_refArtists.text.trim());
    n.setAvoid(_avoid.text.trim());
    n.setLanguage(
      PromptFlowData.languageForCommit(
        preset: _languagePreset,
        customText: _language.text,
      ),
    );
    n.setSongStructureCustom(_structureCustom.text.trim());
    n.setRealInstrumentals(_realInstrumentals.text.trim());
    n.setMelodyStyleId(_melodyStyleId);
    n.setMelodyCustomNotes(_melodyCustom.text.trim());
    n.setMelodyVariationMode(_melodyVariationMode);
    n.setChordProgression(_chordProgression.text.trim());
    final mode = ref.read(promptFormProvider).sunoFieldOutputMode;
    if (mode == SunoFieldOutputMode.simple) {
      n.setOptionalLyrics('');
      n.setGenerateLyrics(false);
    } else {
      final lyricsTrim = _lyrics.text.trim();
      var genLyrics = _generateLyrics;
      if (lyricsTrim.isNotEmpty) genLyrics = false;
      n.setGenerateLyrics(genLyrics);
      if (genLyrics) {
        n.setOptionalLyrics('');
      } else {
        n.setOptionalLyrics(lyricsTrim);
      }
    }
    n.setLyricThemeNotes(_lyricTheme.text.trim());
    n.setLyricTemperamentCodes(_temperamentLine());
    n.setHumanRealism(_humanRealism);
    n.setProductionIntensity(_productionIntensity);
    n.setGenreFxLaneId(_genreFxLaneId);
    n.setRemixOriginalSongTitle(_remixSongTitle.text.trim());
    n.setRemixOriginalArtist(_remixArtist.text.trim());
    n.setSongGenerationType(_songGenerationType);
  }

  void _reloadControllersFromProvider() {
    final form = ref.read(promptFormProvider);
    setState(() {
      _hydrateFlowFieldsFromForm(form);
      _bpm.text = form.bpm ?? '';
      _refArtists.text = form.referenceArtists;
      _avoid.text = form.avoid;
      _hydrateLanguageField(form.language);
      _hydrateVocalToneField(form.vocalTone);
      _structureCustom.text = form.songStructureCustom;
      _lyrics.text = form.optionalLyrics;
      _realInstrumentals.text = form.realInstrumentals;
      _melodyStyleId = form.melodyStyleId.isEmpty
          ? MelodyStyleData.autoId
          : form.melodyStyleId;
      _melodyCustom.text = form.melodyCustomNotes;
      _melodyVariationMode = form.melodyVariationMode;
      _chordProgression.text = form.chordProgression;
      _generateLyrics = form.generateLyrics;
      _lyricTheme.text = form.lyricThemeNotes;
      _remixSongTitle.text = form.remixOriginalSongTitle;
      _remixArtist.text = form.remixOriginalArtist;
      _songGenerationType = form.songGenerationType;
      _temperamentPick
        ..clear()
        ..addAll(_temperamentCodesFromString(form.lyricTemperamentCodes));
      _humanRealism = form.humanRealism;
      _productionIntensity = form.productionIntensity;
      _genreFxLaneId = form.genreFxLaneId;
      _vocalChoice = form.vocalSpec;
      _vocalAccent = VocalAccentData.coerceStored(form.vocalAccent);
      _dialectStyleId = DialectStyleData.coerceId(form.dialectStyleId);
      _dialectVariantId = DialectStyleData.coerceVariantId(form.dialectVariantId);
      _audioEnvironmentModeId =
          AudioEnvironmentData.coerceId(form.audioEnvironmentModeId);
      _keyRoot = form.keyRoot;
      _scale = form.scale;
      if (form.primaryGenre.isNotEmpty) {
        _primarySub = form.primaryGenre;
        _category = GenreData.categoryForSubGenre(form.primaryGenre);
      }
      _fusionSub =
          form.subGenreFusion.isEmpty ? null : form.subGenreFusion;
      if (form.sunoFieldOutputMode == SunoFieldOutputMode.simple) {
        _generateLyrics = false;
        _lyrics.clear();
      }
      _trackDuration = form.trackDuration;
      _customDuration.text = form.trackDuration == TrackDuration.custom
          ? (form.trackDurationLabel ?? '')
          : '';
    });
  }

  Future<void> _openTemplates() async {
    _commitFormToProvider();
    final applied = await context.push<bool>('/templates');
    if (!mounted) return;
    if (applied == true) _reloadControllersFromProvider();
  }

  void _openBatchGenerate() {
    _commitFormToProvider();
    context.push('/batch-generate');
  }

  void _openAbCompare() {
    _commitFormToProvider();
    context.push('/ab-compare');
  }

  void _openQuickDescribe() {
    _commitFormToProvider();
    context.push('/quick-describe');
  }

  Future<void> _generate() async {
    _commitFormToProvider();

    final form = ref.read(promptFormProvider);
    if (form.primaryGenre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a primary sub-genre.')),
      );
      return;
    }
    if (form.vibe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a mood and/or describe your vibe / idea.'),
        ),
      );
      return;
    }
    if (form.trackDuration == TrackDuration.custom) {
      final ok = parseFlexibleDurationMinutes(form.trackDurationLabel) != null;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid custom duration (e.g. 3:45, 4 min, 180 for seconds).',
            ),
          ),
        );
        return;
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const _GeneratingDialog(),
    );

    try {
      final preferLight =
          ref.read(preferLightweightNextGenerationProvider);
      if (preferLight) {
        ref.read(preferLightweightNextGenerationProvider.notifier).state =
            false;
      }
      final text = await ref.read(aiRepositoryProvider).generatePrompt(
            ref.read(promptFormProvider),
            preferLightweightModel: preferLight,
          );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref.read(lastOutputGenerationInputProvider.notifier).state = form;
      context.push('/output', extra: {
        'prompt': text,
        'version': form.sunoVersion,
        'field_mode': form.sunoFieldOutputMode.name,
        'trusted_generation_input': true,
      });
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: ${dioErrorMessage(e)}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(promptFormProvider);
    final analysis = ref.watch(analysisResultProvider);
    final loadedDuration = ref.watch(audioDurationProvider);
    final bpmHint = GenreData.bpmHintForLabel(_primarySub ?? _category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prompt Generator'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Fields'),
                  content: const Text(
                    'Genre + vibe are required. Everything else steers Suno density, harmony, and mix intent.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(PhosphorIconsRegular.info),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MainShell.contentBottomPadding(context),
        ),
        children: [
          const RecentPromptsProTipSection(),
          const SizedBox(height: 18),
          _heroRow(context),
          const SizedBox(height: 14),
          _featureToolsRow(context),
          const SizedBox(height: 20),
          _versionRow(form),
          const SizedBox(height: 20),
          _sunoOutputModeRow(form),
          const SizedBox(height: 20),
          Text(
            'PRIMARY GENRE',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GenreData.categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = GenreData.categories[i];
                final sel = _category == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) {
                    hapticSelection();
                    setState(() {
                      _category = c;
                      _primarySub = null;
                      _fusionSub = null;
                    });
                  },
                  selectedColor: AppColors.accentPrimary.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          if (_category != null) ...[
            const SizedBox(height: 12),
            Text(
              'SUB-GENRE (pick primary + optional fusion)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s
                    in GenreData.subGenresByCategory[_category!] ?? const [])
                  Builder(
                    builder: (context) {
                      final isPrimary = _primarySub == s;
                      final isFusion = _fusionSub == s;
                      final active = isPrimary || isFusion;
                      return FilterChip(
                        label: Text(s),
                        selected: active,
                        onSelected: (_) {
                          hapticLight();
                          setState(() {
                            if (_primarySub == null || _primarySub == s) {
                              _primarySub = _primarySub == s ? null : s;
                            } else if (_fusionSub == s) {
                              _fusionSub = null;
                            } else if (_fusionSub == null && s != _primarySub) {
                              _fusionSub = s;
                            } else {
                              _primarySub = s;
                              _fusionSub = null;
                            }
                            if (_primarySub != null) {
                              ref
                                  .read(promptFormProvider.notifier)
                                  .setGenreSelection(
                                    _primarySub!,
                                    fusion: _fusionSub ?? '',
                                  );
                              if (_genreFxLaneId.isEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) _applyFxLayoutToLyricsField();
                                });
                              }
                            }
                            _syncBpmPresetFromText(_bpm.text);
                          });
                        },
                        selectedColor:
                            AppColors.accentPrimary.withValues(alpha: 0.35),
                        checkmarkColor: AppColors.textPrimary,
                        labelStyle: TextStyle(
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'QUICK START',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GenreData.quickPickRows.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final row = GenreData.quickPickRows[i];
                final label = row.$1;
                final value = row.$2;
                return ActionChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    hapticLight();
                    setState(() => _primarySub = value);
                    ref.read(promptFormProvider.notifier).setGenreSelection(value);
                  },
                  backgroundColor: AppColors.surfaceElevated,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          RemixFormWidget(
            songTitleController: _remixSongTitle,
            artistController: _remixArtist,
            generationType: _songGenerationType,
            onGenerationTypeChanged: (mode) {
              setState(() => _songGenerationType = mode);
              ref.read(promptFormProvider.notifier).setSongGenerationType(mode);
            },
            onFieldChanged: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TARGET LENGTH',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Standard lengths set the Suno prompt target; Custom accepts formats like 3:45, 4 min, or 210 (seconds).',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in TrackDuration.values)
                      ChoiceChip(
                        label: Text(
                          d == TrackDuration.custom ? 'Custom' : d.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _trackDuration == d,
                        onSelected: (_) {
                          hapticLight();
                          setState(() => _trackDuration = d);
                          ref.read(promptFormProvider.notifier).setTrackDuration(d);
                        },
                        selectedColor:
                            AppColors.accentPrimary.withValues(alpha: 0.35),
                        checkmarkColor: AppColors.textPrimary,
                        labelStyle: TextStyle(
                          color: _trackDuration == d
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (_trackDuration == TrackDuration.custom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customDuration,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Custom duration',
                      hintText: 'e.g. 3:45 · 4 min · 180',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  loadedDuration != null && loadedDuration > Duration.zero
                      ? 'Reference (loaded audio): ${formatTrackDuration(loadedDuration)} — target above is what the prompt uses.'
                      : 'Load audio in the Analyzer to see reference length; target above is still sent to the model.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'DJ MIXING (SUNO PROMPT)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Optional DJ-friendly intro/outro language in the generated Suno prompt.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DJ intro (mix-in)'),
                  subtitle: Text(
                    'Describe a long blend-friendly intro (previous → this track)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  value: form.djIntroMixIn,
                  onChanged: (v) =>
                      ref.read(promptFormProvider.notifier).setDjIntroMixIn(v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DJ outro (mix-out)'),
                  subtitle: Text(
                    'Describe a long blend-friendly outro (this track → next)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  value: form.djOutroMixOut,
                  onChanged: (v) =>
                      ref.read(promptFormProvider.notifier).setDjOutroMixOut(v),
                ),
                const SizedBox(height: 16),
                Text(
                  'SONG STRUCTURE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The generated Suno prompt will follow this roadmap — same order, no mixed-up sections. '
                  'For Custom, use bracket lines like [Verse] and (staging notes) so Suno does not read the outline as lyrics.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _presetIdOrFlexible(form.songStructurePresetId),
                  decoration: const InputDecoration(
                    labelText: 'Arrangement',
                  ),
                  items: [
                    for (final p in SongStructureData.presets)
                      DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.label),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    hapticLight();
                    ref.read(promptFormProvider.notifier).setSongStructurePreset(v);
                  },
                ),
                Builder(
                  builder: (context) {
                    final id = _presetIdOrFlexible(form.songStructurePresetId);
                    final preset = SongStructureData.presetById(id);
                    if (preset == null) return const SizedBox.shrink();
                    if (preset.id == SongStructureData.flexibleId) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'One coherent layout; sections named in order through the prompt.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            height: 1.35,
                          ),
                        ),
                      );
                    }
                    if (preset.id == SongStructureData.customId) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                hapticLight();
                                final t = kSunoBracketStructureExampleFull;
                                _structureCustom.text = t;
                                _structureCustom.selection =
                                    TextSelection.collapsed(offset: t.length);
                                ref
                                    .read(promptFormProvider.notifier)
                                    .setSongStructureCustom(t);
                              },
                              icon: Icon(
                                PhosphorIconsRegular.copy,
                                size: 18,
                                color: AppColors.accentPrimary,
                              ),
                              label: Text(
                                'Paste bracket template (EDM example)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ),
                          MdTextField(
                            controller: _structureCustom,
                            label: 'CUSTOM SECTION ORDER',
                            hint:
                                '[Intro]\n(staging notes)\n[Verse]\n… or plain: Intro → Verse → Chorus → Outro',
                            maxLines: 14,
                            maxLength: 2000,
                            onChanged: (t) => ref
                                .read(promptFormProvider.notifier)
                                .setSongStructureCustom(t),
                          ),
                        ],
                      );
                    }
                    if (preset.sectionOrder.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Roadmap: ${preset.sectionOrder}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (form.sunoFieldOutputMode == SunoFieldOutputMode.simple) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      'Simple Mode uses Suno’s single Description field (same prose budget: 130–150 words, ≤1000 characters). '
                      'Switch to Custom for Style + Lyrics.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildHumanRealismSlider(),
                const SizedBox(height: 16),
                _buildGenreFxSection(),
                const SizedBox(height: 16),
                Opacity(
                  opacity: form.sunoFieldOutputMode == SunoFieldOutputMode.simple
                      ? 0.48
                      : 1,
                  child: AbsorbPointer(
                    absorbing: form.sunoFieldOutputMode ==
                        SunoFieldOutputMode.simple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LYRICS (OPTIONAL)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Every run returns Block 1 (Style / Description — 130–150 words, ≤1000 chars) + Block 2 (Lyrics field: structure and, for vocal genres, lines). '
                          'Leave empty to let the model fill Block 2 from your genre and vibe (instrumental sections when it fits). '
                          'Add “style only” or “no lyrics” in Vibe if you truly want Block 1 alone.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MdTextField(
                          controller: _lyrics,
                          label: 'YOUR LYRICS',
                          hint: 'Paste draft lyrics or poem lines…',
                          maxLines: 10,
                          maxLength: 8000,
                          onChanged: (t) {
                            if (t.trim().isNotEmpty && _generateLyrics) {
                              setState(() => _generateLyrics = false);
                            }
                            ref
                                .read(promptFormProvider.notifier)
                                .setOptionalLyrics(t);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Generate original lyrics (Path C)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Elite Human Lyricist + Human Realism slider + optional temperament. Turn off to paste lyrics above. '
                            'V2 master prompt is on by default; set USE_SUNO_PROMPT_V2=false in .env for legacy word-budget only.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: _generateLyrics,
                          onChanged: (v) {
                            hapticLight();
                            setState(() {
                              _generateLyrics = v;
                              if (v) {
                                _lyrics.clear();
                                ref
                                    .read(promptFormProvider.notifier)
                                    .setOptionalLyrics('');
                              }
                            });
                          },
                        ),
                        if (_generateLyrics) ...[
                          MdTextField(
                            controller: _lyricTheme,
                            label: 'LYRIC THEME / STORY (OPTIONAL)',
                            hint:
                                'What the song is about — POV, setting, who it is for, images to include…',
                            maxLines: 4,
                            maxLength: 1200,
                            onChanged: (t) => ref
                                .read(promptFormProvider.notifier)
                                .setLyricThemeNotes(t),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TEMPERAMENT (OPTIONAL)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final c in LyricTemperamentData.codes)
                                FilterChip(
                                  label: Text(
                                    LyricTemperamentData.labelFor(c),
                                    style: GoogleFonts.inter(fontSize: 11),
                                  ),
                                  selected: _temperamentPick.contains(c),
                                  onSelected: (_) => _toggleTemperament(c),
                                  selectedColor: AppColors.accentPrimary
                                      .withValues(alpha: 0.35),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MOOD & VIBE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick tone anchors from the menus, then add scene or story detail below.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'POWER CODES (OPTIONAL)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in PowerCodeData.codes)
                      FilterChip(
                        label: Text(
                          PowerCodeData.labelFor(c),
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        tooltip: PowerCodeData.hintFor(c),
                        selected: _temperamentPick.contains(c),
                        onSelected: (_) => _toggleTemperament(c),
                        selectedColor:
                            AppColors.accentPrimary.withValues(alpha: 0.35),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        // ignore: deprecated_member_use
                        value: _moodTone,
                        decoration: const InputDecoration(
                          labelText: 'Mood / emotional tone',
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not set'),
                          ),
                          for (final m in PromptFlowData.moodTones)
                            DropdownMenuItem<String?>(
                              value: m,
                              child: Text(m),
                            ),
                        ],
                        onChanged: (v) {
                          hapticLight();
                          setState(() => _moodTone = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        // ignore: deprecated_member_use
                        value: _eraScene,
                        decoration: const InputDecoration(
                          labelText: 'Era / scene (optional)',
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not set'),
                          ),
                          for (final e in PromptFlowData.eraScenes)
                            DropdownMenuItem<String?>(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) {
                          hapticLight();
                          setState(() => _eraScene = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _grooveFeel,
                  decoration: const InputDecoration(
                    labelText: 'Groove feel (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not set'),
                    ),
                    for (final g in PromptFlowData.grooveFeels)
                      DropdownMenuItem<String?>(
                        value: g,
                        child: Text(g),
                      ),
                  ],
                  onChanged: (v) {
                    hapticLight();
                    setState(() => _grooveFeel = v);
                  },
                ),
                const SizedBox(height: 10),
                MdTextField(
                  controller: _vibe,
                  label: 'VIBE / IDEA (scene, story, concept)',
                  hint:
                      'e.g. late-night drive after the show, rooftop summer, breakup voicemail…',
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  'REAL / ACOUSTIC INSTRUMENTS (OPTIONAL)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Genre-accurate live instrument picks (articulation + mix role baked in). '
                  'Chips match your primary/fusion genre — or pick from All.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _realInstrumentGenreFilter,
                  decoration: const InputDecoration(
                    labelText: 'Instrument filter',
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        _primarySub == null || _primarySub!.isEmpty
                            ? 'All — every distinct instrument'
                            : 'Genre match — $_primarySub',
                      ),
                    ),
                    const DropdownMenuItem<String?>(
                      value: '__all__',
                      child: Text('All — every distinct instrument'),
                    ),
                  ],
                  onChanged: (v) {
                    hapticLight();
                    setState(() => _realInstrumentGenreFilter = v);
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final pick in _realInstrumentGenreFilter == '__all__'
                        ? RealInstrumentsData.quickPicks
                        : RealInstrumentsData.instrumentsForGenre(
                            _primarySub ?? '',
                            _fusionSub ?? '',
                          ))
                      ActionChip(
                        label: Text(
                          pick,
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          hapticLight();
                          _appendRealInstrument(pick);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                MdTextField(
                  controller: _realInstrumentals,
                  label: 'INSTRUMENTS LIST',
                  hint:
                      'e.g. Wurlitzer Electric Piano, Fender Jazz Bass — articulation injected per Suno version',
                  maxLines: 3,
                  maxLength: 400,
                  onChanged: (t) => ref
                      .read(promptFormProvider.notifier)
                      .setRealInstrumentals(t),
                ),
                const SizedBox(height: 20),
                Text(
                  'CHORD PROGRESSION (OPTIONAL)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Locks harmony into the model output: numerals, chord symbols, or a bar map. '
                  'Pick a chip or type your own; set Key/scale above when it matters.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final q in ChordProgressionData.quickPicks)
                      ActionChip(
                        label: Text(
                          q.label,
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          hapticLight();
                          _appendChordSnippet(q.insert);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                MdTextField(
                  controller: _chordProgression,
                  label: 'CHORDS / HARMONY',
                  hint:
                      'e.g. I–V–vi–IV · or Dm7–G7–Cmaj7 · or 4 bars each on I, vi, IV, V',
                  maxLines: 3,
                  maxLength: 300,
                  onChanged: (t) => ref
                      .read(promptFormProvider.notifier)
                      .setChordProgression(t),
                ),
                const SizedBox(height: 20),
                Text(
                  'MELODY (OPTIONAL)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Steers melodic contour and phrasing. Session variation adds a different angle on each generate '
                  '(useful with Batch or multiple runs). Rotate remembers order; Random picks fresh each time.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _melodyStyleId == MelodyStyleData.customId ||
                          MelodyStyleData.presetById(_melodyStyleId) != null
                      ? _melodyStyleId
                      : MelodyStyleData.autoId,
                  decoration: const InputDecoration(
                    labelText: 'Melody style',
                  ),
                  items: [
                    for (final p in MelodyStyleData.presets)
                      DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.label),
                      ),
                    const DropdownMenuItem<String>(
                      value: MelodyStyleData.customId,
                      child: Text('Custom (write your own)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    hapticLight();
                    setState(() => _melodyStyleId = v);
                    ref.read(promptFormProvider.notifier).setMelodyStyleId(v);
                  },
                ),
                if (_melodyStyleId == MelodyStyleData.customId) ...[
                  const SizedBox(height: 10),
                  MdTextField(
                    controller: _melodyCustom,
                    label: 'CUSTOM MELODY NOTES',
                    hint:
                        'e.g. Narrow range verses, octave leap on hook, staccato chant…',
                    maxLines: 3,
                    maxLength: 400,
                    onChanged: (t) => ref
                        .read(promptFormProvider.notifier)
                        .setMelodyCustomNotes(t),
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<MelodyVariationMode>(
                  // ignore: deprecated_member_use
                  value: _melodyVariationMode,
                  decoration: const InputDecoration(
                    labelText: 'Melody variation (multi-prompt sessions)',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MelodyVariationMode.none,
                      child: Text('Off — only melody style above'),
                    ),
                    DropdownMenuItem(
                      value: MelodyVariationMode.rotate,
                      child: Text('Rotate — cycle angles each generation'),
                    ),
                    DropdownMenuItem(
                      value: MelodyVariationMode.random,
                      child: Text('Random — new angle each generation'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    hapticLight();
                    setState(() => _melodyVariationMode = v);
                    ref
                        .read(promptFormProvider.notifier)
                        .setMelodyVariationMode(v);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _bpmPreset ?? '',
                  decoration: InputDecoration(
                    labelText: 'BPM (optional)',
                    helperText: bpmHint != null ? 'Genre hint: $bpmHint' : null,
                  ),
                  isExpanded: true,
                  items: _bpmDropdownItems(),
                  onChanged: (v) {
                    if (v == null) return;
                    hapticLight();
                    setState(() {
                      if (v.isEmpty) {
                        _bpmPreset = null;
                        _bpm.clear();
                      } else if (v == PromptFlowData.customOption) {
                        _bpmPreset = PromptFlowData.customOption;
                      } else {
                        _bpmPreset = v;
                        _bpm.text = v;
                      }
                    });
                  },
                ),
                if (_bpmPreset == PromptFlowData.customOption) ...[
                  const SizedBox(height: 10),
                  MdTextField(
                    controller: _bpm,
                    label: 'CUSTOM BPM',
                    hint: 'e.g. 128',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Advanced options',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  initiallyExpanded: _advanced,
                  onExpansionChanged: (v) => setState(() => _advanced = v),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _keyRoot,
                            decoration: const InputDecoration(
                              labelText: 'Key',
                            ),
                            items: [
                              for (final k in _keys)
                                DropdownMenuItem(value: k, child: Text(k)),
                            ],
                            onChanged: (v) => setState(() => _keyRoot = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _scale,
                            decoration: const InputDecoration(
                              labelText: 'Scale',
                            ),
                            items: [
                              for (final s in _scales)
                                DropdownMenuItem(value: s, child: Text(s)),
                            ],
                            onChanged: (v) => setState(() => _scale = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VOCAL SPEC',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final v in _vocals)
                          ChoiceChip(
                            label: Text(v, style: const TextStyle(fontSize: 12)),
                            selected: _vocalChoice == v,
                            onSelected: (_) {
                              final form = ref.read(promptFormProvider);
                              setState(() {
                                _vocalChoice = v;
                                if (v == 'Instrumental Only') {
                                  _vocalAccent = null;
                                  _dialectStyleId =
                                      DialectStyleData.standardEnglishId;
                                  _dialectVariantId =
                                      DialectStyleData.generalVariantId;
                                }
                              });
                              ref.read(promptFormProvider.notifier).setVocal(
                                    spec: v,
                                    tone: form.vocalTone,
                                  );
                              if (v == 'Instrumental Only') {
                                ref
                                    .read(promptFormProvider.notifier)
                                    .setVocalAccent(null);
                                ref
                                    .read(promptFormProvider.notifier)
                                    .setDialectStyleId(
                                      DialectStyleData.standardEnglishId,
                                    );
                                ref
                                    .read(promptFormProvider.notifier)
                                    .setDialectVariantId(
                                      DialectStyleData.generalVariantId,
                                    );
                              }
                            },
                            selectedColor:
                                AppColors.accentPrimary.withValues(alpha: 0.35),
                          ),
                      ],
                    ),
                    if (_vocalChoice != null &&
                        _vocalChoice != 'Instrumental Only') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        // ignore: deprecated_member_use
                        value: _vocalTonePreset,
                        decoration: const InputDecoration(
                          labelText: 'Vocal tone (optional)',
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not set — infer from genre'),
                          ),
                          for (final t in PromptFlowData.vocalTones)
                            DropdownMenuItem<String?>(
                              value: t,
                              child: Text(t),
                            ),
                          const DropdownMenuItem<String?>(
                            value: PromptFlowData.customOption,
                            child: Text('Custom…'),
                          ),
                        ],
                        onChanged: (v) {
                          hapticLight();
                          setState(() {
                            _vocalTonePreset = v;
                            if (v != null && v != PromptFlowData.customOption) {
                              _vocalTone.clear();
                            }
                          });
                        },
                      ),
                      if (_vocalTonePreset == PromptFlowData.customOption) ...[
                        const SizedBox(height: 8),
                        MdTextField(
                          controller: _vocalTone,
                          label: 'CUSTOM VOCAL TONE',
                          hint: 'e.g. gravelly baritone, falsetto hook',
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        // ignore: deprecated_member_use
                        value: _vocalAccent,
                        decoration: const InputDecoration(
                          labelText: 'SINGER ACCENT / DELIVERY (OPTIONAL)',
                          helperText:
                              'Pronunciation & cadence as production style — not voice cloning.',
                        ),
                        isExpanded: true,
                        items: [
                          for (final a in VocalAccentData.dropdownValues)
                            DropdownMenuItem<String?>(
                              value: a,
                              child: Text(
                                VocalAccentData.menuLabel(a),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() => _vocalAccent = v);
                          ref
                              .read(promptFormProvider.notifier)
                              .setVocalAccent(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _dialectStyleId,
                        decoration: const InputDecoration(
                          labelText: 'LYRIC DIALECT / LANGUAGE MODE',
                          helperText:
                              'Nigerian Pidgin writes verses natively in West African Pidgin — staging tags stay in brackets.',
                        ),
                        isExpanded: true,
                        items: [
                          for (final o in DialectStyleData.options)
                            DropdownMenuItem<String>(
                              value: o.id,
                              child: Text(
                                o.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          hapticLight();
                          setState(() {
                            _dialectStyleId = v;
                            if (!DialectStyleData.isNigerianPidgin(v)) {
                              _dialectVariantId =
                                  DialectStyleData.generalVariantId;
                            }
                          });
                          ref
                              .read(promptFormProvider.notifier)
                              .setDialectStyleId(v);
                          if (!DialectStyleData.isNigerianPidgin(v)) {
                            ref
                                .read(promptFormProvider.notifier)
                                .setDialectVariantId(
                                  DialectStyleData.generalVariantId,
                                );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: AudioEnvironmentData.coerceId(
                          _audioEnvironmentModeId,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'AUDIO ENVIRONMENT / LIVE MODE',
                          helperText:
                              'Studio = dead-room isolation, no crowd. Live Arena = stadium cheers and sing-along.',
                        ),
                        isExpanded: true,
                        items: [
                          for (final o in AudioEnvironmentData.options)
                            DropdownMenuItem<String>(
                              value: o.id,
                              child: Text(
                                o.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          hapticLight();
                          setState(() => _audioEnvironmentModeId = v);
                          ref
                              .read(promptFormProvider.notifier)
                              .setAudioEnvironmentModeId(v);
                        },
                      ),
                      if (DialectStyleData.isNigerianPidgin(_dialectStyleId)) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: DialectStyleData.coerceVariantId(
                            _dialectVariantId,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'REGIONAL DIALECT FLAVOR',
                            helperText:
                                'Ibibio, Efik, Yoruba, Igbo, Hausa, Urhobo — inflection on Nigerian Pidgin lyrics.',
                          ),
                          isExpanded: true,
                          items: [
                            for (final v in DialectStyleData.pidginVariants)
                              DropdownMenuItem<String>(
                                value: v.id,
                                child: Text(
                                  v.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            hapticLight();
                            setState(() => _dialectVariantId = v);
                            ref
                                .read(promptFormProvider.notifier)
                                .setDialectVariantId(v);
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'REFERENCE (OPTIONAL)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sonic cues, era, your catalog codename, and/or optional artist names. '
                      'Some hosts (including Suno) may restrict famous names — production tags are safest.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MdTextField(
                      controller: _refArtists,
                      label: 'TEXT',
                      hint:
                          'e.g. late-90s R&B mix, dry rap upfront, my EP NX-07 — or optional: …',
                      onChanged: (t) => ref
                          .read(promptFormProvider.notifier)
                          .setReferenceArtists(t),
                    ),
                    if (_primarySub != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Production tags',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final a in GenreData.sonicReferenceChipsForGenre(
                              _primarySub,
                            ))
                              ActionChip(
                                label: Text(
                                  a,
                                  style: GoogleFonts.inter(fontSize: 11),
                                ),
                                onPressed: () {
                                  final t = _refArtists.text.trim();
                                  final next = t.isEmpty ? a : '$t, $a';
                                  _refArtists.text = next;
                                  ref
                                      .read(promptFormProvider.notifier)
                                      .setReferenceArtists(next);
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Optional artist names',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final a in GenreData.optionalArtistNameChipsForGenre(
                              _primarySub,
                            ))
                              ActionChip(
                                label: Text(
                                  a,
                                  style: GoogleFonts.inter(fontSize: 11),
                                ),
                                onPressed: () {
                                  hapticLight();
                                  final t = _refArtists.text.trim();
                                  final next = t.isEmpty ? a : '$t, $a';
                                  _refArtists.text = next;
                                  ref
                                      .read(promptFormProvider.notifier)
                                      .setReferenceArtists(next);
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    MdTextField(
                      controller: _avoid,
                      label: 'AVOID (OPTIONAL)',
                      hint: 'e.g. no trap hi-hats, no clipping',
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Steer away (Part G — woven into Block 1)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final chip in NegativeStyleDescriptors.chips)
                          ActionChip(
                            label: Text(
                              chip.$1,
                              style: GoogleFonts.inter(fontSize: 11),
                            ),
                            onPressed: () {
                              hapticLight();
                              final next = NegativeStyleDescriptors.mergeIntoAvoid(
                                _avoid.text,
                                chip.$2,
                              );
                              _avoid.text = next;
                              ref
                                  .read(promptFormProvider.notifier)
                                  .setAvoid(next);
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: _languagePreset ?? 'English',
                      decoration: const InputDecoration(
                        labelText: 'Language',
                      ),
                      isExpanded: true,
                      items: [
                        for (final lang in PromptFlowData.languages)
                          DropdownMenuItem<String?>(
                            value: lang,
                            child: Text(lang),
                          ),
                        const DropdownMenuItem<String?>(
                          value: PromptFlowData.customOption,
                          child: Text('Other…'),
                        ),
                      ],
                      onChanged: (v) {
                        hapticLight();
                        setState(() {
                          _languagePreset = v;
                          if (v != null && v != PromptFlowData.customOption) {
                            _language.text = v;
                          }
                        });
                        if (v != null && v != PromptFlowData.customOption) {
                          ref.read(promptFormProvider.notifier).setLanguage(v);
                        }
                      },
                    ),
                    if (_languagePreset == PromptFlowData.customOption) ...[
                      const SizedBox(height: 8),
                      MdTextField(
                        controller: _language,
                        label: 'CUSTOM LANGUAGE',
                        hint: 'e.g. Igbo, Tagalog',
                        onChanged: (t) => ref
                            .read(promptFormProvider.notifier)
                            .setLanguage(t.trim().isEmpty ? 'English' : t),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            initiallyExpanded: _analyserExpanded,
            onExpansionChanged: (v) => setState(() => _analyserExpanded = v),
            backgroundColor: AppColors.surface,
            collapsedBackgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Use Audio Analyser Data',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: analysis == null
                ? const Text('No analysis yet')
                : Text(analysis.genre ?? 'Analysis loaded'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (analysis == null)
                      TextButton(
                        onPressed: () => context.go('/analyzer'),
                        child: const Text('Go to Audio Analyser →'),
                      )
                    else ...[
                      Text(
                        analysis.toPromptSummary(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include in prompt generation'),
                        value: form.includeAnalyzerData,
                        onChanged: (v) {
                          ref
                              .read(promptFormProvider.notifier)
                              .setIncludeAnalyzer(v);
                          if (v) {
                            ref
                                .read(promptFormProvider.notifier)
                                .setAnalyzerSummary(
                                  analysis.toPromptSummary(),
                                );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'GENERATE PROMPT',
            icon: PhosphorIconsRegular.magicWand,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }

  Widget _featureToolsRow(BuildContext context) {
    const gold = Color(0xFFFFCA28);
    Widget card({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return FeatureToolCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        onTap: () {
          hapticLight();
          onTap();
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final tiles = [
          card(
            icon: PhosphorIconsRegular.star,
            iconColor: gold,
            title: 'Templates',
            subtitle: 'Pre-built prompt configurations',
            onTap: _openTemplates,
          ),
          card(
            icon: PhosphorIconsRegular.chartBar,
            iconColor: const Color(0xFF42A5F5),
            title: 'Batch generate',
            subtitle: 'Create multiple prompts at once',
            onTap: _openBatchGenerate,
          ),
          card(
            icon: PhosphorIconsRegular.scales,
            iconColor: gold,
            title: 'A / B compare',
            subtitle: 'Compare prompts side-by-side',
            onTap: _openAbCompare,
          ),
          card(
            icon: PhosphorIconsRegular.textAa,
            iconColor: const Color(0xFF26A69A),
            title: 'Quick describe',
            subtitle: 'One paragraph → full Suno prompt',
            onTap: _openQuickDescribe,
          ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                SizedBox(width: 168, child: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _heroRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            accentBorder: true,
            padding: const EdgeInsets.all(14),
            onTap: () {
              hapticLight();
              context.go('/analyzer');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsRegular.waveform, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Analyze Audio',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Upload / record',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            onTap: () {
              hapticLight();
              context.go('/history');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsRegular.clock, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Saved prompts',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sunoOutputModeRow(UserInputModel form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUNO FIELD MODE',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<SunoFieldOutputMode>(
          segments: const [
            ButtonSegment<SunoFieldOutputMode>(
              value: SunoFieldOutputMode.custom,
              label: Text('Custom'),
              icon: Icon(PhosphorIconsRegular.slidersHorizontal),
            ),
            ButtonSegment<SunoFieldOutputMode>(
              value: SunoFieldOutputMode.simple,
              label: Text('Simple'),
              icon: Icon(PhosphorIconsRegular.article),
            ),
          ],
          selected: {form.sunoFieldOutputMode},
          onSelectionChanged: (s) {
            final m = s.first;
            hapticLight();
            ref.read(promptFormProvider.notifier).setSunoFieldOutputMode(m);
            if (m == SunoFieldOutputMode.simple) {
              setState(() {
                _generateLyrics = false;
                _lyrics.clear();
              });
              ref.read(promptFormProvider.notifier)
                ..setGenerateLyrics(false)
                ..setOptionalLyrics('');
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          form.sunoFieldOutputMode == SunoFieldOutputMode.custom
              ? 'Custom: Style — producer prose (130–150 words, ≤1000 chars) + optional Lyrics (≤2500 chars).'
              : 'Simple: Description — same prose budget (130–150 words, ≤1000 chars; no lyrics block).',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _versionRow(UserInputModel form) {
    const versions = ['v4.5', 'v5.0', 'v5.5'];
    const hints = {
      'v4.5': 'Tier feel: dense; V2 Block 1 size = Custom/Simple caps (not this chip)',
      'v5.0': 'Balanced tier; lyrics/detail depth — Block 1 char cap unchanged',
      'v5.5': 'Richer lyric arcs; Block 2 up to 2500 characters',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUNO VERSION',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final v in versions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: hints[v]!,
                  child: ChoiceChip(
                    label: Text(v),
                    selected: form.sunoVersion == v,
                    onSelected: (_) {
                      hapticLight();
                      ref.read(promptFormProvider.notifier).setSunoVersion(v);
                    },
                    selectedColor: AppColors.accentPrimary,
                    labelStyle: TextStyle(
                      color: form.sunoVersion == v
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static const _keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const _scales = [
    'Major',
    'Minor',
    'Dorian',
    'Phrygian',
    'Lydian',
    'Mixolydian',
    'Aeolian',
    'Locrian',
    'Harmonic Minor',
    'Pentatonic Minor',
  ];

  static const _vocals = [
    'Male Lead',
    'Female Lead',
    'Dual Lead',
    'Rap Vocal Space',
    'Gospel Choir',
    "Children's Choir",
    'Instrumental Only',
  ];
}

class _GeneratingDialog extends StatelessWidget {
  const _GeneratingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.accentPrimary),
              const SizedBox(height: 16),
              Text(
                'Gemini 2.5 Flash (draft + polish)\n'
                'This usually takes 1–4 minutes. Please keep the app open.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
