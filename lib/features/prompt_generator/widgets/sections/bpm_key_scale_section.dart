import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/advanced_options_section.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class BpmKeyScaleSection extends ConsumerWidget {
  const BpmKeyScaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primarySub = ref.watch(selectedPrimarySubProvider);
    final category = ref.watch(selectedCategoryProvider);
    final bpmPreset = ref.watch(bpmPresetProvider);
    final bpmCtrl = ref.watch(bpmControllerProvider);
    final bpmHint = GenreData.bpmHintForLabel(primarySub ?? category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: bpmPreset ?? '',
          decoration: InputDecoration(
            labelText: 'BPM (optional)',
            helperText: bpmHint != null ? 'Genre hint: $bpmHint' : null,
          ),
          isExpanded: true,
          items: _bpmDropdownItems(primarySub, category),
          onChanged: (v) {
            if (v == null) return;
            hapticLight();
            if (v.isEmpty) {
              ref.read(bpmPresetProvider.notifier).state = null;
              bpmCtrl.clear();
            } else if (v == PromptFlowData.customOption) {
              ref.read(bpmPresetProvider.notifier).state =
                  PromptFlowData.customOption;
            } else {
              ref.read(bpmPresetProvider.notifier).state = v;
              bpmCtrl.text = v;
            }
          },
        ),
        if (bpmPreset == PromptFlowData.customOption) ...[
          const SizedBox(height: 10),
          MdTextField(
            controller: bpmCtrl,
            label: 'CUSTOM BPM',
            hint: 'e.g. 128',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 12),
        const AdvancedOptionsSection(),
      ],
    );
  }

  List<DropdownMenuItem<String>> _bpmDropdownItems(
    String? primarySub,
    String? category,
  ) {
    final options =
        PromptFlowData.bpmOptionsForGenre(primarySub ?? category);
    // Surface Custom near the top so users can type any BPM without scrolling.
    final custom = options.where((o) => o.isCustom);
    final presets = options.where((o) => !o.isCustom);
    return [
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Not set — model picks'),
      ),
      for (final o in custom)
        DropdownMenuItem<String>(
          value: o.value,
          child: const Text('Custom…'),
        ),
      for (final o in presets)
        DropdownMenuItem<String>(
          value: o.value,
          child: Text(o.label),
        ),
    ];
  }
}
