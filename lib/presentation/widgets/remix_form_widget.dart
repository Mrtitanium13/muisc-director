import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/song_generation_type.dart';
import 'common/glass_card.dart';
import 'common/md_text_field.dart';

/// Musical Interpolation & Style-Flip Engine — source metadata + generation mode.
class RemixFormWidget extends StatelessWidget {
  const RemixFormWidget({
    super.key,
    required this.songTitleController,
    required this.artistController,
    required this.generationType,
    required this.onGenerationTypeChanged,
    this.onFieldChanged,
  });

  final TextEditingController songTitleController;
  final TextEditingController artistController;
  final SongGenerationType generationType;
  final ValueChanged<SongGenerationType> onGenerationTypeChanged;
  final VoidCallback? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final active = songTitleController.text.trim().isNotEmpty &&
        artistController.text.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppColors.accentPrimary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'MUSICAL INTERPOLATION REMIX',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ENGINE ON',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Flip a known track into your selected genre while locking chord progression, topline melody, and vocal rhythm. Names stay in metadata only — never printed in the Suno output.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          MdTextField(
            controller: songTitleController,
            label: 'Original song title',
            hint: 'e.g. Mercy',
            onChanged: (_) => onFieldChanged?.call(),
          ),
          const SizedBox(height: 12),
          MdTextField(
            controller: artistController,
            label: 'Original artist',
            hint: 'e.g. Acoustic Worship',
            onChanged: (_) => onFieldChanged?.call(),
          ),
          const SizedBox(height: 16),
          Text(
            'OUTPUT MODE',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SongGenerationType>(
            segments: [
              for (final mode in SongGenerationType.values)
                ButtonSegment(
                  value: mode,
                  label: Text(mode.label),
                ),
            ],
            selected: {generationType},
            onSelectionChanged: (selection) {
              onGenerationTypeChanged(selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            generationType == SongGenerationType.instrumental
                ? 'Instrumental: instruments must track the original topline melody and syncopated groove — no lyrics or vocals.'
                : 'Full song: lyrics + staging per section; vocal cadence mirrors the original performance rhythm.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
