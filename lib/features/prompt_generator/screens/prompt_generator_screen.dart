import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/features/prompt_generator/utils/form_hydration.dart';
import 'package:music_director/features/prompt_generator/widgets/common/collapsible_panel.dart';
import 'package:music_director/features/prompt_generator/widgets/common/workflow_step_label.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/feature_tools_row.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/generate_button.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/genre_selection_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/language_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/lyrics_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/mood_vibe_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/production_options_card.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/quick_start_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/remix_form_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/song_structure_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/sub_genre_selection_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/suno_field_mode_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/suno_version_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/track_duration_section.dart';
import 'package:music_director/presentation/widgets/common/recent_prompts_pro_tip_section.dart';
import 'package:music_director/presentation/widgets/shell/main_shell.dart';

class PromptGeneratorScreen extends ConsumerStatefulWidget {
  const PromptGeneratorScreen({super.key});

  @override
  ConsumerState<PromptGeneratorScreen> createState() =>
      _PromptGeneratorScreenState();
}

class _PromptGeneratorScreenState extends ConsumerState<PromptGeneratorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FormHydration.hydrateAll(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Music Director',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFieldHelp(context),
            icon: const Icon(PhosphorIconsRegular.info),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MainShell.contentBottomPadding(context),
        ),
        children: [
          CollapsiblePanel(
            title: 'Pro tips and shortcuts',
            subtitle: 'Pro tip · Quick start · Tools',
            icon: PhosphorIconsRegular.lightning,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProTipSection(),
                SizedBox(height: 16),
                QuickStartSection(),
                SizedBox(height: 16),
                FeatureToolsRow(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'STEPS',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 1,
            title: 'Genre',
            subtitle: 'Primary category + sub-genre / fusion',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GenreSelectionSection(),
                SubGenreSelectionSection(),
              ],
            ),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 2,
            title: 'Mood & vibe',
            subtitle: 'Required — tone, era, groove, story',
            child: const MoodVibeSection(compact: true),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 3,
            title: 'Song details',
            subtitle: 'Language · structure · lyrics',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkflowStepLabel(
                  step: 3,
                  title: 'Language',
                  subtitle: 'Lyric language for Block 2.',
                ),
                SizedBox(height: 12),
                LanguageSection(),
                SizedBox(height: 20),
                WorkflowStepLabel(
                  step: 3,
                  title: 'Song structure',
                  subtitle: 'Standard pop, Flexible, or Custom.',
                ),
                SizedBox(height: 12),
                SongStructureSection(compact: true),
                SizedBox(height: 20),
                WorkflowStepLabel(
                  step: 3,
                  title: 'Write lyrics',
                  subtitle: 'Theme + optional Advanced songwriter.',
                ),
                SizedBox(height: 12),
                LyricsSection(compact: true),
              ],
            ),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 4,
            title: 'Suno target',
            subtitle: 'Version + Style / Lyrics field mode',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SunoVersionSection(),
                SizedBox(height: 12),
                SunoFieldModeSection(),
              ],
            ),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 5,
            title: 'Track length',
            subtitle: 'Duration target for Suno',
            child: const TrackDurationSection(),
          ),
          const SizedBox(height: 10),

          CollapsiblePanel(
            step: 6,
            title: 'Production & mix',
            subtitle: 'FX · instruments · melody · BPM · realism',
            child: const ProductionOptionsCard(),
          ),
          const SizedBox(height: 20),

          const WorkflowStepLabel(
            step: 7,
            title: 'Generate',
            subtitle: 'Build Block 1 style + Block 2 lyrics for Suno.',
          ),
          const SizedBox(height: 12),
          const GenerateButton(),
          const SizedBox(height: 24),

          Text(
            'OPTIONAL',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          CollapsiblePanel(
            title: 'Interpolation / remix',
            subtitle: 'Remix source & intensity',
            icon: PhosphorIconsRegular.arrowsClockwise,
            child: const RemixFormSection(),
          ),
          const SizedBox(height: 10),
          const CollapsibleRecentHistorySection(),
        ],
      ),
    );
  }

  void _showFieldHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('How to use'),
        content: const Text(
          'Pro tips and shortcuts sit at the top. Open steps 1–6 in order '
          '(Genre → Mood → Details → Suno → Length → Production), then Generate. '
          'Everything stays collapsed until you need it. Arrow cues on chip rows '
          'mean more options are off-screen — tap or swipe to see them. Remix '
          'and history stay optional below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
