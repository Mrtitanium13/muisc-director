import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/saved_prompt_model.dart';
import '../../providers/app_providers.dart';

/// “Recent Prompts” (from Hive) + static “Pro tip” — top of Prompt Generator.
class RecentPromptsProTipSection extends ConsumerWidget {
  const RecentPromptsProTipSection({super.key});

  static const _maxRecent = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(promptHistoryRevisionProvider);
    final all = ref.read(hiveStorageProvider).loadAllSorted();
    final recent = all.take(_maxRecent).toList();
    final hasMore = all.length > _maxRecent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recent prompts',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _RecentCard(
          child: recent.isEmpty
              ? const _EmptyRecent()
              : _RecentList(
                  items: recent,
                  hasMore: hasMore,
                  totalCount: all.length,
                ),
        ),
        const SizedBox(height: 14),
        const _ProTipCard(),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          PhosphorIconsRegular.clockCounterClockwise,
          size: 40,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text(
          'No prompts yet.',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Generate your first prompt!',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({
    required this.items,
    required this.hasMore,
    required this.totalCount,
  });

  final List<SavedPromptModel> items;
  final bool hasMore;
  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tsFmt = DateFormat.MMMd().add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RecentTile(
            model: items[i],
            timeLabel: tsFmt.format(items[i].createdAt),
            onOpen: () {
              hapticLight();
              ref
                  .read(lastOutputGenerationInputProvider.notifier)
                  .state = null;
              context.push(
                '/output',
                extra: {
                  'prompt': items[i].promptText,
                  'version': items[i].sunoVersion,
                  'trusted_generation_input': false,
                },
              );
            },
          ),
        ],
        if (hasMore) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                hapticLight();
                context.go('/history');
              },
              child: Text('See all ($totalCount)'),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.model,
    required this.timeLabel,
    required this.onOpen,
  });

  final SavedPromptModel model;
  final String timeLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final preview = model.promptText.length > 72
        ? '${model.promptText.substring(0, 72)}…'
        : model.promptText;

    return Material(
      color: AppColors.background.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(model.genreTag),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 11),
                          backgroundColor:
                              AppColors.accentPrimary.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suno ${model.sunoVersion}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                PhosphorIconsRegular.arrowRight,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProTipCard extends StatelessWidget {
  const _ProTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.sparkle,
            size: 22,
            color: AppColors.accentPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro tip',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'For best results, be specific with your vibe description. '
                  'Instead of “energetic track”, try “dark hypnotic late-night '
                  'driving anthem with tension and release”.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
