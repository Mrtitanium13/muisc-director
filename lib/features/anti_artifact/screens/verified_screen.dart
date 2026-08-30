import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/reroll_coach.dart';
import '../providers/artifact_providers.dart';

class VerifiedScreen extends ConsumerWidget {
  const VerifiedScreen({super.key});

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _copy(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrompts = ref.watch(verifiedPromptsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verified'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
            onPressed: () => ref.invalidate(verifiedPromptsProvider),
          ),
        ],
      ),
      body: asyncPrompts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prompts) {
          if (prompts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No verified prompts yet.\nUse "This one worked!" on the Create screen after a clean generation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              final p = prompts[index];
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.sealCheck,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _relativeTime(p.savedAt),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              PhosphorIconsRegular.trash,
                              color: AppColors.error,
                            ),
                            onPressed: () async {
                              await RerollCoach.deleteVerifiedPrompt(index);
                              ref.invalidate(verifiedPromptsProvider);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Style prompt',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.stylePrompt,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                            onPressed: () => _copy(p.stylePrompt, context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Exclude styles',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.excludeStyles,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                            onPressed: () => _copy(p.excludeStyles, context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
