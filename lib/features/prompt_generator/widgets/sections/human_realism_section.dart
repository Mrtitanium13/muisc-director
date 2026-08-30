import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/human_realism_config.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class HumanRealismSection extends ConsumerWidget {
  const HumanRealismSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level =
        HumanRealismConfig.clampLevel(ref.watch(humanRealismLevelProvider));
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
                color: AppColors.creodomeCyan,
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
            activeTrackColor: AppColors.accentTertiary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.creodomeCyan,
            overlayColor: AppColors.accentTertiary.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: level.toDouble(),
            min: HumanRealismConfig.minLevel.toDouble(),
            max: HumanRealismConfig.maxLevel.toDouble(),
            divisions: HumanRealismConfig.maxLevel,
            label: '$level',
            onChanged: (v) {
              final next = v.round();
              ref.read(humanRealismLevelProvider.notifier).state = next;
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
}
