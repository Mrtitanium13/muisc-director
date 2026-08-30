import 'package:flutter/foundation.dart';

/// Studio-isolated vs live-arena staging for Block 2 arrangement tags.
enum AudioEnvironmentMode {
  studioIsolated,
  livePerformance,
}

/// A selectable audio environment option.
@immutable
class AudioEnvironmentOption {
  const AudioEnvironmentOption({
    required this.id,
    required this.label,
    required this.promptDirective,
    required this.mode,
  });

  final String id;

  /// Human-readable label. Stored raw; use [htmlLabel] for HTML contexts.
  final String label;

  /// Injected into generation user block + Stage 4 (humanize) + Stage 5 (compress).
  final String promptDirective;
  final AudioEnvironmentMode mode;

  bool get isStudio => mode == AudioEnvironmentMode.studioIsolated;
  bool get isLive => mode == AudioEnvironmentMode.livePerformance;

  /// Label with HTML special characters escaped.
  String get htmlLabel => _HtmlEscaper.escape(label);

  @override
  String toString() => 'AudioEnvironmentOption(id: $id, label: $label)';
}

/// Container for audio environment configuration and formatting.
///
/// This class is not meant to be instantiated, extended, or implemented.
abstract final class AudioEnvironmentData {
  AudioEnvironmentData._();

  static const String studioIsolatedId = 'studio_isolated';
  static const String livePerformanceId = 'live_performance';

  static const AudioEnvironmentOption studioIsolated = AudioEnvironmentOption(
    id: studioIsolatedId,
    label: 'Pristine Studio (No Crowd)',
    mode: AudioEnvironmentMode.studioIsolated,
    promptDirective:
        'CRITICAL DIRECTIVE: Enforce strict studio isolation. In Block 1 and Block 2 '
        'use only positive engineering tokens: "Dead-room isolation, Pristine studio '
        'environment, Close-mic vocal tracking, Dry acoustic room, Focused studio room". '
        'For vocal stacks use "Isolated multi-tracked vocal doubles" or "Tight '
        'double-tracked vocal stacks". '
        'INTERNAL (do not write in Suno output): never use the words crowd, cheer, '
        'applause, audience, stadium, ovation, or live — Suno treats them as triggers '
        'even inside bans.',
  );

  static const AudioEnvironmentOption livePerformance = AudioEnvironmentOption(
    id: livePerformanceId,
    label: 'Live Arena (Crowd & Cheers)',
    mode: AudioEnvironmentMode.livePerformance,
    promptDirective:
        'CRITICAL DIRECTIVE: Simulate an epic, high-energy live stadium concert. '
        'Force heavy crowd participation using words like "Thunderous stadium crowd cheering, '
        'Loud audience applause, Large outdoor stage reverb, Crowd singing along loudly" '
        'inside the bracket layers.',
  );

  static const List<AudioEnvironmentOption> options = [
    studioIsolated,
    livePerformance,
  ];

  /// Compile-time lookup. When adding a mode, register it here and in [options].
  static const Map<String, AudioEnvironmentOption> _optionById = {
    studioIsolatedId: studioIsolated,
    livePerformanceId: livePerformance,
  };

  static Set<String> get ids => _optionById.keys.toSet();

  /// Returns a valid option id. Defaults to studio isolated.
  static String coerceId(String? raw) {
    final id = (raw ?? '').trim();
    return _optionById.containsKey(id) ? id : studioIsolatedId;
  }

  /// Returns the option for [raw], never null.
  static AudioEnvironmentOption optionForId(String? raw) =>
      _optionById[coerceId(raw)]!;

  static AudioEnvironmentMode modeForId(String? raw) => optionForId(raw).mode;

  static bool isLivePerformance(String? raw) => optionForId(raw).isLive;

  static bool isStudioIsolated(String? raw) => optionForId(raw).isStudio;

  /// Full directive for context injection.
  static String postProcessContextLine(String? modeId) =>
      optionForId(modeId).promptDirective;

  /// Compact tag line for post-processing.
  static String postProcessCompactLine(String? modeId) {
    final opt = optionForId(modeId);
    return switch (opt.mode) {
      AudioEnvironmentMode.livePerformance =>
        'ENV:live-arena|stadium crowd cheering|chorus sing-along|ovation outro',
      AudioEnvironmentMode.studioIsolated =>
        'ENV:studio|dead-room isolation|close-mic tracking|dry acoustic room',
    };
  }

  /// User-block line for Block 1 (raw text for LLM prompts).
  static String userBlockDirective(String? modeId) {
    final opt = optionForId(modeId);
    return 'AUDIO ENVIRONMENT (${opt.label}):\n${opt.promptDirective}';
  }

  /// HTML-safe user block line for web previews only — not for LLM injection.
  static String userBlockDirectiveHtml(String? modeId) {
    final opt = optionForId(modeId);
    return 'AUDIO ENVIRONMENT (${opt.htmlLabel}):\n'
        '${_HtmlEscaper.escape(opt.promptDirective)}';
  }
}

class _HtmlEscaper {
  _HtmlEscaper._();

  static final RegExp _pattern = RegExp(r'''[&<>"']''');
  static const Map<String, String> _map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  };

  static String escape(String input) => input.splitMapJoin(
        _pattern,
        onMatch: (m) => _map[m[0]!]!,
        onNonMatch: (s) => s,
      );
}
