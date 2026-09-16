import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../presentation/utils/show_user_notices.dart';
import '../../../services/composition_pipeline_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/gradient_button.dart';

class BatchGenerateScreen extends ConsumerStatefulWidget {
  const BatchGenerateScreen({super.key});

  @override
  ConsumerState<BatchGenerateScreen> createState() =>
      _BatchGenerateScreenState();
}

class _BatchGenerateScreenState extends ConsumerState<BatchGenerateScreen> {
  int _count = 3;
  bool _suffixTakes = true;
  bool _running = false;

  Future<void> _run() async {
    final base = ref.read(promptFormProvider);
    if (base.primaryGenre.isEmpty || base.vibe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set primary genre and vibe on Prompt Generator first, then open Batch again.',
          ),
        ),
      );
      return;
    }

    setState(() => _running = true);
    final repo = ref.read(aiRepositoryProvider);
    final items = <Map<String, String>>[];
    final composition = CompositionPipelineService.run(userInput: base);
    showUserNotices(context, composition.userNotices);

    try {
      for (var i = 0; i < _count; i++) {
        final take = i + 1;
        final vibe = _suffixTakes && _count > 1
            ? '${composition.composedInput.vibe.trim()} — take $take'
            : composition.composedInput.vibe.trim();
        final input = composition.composedInput.copyWith(vibe: vibe);
        final text = await repo.generatePrompt(input);
        items.add({
          'label': 'Variation $take',
          'prompt': text,
          'version': base.sunoVersion,
        });
      }
      if (!mounted) return;
      context.push('/batch-output', extra: {'items': items});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch failed: ${dioErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(promptFormProvider);
    final ready = form.primaryGenre.isNotEmpty && form.vibe.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Batch generate'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Create multiple prompts in one run using your current generator settings (genre, structure, melody variation if enabled, analyser flags, etc.).',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PREVIEW',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? '${form.primaryGenre} · ${form.vibe.length > 120 ? '${form.vibe.substring(0, 117)}…' : form.vibe}'
                : 'Missing genre or vibe — go back to Prompt Generator.',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: ready ? AppColors.textSecondary : AppColors.textTertiary,
              height: 1.45,
            ),
          ),
          if (ready && form.optionalLyrics.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Lyrics box: your pasted/written lyrics will be used on each run (Path A).',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accentPrimary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (ready &&
              form.generateLyrics &&
              form.optionalLyrics.trim().isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Path C: each run generates original lyrics (same theme/temperament as Prompt Generator).',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accentPrimary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'HOW MANY PROMPTS',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final n in [2, 3, 4, 5])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n'),
                    selected: _count == n,
                    onSelected: (_) {
                      hapticSelection();
                      setState(() => _count = n);
                    },
                    selectedColor: AppColors.accentPrimary.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Append “take N” to vibe'),
            subtitle: Text(
              'Helps the model diversify when count is more than one',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            value: _suffixTakes,
            onChanged: (v) => setState(() => _suffixTakes = v),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _running ? 'GENERATING…' : 'GENERATE BATCH',
            icon: PhosphorIconsRegular.chartBar,
            enabled: !_running && ready,
            onPressed: (_running || !ready) ? null : _run,
          ),
        ],
      ),
    );
  }
}
