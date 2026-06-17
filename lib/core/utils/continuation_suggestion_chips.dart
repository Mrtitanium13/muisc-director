import 'suno_output_split.dart';

/// Curated follow-ups when model lines are missing or thin — each is one tap to refine.
const List<String> kDefaultContinuationSuggestions = [
  '→ Tighten Block 1: clearer stereo width, firm mono sub, and one concrete master-chain move — keep BPM and key.',
  '→ Humanize Block 2: more conversational lines; one specific time/place/object per verse; vary the final hook.',
  '→ Bigger chorus lift: wider BGV/stack cues in Block 2 and matching energy in Block 1 — stay on theme.',
  '→ Strip it back: sparser Block 1 in verses; simpler staging lines; punchier, shorter hook in Block 2.',
];

bool _sharesLongPrefix(String a, String b, int n) {
  final al = a.trim().toLowerCase();
  final bl = b.trim().toLowerCase();
  if (al.isEmpty || bl.isEmpty) return false;
  final len = n.clamp(1, al.length.clamp(1, bl.length));
  return al.substring(0, len) == bl.substring(0, len);
}

/// Model-derived lines first; pad with [kDefaultContinuationSuggestions] up to [maxChips] without near-duplicates.
List<String> buildContinuationChips(
  String? suggestionsBody, {
  int maxChips = 6,
}) {
  final fromModel = suggestionLinesFromBody(suggestionsBody);
  final out = <String>[...fromModel];
  for (final d in kDefaultContinuationSuggestions) {
    if (out.length >= maxChips) break;
    final isDup = out.any(
      (e) =>
          e.trim().toLowerCase() == d.trim().toLowerCase() ||
          _sharesLongPrefix(e, d, 20),
    );
    if (!isDup) out.add(d);
  }
  return out;
}
