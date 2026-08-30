import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/chord_progression_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class ChordProgressionSection extends ConsumerWidget {
  const ChordProgressionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chordCtrl = ref.watch(chordProgressionControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHORD PROGRESSION (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Locks harmony into the model output: numerals, chord symbols, or a bar map. '
          'Pick a chip or type your own; set Key/scale above when it matters.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final q in ChordProgressionData.quickPicks)
              ActionChip(
                label: Text(
                  q.label,
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  hapticLight();
                  _appendChordSnippet(ref, q.insert);
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        MdTextField(
          controller: chordCtrl,
          label: 'CHORDS / HARMONY',
          hint:
              'e.g. I–V–vi–IV · or Dm7–G7–Cmaj7 · or 4 bars each on I, vi, IV, V',
          maxLines: 3,
          maxLength: 300,
          onChanged: (t) =>
              ref.read(promptFormProvider.notifier).setChordProgression(t),
        ),
      ],
    );
  }

  void _appendChordSnippet(WidgetRef ref, String insert) {
    final ins = insert.trim();
    if (ins.isEmpty) return;
    final ctrl = ref.read(chordProgressionControllerProvider);
    final cur = ctrl.text.trim();
    if (cur.contains(ins)) return;
    final next = cur.isEmpty ? ins : '$cur · $ins';
    ctrl.text = next;
    ctrl.selection = TextSelection.collapsed(offset: next.length);
    ref.read(promptFormProvider.notifier).setChordProgression(next);
  }
}
