import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/duration_format.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/data/models/track_duration_config.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/widgets/common/scrollable_chip_row.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/glass_card.dart';

class TrackDurationSection extends ConsumerWidget {
  const TrackDurationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final loadedDuration = ref.watch(audioDurationProvider);
    final customDurationCtrl = ref.watch(customDurationControllerProvider);

    return GlassCard(
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
          ScrollableChipRow(
            children: [
              for (final d in TrackDuration.values)
                ChoiceChip(
                  label: Text(
                    d == TrackDuration.custom ? 'Custom' : d.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: form.trackDuration == d,
                  onSelected: (_) {
                    hapticLight();
                    ref.read(promptFormProvider.notifier).setTrackDuration(d);
                  },
                  selectedColor: AppColors.chipSelectedFill,
                  checkmarkColor: AppColors.creodomeCyan,
                  side: BorderSide(
                    color: form.trackDuration == d
                        ? AppColors.chipSelectedBorder
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: form.trackDuration == d
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: form.trackDuration == d
                        ? AppColors.creodomeCyan
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (form.trackDuration == TrackDuration.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: customDurationCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Custom duration',
                hintText: 'e.g. 3:45 · 4 min · 180',
              ),
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
    );
  }
}
