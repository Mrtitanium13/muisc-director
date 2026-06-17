import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/saved_prompt_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shell/main_shell.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = ref.read(hiveStorageProvider).loadAllSorted();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('History')),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No prompts yet. Generate your first.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MainShell.contentBottomPadding(context),
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return _HistoryTile(
                    model: p,
                    onOpen: () {
                      ref
                          .read(lastOutputGenerationInputProvider.notifier)
                          .state = null;
                      context.push(
                        '/output',
                        extra: {
                          'prompt': p.promptText,
                          'version': p.sunoVersion,
                          'trusted_generation_input': false,
                        },
                      );
                    },
                    onDelete: () async {
                      await ref.read(hiveStorageProvider).delete(p.id);
                      ref.read(promptHistoryRevisionProvider.notifier).state++;
                      await _reload();
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.model,
    required this.onOpen,
    required this.onDelete,
  });

  final SavedPromptModel model;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = model.promptText.length > 80
        ? '${model.promptText.substring(0, 80)}…'
        : model.promptText;
    final ts = DateFormat.MMMd().add_jm().format(model.createdAt);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(model.genreTag),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ts,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
