import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/constants/prompt_templates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/user_input_model.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Templates'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: PromptTemplates.all.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: PromptTemplates.all.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                return _TemplateCard(template: PromptTemplates.all[i]);
              },
            ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final PromptTemplate template;

  static final _titleStyle = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );
  static final _descStyle = GoogleFonts.inter(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.35,
  );
  static final _genreStyle = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    color: AppColors.textTertiary,
  );

  @override
  Widget build(BuildContext context) {
    final model = template.model;
    final genreText = model.subGenreFusion.isNotEmpty
        ? '${model.primaryGenre} · ${model.subGenreFusion}'
        : model.primaryGenre;

    return Semantics(
      button: true,
      label: 'Select ${template.title} template for ${model.primaryGenre}',
      child: Card(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            hapticLight();
            context.pop<UserInputModel>(model);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.star,
                  color: AppColors.accentGold,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(template.title, style: _titleStyle),
                      const SizedBox(height: 4),
                      Text(template.description, style: _descStyle),
                      const SizedBox(height: 6),
                      Text(genreText, style: _genreStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  PhosphorIconsRegular.arrowRight,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static final _messageStyle = GoogleFonts.inter(
    color: AppColors.textSecondary,
    fontSize: 16,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsRegular.musicNotes,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text('No templates available yet.', style: _messageStyle),
        ],
      ),
    );
  }
}
