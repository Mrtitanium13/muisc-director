import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

/// Lyric language picker — used early in the songwriter workflow.
class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagePreset = ref.watch(languagePresetProvider);
    final languageCtrl = ref.watch(languageControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          // ignore: deprecated_member_use
          value: languagePreset ?? 'English',
          decoration: const InputDecoration(
            labelText: 'Language',
            helperText: 'Routes the songwriter to the right models and diction.',
          ),
          isExpanded: true,
          items: [
            for (final lang in PromptFlowData.languages)
              DropdownMenuItem<String?>(
                value: lang,
                child: Text(lang),
              ),
            const DropdownMenuItem<String?>(
              value: PromptFlowData.customOption,
              child: Text('Other…'),
            ),
          ],
          onChanged: (v) {
            hapticLight();
            ref.read(languagePresetProvider.notifier).state = v;
            if (v != null && v != PromptFlowData.customOption) {
              languageCtrl.text = v;
              ref.read(promptFormProvider.notifier).setLanguage(v);
            }
          },
        ),
        if (languagePreset == PromptFlowData.customOption) ...[
          const SizedBox(height: 8),
          MdTextField(
            controller: languageCtrl,
            label: 'CUSTOM LANGUAGE',
            hint: 'e.g. Igbo, Tagalog',
            onChanged: (t) => ref.read(promptFormProvider.notifier).setLanguage(
                  t.trim().isEmpty ? 'English' : t,
                ),
          ),
        ],
      ],
    );
  }
}
