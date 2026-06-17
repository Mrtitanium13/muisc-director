import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/quick_describe_mapper.dart';
import '../../../core/utils/suno_block2_opt_out.dart';
import '../../../core/utils/suno_format_validation.dart';
import '../../../core/utils/continuation_suggestion_chips.dart';
import '../../../core/utils/suno_output_split.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shell/main_shell.dart';

/// One-shot flow: free text → heuristic [UserInputModel] → generate Suno prompt
/// (with one format QA retry). Syncs the merged model to [promptFormProvider] and
/// opens [OutputScreen] on success.
class QuickDescribeScreen extends ConsumerStatefulWidget {
  const QuickDescribeScreen({super.key});

  @override
  ConsumerState<QuickDescribeScreen> createState() =>
      _QuickDescribeScreenState();
}

class _QuickDescribeScreenState extends ConsumerState<QuickDescribeScreen> {
  final _ctrl = TextEditingController();
  final _continuationCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  QuickDescribeMapResult? _mapped;
  String? _rawOutput;
  FormatValidationResult? _qa;
  double? _score;
  List<String> _suggestionLines = const [];

  @override
  void dispose() {
    _ctrl.dispose();
    _continuationCtrl.dispose();
    super.dispose();
  }

  void _refreshSuggestionsFromOutput(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      _suggestionLines = const [];
      return;
    }
    final parsed = parseSunoOutput(raw);
    _suggestionLines = buildContinuationChips(parsed.suggestionsBody);
  }

  void _applyMappingOnly() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe your track first.')),
      );
      return;
    }
    final base = ref.read(promptFormProvider);
    final mapped = mapQuickDescribeToUserInput(raw, base);
    if (mapped.merged.primaryGenre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No genre detected — name one in the text (e.g. Techno, Pop / Max Martin) '
            'or set a primary genre on the Prompt screen first.',
          ),
        ),
      );
      return;
    }
    ref.read(promptFormProvider.notifier).replace(mapped.merged);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt form updated — open Generate to edit or run again.')),
    );
    context.pop();
  }

  Future<void> _run() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe your track first.')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _mapped = null;
      _rawOutput = null;
      _qa = null;
      _score = null;
      _suggestionLines = const [];
      _continuationCtrl.clear();
    });

    try {
      final base = ref.read(promptFormProvider);
      final mapped = mapQuickDescribeToUserInput(raw, base);
      if (mapped.merged.primaryGenre.isEmpty) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No genre detected — include a genre in your description or pick one on the Prompt screen, then try again.',
            ),
          ),
        );
        return;
      }

      final preferLight =
          ref.read(preferLightweightNextGenerationProvider);
      if (preferLight) {
        ref.read(preferLightweightNextGenerationProvider.notifier).state =
            false;
      }

      final openAi = ref.read(openAiServiceProvider);
      // One LLM call (faster); QA is validated below. Lightweight skips hybrid draft+polish.
      final out = await openAi.generateSunoPrompt(
        mapped.merged,
        preferLightweightModel: true,
      );
      final expectLyrics = !userRequestedBlock2OptOut(mapped.merged);
      final qa = FormatValidationResult.validate(
        out,
        expectLyricsBlock: expectLyrics,
        block1Mode: mapped.merged.sunoFieldOutputMode,
      );
      final score =
          FormatValidationResult.qualityScore(qa, expectLyricsBlock: expectLyrics);
      if (!mounted) return;

      ref.read(promptFormProvider.notifier).replace(mapped.merged);
      ref.read(lastOutputGenerationInputProvider.notifier).state =
          mapped.merged;

      setState(() {
        _mapped = mapped;
        _rawOutput = out;
        _qa = qa;
        _score = score;
        _refreshSuggestionsFromOutput(out);
      });

      context.push('/output', extra: {
        'prompt': out,
        'version': mapped.merged.sunoVersion,
        'field_mode': mapped.merged.sunoFieldOutputMode.name,
        'trusted_generation_input': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runContinuation() async {
    final merged = _mapped?.merged;
    final prior = _rawOutput?.trim();
    final follow = _continuationCtrl.text.trim();
    if (merged == null || prior == null || prior.isEmpty || follow.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preferLight =
          ref.read(preferLightweightNextGenerationProvider);
      if (preferLight) {
        ref.read(preferLightweightNextGenerationProvider.notifier).state =
            false;
      }

      final openAi = ref.read(openAiServiceProvider);
      final out = await openAi.generateSunoPromptWithFormatRetry(
        merged,
        preferLightweightModel: preferLight,
        continuationPriorOutput: prior,
        continuationUserRequest: follow,
      );
      final expectLyrics = !userRequestedBlock2OptOut(merged);
      final qa = FormatValidationResult.validate(
        out,
        expectLyricsBlock: expectLyrics,
        block1Mode: merged.sunoFieldOutputMode,
      );
      final score =
          FormatValidationResult.qualityScore(qa, expectLyricsBlock: expectLyrics);
      if (!mounted) return;
      setState(() {
        _rawOutput = out;
        _qa = qa;
        _score = score;
        _refreshSuggestionsFromOutput(out);
      });

      ref.read(lastOutputGenerationInputProvider.notifier).state = merged;
      context.push('/output', extra: {
        'prompt': out,
        'version': merged.sunoVersion,
        'field_mode': merged.sunoFieldOutputMode.name,
        'trusted_generation_input': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _mapped != null &&
        (_rawOutput?.trim().isNotEmpty ?? false) &&
        _continuationCtrl.text.trim().isNotEmpty &&
        !_busy;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quick describe'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MainShell.contentBottomPadding(context),
        ),
        children: [
          Text(
            'Type a single description. The app maps BPM, genre, key, Suno codes, '
            'Hitmaker / Max Martin lane, Simple field mode, and target length (e.g. 3:45) '
            'into your prompt form, then generates a Suno-ready Block 1 + Block 2 '
            '(one format QA retry when needed). Uses your current Prompt form settings '
            'as a base — open Generate first if you want a specific Suno version or structure.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Describe your track',
              hintText:
                  'e.g. Melodic techno 126 BPM A minor, airy pads — simple mode · 4:12 target',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _run,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate prompt'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _applyMappingOnly,
                  child: const Text('Apply to form'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
            ),
          ],
          if (_mapped != null) ...[
            const SizedBox(height: 16),
            Text(
              'Applied hints',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mapped!.appliedHints.isEmpty
                  ? '(none)'
                  : _mapped!.appliedHints.join(' · '),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Merged: genre=${_mapped!.merged.primaryGenre.isEmpty ? '—' : _mapped!.merged.primaryGenre}, '
              'bpm=${_mapped!.merged.bpm ?? '—'}, '
              'mode=${_mapped!.merged.sunoFieldOutputMode.name}, '
              'generateLyrics=${_mapped!.merged.generateLyrics}, '
              'temperaments=${_mapped!.merged.lyricTemperamentCodes.isEmpty ? '—' : _mapped!.merged.lyricTemperamentCodes}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11),
            ),
          ],
          if (_qa != null && _score != null) ...[
            const SizedBox(height: 16),
            Text(
              'Format QA score: ${(_score! * 100).round()}%',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'B1 chars ${_qa!.block1CharCount}/${_qa!.block1CharLimit} · '
              'B2 chars ${_qa!.block2CharCount} · '
              'End ${_qa!.hasEndTag} · B2 banner ${_qa!.hasBlock2Banner}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11),
            ),
          ],
          if (_rawOutput != null) ...[
            const SizedBox(height: 16),
            Text(
              'Last output (also opened Output screen)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _rawOutput!,
              style: GoogleFonts.jetBrainsMono(fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Continue with a follow-up',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste a suggestion from below the output (after [End]) or type your own. '
              'Generates a new full Block 1 + Block 2 and opens Output again.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.35,
              ),
            ),
            if (_suggestionLines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tap a suggestion to fill the box',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestionLines.map((line) {
                  final short =
                      line.length > 72 ? '${line.substring(0, 72)}…' : line;
                  return ActionChip(
                    label: Text(
                      short,
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _continuationCtrl.text = line;
                            });
                          },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _continuationCtrl,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Follow-up / continuation',
                hintText: 'e.g. → Add more ad-libs in the hook',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: canContinue ? _runContinuation : null,
              child: const Text('Apply follow-up (regenerate)'),
            ),
          ],
        ],
      ),
    );
  }
}
