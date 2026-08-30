import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/genre_fx_sync.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class SubGenreSelectionSection extends ConsumerWidget {
  const SubGenreSelectionSection({super.key});

  /// Tall enough to show several chip rows before scrolling.
  static const double _subGenrePanelMaxHeight = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);
    if (category == null) return const SizedBox.shrink();

    final primarySub = ref.watch(selectedPrimarySubProvider);
    final fusionSub = ref.watch(selectedFusionSubProvider);
    final genreFxLaneId = ref.watch(genreFxLaneIdProvider);
    final subs = GenreData.subGenresByCategory[category] ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'SUB-GENRE (pick primary + optional fusion)',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _subGenrePanelMaxHeight),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subs)
                  Builder(
                    builder: (context) {
                      final isPrimary = primarySub == s;
                      final isFusion = fusionSub == s;
                      final active = isPrimary || isFusion;
                      return FilterChip(
                        label: Text(s),
                        selected: active,
                        onSelected: (_) {
                          hapticLight();
                          String? nextPrimary = primarySub;
                          String? nextFusion = fusionSub;

                          if (nextPrimary == null || nextPrimary == s) {
                            nextPrimary = nextPrimary == s ? null : s;
                          } else if (nextFusion == s) {
                            nextFusion = null;
                          } else if (nextFusion == null && s != nextPrimary) {
                            nextFusion = s;
                          } else {
                            nextPrimary = s;
                            nextFusion = null;
                          }

                          ref.read(selectedPrimarySubProvider.notifier).state =
                              nextPrimary;
                          ref.read(selectedFusionSubProvider.notifier).state =
                              nextFusion;

                          if (nextPrimary != null) {
                            ref
                                .read(promptFormProvider.notifier)
                                .setGenreSelection(
                                  nextPrimary,
                                  fusion: nextFusion ?? '',
                                );
                            if (genreFxLaneId.isEmpty ||
                                genreFxLaneId == GenresConfig.autoLaneId) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                applyFxLayoutToLyricsField(ref);
                              });
                            }
                          }

                          _syncBpmPresetFromText(ref, nextPrimary, category);
                        },
                        selectedColor: AppColors.chipSelectedFill,
                        checkmarkColor: AppColors.creodomeCyan,
                        side: BorderSide(
                          color: active
                              ? AppColors.chipSelectedBorder
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? AppColors.creodomeCyan
                              : AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _syncBpmPresetFromText(
    WidgetRef ref,
    String? primarySub,
    String? category,
  ) {
    final bpmText = ref.read(bpmControllerProvider).text.trim();
    if (bpmText.isEmpty) {
      ref.read(bpmPresetProvider.notifier).state = null;
      return;
    }
    final suggestions =
        PromptFlowData.bpmSuggestionsForGenre(primarySub ?? category);
    if (suggestions.any((n) => n.toString() == bpmText)) {
      ref.read(bpmPresetProvider.notifier).state = bpmText;
    } else {
      ref.read(bpmPresetProvider.notifier).state = PromptFlowData.customOption;
    }
  }
}
