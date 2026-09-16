import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/suno_prompt_limits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/clipboard_utils.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/utils/suno_block1_trim.dart'
    show smartTrimBlock1Prose;
import '../../../core/utils/suno_format_validation.dart';
import '../../../core/utils/suno_lyrics_merge.dart';
import '../../../core/utils/continuation_suggestion_chips.dart';
import '../../../core/utils/suno_output_split.dart';
import '../../../data/models/saved_prompt_model.dart';
import '../../../data/models/suno_field_output_mode.dart';
import '../../../data/models/user_input_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/suno_paste_diagram.dart';

class OutputScreen extends ConsumerStatefulWidget {
  const OutputScreen({
    super.key,
    required this.prompt,
    required this.sunoVersion,
    this.fieldMode = 'custom',
    this.trustedGenerationInput = false,
  });

  final String prompt;
  final String sunoVersion;

  /// Route extra: `custom` or `simple`.
  final String fieldMode;

  /// When true, follow-up uses [lastOutputGenerationInputProvider] from the last live generate.
  final bool trustedGenerationInput;

  @override
  ConsumerState<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends ConsumerState<OutputScreen> {
  late String _prompt;
  final _continuationCtrl = TextEditingController();
  bool _continuationBusy = false;

  SunoFieldOutputMode get _fieldOutputMode =>
      widget.fieldMode.trim().toLowerCase() == 'simple'
          ? SunoFieldOutputMode.simple
          : SunoFieldOutputMode.custom;

  @override
  void initState() {
    super.initState();
    _prompt = widget.prompt;
  }

  @override
  void didUpdateWidget(OutputScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt != widget.prompt) {
      _prompt = widget.prompt;
    }
  }

  @override
  void dispose() {
    _continuationCtrl.dispose();
    super.dispose();
  }

  UserInputModel _userInputForContinuation() {
    if (widget.trustedGenerationInput) {
      final snap = ref.read(lastOutputGenerationInputProvider);
      if (snap != null) return snap;
    }
    return ref.read(promptFormProvider);
  }

  Future<void> _applyContinuation() async {
    final follow = _continuationCtrl.text.trim();
    final prior = _prompt.trim();
    if (follow.isEmpty || prior.isEmpty) return;
    final input = _userInputForContinuation();
    setState(() => _continuationBusy = true);
    try {
      final out =
          await ref.read(openAiServiceProvider).generateSunoPromptWithFormatRetry(
                input,
                continuationPriorOutput: prior,
                continuationUserRequest: follow,
              );
      if (!mounted) return;
      setState(() {
        _prompt = out;
        _continuationCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated with follow-up')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follow-up failed: ${dioErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _continuationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _prompt.trim().isEmpty
        ? 0
        : _prompt.trim().split(RegExp(r'\s+')).length;
    final split = parseSunoOutput(_prompt);
    final unified = split.unifiedTwoBlockFormat;
    final hasStructure = split.structureBody != null &&
        split.structureBody!.trim().isNotEmpty;
    final hasLyricsSection =
        split.lyricsBody != null && split.lyricsBody!.trim().isNotEmpty;
    final mergedLyricsPaste = mergedSunoLyricsForPaste(
      structureBody: split.structureBody,
      lyricsBody: split.lyricsBody,
    );
    final lyricsForSunoBox =
        (mergedLyricsPaste ?? split.lyricsBody?.trim() ?? '').trim();
    final block1Text = (split.styleBody ?? '').trim();
    final expectLyrics = unified;
    final showBlock2MissingWarning =
        unified && split.unifiedBlock2Missing && block1Text.isNotEmpty;
    final validation = _prompt.trim().isEmpty
        ? null
        : FormatValidationResult.validate(
            _prompt,
            expectLyricsBlock: expectLyrics,
            block1Mode: _fieldOutputMode,
          );
    final block1CharCap =
        SunoPromptLimits.block1CharHardCapForMode(_fieldOutputMode);
    final block1Len = block1Text.length;
    final block1WordCount = block1Text.isEmpty
        ? 0
        : block1Text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final block1WordRange =
        SunoPromptLimits.block1StyleWordRangeFor(widget.sunoVersion);
    final block1OverChars = unified && block1Len > block1CharCap;
    final block1OverWords =
        unified && block1WordCount > SunoPromptLimits.block1StyleWordHardMax;
    final canCopyStyle = block1Text.isNotEmpty;
    final showCopyRow =
        hasStructure || hasLyricsSection || canCopyStyle;
    final quality = validation == null
        ? null
        : FormatValidationResult.qualityScore(
            validation,
            expectLyricsBlock: expectLyrics,
          );
    final showEndWarning =
        unified && hasLyricsSection && !split.block2HasEndTag;
    final suggestionText = split.suggestionsBody?.trim() ?? '';
    final hasSuggestions = suggestionText.isNotEmpty;
    final suggestionLineChips =
        buildContinuationChips(split.suggestionsBody);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Generated Prompt'),
        actions: [
          IconButton(
            onPressed: () {
              hapticLight();
              Share.share(_prompt, subject: 'Suno prompt');
            },
            icon: const Icon(PhosphorIconsRegular.shareNetwork),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Suno ${widget.sunoVersion}'),
                  backgroundColor:
                      AppColors.accentPrimary.withValues(alpha: 0.2),
                ),
                Chip(label: Text('$words words')),
                if (hasStructure) ...[
                  Chip(
                    label: const Text('Structure'),
                    backgroundColor:
                        AppColors.accentSecondary.withValues(alpha: 0.2),
                  ),
                ],
                Chip(
                  label: Text(
                    unified
                        ? (_fieldOutputMode == SunoFieldOutputMode.simple
                            ? 'Block 1 · Description'
                            : 'Block 1 · Style')
                        : 'Style',
                  ),
                  backgroundColor:
                      AppColors.accentPrimary.withValues(alpha: 0.12),
                ),
                if (unified && block1Text.isNotEmpty) ...[
                  Chip(
                    label: Text(
                      '$block1WordCount / ${block1WordRange.min}–${block1WordRange.max} words',
                    ),
                    backgroundColor: block1OverWords
                        ? Colors.red.withValues(alpha: 0.12)
                        : block1WordCount >= block1WordRange.max - 5
                            ? Colors.amber.withValues(alpha: 0.14)
                            : Colors.green.withValues(alpha: 0.12),
                  ),
                  Chip(
                    label: Text('$block1Len / $block1CharCap chars'),
                    backgroundColor: block1OverChars
                        ? Colors.red.withValues(alpha: 0.12)
                        : block1Len >= block1CharCap - 15
                            ? Colors.amber.withValues(alpha: 0.14)
                            : Colors.green.withValues(alpha: 0.12),
                  ),
                ],
                if (hasLyricsSection)
                  Chip(
                    label: Text(unified ? 'Block 2 · Lyrics' : 'Lyrics'),
                    backgroundColor:
                        AppColors.accentTertiary.withValues(alpha: 0.15),
                  ),
                if (kDebugMode && quality != null)
                  Chip(
                    label: Text('Format ${(quality * 100).round()}%'),
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.15),
                  ),
              ],
            ),
            if (unified) ...[
              const SizedBox(height: 12),
              const SunoPasteDiagram(),
            ],
            if (unified && (block1OverChars || block1OverWords)) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.warningCircle,
                      color: Colors.red.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        block1OverChars && block1OverWords
                            ? 'Block 1 exceeds Suno’s $block1CharCap-character limit by '
                                '${block1Len - block1CharCap} and exceeds '
                                '${SunoPromptLimits.block1StyleWordHardMax} words by '
                                '${block1WordCount - SunoPromptLimits.block1StyleWordHardMax}. '
                                'Use Trim & copy below.'
                            : block1OverChars
                                ? 'Block 1 is ${block1Len - block1CharCap} characters over '
                                    'Suno’s $block1CharCap-character limit. Use Trim & copy below.'
                                : 'Block 1 is '
                                    '${block1WordCount - SunoPromptLimits.block1StyleWordHardMax} '
                                    'words over the ${SunoPromptLimits.block1StyleWordHardMax}-word cap. '
                                    'Use Trim & copy below.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (validation != null &&
                expectLyrics &&
                validation.block2CharCount >
                    SunoPromptLimits.lyricsCharLimit) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Block 2 exceeds ${SunoPromptLimits.lyricsCharLimit} characters '
                  '(${validation.block2CharCount}). Trim in an editor before pasting.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                ),
              ),
            ],
            if (showEndWarning) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.warningCircle,
                      color: Colors.amber.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Block 2 may be incomplete: no [End] tag detected. '
                        'Copy carefully and check Suno’s Lyrics field for truncation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showBlock2MissingWarning) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.warningCircle,
                      color: Colors.amber.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Song structure (Block 2 · Lyrics field) was not returned. '
                        'Regenerate with the same settings, or add “no lyrics” / “style only” '
                        'to your vibe if you only want Block 1.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                _prompt,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (hasSuggestions) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  suggestionText,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (_prompt.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              if (!widget.trustedGenerationInput) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIconsRegular.info,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Follow-up uses your current Prompt Generator fields. '
                          'Adjust them to match this prompt if you opened it from History.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Continue with a follow-up',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Paste a suggestion from above or type your own. The model returns a full '
                'new Block 1 + Block 2.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              if (suggestionLineChips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap a suggestion to fill the box (includes smart defaults)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestionLineChips.map((line) {
                    final short = line.length > 72
                        ? '${line.substring(0, 72)}…'
                        : line;
                    return ActionChip(
                      label: Text(
                        short,
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                      onPressed: _continuationBusy
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
                  hintText: 'e.g. → Heavier drums in the chorus',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: !_continuationBusy &&
                        _continuationCtrl.text.trim().isNotEmpty
                    ? () {
                        hapticLight();
                        _applyContinuation();
                      }
                    : null,
                child: _continuationBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply follow-up (regenerate full output)'),
              ),
            ],
            const SizedBox(height: 12),
            if (showCopyRow)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasStructure)
                    OutlinedButton.icon(
                      onPressed: () async {
                        hapticLight();
                        await copyToClipboard(split.structureBody!.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Structure block copied'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        PhosphorIconsRegular.treeStructure,
                        size: 20,
                      ),
                      label: const Text('Copy structure'),
                    ),
                  if (canCopyStyle)
                    OutlinedButton.icon(
                      onPressed: () async {
                        hapticLight();
                        final t = (split.styleBody ?? _prompt).trim();
                        await copyToClipboard(t);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                unified
                                    ? (_fieldOutputMode ==
                                            SunoFieldOutputMode.simple
                                        ? 'Block 1 copied — paste into Suno Description'
                                        : 'Block 1 copied — paste into Suno Style')
                                    : 'SUNO STYLE copied',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        PhosphorIconsRegular.musicNote,
                        size: 20,
                      ),
                      label: Text(
                        unified
                            ? (_fieldOutputMode == SunoFieldOutputMode.simple
                                ? 'Copy Block 1 (Description)'
                                : 'Copy Block 1 (Style)')
                            : 'Copy style',
                      ),
                    ),
                  if (canCopyStyle &&
                      unified &&
                      (block1OverChars || block1OverWords))
                    OutlinedButton.icon(
                      onPressed: () async {
                        hapticLight();
                        final flat = block1Text
                            .replaceAll(RegExp(r'[\r\n]+'), ' ')
                            .replaceAll(RegExp(r'\s+'), ' ')
                            .trim();
                        final trimmed = smartTrimBlock1Prose(
                          flat,
                          maxWords:
                              SunoPromptLimits.block1StyleWordHardMax,
                          maxChars: block1CharCap,
                        );
                        await copyToClipboard(trimmed);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Trimmed to ${trimmed.length} chars and copied',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(PhosphorIconsRegular.scissors),
                      label: const Text('Trim Block 1 & copy'),
                    ),
                  if (hasLyricsSection)
                    OutlinedButton.icon(
                      onPressed: () async {
                        hapticLight();
                        await copyToClipboard(lyricsForSunoBox);
                        if (context.mounted) {
                          final extra = hasStructure &&
                                  mergedLyricsPaste != null &&
                                  mergedLyricsPaste.trim() !=
                                      split.lyricsBody!.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                unified
                                    ? 'Block 2 copied — paste into Suno Lyrics'
                                    : extra
                                        ? 'Lyrics copied (section order from SUNO STRUCTURE)'
                                        : 'SUNO LYRICS copied',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        PhosphorIconsRegular.textAa,
                        size: 20,
                      ),
                      label: Text(
                        unified
                            ? 'Copy Block 2 (Lyrics)'
                            : hasStructure
                                ? 'Copy lyrics (Suno box)'
                                : 'Copy lyrics',
                      ),
                    ),
                ],
              ),
            if (showCopyRow) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      hapticLight();
                      await copyToClipboard(_prompt);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              showCopyRow
                                  ? 'Full output copied'
                                  : 'Copied',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(PhosphorIconsRegular.copy),
                    label: Text(
                      showCopyRow ? 'Copy all' : 'Copy',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      hapticLight();
                      final genre =
                          ref.read(promptFormProvider).primaryGenre;
                      await ref.read(hiveStorageProvider).save(
                            SavedPromptModel(
                              id: const Uuid().v4(),
                              createdAt: DateTime.now(),
                              genreTag: genre.isEmpty ? 'General' : genre,
                              promptText: _prompt,
                              sunoVersion: widget.sunoVersion,
                            ),
                          );
                      ref.read(promptHistoryRevisionProvider.notifier).state++;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to history')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GradientButton(
              label: 'REGENERATE (same settings)',
              icon: PhosphorIconsRegular.arrowsClockwise,
              onPressed: () {
                hapticLight();
                ref.read(preferLightweightNextGenerationProvider.notifier).state =
                    true;
                Navigator.of(context).pop();
              },
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
