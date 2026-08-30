import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';



import 'package:music_director/core/constants/lyric_temperament_data.dart';

import 'package:music_director/core/theme/app_colors.dart';

import 'package:music_director/core/utils/dio_error_message.dart';

import 'package:music_director/core/utils/haptic_utils.dart';

import 'package:music_director/data/models/suno_field_output_mode.dart';

import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';

import 'package:music_director/features/prompt_generator/utils/temperament_toggle.dart';

import 'package:music_director/presentation/providers/app_providers.dart';

import 'package:music_director/presentation/widgets/common/md_text_field.dart';

import 'package:music_director/songwriter/songwriter.dart';



class LyricsSection extends ConsumerStatefulWidget {

  const LyricsSection({super.key, this.compact = false});



  final bool compact;



  @override

  ConsumerState<LyricsSection> createState() => _LyricsSectionState();

}



class _LyricsSectionState extends ConsumerState<LyricsSection> {

  bool _runningPipeline = false;

  String? _lastScoreLine;



  Future<void> _runSongwriterPipeline() async {

    final form = ref.read(promptFormProvider);

    final mode = ref.read(songwriterOutputModeProvider);

    final qualityMode = ref.read(songwriterQualityModeProvider);

    final lyricsCtrl = ref.read(lyricsControllerProvider);

    final themeCtrl = ref.read(lyricThemeControllerProvider);

    final vibeCtrl = ref.read(vibeControllerProvider);

    final langCtrl = ref.read(languageControllerProvider);



    final genre = form.primaryGenre.trim().isNotEmpty

        ? form.primaryGenre.trim()

        : 'pop';

    final themeStory = themeCtrl.text.trim().isNotEmpty

        ? themeCtrl.text.trim()

        : form.lyricThemeNotes;

    final brief = songBriefFromForm(

      genre: genre,

      subgenre: form.subGenreFusion,

      mood: vibeCtrl.text.trim().isNotEmpty

          ? vibeCtrl.text.trim()

          : form.vibe,

      theme: themeStory,

      story: themeStory,

      language: langCtrl.text.trim().isNotEmpty

          ? langCtrl.text.trim()

          : form.language,

      mode: mode,

      qualityMode: qualityMode,

      inputLyrics: lyricsCtrl.text.trim(),

      bpm: form.bpm ?? '',

    );



    setState(() {

      _runningPipeline = true;

      _lastScoreLine = null;

    });

    try {

      final result =

          await ref.read(aiRepositoryProvider).generateSongwriterLyrics(brief);

      if (!mounted) return;

      final text = result.lyrics.trim().isNotEmpty
          ? result.lyrics
          : result.ideas.isNotEmpty
              ? result.ideas.map((e) => '- $e').join('\n')
              : '';
      lyricsCtrl.text = text;

      ref.read(promptFormProvider.notifier).setOptionalLyrics(text);

      ref.read(generateLyricsProvider.notifier).state = false;

      final qa = result.qa;
      final partial = result.raw['partial'] == true || result.raw['timed_out'] == true;
      final status = qa?.qualityStatus ?? '${result.raw['quality_status'] ?? ''}';

      setState(() {
        if (partial && text.isNotEmpty) {
          _lastScoreLine =
              'Partial draft (timed out mid-pipeline)${result.title != null && result.title!.isNotEmpty ? ' · ${result.title}' : ''}';
        } else if (result.ideas.isNotEmpty && result.lyrics.trim().isEmpty) {
          _lastScoreLine =
              '${result.ideas.length} ideas · $status'
              '${result.title != null && result.title!.isNotEmpty ? ' · ${result.title}' : ''}';
        } else {
          _lastScoreLine = qa == null
              ? null
              : 'Score ${qa.weightedTotal.toStringAsFixed(0)}'
                  ' · $status'
                  '${qa.ship ? ' · ship' : ''}'
                  '${result.title != null && result.title!.isNotEmpty ? ' · ${result.title}' : ''}';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              text.isEmpty
                  ? 'Songwriter returned empty lyrics. Check server logs / SONGWRITER_PIPELINE.'
                  : (_lastScoreLine ?? 'Lyrics generated.'),
            ),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(dioErrorMessage(e))),

      );

    } finally {

      if (mounted) setState(() => _runningPipeline = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final form = ref.watch(promptFormProvider);

    final generateLyrics = ref.watch(generateLyricsProvider);

    final temperamentPick = ref.watch(temperamentPickProvider);

    final lyricsCtrl = ref.watch(lyricsControllerProvider);

    final lyricThemeCtrl = ref.watch(lyricThemeControllerProvider);

    final pipelineOn = ref.watch(songwriterPipelineEnabledProvider);

    final outputMode = ref.watch(songwriterOutputModeProvider);

    final qualityMode = ref.watch(songwriterQualityModeProvider);

    final modes = songwriterOutputModes();

    final qualityModes = songwriterQualityModes();



    final isSimple = form.sunoFieldOutputMode == SunoFieldOutputMode.simple;

    final showTheme = widget.compact || pipelineOn || generateLyrics;



    return Opacity(

      opacity: isSimple ? 0.48 : 1,

      child: AbsorbPointer(

        absorbing: isSimple,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            if (!widget.compact) ...[

              Text(

                'LYRICS (OPTIONAL)',

                style: GoogleFonts.inter(

                  fontSize: 11,

                  letterSpacing: 1.2,

                  color: AppColors.textTertiary,

                  fontWeight: FontWeight.w600,

                ),

              ),

              const SizedBox(height: 6),

              Text(

                'Fill theme → run Advanced songwriter → edit output → Generate for Suno Block 1 + 2.',

                style: GoogleFonts.inter(

                  fontSize: 12,

                  color: AppColors.textSecondary,

                  height: 1.35,

                ),

              ),

              const SizedBox(height: 10),

            ],

            if (showTheme) ...[

              MdTextField(

                controller: lyricThemeCtrl,

                label: 'LYRIC THEME / STORY',

                hint:

                    'POV, setting, must-include images, must-avoid clichés… '

                    'e.g. rooftop party, missed call, hook as a chant.',

                maxLines: 5,

                maxLength: 1200,

                onChanged: (t) =>

                    ref.read(promptFormProvider.notifier).setLyricThemeNotes(t),

              ),

              const SizedBox(height: 14),

            ],

            SwitchListTile(

              contentPadding: EdgeInsets.zero,

              title: Text(

                'Advanced songwriter pipeline',

                style: GoogleFonts.inter(

                  fontWeight: FontWeight.w600,

                  color: AppColors.textPrimary,

                ),

              ),

              subtitle: Text(

                '12-stage chorus-first engine. Pick Full song, run pipeline, then edit lyrics below.',

                style: GoogleFonts.inter(

                  fontSize: 12,

                  color: AppColors.textSecondary,

                ),

              ),

              value: pipelineOn,

              onChanged: (v) {

                hapticLight();

                ref.read(songwriterPipelineEnabledProvider.notifier).state = v;

                if (v) {

                  ref.read(generateLyricsProvider.notifier).state = false;

                }

              },

            ),

            if (pipelineOn) ...[

              const SizedBox(height: 8),

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: AppColors.surfaceElevated,

                  borderRadius: BorderRadius.circular(10),

                  border: Border.all(color: AppColors.border),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    Text(

                      'OUTPUT MODE',

                      style: GoogleFonts.inter(

                        fontSize: 12,

                        letterSpacing: 1.0,

                        fontWeight: FontWeight.w800,

                        color: AppColors.accentTertiary,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Wrap(

                      spacing: 6,

                      runSpacing: 6,

                      children: [

                        for (final m in modes)

                          FilterChip(

                            label: Text(

                              '${m['label'] ?? m['id']}',

                              style: GoogleFonts.inter(fontSize: 11),

                            ),

                            selected: outputMode == m['id'],

                            onSelected: (_) {

                              hapticLight();

                              ref

                                  .read(songwriterOutputModeProvider.notifier)

                                  .state = '${m['id']}';

                            },

                            selectedColor: AppColors.chipSelectedFill,
                            checkmarkColor: AppColors.creodomeCyan,
                            side: BorderSide(
                              color: outputMode == m['id']
                                  ? AppColors.chipSelectedBorder
                                  : AppColors.border,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: outputMode == m['id']
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: outputMode == m['id']
                                  ? AppColors.creodomeCyan
                                  : AppColors.textSecondary,
                            ),

                          ),

                      ],

                    ),

                    const SizedBox(height: 10),

                    Text(

                      'QUALITY',

                      style: GoogleFonts.inter(

                        fontSize: 12,

                        letterSpacing: 1.0,

                        fontWeight: FontWeight.w800,

                        color: AppColors.accentTertiary,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Wrap(

                      spacing: 6,

                      runSpacing: 6,

                      children: [

                        for (final q in qualityModes)

                          FilterChip(

                            label: Text(

                              q,

                              style: GoogleFonts.inter(fontSize: 11),

                            ),

                            selected: qualityMode == q,

                            onSelected: (_) {

                              hapticLight();

                              ref

                                  .read(songwriterQualityModeProvider.notifier)

                                  .state = q;

                            },

                            selectedColor: AppColors.chipSelectedFill,
                            checkmarkColor: AppColors.creodomeCyan,
                            side: BorderSide(
                              color: qualityMode == q
                                  ? AppColors.chipSelectedBorder
                                  : AppColors.border,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: qualityMode == q
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: qualityMode == q
                                  ? AppColors.creodomeCyan
                                  : AppColors.textSecondary,
                            ),
                          ),

                      ],

                    ),

                    const SizedBox(height: 10),

                    SizedBox(

                      width: double.infinity,

                      child: FilledButton.icon(

                        onPressed:

                            _runningPipeline ? null : _runSongwriterPipeline,

                        icon: _runningPipeline

                            ? const SizedBox(

                                width: 16,

                                height: 16,

                                child:

                                    CircularProgressIndicator(strokeWidth: 2),

                              )

                            : const Icon(Icons.auto_awesome, size: 18),

                        label: Text(

                          _runningPipeline

                              ? 'Writing lyrics…'

                              : 'Run songwriter pipeline',

                        ),

                      ),

                    ),

                    if (_lastScoreLine != null) ...[

                      const SizedBox(height: 8),

                      Text(

                        _lastScoreLine!,

                        style: GoogleFonts.inter(

                          fontSize: 12,

                          color: AppColors.textSecondary,

                        ),

                      ),

                    ],

                  ],

                ),

              ),

              const SizedBox(height: 14),

            ],

            // Review sits under step 5 (Write lyrics) — no competing step number
            Text(
              'REVIEW LYRICS',
              style: GoogleFonts.inter(
                fontSize: 12,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
                color: AppColors.accentTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pipeline output lands here (lyrics only). FX tags are in Production → YOUR FX LAYOUT.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 10),

            MdTextField(

              controller: lyricsCtrl,

              label: 'YOUR LYRICS',

              hint:
                  'Songwriter / draft lyrics only — FX arrangement tags live in Production → YOUR FX LAYOUT.',

              maxLines: 10,

              maxLength: 8000,

              onChanged: (t) {

                if (t.trim().isNotEmpty && generateLyrics) {

                  ref.read(generateLyricsProvider.notifier).state = false;

                }

                ref.read(promptFormProvider.notifier).setOptionalLyrics(t);

              },

            ),

            const SizedBox(height: 8),

            ExpansionTile(

              tilePadding: EdgeInsets.zero,

              title: Text(

                'Simple lyric generation (Path C)',

                style: GoogleFonts.inter(

                  fontWeight: FontWeight.w600,

                  fontSize: 13,

                  color: AppColors.textSecondary,

                ),

              ),

              subtitle: Text(

                'Single-pass lyrics during Generate — use Advanced songwriter instead when possible.',

                style: GoogleFonts.inter(

                  fontSize: 11,

                  color: AppColors.textTertiary,

                ),

              ),

              children: [

                SwitchListTile(

                  contentPadding: EdgeInsets.zero,

                  title: Text(

                    'Generate original lyrics (Path C)',

                    style: GoogleFonts.inter(

                      fontWeight: FontWeight.w600,

                      color: AppColors.textPrimary,

                    ),

                  ),

                  value: generateLyrics,

                  onChanged: pipelineOn

                      ? null

                      : (v) {

                          hapticLight();

                          ref.read(generateLyricsProvider.notifier).state = v;

                          if (v) {

                            lyricsCtrl.clear();

                            ref

                                .read(promptFormProvider.notifier)

                                .setOptionalLyrics('');

                          }

                        },

                ),

                if (generateLyrics && !pipelineOn) ...[

                  const SizedBox(height: 8),

                  Text(

                    'TEMPERAMENT (OPTIONAL)',

                    style: GoogleFonts.inter(

                      fontSize: 11,

                      color: AppColors.textTertiary,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Wrap(

                    spacing: 6,

                    runSpacing: 6,

                    children: [

                      for (final c in LyricTemperamentData.codes)

                        FilterChip(

                          label: Text(

                            LyricTemperamentData.labelFor(c),

                            style: GoogleFonts.inter(fontSize: 11),

                          ),

                          selected: temperamentPick.contains(c),

                          onSelected: (_) => toggleTemperament(ref, c),

                          selectedColor: AppColors.chipSelectedFill,
                          checkmarkColor: AppColors.creodomeCyan,
                          side: BorderSide(
                            color: temperamentPick.contains(c)
                                ? AppColors.chipSelectedBorder
                                : AppColors.border,
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: temperamentPick.contains(c)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: temperamentPick.contains(c)
                                ? AppColors.creodomeCyan
                                : AppColors.textSecondary,
                          ),

                        ),

                    ],

                  ),

                ],

              ],

            ),

          ],

        ),

      ),

    );

  }

}


