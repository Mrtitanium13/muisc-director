/// Duration formatting and parsing utilities for track length display.
abstract final class TrackDurationUtils {
  TrackDurationUtils._();

  static const int _secondsPerMinute = 60;
  static const int _secondsPerHour = 3600;
  static const int _maxSeconds = 3599999; // ~999h 59m 59s

  /// Formats [Duration] as H:MM:SS or M:SS for track length display.
  ///
  /// Returns `'—'` for zero or negative durations.
  static String format(Duration d) {
    if (d.inMilliseconds <= 0) return '—';
    final totalSec = d.inSeconds.clamp(0, _maxSeconds);
    final h = totalSec ~/ _secondsPerHour;
    final m = (totalSec % _secondsPerHour) ~/ _secondsPerMinute;
    final s = totalSec % _secondsPerMinute;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$m:$ss';
  }

  /// Total minutes from a fractional value as M:SS (no hour roll-over).
  ///
  /// Returns `'0:00'` for NaN, infinite, or negative values.
  static String formatMinutes(double minutes) {
    if (minutes.isNaN || minutes.isInfinite || minutes < 0) return '0:00';
    final totalSec =
        (minutes * _secondsPerMinute).round().clamp(0, _maxSeconds);
    final m = totalSec ~/ _secondsPerMinute;
    final s = totalSec % _secondsPerMinute;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Parses flexible target-length input into **minutes** (fractional).
  ///
  /// Supported:
  /// - `M:SS` or `H:MM:SS`
  /// - Decimal minutes (`3.5`)
  /// - Whole minutes (`3`)
  /// - Plain seconds when integer > 90 (`180` → 3.0)
  /// - `min` / `minutes` / `m` suffix (`3min`, `3.5 minutes`)
  ///
  /// Returns `null` for invalid/ambiguous input.
  static double? parseMinutes(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Normalized min / minutes / m suffix.
    final minMatch = RegExp(
      r'^([\d.]+)\s*(?:min(?:utes?)?|m)\b',
      caseSensitive: false,
    ).firstMatch(s);
    if (minMatch != null) {
      final v = double.tryParse(minMatch.group(1)!);
      if (v == null || v <= 0) return null;
      return v;
    }

    // Colon format: M:SS or H:MM:SS.
    final colonMatch =
        RegExp(r'^(\d+):(\d{1,2})(?::(\d{1,2}))?$').firstMatch(s);
    if (colonMatch != null) {
      final p1 = int.tryParse(colonMatch.group(1)!);
      final p2 = int.tryParse(colonMatch.group(2)!);
      if (p1 == null || p2 == null) return null;
      final p3 = colonMatch.group(3) != null
          ? int.tryParse(colonMatch.group(3)!)
          : null;

      // H:MM:SS
      if (p3 != null) {
        final h = p1;
        final mm = p2;
        final sec = p3;
        if (mm >= 60 || sec >= 60) return null;
        return (h * _secondsPerHour + mm * _secondsPerMinute + sec) /
            _secondsPerMinute;
      }

      // M:SS
      final mins = p1;
      final sec = p2;
      if (sec >= 60) return null;
      return mins + sec / _secondsPerMinute;
    }

    // Plain number.
    if (RegExp(r'^[\d.]+$').hasMatch(s)) {
      if (s.contains('.')) {
        final v = double.tryParse(s);
        if (v == null || v <= 0) return null;
        return v;
      }
      final intVal = int.tryParse(s);
      if (intVal == null || intVal <= 0) return null;
      if (intVal > 90) return intVal / _secondsPerMinute;
      return intVal.toDouble();
    }

    return null;
  }

  /// Converts a parsed minute value into a [Duration].
  static Duration? toDuration(String? raw) {
    final minutes = parseMinutes(raw);
    if (minutes == null) return null;
    return Duration(
      seconds: (minutes * _secondsPerMinute).round(),
    );
  }
}

/// Convenience extension on [Duration].
extension TrackDurationFormat on Duration {
  /// `H:MM:SS` or `M:SS`.
  String get trackDisplay => TrackDurationUtils.format(this);
}

// Back-compat aliases for existing call sites.
String formatTrackDuration(Duration d) => TrackDurationUtils.format(d);

String formatMinutesToMmSs(double minutes) =>
    TrackDurationUtils.formatMinutes(minutes);

double? parseFlexibleDurationMinutes(String? raw) =>
    TrackDurationUtils.parseMinutes(raw);
