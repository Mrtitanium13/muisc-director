import 'package:flutter/foundation.dart';

import '../utils/live_instrument_matrix.dart';
import '../utils/live_instrument_matrix_data.dart';

/// Live / acoustic instrument picker — genre-accurate matrix with articulation metadata.
abstract final class RealInstrumentsData {
  RealInstrumentsData._();

  /// Instruments recommended for the user's primary + fusion genre (matrix-backed).
  static List<String> instrumentsForGenre(String primary, [String fusion = '']) {
    final instruments =
        LiveInstrumentMatrix.instrumentsForGenre(primary, fusion);
    return instruments.map((i) => i.name).toList(growable: false);
  }

  /// Backward-compatible filter: [label] is primary sub-genre text, or null for essentials.
  static List<String> instrumentsForGenreFilter(String? label) {
    if (label == null || label.trim().isEmpty) return quickPicks;
    final fromMatrix = instrumentsForGenre(label);
    if (fromMatrix.isNotEmpty) return decongestGenrePicks(fromMatrix);
    return quickPicks;
  }

  /// Curated everyday chips (piano / guitar / bass / drums / etc.).
  /// Full catalog stays available via [search] / [allDistinctNames].
  static const List<String> quickPicks = [
    'Grand Piano',
    'Acoustic Piano',
    'Rhodes Electric Piano',
    'Wurlitzer Electric Piano',
    'Hammond B3 Organ',
    'Acoustic Guitar',
    'Electric Guitar',
    'Nylon String Guitar',
    'Bass Guitar',
    'Fender Jazz Bass',
    'Upright Bass',
    'Drum Kit',
    'Live Drum Kit',
    'Synth Pad',
    'Synth Lead',
    'String Section',
    'Brass Section',
    'Trumpet',
    'Trombone',
    'Congas',
    'Cajon',
    'Harmonica',
    'Accordion',
  ];

  /// Max chips shown for a genre profile before search.
  static const int genreChipCap = 14;

  /// Prefer essentials that exist in [genreNames], then fill from the genre list.
  static List<String> decongestGenrePicks(List<String> genreNames) {
    if (genreNames.isEmpty) return quickPicks;
    final seen = <String>{};
    final out = <String>[];
    final genreSet = genreNames.toSet();
    for (final name in quickPicks) {
      if (genreSet.contains(name) && seen.add(name)) out.add(name);
      if (out.length >= genreChipCap) {
        return List<String>.unmodifiable(out);
      }
    }
    for (final name in genreNames) {
      if (seen.add(name)) out.add(name);
      if (out.length >= genreChipCap) break;
    }
    return List<String>.unmodifiable(out);
  }

  /// All distinct instrument names across every genre profile (A–Z).
  static List<String> get allDistinctNames {
    final seen = <String>{};
    final out = <String>[];
    for (final rows in LiveInstrumentMatrixData.byGenre.values) {
      for (final row in rows) {
        final name = row['name']?.trim();
        if (name != null && name.isNotEmpty && seen.add(name)) {
          out.add(name);
        }
      }
    }
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(out);
  }

  /// Rich instrument objects recommended for a genre pair.
  static List<InstrumentModel> richInstrumentsForGenre(
    String primary, [
    String fusion = '',
  ]) =>
      LiveInstrumentMatrix.instrumentsForGenre(primary, fusion)
          .map(InstrumentModel.fromLive)
          .toList(growable: false);

  /// Searches across instrument names, family, articulations, and tags.
  static List<InstrumentModel> search(String query, {String? genreFilter}) {
    final lower = query.toLowerCase().trim();
    final pool = genreFilter == null || genreFilter.trim().isEmpty
        ? allInstruments
        : richInstrumentsForGenre(genreFilter);

    if (lower.isEmpty) return List<InstrumentModel>.unmodifiable(pool);

    final familyAliases = _familySearchAliases(lower);

    return pool
        .where(
          (i) =>
              i.name.toLowerCase().contains(lower) ||
              i.family.toLowerCase().contains(lower) ||
              familyAliases.contains(i.family.toLowerCase()) ||
              i.articulations.any((a) => a.toLowerCase().contains(lower)) ||
              i.tags.any((t) => t.toLowerCase().contains(lower)),
        )
        .toList(growable: false);
  }

  /// Maps everyday search words onto matrix category keys.
  static Set<String> _familySearchAliases(String query) {
    final out = <String>{};
    if (query.contains('brass') || query.contains('horn')) {
      out.addAll({'horns', 'trumpets'});
    }
    if (query.contains('wind') || query.contains('woodwind')) {
      out.add('winds');
    }
    if (query.contains('string') ||
        query.contains('violin') ||
        query.contains('cello') ||
        query.contains('viola')) {
      out.add('strings');
    }
    return out;
  }

  /// Union of every distinct instrument object in the matrix.
  static List<InstrumentModel> get allInstruments {
    final seen = <String>{};
    final out = <InstrumentModel>[];
    for (final rows in LiveInstrumentMatrixData.byGenre.values) {
      for (final row in rows) {
        final model = InstrumentModel.fromRow(row);
        if (model.name.isEmpty) continue;
        if (seen.add(model.signature)) out.add(model);
      }
    }
    return List<InstrumentModel>.unmodifiable(out);
  }

  /// Instruments grouped by family for UI organization.
  static Map<String, List<InstrumentModel>> instrumentsByFamily(
    String primary, [
    String fusion = '',
  ]) {
    final map = <String, List<InstrumentModel>>{};
    for (final i in richInstrumentsForGenre(primary, fusion)) {
      map.putIfAbsent(i.family, () => <InstrumentModel>[]).add(i);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return Map<String, List<InstrumentModel>>.unmodifiable({
      for (final e in map.entries)
        e.key: List<InstrumentModel>.unmodifiable(e.value),
    });
  }
}

/// A live/acoustic instrument with articulation metadata.
///
/// Mapped from [LiveInstrument] / matrix rows:
/// - [family] ← `category`
/// - [articulations] ← `defaultArticulation` (single entry when present)
/// - [tags] ← `aliasHints`
/// - [description] ← `mixRole`
@immutable
final class InstrumentModel {
  const InstrumentModel({
    required this.name,
    required this.family,
    this.id = '',
    this.articulations = const <String>[],
    this.tags = const <String>[],
    this.description,
  });

  final String id;
  final String name;
  final String family;
  final List<String> articulations;
  final List<String> tags;
  final String? description;

  /// Stable deduplication signature (prefers matrix id when present).
  String get signature =>
      id.trim().isNotEmpty ? id.trim() : '$family|$name';

  factory InstrumentModel.fromLive(LiveInstrument instrument) {
    final articulation = instrument.defaultArticulation.trim();
    final mix = instrument.mixRole.trim();
    return InstrumentModel(
      id: instrument.id,
      name: instrument.name.trim(),
      family: instrument.category.trim().isEmpty
          ? 'Other'
          : instrument.category.trim(),
      articulations:
          articulation.isEmpty ? const <String>[] : <String>[articulation],
      tags: List<String>.unmodifiable(instrument.aliasHints),
      description: mix.isEmpty ? null : mix,
    );
  }

  factory InstrumentModel.fromRow(Map<String, String> row) {
    final aliasRaw = (row['aliasHints'] ?? '').trim();
    final articulation = (row['defaultArticulation'] ?? '').trim();
    final mix = (row['mixRole'] ?? '').trim();
    final family = (row['category'] ?? '').trim();
    return InstrumentModel(
      id: (row['id'] ?? '').trim(),
      name: (row['name'] ?? '').trim(),
      family: family.isEmpty ? 'Other' : family,
      articulations:
          articulation.isEmpty ? const <String>[] : <String>[articulation],
      tags: aliasRaw.isEmpty
          ? const <String>[]
          : aliasRaw
              .split('|')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false),
      description: mix.isEmpty ? null : mix,
    );
  }

  @override
  String toString() => 'InstrumentModel($name, family: $family)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentModel && signature == other.signature;

  @override
  int get hashCode => signature.hashCode;
}
