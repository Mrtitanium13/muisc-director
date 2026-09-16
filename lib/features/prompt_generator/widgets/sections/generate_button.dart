import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:music_director/core/utils/dio_error_message.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/form_commit.dart';
import 'package:music_director/features/prompt_generator/utils/form_validation.dart';
import 'package:music_director/features/prompt_generator/widgets/common/generating_dialog.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/utils/show_user_notices.dart';
import 'package:music_director/presentation/widgets/common/gradient_button.dart';
import 'package:music_director/services/composition_pipeline_service.dart';

class GenerateButton extends ConsumerWidget {
  const GenerateButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientButton(
      label: 'GENERATE PROMPT',
      icon: PhosphorIconsRegular.magicWand,
      onPressed: () => _generate(context, ref),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    FormCommit.commitAll(ref);

    final form = ref.read(promptFormProvider);
    final composition = CompositionPipelineService.run(userInput: form);
    _applyComposition(ref, composition);
    showUserNotices(context, composition.userNotices);

    final committedForm = composition.composedInput;
    final errors = FormValidation.validate(committedForm);
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.map((e) => e.message).join('\n')),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const GeneratingDialog(),
    );

    try {
      final preferLight = ref.read(preferLightweightNextGenerationProvider);
      if (preferLight) {
        ref.read(preferLightweightNextGenerationProvider.notifier).state =
            false;
      }
      final text = await ref.read(aiRepositoryProvider).generatePrompt(
            committedForm,
            preferLightweightModel: preferLight,
          );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref.read(lastOutputGenerationInputProvider.notifier).state = committedForm;
      context.push('/output', extra: {
        'prompt': text,
        'version': committedForm.sunoVersion,
        'field_mode': committedForm.sunoFieldOutputMode.name,
        'trusted_generation_input': true,
      });
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: ${dioErrorMessage(e)}'),
          ),
        );
      }
    }
  }

  static void _applyComposition(WidgetRef ref, CompositionResult composition) {
    final composed = composition.composedInput;
    final n = ref.read(promptFormProvider.notifier);
    final merged = composed.optionalLyrics;
    final core = SunoPromptBuilder.stripFxLayout(merged);
    final fx = SunoPromptBuilder.extractFxLayout(merged);
    n.setOptionalLyrics(core);
    n.setVibe(composed.vibe);
    ref.read(lyricsControllerProvider).text = core;
    ref.read(fxLayoutControllerProvider).text = fx;
  }
}
