import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/audio_environment_data.dart';
import 'package:music_director/core/constants/dialect_style_data.dart';
import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/negative_style_descriptors.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/constants/vocal_accent_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/prompt_form_constants.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class AdvancedOptionsSection extends ConsumerWidget {
  const AdvancedOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advanced = ref.watch(advancedExpandedProvider);
    final keyRoot = ref.watch(keyRootProvider);
    final scale = ref.watch(scaleProvider);
    final vocalChoice = ref.watch(vocalChoiceProvider);
    final vocalAccent = ref.watch(vocalAccentUiProvider);
    final nigerianAccentSub = ref.watch(nigerianAccentSubUiProvider);
    final vocalTonePreset = ref.watch(vocalTonePresetProvider);
    final dialectStyleId =
        ref.watch(dialectStyleUiProvider) ?? DialectStyleData.standardEnglishId;
    final pidginActive = DialectStyleData.isNigerianPidgin(dialectStyleId);
    final dialectVariantId = ref.watch(dialectVariantUiProvider) ??
        DialectStyleData.generalVariantId;
    final audioEnvironmentModeId = ref.watch(audioEnvironmentUiProvider) ??
        AudioEnvironmentData.studioIsolatedId;
    final languagePreset = ref.watch(languagePresetProvider);
    final primarySub = ref.watch(selectedPrimarySubProvider);

    final vocalToneCtrl = ref.watch(vocalToneControllerProvider);
    final refArtistsCtrl = ref.watch(referenceArtistsControllerProvider);
    final sonicTags = ref.watch(sonicTagsUiProvider);
    final avoidCtrl = ref.watch(avoidControllerProvider);
    final languageCtrl = ref.watch(languageControllerProvider);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Advanced options',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      initiallyExpanded: advanced,
      onExpansionChanged: (v) =>
          ref.read(advancedExpandedProvider.notifier).state = v,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: keyRoot,
                decoration: const InputDecoration(
                  labelText: 'Key',
                ),
                items: [
                  for (final k in PromptFormConstants.keys)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) =>
                    ref.read(keyRootProvider.notifier).state = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: scale,
                decoration: const InputDecoration(
                  labelText: 'Scale',
                ),
                items: [
                  for (final s in PromptFormConstants.scales)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) =>
                    ref.read(scaleProvider.notifier).state = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'VOCAL SPEC',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w800,
            color: AppColors.accentTertiary,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final v in PromptFormConstants.vocals)
              ChoiceChip(
                label: Text(v, style: const TextStyle(fontSize: 12)),
                selected: vocalChoice == v,
                onSelected: (_) {
                  final form = ref.read(promptFormProvider);
                  ref.read(vocalChoiceProvider.notifier).state = v;
                  if (v == 'Instrumental Only') {
                    ref.read(vocalAccentUiProvider.notifier).state = null;
                    ref.read(dialectStyleUiProvider.notifier).state =
                        DialectStyleData.standardEnglishId;
                    ref.read(dialectVariantUiProvider.notifier).state =
                        DialectStyleData.generalVariantId;
                  }
                  ref.read(promptFormProvider.notifier).setVocal(
                        spec: v,
                        tone: form.vocalTone,
                      );
                  if (v == 'Instrumental Only') {
                    ref.read(promptFormProvider.notifier)
                      ..setVocalAccent(null)
                      ..setDialectStyleId(DialectStyleData.standardEnglishId)
                      ..setDialectVariantId(DialectStyleData.generalVariantId);
                  }
                },
                selectedColor: AppColors.chipSelectedFill,
                checkmarkColor: AppColors.creodomeCyan,
                side: BorderSide(
                  color: vocalChoice == v
                      ? AppColors.chipSelectedBorder
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: vocalChoice == v
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: vocalChoice == v
                      ? AppColors.creodomeCyan
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        if (vocalChoice != null && vocalChoice != 'Instrumental Only') ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: vocalTonePreset,
            decoration: const InputDecoration(
              labelText: 'Vocal tone (optional)',
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Not set — infer from genre'),
              ),
              for (final t in PromptFlowData.vocalTones)
                DropdownMenuItem<String?>(
                  value: t,
                  child: Text(t),
                ),
              const DropdownMenuItem<String?>(
                value: PromptFlowData.customOption,
                child: Text('Custom…'),
              ),
            ],
            onChanged: (v) {
              hapticLight();
              ref.read(vocalTonePresetProvider.notifier).state = v;
              if (v != null && v != PromptFlowData.customOption) {
                vocalToneCtrl.clear();
              }
            },
          ),
          if (vocalTonePreset == PromptFlowData.customOption) ...[
            const SizedBox(height: 8),
            MdTextField(
              controller: vocalToneCtrl,
              label: 'CUSTOM VOCAL TONE',
              hint: 'e.g. gravelly baritone, falsetto hook',
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: vocalAccent,
            decoration: InputDecoration(
              labelText: 'SINGER ACCENT / DELIVERY (OPTIONAL)',
              helperText: _accentHelperText(
                vocalAccent,
                nigerianAccentSub,
                pidginActive,
              ),
            ),
            isExpanded: true,
            items: [
              for (final a in VocalAccentData.topLevelDropdownValues)
                DropdownMenuItem<String?>(
                  value: a,
                  child: Text(
                    VocalAccentData.topLevelMenuLabel(a),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
            onChanged: (v) {
              ref.read(vocalAccentUiProvider.notifier).state = v;
              final effective = VocalAccentData.resolveEffectiveAccent(
                topLevel: v,
                nigerianSub: ref.read(nigerianAccentSubUiProvider),
                useNigerianSubRegion:
                    pidginActive && v == 'nigerian',
              );
              ref.read(promptFormProvider.notifier).setVocalAccent(effective);
            },
          ),
          if (pidginActive && vocalAccent == 'nigerian') ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: nigerianRegionalValue(nigerianAccentSub),
              decoration: InputDecoration(
                labelText: 'NIGERIAN REGION / DELIVERY',
                helperText: VocalAccentData.descriptionFor(
                        nigerianRegionalValue(nigerianAccentSub))
                        .isNotEmpty
                    ? VocalAccentData.descriptionFor(
                        nigerianRegionalValue(nigerianAccentSub),
                      )
                    : 'Routes Layer 1 descriptors and Pidgin sub-variant vocabulary.',
              ),
              isExpanded: true,
              items: [
                for (final k in VocalAccentData.nigerianRegionalAccentValues)
                  DropdownMenuItem<String>(
                    value: k,
                    child: Text(
                      VocalAccentData.nigerianRegionMenuLabel(k),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                hapticLight();
                ref.read(nigerianAccentSubUiProvider.notifier).state = v;
                ref.read(promptFormProvider.notifier).setVocalAccent(
                      VocalAccentData.resolveEffectiveAccent(
                        topLevel: 'nigerian',
                        nigerianSub: v,
                        useNigerianSubRegion: true,
                      ),
                    );
              },
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: dialectStyleId,
            decoration: const InputDecoration(
              labelText: 'LYRIC DIALECT / LANGUAGE MODE',
              helperText:
                  'Nigerian Pidgin writes verses natively in West African Pidgin — staging tags stay in brackets.',
            ),
            isExpanded: true,
            items: [
              for (final o in DialectStyleData.options)
                DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(
                    o.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              hapticLight();
              ref.read(dialectStyleUiProvider.notifier).state = v;
              final pidginOn = DialectStyleData.isNigerianPidgin(v);
              if (!pidginOn) {
                ref.read(dialectVariantUiProvider.notifier).state =
                    DialectStyleData.generalVariantId;
                if (ref.read(vocalAccentUiProvider) == 'nigerian') {
                  ref.read(promptFormProvider.notifier).setVocalAccent('nigerian');
                }
              } else if (ref.read(vocalAccentUiProvider) == 'nigerian') {
                ref.read(promptFormProvider.notifier).setVocalAccent(
                      VocalAccentData.resolveEffectiveAccent(
                        topLevel: 'nigerian',
                        nigerianSub: ref.read(nigerianAccentSubUiProvider),
                        useNigerianSubRegion: true,
                      ),
                    );
              }
              ref.read(promptFormProvider.notifier).setDialectStyleId(v);
              if (!pidginOn) {
                ref
                    .read(promptFormProvider.notifier)
                    .setDialectVariantId(DialectStyleData.generalVariantId);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: AudioEnvironmentData.coerceId(audioEnvironmentModeId),
            decoration: const InputDecoration(
              labelText: 'AUDIO ENVIRONMENT / LIVE MODE',
              helperText:
                  'Studio = dead-room isolation, no crowd. Live Arena = stadium cheers and sing-along.',
            ),
            isExpanded: true,
            items: [
              for (final o in AudioEnvironmentData.options)
                DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(
                    o.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              hapticLight();
              ref.read(audioEnvironmentUiProvider.notifier).state = v;
              ref.read(promptFormProvider.notifier).setAudioEnvironmentModeId(v);
            },
          ),
          if (DialectStyleData.isNigerianPidgin(dialectStyleId)) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: DialectStyleData.coerceVariantId(dialectVariantId),
              decoration: const InputDecoration(
                labelText: 'REGIONAL DIALECT FLAVOR',
                helperText:
                    'Ibibio, Efik, Yoruba, Igbo, Hausa, Urhobo — inflection on Nigerian Pidgin lyrics.',
              ),
              isExpanded: true,
              items: [
                for (final v in DialectStyleData.pidginVariants)
                  DropdownMenuItem<String>(
                    value: v.id,
                    child: Text(
                      v.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                hapticLight();
                ref.read(dialectVariantUiProvider.notifier).state = v;
                ref.read(promptFormProvider.notifier).setDialectVariantId(v);
              },
            ),
          ],
        ],
        const SizedBox(height: 8),
        Text(
          'REFERENCE (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Artist names and catalog codenames route through the DNA translation engine. '
          'Production tags below are direct sonic instructions.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        MdTextField(
          controller: refArtistsCtrl,
          label: 'ARTIST / CATALOG REFERENCES',
          hint: 'e.g. Frank Ocean, my EP NX-07, Metro Boomin',
          onChanged: (t) =>
              ref.read(promptFormProvider.notifier).setReferenceArtists(t),
        ),
        if (primarySub != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Production tags',
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final a in GenreData.sonicReferenceChipsForGenre(primarySub))
                  FilterChip(
                    label: Text(
                      a,
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    selected: sonicTags.contains(a),
                    onSelected: (selected) {
                      hapticLight();
                      final next = selected
                          ? [...sonicTags, a]
                          : sonicTags.where((t) => t != a).toList();
                      ref.read(sonicTagsUiProvider.notifier).state = next;
                      ref.read(promptFormProvider.notifier).setSonicTags(next);
                    },
                    selectedColor: AppColors.chipSelectedFill,
                    checkmarkColor: AppColors.creodomeCyan,
                    side: BorderSide(
                      color: sonicTags.contains(a)
                          ? AppColors.chipSelectedBorder
                          : AppColors.border,
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: sonicTags.contains(a)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: sonicTags.contains(a)
                          ? AppColors.creodomeCyan
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Optional artist names',
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final a
                    in GenreData.optionalArtistNameChipsForGenre(primarySub))
                  ActionChip(
                    label: Text(
                      a,
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onPressed: () {
                      hapticLight();
                      final t = refArtistsCtrl.text.trim();
                      final next = t.isEmpty ? a : '$t, $a';
                      refArtistsCtrl.text = next;
                      ref
                          .read(promptFormProvider.notifier)
                          .setReferenceArtists(next);
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        MdTextField(
          controller: avoidCtrl,
          label: 'AVOID (OPTIONAL)',
          hint: 'e.g. no trap hi-hats, no clipping',
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Steer away (Part G — woven into Block 1)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final chip in NegativeStyleDescriptors.chips)
              ActionChip(
                label: Text(
                  chip.$1,
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                onPressed: () {
                  hapticLight();
                  final next = NegativeStyleDescriptors.mergeIntoAvoid(
                    avoidCtrl.text,
                    chip.$2,
                  );
                  avoidCtrl.text = next;
                  ref.read(promptFormProvider.notifier).setAvoid(next);
                },
              ),
          ],
        ),
        DropdownButtonFormField<String?>(
          // ignore: deprecated_member_use
          value: languagePreset ?? 'English',
          decoration: const InputDecoration(
            labelText: 'Language',
            helperText: 'Set in Songwriter workflow (step 3) above BPM.',
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

String _accentHelperText(
  String? topLevel,
  String nigerianSub,
  bool pidginActive,
) {
  final effective = VocalAccentData.resolveEffectiveAccent(
    topLevel: topLevel,
    nigerianSub: nigerianSub,
    useNigerianSubRegion: pidginActive && topLevel == 'nigerian',
  );
  final desc = VocalAccentData.descriptionFor(effective);
  if (desc.isNotEmpty) return desc;
  return 'Pronunciation & cadence as production style — not voice cloning.';
}

String nigerianRegionalValue(String sub) {
  return VocalAccentData.nigerianRegionalAccentValues.contains(sub)
      ? sub
      : VocalAccentData.defaultNigerianSubAccent;
}
