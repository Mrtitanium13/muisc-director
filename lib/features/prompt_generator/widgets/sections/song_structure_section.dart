import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_director/core/constants/song_structure_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/song_structure_helpers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class SongStructureSection extends ConsumerWidget {
  const SongStructureSection({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final structureCustomCtrl = ref.watch(structureCustomControllerProvider);
    final example = ref.watch(sunoStructureExampleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            'SONG STRUCTURE',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The generated Suno prompt will follow this roadmap — same order, no mixed-up sections. '
            'For Custom, use bracket lines like [Verse] and (staging notes) so Suno does not read the outline as lyrics.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: presetIdOrFlexible(form.songStructurePresetId),
          decoration: const InputDecoration(
            labelText: 'Arrangement',
          ),
          items: [
            for (final p in SongStructureData.arrangementDropdownPresets)
              DropdownMenuItem<String>(
                value: p.id,
                child: Text(p.label),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            hapticLight();
            ref.read(promptFormProvider.notifier).setSongStructurePreset(v);
          },
        ),
        Builder(
          builder: (context) {
            final id = presetIdOrFlexible(form.songStructurePresetId);
            final preset = SongStructureData.presetById(id);
            if (preset == null) return const SizedBox.shrink();
            if (preset.id == SongStructureData.flexibleId) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  preset.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    height: 1.35,
                  ),
                ),
              );
            }
            if (preset.id == SongStructureData.customId) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        hapticLight();
                        structureCustomCtrl.text = example;
                        structureCustomCtrl.selection =
                            TextSelection.collapsed(offset: example.length);
                        ref
                            .read(promptFormProvider.notifier)
                            .setSongStructureCustom(example);
                      },
                      icon: Icon(
                        PhosphorIconsRegular.copy,
                        size: 18,
                        color: AppColors.creodomeCyan,
                      ),
                      label: Text(
                        'Paste bracket template (version + genre)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.creodomeCyan,
                        ),
                      ),
                    ),
                  ),
                  MdTextField(
                    controller: structureCustomCtrl,
                    label: 'CUSTOM SECTION ORDER',
                    hint:
                        '[Intro]\n(staging notes)\n[Verse]\n… or plain: Intro → Verse → Chorus → Outro',
                    maxLines: 14,
                    maxLength: 2000,
                    onChanged: (t) => ref
                        .read(promptFormProvider.notifier)
                        .setSongStructureCustom(t),
                  ),
                ],
              );
            }
            if (preset.canonicalRoadmap.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roadmap: ${preset.canonicalRoadmap}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
