import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Maps Music Director blocks to Suno's two paste fields.
class SunoPasteDiagram extends StatelessWidget {
  const SunoPasteDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paste into Suno', style: labelStyle),
          const SizedBox(height: 8),
          _row(
            context,
            fromBlock: 'Block 1',
            toSunoField: 'Style',
            emphasized: true,
          ),
          const SizedBox(height: 6),
          _row(
            context,
            fromBlock: 'Block 2',
            toSunoField: 'Lyrics',
            emphasized: false,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String fromBlock,
    required String toSunoField,
    required bool emphasized,
  }) {
    final bg = emphasized
        ? AppColors.accentPrimary.withValues(alpha: 0.12)
        : AppColors.accentTertiary.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Text(
            fromBlock,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
          ),
          Text(
            'Suno $toSunoField',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
