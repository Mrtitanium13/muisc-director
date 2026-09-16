import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';

class BatchOutputItem {
  const BatchOutputItem({
    required this.label,
    required this.prompt,
    required this.sunoVersion,
  });

  final String label;
  final String prompt;
  final String sunoVersion;
}

class BatchOutputScreen extends StatelessWidget {
  const BatchOutputScreen({super.key, required this.items});

  final List<BatchOutputItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Batch (${items.length})'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final it = items[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text('Suno ${it.sunoVersion}'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          AppColors.accentPrimary.withValues(alpha: 0.15),
                    ),
                    IconButton(
                      onPressed: () async {
                        hapticLight();
                        await Clipboard.setData(ClipboardData(text: it.prompt));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        }
                      },
                      icon: const Icon(PhosphorIconsRegular.copy, size: 20),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  it.prompt,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
