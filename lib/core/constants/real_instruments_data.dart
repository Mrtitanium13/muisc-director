import '../utils/live_instrument_matrix.dart';
import '../utils/live_instrument_matrix_data.dart';

/// Live / acoustic instrument picker — genre-accurate matrix with articulation metadata.
class RealInstrumentsData {
  RealInstrumentsData._();

  /// Instruments recommended for the user's primary + fusion genre (matrix-backed).
  static List<String> instrumentsForGenre(String primary, [String fusion = '']) {
    return LiveInstrumentMatrix.instrumentsForGenre(primary, fusion)
        .map((i) => i.name)
        .toList();
  }

  /// Backward-compatible filter: [label] is primary sub-genre text, or null for union.
  static List<String> instrumentsForGenreFilter(String? label) {
    if (label == null || label.isEmpty) return quickPicks;
    final fromMatrix = instrumentsForGenre(label);
    if (fromMatrix.isNotEmpty) return fromMatrix;
    return quickPicks;
  }

  /// All distinct instrument names across every genre profile (A–Z).
  static List<String> get quickPicks {
    final seen = <String>{};
    final out = <String>[];
    for (final rows in LiveInstrumentMatrixData.byGenre.values) {
      for (final row in rows) {
        final name = row['name'];
        if (name != null && seen.add(name)) out.add(name);
      }
    }
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// Legacy commercial lane labels — used only for display hints in UI.
  static const List<String> commercialGenreLabels = [
    'EDM',
    'Hip Hop',
    'R&B/Soul',
    'Pop',
    'Rock/Metal',
    'Gospel',
    'Jazz',
    'World',
    'Cinematic',
  ];

  @Deprecated('Use instrumentsForGenre(primary, fusion) — matrix-backed picks')
  static const List<CommercialGenreInstruments> commercialByGenre = [];
}

/// Deprecated placeholder — matrix replaces per-lane static lists.
@Deprecated('Matrix-backed LiveInstrumentMatrix replaces static buckets')
class CommercialGenreInstruments {
  const CommercialGenreInstruments({
    required this.label,
    required this.instruments,
  });

  final String label;
  final List<String> instruments;
}
