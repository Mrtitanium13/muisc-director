import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/constants/production_intensity_config.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/genre_fx_sync.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/glass_card.dart';

/// Dedicated Genre FX card — lane + intensity with a separate FX layout box.
class GenreFxSection extends ConsumerStatefulWidget {
  const GenreFxSection({super.key});

  @override
  ConsumerState<GenreFxSection> createState() => _GenreFxSectionState();
}

class _GenreFxSectionState extends ConsumerState<GenreFxSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncFxLayoutPreview(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(promptFormProvider);
    final productionIntensity = ref.watch(productionIntensityLevelProvider);
    final genreFxLaneId = ref.watch(genreFxLaneIdProvider);
    final primarySub = ref.watch(selectedPrimarySubProvider);

    final level = ProductionIntensityConfig.clampLevel(productionIntensity);
    final isAuto =
        genreFxLaneId.trim().isEmpty || genreFxLaneId.trim().toLowerCase() == 'auto';
    final lane = GenresConfig.effectiveLaneId(
      genreFxLaneId: genreFxLaneId,
      primaryGenre: form.primaryGenre.isNotEmpty
          ? form.primaryGenre
          : (primarySub ?? ''),
      fusionGenre: form.subGenreFusion,
    );
    final laneMeta = GenresConfig.byId(lane);
    final selectedLaneLabel = isAuto
        ? 'Auto (match genre)'
        : (GenresConfig.byId(genreFxLaneId)?.label ?? genreFxLaneId);
    final resolvedLaneLabel = laneMeta?.label ?? lane;
    final resolvedCategory = laneMeta?.category ?? '';

    final dropdownValue = () {
      final raw = genreFxLaneId.trim().toLowerCase();
      if (raw.isEmpty || raw == 'auto') return GenresConfig.autoLaneId;
      final known = GenresConfig.appSupportedGenres.any((g) => g.id == raw);
      return known ? raw : GenresConfig.autoLaneId;
    }();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            'Pick a production lane and FX intensity. Arrangement tags appear in '
            'YOUR FX LAYOUT below — your lyrics stay in the Lyrics box.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _SelectedFxSettingsBox(
            laneMode: isAuto ? 'Auto' : 'Manual',
            selectedLane: selectedLaneLabel,
            resolvedLane: resolvedLaneLabel,
            category: resolvedCategory,
            intensityLevel: level,
            intensityLabel: ProductionIntensityConfig.levelLabel(level),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: dropdownValue,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) {
              final next = v ?? GenresConfig.autoLaneId;
              ref.read(genreFxLaneIdProvider.notifier).state = next;
              ref.read(promptFormProvider.notifier).setGenreFxLaneId(next);
              applyFxLayoutToLyricsField(ref);
            },
          ),
          const SizedBox(height: 14),
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
                '$level — ${ProductionIntensityConfig.levelLabel(level)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.creodomeCyan,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentTertiary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.creodomeCyan,
              overlayColor: AppColors.accentTertiary.withValues(alpha: 0.16),
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
                ref.read(productionIntensityLevelProvider.notifier).state = next;
                ref.read(promptFormProvider.notifier).setProductionIntensity(next);
                applyFxLayoutToLyricsField(ref);
              },
            ),
          ),
          Text(
            ProductionIntensityConfig.helperText,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
          if (lane == 'hardstyle' && level >= 2) ...[
            const SizedBox(height: 8),
            Text(
              level >= 3
                  ? 'High FX injects [Monologue] cinematic openers + reverse-bass drop scaffolding.'
                  : 'Hardstyle FX favors spoken [Monologue] manifestos over sung verses.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accentTertiary.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _FxLayoutPreviewBox(
            preview: SunoPromptBuilder.fxLayoutPreview(
              primaryGenre: lane,
              intensity: level,
              sunoVersion: form.sunoVersion,
            ),
          ),
        ],
      ),
    );
  }
}

class _FxLayoutPreviewBox extends StatelessWidget {
  const _FxLayoutPreviewBox({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.chipSelectedBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR FX LAYOUT',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.creodomeCyan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Arrangement tags for this lane + intensity. Separate from the Lyrics '
            'box. Merged at Generate.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (preview.trim().isEmpty)
            Text(
              'No extra arrangement tags for this lane/intensity.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SelectableText(
              preview,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedFxSettingsBox extends StatelessWidget {
  const _SelectedFxSettingsBox({
    required this.laneMode,
    required this.selectedLane,
    required this.resolvedLane,
    required this.category,
    required this.intensityLevel,
    required this.intensityLabel,
  });

  final String laneMode;
  final String selectedLane;
  final String resolvedLane;
  final String category;
  final int intensityLevel;
  final String intensityLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.chipSelectedBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR FX SETTINGS',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.creodomeCyan,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SettingChip(label: 'Mode', value: laneMode),
              _SettingChip(label: 'Lane', value: selectedLane),
              if (laneMode == 'Auto')
                _SettingChip(label: 'Resolved', value: resolvedLane),
              if (category.isNotEmpty)
                _SettingChip(label: 'Category', value: category),
              _SettingChip(
                label: 'Intensity',
                value: '$intensityLevel — $intensityLabel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  const _SettingChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
