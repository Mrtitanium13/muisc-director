import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/presentation/widgets/common/glass_card.dart';

/// Analyze Audio shortcut (History lives in the collapsible section).
class HeroRow extends ConsumerWidget {
  const HeroRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      accentBorder: true,
      padding: const EdgeInsets.all(14),
      onTap: () {
        hapticLight();
        context.go('/analyzer');
      },
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.waveform, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyze Audio',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Upload / record · pull genre & vibe from a track',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
