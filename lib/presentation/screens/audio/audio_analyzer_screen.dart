import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:record/record.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/genre_data.dart';
import '../../../core/platform/audio_playback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/audio_session.dart';
import '../../../services/composition_pipeline_service.dart';
import '../../providers/app_providers.dart';
import '../../utils/show_user_notices.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/shell/main_shell.dart';
import '../../widgets/common/gradient_button.dart';
import '../../../features/prompt_generator/providers/prompt_form_providers.dart';
import '../../../features/prompt_generator/widgets/sections/analyzer_integration_section.dart';

class AudioAnalyzerScreen extends ConsumerStatefulWidget {
  const AudioAnalyzerScreen({super.key});

  @override
  ConsumerState<AudioAnalyzerScreen> createState() =>
      _AudioAnalyzerScreenState();
}

class _AudioAnalyzerScreenState extends ConsumerState<AudioAnalyzerScreen> {
  final _player = AudioPlayer();
  final _recorder = AudioRecorder();
  Timer? _tick;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _recording = false;
  int _seconds = 0;
  bool _busy = false;
  bool _remixBusy = false;
  late String _remixTargetGenre;
  bool _remixDjIntro = false;
  bool _remixDjOutro = false;

  @override
  void initState() {
    super.initState();
    _remixTargetGenre = GenreData.remixTargetGenres.contains(
      GenreData.remixTargetDefault,
    )
        ? GenreData.remixTargetDefault
        : GenreData.remixTargetGenres.first;
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
      ref.read(audioDurationProvider.notifier).state = d;
    });
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _playing = s.playing);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerFor(AudioSession session) async {
    ref.read(audioDurationProvider.notifier).state = null;
    if (mounted) setState(() => _duration = Duration.zero);
    final src = await createPlaybackSource(
      filePath: session.path,
      bytes: session.bytes,
      fileName: session.name,
    );
    if (kIsWeb) {
      await _player.setUrl(src);
    } else {
      await _player.setFilePath(src);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickFile() async {
    hapticLight();
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: kIsWeb,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'flac'],
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    if (kIsWeb) {
      final bytes = f.bytes;
      final name = f.name;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read file bytes (try a smaller file).'),
            ),
          );
        }
        return;
      }
      ref.read(audioSessionProvider.notifier).state =
          AudioSession(bytes: bytes, name: name.isEmpty ? 'audio' : name);
    } else {
      final path = f.path;
      if (path == null) return;
      ref.read(audioSessionProvider.notifier).state = AudioSession(
        path: path,
        name: f.name.isEmpty ? p.basename(path) : f.name,
      );
    }
    final loaded = ref.read(audioSessionProvider);
    if (loaded != null) await _loadPlayerFor(loaded);
  }

  Future<void> _toggleRecord() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recording is not available in the web app — upload a file from your PC.',
            ),
          ),
        );
      }
      return;
    }

    hapticMedium();
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required.')),
        );
      }
      return;
    }

    if (!_recording) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/md_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    } else {
      _tick?.cancel();
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) {
        final name = p.basename(path);
        final session = AudioSession(path: path, name: name);
        ref.read(audioSessionProvider.notifier).state = session;
        await _loadPlayerFor(session);
      }
    }
  }

  Future<void> _analyze() async {
    final session = ref.read(audioSessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load or record audio first.')),
      );
      return;
    }
    hapticLight();
    setState(() => _busy = true);
    try {
      final result = await ref.read(audioRepositoryProvider).analyze(session);
      ref.read(analysisResultProvider.notifier).state = result;
      final base = ref.read(analyzeBaseUrlProvider);
      final demo = base == null || base.isEmpty;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              demo
                  ? 'Demo analysis only — set Music Director API URL in Settings for real results.'
                  : 'Analysis complete',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${dioErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playPause() async {
    hapticLight();
    if (ref.read(audioSessionProvider) == null) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _useInPrompt() {
    final a = ref.read(analysisResultProvider);
    if (a == null) return;
    hapticLight();
    final d = ref.read(audioDurationProvider);
    ref.read(promptFormProvider.notifier).applyAnalysis(
          a,
          trackDurationLabel: (d != null && d > Duration.zero)
              ? formatTrackDuration(d)
              : null,
        );
    context.go('/generate');
  }

  Future<void> _generateRemixPrompt() async {
    final analysis = ref.read(analysisResultProvider);
    if (analysis == null) return;

    hapticLight();
    setState(() => _remixBusy = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => Center(
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.accentPrimary),
                const SizedBox(height: 16),
                Text(
                  'Composing remix prompt…',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final d = ref.read(audioDurationProvider);
      ref.read(promptFormProvider.notifier).applyRemixFromAnalysis(
          analysis: analysis,
          targetGenre: _remixTargetGenre,
          trackDurationLabel: (d != null && d > Duration.zero)
              ? formatTrackDuration(d)
              : null,
          djIntroMixIn: _remixDjIntro,
          djOutroMixOut: _remixDjOutro,
        );
      // Clear interpolation controllers (mutual exclusion with analyzer flip).
      ref.read(remixSongTitleControllerProvider).clear();
      ref.read(remixArtistControllerProvider).clear();
      final form = ref.read(promptFormProvider);
      final composition = CompositionPipelineService.run(userInput: form);
      ref.read(promptFormProvider.notifier)
        ..setOptionalLyrics(composition.composedInput.optionalLyrics)
        ..setVibe(composition.composedInput.vibe);
      if (mounted) showUserNotices(context, composition.userNotices);
      final text = await ref
          .read(aiRepositoryProvider)
          .generatePrompt(composition.composedInput);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref.read(lastOutputGenerationInputProvider.notifier).state =
          composition.composedInput;
      context.push(
        '/output',
        extra: {
          'prompt': text,
        'version': composition.composedInput.sunoVersion,
        'field_mode': composition.composedInput.sunoFieldOutputMode.name,
          'trusted_generation_input': true,
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remix prompt failed: ${dioErrorMessage(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _remixBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(audioSessionProvider);
    final analysis = ref.watch(analysisResultProvider);
    final hasAudio = session != null;
    final analyzeBase = ref.watch(analyzeBaseUrlProvider);
    final usingDemoAnalysis = analyzeBase == null || analyzeBase.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Audio Analyzer')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MainShell.contentBottomPadding(context),
        ),
        children: [
          if (usingDemoAnalysis)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.info,
                            color: AppColors.accentPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo analysis (not your file)',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Music Director API URL is configured. The app shows placeholder BPM '
                        'and fixed genre/mood tags. Deploy the FastAPI server from the repo '
                        '(server/) and set MD_API_BASE_URL in Settings (or .env) so POST /analyze '
                        'runs Gemini 2.5 analysis (genre, mood, BPM/key, structure, lyrics).',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  title: 'Upload',
                  subtitle: 'MP3, WAV, M4A…',
                  icon: PhosphorIconsRegular.uploadSimple,
                  onTap: _pickFile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeCard(
                  title: 'Record',
                  subtitle: kIsWeb
                      ? 'Use desktop for now'
                      : (_recording ? _fmt(_seconds) : 'Tap to record'),
                  icon: PhosphorIconsRegular.microphone,
                  onTap: _toggleRecord,
                  highlight: _recording,
                  dimmed: kIsWeb,
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Web: upload stems or bounces from your PC. Deploy the API and set MD_API_BASE_URL for real analysis.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Waveform',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _wavePlaceholder(hasAudio),
          const SizedBox(height: 12),
          if (hasAudio)
            Row(
              children: [
                IconButton(
                  onPressed: _playPause,
                  icon: Icon(
                    _playing ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _duration.inMilliseconds == 0
                        ? 0
                        : _position.inMilliseconds /
                            _duration.inMilliseconds.clamp(1, 1 << 30),
                    onChanged: (v) async {
                      final ms = (v * _duration.inMilliseconds).round();
                      await _player.seek(Duration(milliseconds: ms));
                    },
                  ),
                ),
                Text(
                  '${_fmt(_position.inSeconds)} / ${_fmt(_duration.inSeconds)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          if (hasAudio && _duration > Duration.zero)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Track length: ${formatTrackDuration(_duration)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 16),
          GradientButton(
            label: _busy ? 'ANALYZING… (may take 1–3 min)' : 'ANALYZE TRACK',
            icon: PhosphorIconsRegular.pulse,
            enabled: hasAudio && !_busy,
            onPressed: _analyze,
          ),
          if (analysis != null) ...[
            const SizedBox(height: 20),
            Text(
              'Analysis Results',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              accentBorder: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow('Title', analysis.title),
                  _resultRow('Artist', analysis.artist),
                  _resultRow('Album', analysis.album),
                  if (analysis.releaseDate.trim().isNotEmpty)
                    _resultRow('Release', analysis.releaseDate),
                  if (analysis.richDescription != null &&
                      analysis.richDescription!.trim().isNotEmpty)
                    _resultRow('Summary', analysis.richDescription!.trim()),
                  _resultRow(
                    'BPM',
                    analysis.bpm != null
                        ? analysis.bpm!.toStringAsFixed(0)
                        : '—',
                  ),
                  _resultRow('Energy', analysis.energy ?? '—'),
                  _resultRow('Key & scale', analysis.keyScale ?? '—'),
                  _resultRow('Genre', analysis.genre ?? '—'),
                  if (analysis.subGenre != null &&
                      analysis.subGenre!.trim().isNotEmpty)
                    _resultRow('Sub-genre', analysis.subGenre!),
                  _resultRow('Loudness', analysis.loudness ?? '—'),
                  _resultRow(
                    'Mood',
                    analysis.moodTags.isEmpty
                        ? '—'
                        : analysis.moodTags.join(' · '),
                  ),
                  if (analysis.vocals != null && analysis.vocals!.trim().isNotEmpty)
                    _resultRow('Vocals', analysis.vocals!),
                  if (analysis.structure != null &&
                      analysis.structure!.trim().isNotEmpty)
                    _resultRow('Structure', analysis.structure!),
                  _resultRow(
                    'Instruments',
                    analysis.instruments.isEmpty
                        ? '—'
                        : analysis.instruments.join(' · '),
                  ),
                  if (analysis.hasLyrics)
                    _resultRow(
                      'Lyrics',
                      analysis.lyricsTranscription!.length > 400
                          ? '${analysis.lyricsTranscription!.substring(0, 400)}…'
                          : analysis.lyricsTranscription!,
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        if (analysis.analysisMode != null)
                          Chip(
                            label: Text(
                              analysis.analysisMode!,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        Chip(
                          label: Text(
                            'Confidence: ${analysis.confidenceOverall}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'USE IN PROMPT GENERATOR',
                    onPressed: _useInPrompt,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const AnalyzerIntegrationSection(),
          if (analysis != null) ...[
            const SizedBox(height: 20),
            Text(
              'Remix to another genre',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Builds a Suno-ready prompt that reframes this track’s DNA into your chosen genre (text prompt — use Suno to render audio).',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'TARGET GENRE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: GenreData.remixTargetGenres.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final g = GenreData.remixTargetGenres[i];
                        final sel = _remixTargetGenre == g;
                        return ChoiceChip(
                          label: Text(g, style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          onSelected: (_) {
                            hapticSelection();
                            setState(() => _remixTargetGenre = g);
                          },
                          selectedColor:
                              AppColors.accentPrimary.withValues(alpha: 0.35),
                          labelStyle: TextStyle(
                            color: sel
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('DJ intro (mix-in)'),
                    subtitle: Text(
                      'Extended intro for blending from the previous track',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    value: _remixDjIntro,
                    onChanged: (v) => setState(() => _remixDjIntro = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('DJ outro (mix-out)'),
                    subtitle: Text(
                      'Extended outro for blending into the next track',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    value: _remixDjOutro,
                    onChanged: (v) => setState(() => _remixDjOutro = v),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'GENERATE REMIX PROMPT',
                    icon: PhosphorIconsRegular.arrowsClockwise,
                    enabled: !_remixBusy,
                    onPressed: _generateRemixPrompt,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Uses the Suno version from Generate (${ref.watch(promptFormProvider).sunoVersion}) — '
                      'SUNO STRUCTURE + SUNO STYLE follow that tier’s word budgets for paste-friendly length.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
    bool dimmed = false,
  }) {
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: GlassCard(
        accentBorder: highlight,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wavePlaceholder(bool hasAudio) {
    if (hasAudio) {
      return SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(28, (i) {
            final h = 16.0 + (i * 17 % 40);
            return Container(
              width: 4,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: AppColors.ctaGradient,
              ),
            );
          }),
        ),
      );
    }
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _resultRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
