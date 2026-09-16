import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:music_director/features/prompt_generator/widgets/common/collapsible_panel.dart';
import 'package:music_director/features/prompt_generator/widgets/common/workflow_step_label.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/language_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/lyrics_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/mood_vibe_section.dart';
import 'package:music_director/features/prompt_generator/widgets/sections/song_structure_section.dart';
import 'package:music_director/presentation/widgets/common/glass_card.dart';

/// Core brief: mood always visible; language / structure / lyrics collapsed.
class SongBriefWorkflowCard extends ConsumerWidget {
  const SongBriefWorkflowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WorkflowStepLabel(
                step: 2,
                title: 'Mood & vibe',
                subtitle: 'Required — e.g. confident, warm, danceable.',
              ),
              const SizedBox(height: 12),
              const MoodVibeSection(compact: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CollapsiblePanel(
          title: 'Song details',
          subtitle: '3–5 · Language · structure · lyrics box',
          icon: PhosphorIconsRegular.notebook,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WorkflowStepLabel(
                step: 3,
                title: 'Language',
                subtitle: 'Lyric language for the songwriter / Block 2.',
              ),
              const SizedBox(height: 12),
              const LanguageSection(),
              const SizedBox(height: 20),
              const WorkflowStepLabel(
                step: 4,
                title: 'Song structure',
                subtitle: 'Roadmap — Standard pop, Flexible, or Custom.',
              ),
              const SizedBox(height: 12),
              const SongStructureSection(compact: true),
              const SizedBox(height: 20),
              const WorkflowStepLabel(
                step: 5,
                title: 'Lyrics box',
                subtitle: 'Paste or write your own lyrics, or run Advanced songwriter.',
              ),
              const SizedBox(height: 12),
              const LyricsSection(compact: true),
            ],
          ),
        ),
      ],
    );
  }
}
