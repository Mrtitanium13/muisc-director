import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/engine_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/duration_budgeter.dart';
import '../../../services/lyric_linter.dart';
import '../../../services/reroll_coach.dart';
import '../../../widgets/lint_highlight_controller.dart';
import '../providers/artifact_providers.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late final LintHighlightController _lyricsController;
  Timer? _debounce;
  int _prevLyricsLen = 0;
  List<LintIssue> _currentIssues = [];

  @override
  void initState() {
    super.initState();
    _lyricsController = LintHighlightController();
    _lyricsController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lyricsController.removeListener(_onControllerChanged);
    _lyricsController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final text = _lyricsController.text;
    final lenJump = (text.length - _prevLyricsLen).abs();
    _prevLyricsLen = text.length;

    if (lenJump > 20) {
      final normalized = LyricLinter.normalizeLyrics(text);
      if (normalized != text) {
        _lyricsController.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
        ref.read(artifactFormProvider.notifier).setLyrics(normalized);
        return;
      }
    }

    ref.read(artifactFormProvider.notifier).setLyrics(text);
    _debounceLint(text);
  }

  void _debounceLint(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final cap = ref.read(assemblerOutputProvider).syllableCap;
      final issues = text.trim().isEmpty
          ? <LintIssue>[]
          : LyricLinter.lint(text, syllableCap: cap);
      _lyricsController.updateIssues(issues);
      setState(() => _currentIssues = issues);
    });
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _insertBracket(String bracket) {
    final text = _lyricsController.text;
    final sel = _lyricsController.selection;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final before = text.substring(0, pos);
    final after = text.substring(pos);
    final prefix = before.isEmpty || before.endsWith('\n') ? '' : '\n';
    final insertion = '$prefix$bracket\n';
    final newText = before + insertion + after;
    final newPos = (before + insertion).length;
    _lyricsController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPos),
    );
  }

  void _applyLineFix(LintIssue issue) {
    if (issue.fix == null) return;
    final lines = _lyricsController.text.split('\n');
    if (issue.line < 0 || issue.line >= lines.length) {
      if (issue.code == 'MISSING_END') {
        _lyricsController.text = '${_lyricsController.text.trimRight()}\n\n[End]';
      }
      return;
    }
    lines[issue.line] = issue.fix!;
    _lyricsController.text = lines.join('\n');
  }

  void _fixAll() {
    final fixed = LyricLinter.autoFix(_lyricsController.text);
    _lyricsController.text = fixed;
  }

  void _showDurationBreakdown(DurationResult result) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section breakdown',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            if (result.breakdown.isEmpty)
              const Text(
                'Add section brackets to estimate duration.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              for (final s in result.breakdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.section,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        _formatDuration(s.seconds),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showRerollSheet() {
    final form = ref.read(artifactFormProvider);
    final failCount = form.failCount + 1;
    ref.read(artifactFormProvider.notifier).incrementFailCount();
    final coach = RerollCoach.getSimplifiedRetry(form.input, failCount);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.paddingOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simplified retry (attempt $failCount)',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              coach.coachMessage,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            _PromptCard(
              title: 'Style prompt',
              text: coach.output.stylePrompt,
              onCopy: () => _copy(coach.output.stylePrompt),
            ),
            const SizedBox(height: 8),
            _PromptCard(
              title: 'Exclude styles',
              text: coach.output.excludeStyles,
              onCopy: () => _copy(coach.output.excludeStyles),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVerified() async {
    final form = ref.read(artifactFormProvider);
    final output = ref.read(assemblerOutputProvider);
    await RerollCoach.saveVerifiedPrompt(
      VerifiedPrompt(
        stylePrompt: output.stylePrompt,
        excludeStyles: output.excludeStyles,
        input: form.input,
        savedAt: DateTime.now().toIso8601String(),
      ),
    );
    ref.read(artifactFormProvider.notifier).resetFailCount();
    ref.invalidate(verifiedPromptsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Verified library')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(artifactFormProvider);
    final output = ref.watch(assemblerOutputProvider);
    final duration = ref.watch(durationResultProvider);
    final visibleWarnings = output.warnings
        .where((w) => !form.dismissedWarnings.contains(w))
        .toList();
    final showSheenTip = visibleWarnings.contains(EngineConfig.v5SheenTip);
    final maxGenres = EngineConfig.maxGenresByModel[form.modelVersion] ??
        EngineConfig.maxGenreTokens;
    final modelProfile = EngineConfig.modelProfiles[form.modelVersion]!;

    final budgetRatio = output.budgetMax > 0
        ? (output.tokenCount / output.budgetMax).clamp(0.0, 1.5)
        : 0.0;
    final overBudget = output.tokenCount > output.budgetMax;
    final durationRatio = duration.maxSongDurationSec > 0
        ? (duration.estimatedSeconds / duration.maxSongDurationSec)
            .clamp(0.0, 1.0)
        : 0.0;
    final safeMarkerRatio = duration.maxSongDurationSec > 0
        ? (duration.safeLimitSeconds / duration.maxSongDurationSec)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'v${EngineConfig.version}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          _sectionLabel('Model version'),
          DropdownButtonFormField<String>(
            initialValue: form.modelVersion,
            dropdownColor: AppColors.surfaceElevated,
            decoration: _inputDecoration(),
            items: [
              for (final key in EngineConfig.modelProfiles.keys)
                DropdownMenuItem(value: key, child: Text(key)),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(artifactFormProvider.notifier).setModelVersion(v);
              }
            },
          ),
          if (modelProfile.versionNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final note in modelProfile.versionNotes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  note,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          _sectionLabel('Genre (max $maxGenres)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in EngineConfig.genreFamilies.entries)
                FilterChip(
                  label: Text(entry.value.label),
                  selected: form.genres.contains(entry.key),
                  onSelected: (_) =>
                      ref.read(artifactFormProvider.notifier).toggleGenre(entry.key),
                  selectedColor: AppColors.accentPrimary.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.accentPrimary,
                  labelStyle: TextStyle(
                    color: form.genres.contains(entry.key)
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Tempo'),
          SegmentedButton<String>(
            segments: [
              for (final entry in EngineConfig.tempoEnergy.entries)
                ButtonSegment(
                  value: entry.key,
                  label: Text(
                    entry.value.label.split(' / ').first,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
            selected: {form.tempo},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) {
                ref.read(artifactFormProvider.notifier).setTempo(s.first);
              }
            },
          ),
          const SizedBox(height: 16),
          _sectionLabel('Vocal profile'),
          DropdownButtonFormField<String>(
            initialValue: form.vocal,
            dropdownColor: AppColors.surfaceElevated,
            decoration: _inputDecoration(),
            items: [
              for (final entry in EngineConfig.vocalProfiles.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.label),
                ),
            ],
            onChanged: (v) {
              if (v != null) ref.read(artifactFormProvider.notifier).setVocal(v);
            },
          ),
          const SizedBox(height: 16),
          _sectionLabel('Mood (optional)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mood in EngineConfig.moodOptions)
                ChoiceChip(
                  label: Text(mood),
                  selected: form.mood == mood,
                  onSelected: (sel) => ref
                      .read(artifactFormProvider.notifier)
                      .setMood(sel ? mood : null),
                  selectedColor: AppColors.accentPrimary.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    color: form.mood == mood
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          for (final w in visibleWarnings)
            _WarningBanner(
              message: w,
              onDismiss: () =>
                  ref.read(artifactFormProvider.notifier).dismissWarning(w),
            ),
          if (showSheenTip) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final token in EngineConfig.humanizingTokens)
                  ActionChip(
                    label: Text(token, style: const TextStyle(fontSize: 11)),
                    onPressed: () => ref
                        .read(artifactFormProvider.notifier)
                        .addCustomToken(token),
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: const TextStyle(color: AppColors.accentPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (output.isInstrumental)
            Card(
              color: AppColors.accentPrimary.withValues(alpha: 0.12),
              margin: const EdgeInsets.only(bottom: 12),
              child: const ListTile(
                leading: Icon(PhosphorIconsRegular.info, color: AppColors.accentPrimary),
                title: Text(
                  "Enable Suno's Instrumental toggle — it is more reliable than prompt text.",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ),
          _PromptCard(
            title: 'Style prompt',
            text: output.stylePrompt.isEmpty ? '—' : output.stylePrompt,
            onCopy: () => _copy(output.stylePrompt),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: budgetRatio.clamp(0.0, 1.0),
                        backgroundColor: AppColors.border,
                        color: overBudget ? AppColors.error : AppColors.success,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${output.tokenCount}/${output.budgetMax}',
                      style: TextStyle(
                        color: overBudget ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _PromptCard(
            title: 'Exclude styles',
            subtitle: "Paste into Suno's Exclude Styles box",
            text: output.excludeStyles,
            onCopy: () => _copy(output.excludeStyles),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Lyrics'),
          TextField(
            controller: _lyricsController,
            maxLines: null,
            minLines: 8,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            decoration: _inputDecoration(hint: 'Paste or write lyrics with section brackets…'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final b in EngineConfig.bracketLibrary)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(b, style: const TextStyle(fontSize: 11)),
                      onPressed: () => _insertBracket(b),
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _fixAll,
              icon: const Icon(PhosphorIconsRegular.wrench, size: 18),
              label: const Text('Fix All'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
              ),
            ),
          ),
          if (_currentIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final issue in _currentIssues)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  issue.severity == LintSeverity.error
                      ? PhosphorIconsRegular.xCircle
                      : PhosphorIconsRegular.warning,
                  color: issue.severity == LintSeverity.error
                      ? AppColors.error
                      : AppColors.warning,
                  size: 20,
                ),
                title: Text(
                  'Line ${issue.line + 1}: ${issue.message}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: issue.fix != null
                    ? TextButton(
                        onPressed: () => _applyLineFix(issue),
                        child: const Text('Fix'),
                      )
                    : null,
              ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showDurationBreakdown(duration),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Duration estimate',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatDuration(duration.estimatedSeconds)} / '
                        '${_formatDuration(duration.safeLimitSeconds)} safe · '
                        '${_formatDuration(duration.maxSongDurationSec)} max',
                        style: TextStyle(
                          color: duration.overBudget
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final safeX = safeMarkerRatio * constraints.maxWidth;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: durationRatio,
                              backgroundColor: AppColors.border,
                              color: duration.estimatedSeconds >
                                      duration.maxSongDurationSec
                                  ? AppColors.error
                                  : duration.overBudget
                                      ? AppColors.warning
                                      : AppColors.success,
                              minHeight: 6,
                            ),
                          ),
                          if (safeMarkerRatio > 0 && safeMarkerRatio < 1)
                            Positioned(
                              left: safeX.clamp(0.0, constraints.maxWidth - 2),
                              top: -3,
                              bottom: -3,
                              child: Container(
                                width: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (duration.overBudget && duration.advice != null) ...[
            const SizedBox(height: 8),
            Card(
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  duration.advice!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showRerollSheet,
                  child: const Text('Generation failed'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveVerified,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('This one worked!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.text,
    required this.onCopy,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final String text;
  final VoidCallback onCopy;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                  color: AppColors.accentPrimary,
                  onPressed: onCopy,
                ),
              ],
            ),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(PhosphorIconsRegular.warning, color: AppColors.warning),
        title: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(PhosphorIconsRegular.x, size: 18),
          onPressed: onDismiss,
        ),
      ),
    );
  }
}
