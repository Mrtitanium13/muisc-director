import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/glass_card.dart';

/// Pull last analysis into Generate — lives on the Analyzer tab only.
class AnalyzerIntegrationSection extends ConsumerWidget {
  const AnalyzerIntegrationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final analysis = ref.watch(analysisResultProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LINK TO GENERATE',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.accentTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Include this analysis when you build a prompt on Generate.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (analysis == null)
            Text(
              'Analyze a track first — results will appear here.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
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
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Include in prompt generation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Attaches analyzer facts to the next Generate run.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              value: form.includeAnalyzerData,
              onChanged: (v) {
                hapticLight();
                ref.read(promptFormProvider.notifier).setIncludeAnalyzer(v);
                if (v) {
                  ref.read(promptFormProvider.notifier).setAnalyzerSummary(
                        analysis.toPromptSummary(),
                      );
                }
              },
              dense: true,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  hapticLight();
                  context.go('/generate');
                },
                child: const Text('Open Generate →'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
