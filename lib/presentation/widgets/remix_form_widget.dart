import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/song_generation_type.dart';
import '../../features/remix/domain/remix_mode.dart';
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
    this.targetGenre = '',
    this.onFieldChanged,
  });

  final TextEditingController songTitleController;
  final TextEditingController artistController;
  final SongGenerationType generationType;
  final ValueChanged<SongGenerationType> onGenerationTypeChanged;
  final String targetGenre;
  final VoidCallback? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final resolution = resolveRemixMode(
      remixOriginalSongTitle: songTitleController.text,
      remixOriginalArtist: artistController.text,
      remixFromAnalyzer: false,
    );
    final active = resolution.mode == RemixMode.interpolation;
    final genre =
        targetGenre.trim().isEmpty ? 'your selected genre' : targetGenre.trim();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppColors.accentTertiary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MUSICAL INTERPOLATION REMIX',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (active)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ENGINE ON',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.creodomeCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Flip a known track into your selected genre while locking chord '
            'progression, topline melody, and vocal rhythm. Song names stay '
            'on-device (chip + leak guard) — the model only receives musical descriptors.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.chipSelectedBorder.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Interpolating: ${songTitleController.text.trim()} — '
                '${artistController.text.trim()} → $genre',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.creodomeCyan,
                  height: 1.35,
                ),
              ),
            ),
          ] else if (resolution.nearActivation) ...[
            const SizedBox(height: 10),
            Text(
              songTitleController.text.trim().length >= 2
                  ? 'Add artist (2+ characters) to activate interpolation.'
                  : 'Add song title (2+ characters) to activate interpolation.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.warning,
                height: 1.35,
              ),
            ),
          ],
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
                ? 'Instrumental: compose staging that tracks the original topline — '
                    'no sung lyrics generated (strip is safety net only).'
                : 'Full song: lyrics + staging; vocal cadence mirrors the original '
                    'performance rhythm.',
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
