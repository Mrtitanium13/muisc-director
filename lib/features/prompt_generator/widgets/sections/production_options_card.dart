import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';



import 'package:music_director/core/theme/app_colors.dart';

import 'package:music_director/data/models/suno_field_output_mode.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/bpm_key_scale_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/chord_progression_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/dj_mixing_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/genre_fx_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/human_realism_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/melody_section.dart';

import 'package:music_director/features/prompt_generator/widgets/sections/real_instruments_section.dart';

import 'package:music_director/presentation/providers/app_providers.dart';

import 'package:music_director/presentation/widgets/common/glass_card.dart';



/// Optional production refinements (shown after Generate step).

class ProductionOptionsCard extends ConsumerWidget {

  const ProductionOptionsCard({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final isSimple =

        ref.watch(promptFormProvider).sunoFieldOutputMode ==

            SunoFieldOutputMode.simple;



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        GlassCard(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Text(

                'PRODUCTION & MIX (OPTIONAL)',

                style: GoogleFonts.inter(

                  fontSize: 11,

                  letterSpacing: 1.2,

                  fontWeight: FontWeight.w700,

                  color: AppColors.textTertiary,

                ),

              ),

              const SizedBox(height: 6),

              Text(

                'Fine-tune after lyrics are set — FX, instruments, melody, BPM, vocal realism.',

                style: GoogleFonts.inter(

                  fontSize: 12,

                  color: AppColors.textSecondary,

                  height: 1.35,

                ),

              ),

              const SizedBox(height: 16),

              const DjMixingSection(),

              const SizedBox(height: 16),

              if (isSimple) ...[

                Container(

                  width: double.infinity,

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(

                    color: AppColors.accentTertiary.withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(

                      color: AppColors.border.withValues(alpha: 0.6),

                    ),

                  ),

                  child: Text(

                    'Simple Mode uses Suno’s single Description field (same prose budget: '

                    '130–150 words, ≤1000 characters). Switch to Custom for Style + Lyrics.',

                    style: GoogleFonts.inter(

                      fontSize: 12,

                      color: AppColors.textSecondary,

                      height: 1.35,

                    ),

                  ),

                ),

                const SizedBox(height: 10),

              ],

              const HumanRealismSection(),

            ],

          ),

        ),

        const SizedBox(height: 16),

        const GenreFxSection(),

        const SizedBox(height: 16),

        GlassCard(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              const RealInstrumentsSection(),

              const SizedBox(height: 20),

              const ChordProgressionSection(),

              const SizedBox(height: 20),

              const MelodySection(),

              const SizedBox(height: 16),

              const BpmKeyScaleSection(),

            ],

          ),

        ),

      ],

    );

  }

}


