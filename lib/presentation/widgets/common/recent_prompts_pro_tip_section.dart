import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/saved_prompt_model.dart';
import '../../providers/app_providers.dart';

/// Static Pro tip — intended first on Prompt Generator.
class ProTipSection extends StatelessWidget {
  const ProTipSection({super.key});

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
            color: AppColors.creodomeCyan,
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

/// Collapsed-by-default recent prompts / history preview.
/// Expands only when the user opens it.
class CollapsibleRecentHistorySection extends ConsumerStatefulWidget {
  const CollapsibleRecentHistorySection({super.key});

  static const _maxRecent = 3;

  @override
  ConsumerState<CollapsibleRecentHistorySection> createState() =>
      _CollapsibleRecentHistorySectionState();
}

class _CollapsibleRecentHistorySectionState
    extends ConsumerState<CollapsibleRecentHistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(promptHistoryRevisionProvider);
    final all = ref.read(hiveStorageProvider).loadAllSorted();
    final recent = all.take(CollapsibleRecentHistorySection._maxRecent).toList();
    final hasMore = all.length > CollapsibleRecentHistorySection._maxRecent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              hapticLight();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.clockCounterClockwise,
                    size: 20,
                    color: AppColors.creodomeCyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          all.isEmpty
                              ? 'No saved prompts yet'
                              : '${all.length} saved · tap to ${_expanded ? 'hide' : 'show'}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open full history',
                    onPressed: () {
                      hapticLight();
                      context.go('/history');
                    },
                    icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(
                    _expanded
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: recent.isEmpty
                  ? const _EmptyRecent()
                  : _RecentList(
                      items: recent,
                      hasMore: hasMore,
                      totalCount: all.length,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Backward-compatible wrapper (pro tip + collapsible history).
class RecentPromptsProTipSection extends ConsumerWidget {
  const RecentPromptsProTipSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProTipSection(),
        SizedBox(height: 14),
        CollapsibleRecentHistorySection(),
      ],
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          PhosphorIconsRegular.clockCounterClockwise,
          size: 32,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 8),
        Text(
          'No prompts yet.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Generate your first prompt!',
          style: GoogleFonts.inter(
            fontSize: 12,
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
              ref.read(lastOutputGenerationInputProvider.notifier).state = null;
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
                              AppColors.accentTertiary.withValues(alpha: 0.16),
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
