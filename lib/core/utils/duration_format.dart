/// Formats [Duration] as H:MM:SS or M:SS for track length display.
String formatTrackDuration(Duration d) {
  if (d.inMilliseconds <= 0) return '—';
  final totalSec = d.inSeconds;
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Total minutes from a fractional value (for bar math / tiers).
String formatMinutesToMmSs(double minutes) {
  if (minutes.isNaN || minutes.isInfinite || minutes < 0) return '0:00';
  final totalSec = (minutes * 60).round().clamp(0, 3599999);
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Parses flexible target-length input into **minutes** (fractional).
///
/// Supported: `M:SS` or `H:MM:SS`, decimal minutes (`3.5`), whole minutes (`3`),
/// plain seconds when the integer is greater than 90 (e.g. `180` → 3:00),
/// and optional `min` / `minutes` suffix.
double? parseFlexibleDurationMinutes(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  final minSuffix =
      RegExp(r'^([\d.]+)\s*(?:min(?:utes)?|m)\b', caseSensitive: false);
  final mMin = minSuffix.firstMatch(s);
  if (mMin != null) {
    final v = double.tryParse(mMin.group(1)!);
    if (v == null || v <= 0) return null;
    return v;
  }

  final colon = RegExp(r'^(\d+):(\d{1,2})(?::(\d{1,2}))?$');
  final mColon = colon.firstMatch(s);
  if (mColon != null) {
    final p1 = int.tryParse(mColon.group(1)!);
    final p2 = int.tryParse(mColon.group(2)!);
    final p3 =
        mColon.group(3) != null ? int.tryParse(mColon.group(3)!) : null;
    if (p1 == null || p2 == null) return null;
    if (p3 != null) {
      final h = p1;
      final mm = p2;
      final sec = p3;
      if (mm >= 60 || sec >= 60) return null;
      return h * 60 + mm + sec / 60.0;
    }
    final mins = p1;
    final sec = p2;
    if (sec >= 60) return null;
    return mins + sec / 60.0;
  }

  if (RegExp(r'^[\d.]+$').hasMatch(s)) {
    if (s.contains('.')) {
      final v = double.tryParse(s);
      if (v == null || v <= 0) return null;
      return v;
    }
    final intVal = int.tryParse(s);
    if (intVal == null || intVal <= 0) return null;
    if (intVal > 90) return intVal / 60.0;
    return intVal.toDouble();
  }

  return null;
}
