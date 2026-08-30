import 'package:flutter/foundation.dart';

import 'big_room_fusion_progressive_preset.dart';
import 'big_room_hardstyle_cinematic_hybrid_preset.dart';
import 'hardstyle_euro_dance_bootleg_preset.dart';
import '../../data/models/user_input_model.dart';
import 'prompt_flow_data.dart';
import 'song_structure_data.dart';
import 'suno_structure_examples.dart';
import 'suno_version.dart';

/// A selectable starting-point template that ships a fully configured
/// [UserInputModel] for the prompt generator.
@immutable
final class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.model,
    this.family,
    this.isFeatured = false,
  });

  /// Unique stable identifier.
  final String id;

  /// Short human-readable title (raw text — escape at UI layer if needed).
  final String title;

  /// One-line summary shown in the template picker.
  final String description;

  /// Pre-built user input configuration.
  final UserInputModel model;

  /// Optional genre family used for grouping / filtering.
  final String? family;

  /// Whether this template should be surfaced in a "featured" row.
  final bool isFeatured;

  PromptTemplate copyWith({
    String? id,
    String? title,
    String? description,
    UserInputModel? model,
    String? family,
    bool? isFeatured,
  }) =>
      PromptTemplate(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        model: model ?? this.model,
        family: family ?? this.family,
        isFeatured: isFeatured ?? this.isFeatured,
      );

  @override
  String toString() => 'PromptTemplate($id: $title)';
}

/// Pre-built [UserInputModel] configurations (genre, vibe, structure, etc.).
abstract final class PromptTemplates {
  PromptTemplates._();

  // ────────────────────────── Featured / preset imports ──────────────────────────

  static const PromptTemplate _bigRoomHardstyleHybrid = PromptTemplate(
    id: BigRoomHardstyleCinematicHybridPreset.id,
    title: 'Elite Hardstyle / Euphoric–Raw Hybrid',
    description:
        '150 BPM hard dance: mid-intro reverse bass → cinematic breakdown → climax drop',
    model: BigRoomHardstyleCinematicHybridPreset.templateModel,
    family: GenreFamily.hardstyle,
    isFeatured: true,
  );

  static const PromptTemplate _hardstyleEuroBootleg = PromptTemplate(
    id: HardstyleEuroDanceBootlegPreset.id,
    title: 'Hardstyle / Euro-Dance Festival Bootleg',
    description:
        'Darklight-style rave crossover: distorted kick, Euro-dance hook, 150 BPM',
    model: HardstyleEuroDanceBootlegPreset.templateModel,
    family: GenreFamily.hardstyle,
    isFeatured: true,
  );

  static const PromptTemplate _bigRoomProgressive = PromptTemplate(
    id: BigRoomFusionProgressivePreset.id,
    title: 'Big Room Fusion / Progressive House',
    description:
        'Festival anthem: supersaw drops, sidechain pump, cinematic build, 128 BPM',
    model: BigRoomFusionProgressivePreset.templateModel,
    family: GenreFamily.edm,
    isFeatured: true,
  );

  // ────────────────────────── Inline templates ──────────────────────────

  static const PromptTemplate _melodicClub = PromptTemplate(
    id: 'melodic_club',
    title: 'Melodic club',
    description: 'Melodic techno, peak-time energy, EDM drop layout',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Melodic Techno',
      subGenreFusion: 'Progressive House',
      vibe:
          'Peak-time melodic techno: driving kick, rolling sub groove, emotional analog lead hooks, wide stereo pads, hypnotic minor-scale staccato flutes, massive sidechain pumping, deep trailing delays.',
      bpm: '128',
      keyRoot: 'A',
      scale: 'Minor',
      vocalSpec: 'Female Lead',
      vocalTone: 'ethereal, distant, wet room decay',
      referenceArtists: 'Tale Of Us, Stephan Bodzin',
      sonicTags: ['melodic techno peak-time', 'warehouse space'],
      avoid: 'four-on-the-floor acoustic only, generic big room pop, dry mix',
      songStructurePresetId: 'edm_drop',
    ),
    family: GenreFamily.edm,
  );

  static const PromptTemplate _radioPop = PromptTemplate(
    id: 'radio_pop',
    title: 'Radio pop',
    description: 'Synth pop, clean mix, standard verse–chorus',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Synth Pop',
      subGenreFusion: 'Dance Pop',
      vibe:
          'Modern radio pop: tight punchy compressed drum kit, glossy Juno synths, lush pop string pads, anthemic brass chord fanfares, aggressive high-frequency brilliance, maximum loudness optimization.',
      bpm: '115',
      keyRoot: 'C',
      scale: 'Major',
      vocalSpec: 'Male Lead',
      vocalTone: 'clear, charismatic, polished double-tracked stacks',
      referenceArtists: 'The Weeknd, Dua Lipa',
      sonicTags: [
        'chart pop gloss',
        'hook-forward chorus',
        'percussive verse',
      ],
      avoid: 'lo-fi, distorted vocals, acoustic folk guitars, uncompressed drums',
      songStructurePresetId: 'standard_pop',
    ),
    family: GenreFamily.pop,
  );

  static const PromptTemplate _hipHopBoomBap = PromptTemplate(
    id: 'hip_hop_boom_bap',
    title: 'Hip hop',
    description: 'Boom bap pocket, warm samples, space for rap vocals',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Boom Bap',
      subGenreFusion: 'Jazz Rap',
      vibe:
          "Classic boom bap: dusty vintage vinyl-sampled acoustic drum breaks, swung MPC pocket, deep warm Fender P-bass mono groove, filtering Rhodes piano stabs, filtered lo-fi violins and close-mic'd muted jazz trumpets, tape hiss, muted congas.",
      bpm: '88',
      keyRoot: 'D',
      scale: 'Minor',
      vocalSpec: 'Rap Vocal Space',
      vocalTone: 'confident, conversational, upfront center dry booth presence',
      referenceArtists: 'DJ Premier, Pete Rock',
      sonicTags: [
        '90s East Coast sample chop',
        'SP-1200 grit',
        'behind-the-beat pocket',
      ],
      avoid: 'modern trap hi-hats only, sliding 808s, supersaw EDM, autotune',
      songStructurePresetId: 'standard_pop',
    ),
    family: GenreFamily.hiphop,
  );

  static const PromptTemplate _trapHeavy = PromptTemplate(
    id: 'trap_heavy',
    title: 'Heavy Trap',
    description: 'Sliding 808s, dark piano loops, rapid hi-hat rolls',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Trap',
      subGenreFusion: 'Drill',
      vibe:
          'Dark heavy trap: massive sliding 808 sub-bass glides, minor-key concert grand piano loops, machinegun rolling triplet hi-hats, staccato orchestral string hits, dark synthesized woodwind accents, mid-range frequency dip at 300Hz.',
      bpm: '140',
      keyRoot: 'G',
      scale: 'Minor',
      vocalSpec: 'Rap Vocal Space',
      vocalTone: 'aggressive, intense, sharp autotuned transients',
      referenceArtists: 'Metro Boomin, Future, 21 Savage',
      sonicTags: ['dark plugg mood', 'heavy 808 sub pocket'],
      avoid: 'acoustic double bass, jazzy sax solos, cheerful major scales',
      songStructurePresetId: 'standard_pop',
    ),
    family: GenreFamily.hiphop,
  );

  static const PromptTemplate _afrobeatsGroove = PromptTemplate(
    id: 'afrobeats_groove',
    title: 'Afrobeats groove',
    description: 'Afrobeats bounce, warm and percussive',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Afrobeats',
      subGenreFusion: 'Highlife',
      vibe:
          'Sunlit Afrobeats groove: syncopated skip-kick drum pocket with shakers and rim clicks, earthy open-tone conga syncopation, warm round sub bass, crisp highlife electric guitar rhythmic picking, wide panned staccato trumpet accent stabs.',
      bpm: '108',
      vocalSpec: 'Male Lead',
      vocalTone: 'smooth, melodic, pidgin inflection, rhythmic cadence',
      referenceArtists: 'Burna Boy, Wizkid, Davido',
      sonicTags: ['Afrobeats swing', 'center-panned perc pocket'],
      avoid:
          'heavy trap sub-bass only, distorted guitars, dark ambient techno pads',
      songStructurePresetId: 'radio_edit',
    ),
    family: GenreFamily.afrobeats,
  );

  static const PromptTemplate _amapianoClub = PromptTemplate(
    id: 'amapiano_club',
    title: 'Amapiano Bounce',
    description: 'Log drum club bass, continuous shakers, vocal chants',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Amapiano',
      subGenreFusion: 'Soulful House',
      vibe:
          'Authentic Amapiano: FM synthesized log-drum club bass, continuous hypnotic seed shakers, syncopated woodblock accents, smooth improvisational alto saxophone lounge lines, clean jazz piano comping, slow rhythmic pocket build.',
      bpm: '112',
      keyRoot: 'F',
      scale: 'Minor',
      vocalSpec: 'Vocal Chants Only',
      vocalTone:
          'hypnotic spoken chant hooks, rhythmic short loops, low-density',
      referenceArtists: 'Kabza De Small, DJ Maphorisa',
      sonicTags: ['log drum bounce', 'sub-heavy groove pocket'],
      avoid:
          'live acoustic log drums, rock drums, heavy distorted vocal screaming',
      songStructurePresetId: 'edm_drop',
    ),
    family: GenreFamily.amapiano,
  );

  static const PromptTemplate _praiseWorshipEpic = PromptTemplate(
    id: 'praise_worship_epic',
    title: 'Praise & Worship',
    description: 'Contemporary Christian worship, pristine dynamic build',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Praise/Worship',
      subGenreFusion: 'Contemporary Gospel',
      vibe:
          'Epic modern worship: contemporary acoustic grand piano chords, soaring ambient electric guitar volume swells, stereo delay loops, lush legato orchestral string pads, majestic sustained French horn swells, pristine studio isolation.',
      bpm: '76',
      keyRoot: 'G',
      scale: 'Major',
      vocalSpec: 'Unison Stacks',
      vocalTone:
          'prayerful, clear, thick multi-tracked vocal doubles, zero room bleed',
      referenceArtists: 'Hillsong, Elevation',
      sonicTags: [
        'worship acoustic dynamic build',
        'analog VCA compression',
      ],
      avoid:
          'club filter sweeps, sidechain pumping, DJ outro, synthetic loop triggers',
      songStructurePresetId: 'rnb_ballad',
    ),
    family: GenreFamily.gospel,
  );

  static const PromptTemplate _vinahouseViet = PromptTemplate(
    id: 'vinahouse_viet',
    title: 'Vinahouse Bounce',
    description: 'High-energy offbeat bounce, traditional strings',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Vinahouse',
      subGenreFusion: 'Hard Bounce',
      vibe:
          'High-energy Vinahouse: relentless offbeat bounce grooves, hard aggressive electronic kick, traditional pentatonic đàn tranh string motifs, cutting high-register trumpet stabs, heavy sub-bass pulses, high-tension festival fills.',
      bpm: '138',
      keyRoot: 'C',
      scale: 'Minor',
      vocalSpec: 'Female Lead',
      vocalTone: 'breathy, upfront, tight short phrase iterations',
      referenceArtists: 'Hoaprox, Masew, DJ Trang Moon',
      sonicTags: ['offbeat bounce groove', 'pentatonic hooks'],
      avoid:
          'slow acoustic guitars, dusty boom bap loops, relaxed behind-the-beat swing',
      songStructurePresetId: 'edm_drop',
    ),
    family: GenreFamily.amapiano,
  );

  static const PromptTemplate _reggaetonLatino = PromptTemplate(
    id: 'reggaeton_latino',
    title: 'Reggaeton Latino',
    description: 'Dem bow drum grid, classical nylon guitar, staccato horns',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Reggaeton',
      subGenreFusion: 'Latin Pop',
      vibe:
          'Urban Latin Pop: iconic crisp syncopated Dem Bow drum grid, heavy 808 sub-bass pulses, intimate bright classical nylon-string acoustic guitar picking, piercing staccato trumpet lines, fast-paced conga rolls, metal guiro scrapes.',
      bpm: '94',
      keyRoot: 'A',
      scale: 'Minor',
      vocalSpec: 'Male Lead',
      vocalTone: 'melodic swagger, fast-paced syncopated rhythmic delivery',
      referenceArtists: 'Bad Bunny, Rauw Alejandro',
      sonicTags: ['dembow 808 pattern', 'bright synth plucks'],
      avoid:
          'heavy rock guitars, distorted industrial techno saws, classic swing jazz',
      songStructurePresetId: 'radio_edit',
    ),
    family: GenreFamily.latin,
  );

  static const PromptTemplate _modernCountryStory = PromptTemplate(
    id: 'modern_country_story',
    title: 'Modern Country',
    description: 'Acoustic strum pocket, pedal steel guitar, dry room',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Modern Country',
      subGenreFusion: 'Americana',
      vibe:
          'Polished modern country: crisp steel-string acoustic guitar strumming pocket, weeping pedal steel guitar slides, organic acoustic violin/fiddle layers, clean punchy studio rock drums, rustic tambourines, upright bass.',
      bpm: '102',
      keyRoot: 'D',
      scale: 'Major',
      vocalSpec: 'Male Lead',
      vocalTone:
          'twang-forward, conversational, authentic story-first delivery',
      referenceArtists: 'Morgan Wallen, Luke Combs',
      sonicTags: ['country acoustic strum', 'crisp radio polish'],
      avoid:
          'synthetic sub bass, 808 glides, digital vocal chops, techno sidechain',
      songStructurePresetId: 'standard_pop',
    ),
    family: GenreFamily.country,
  );

  static const PromptTemplate _neoSoulBallad = PromptTemplate(
    id: 'neo_soul_ballad',
    title: 'Neo-soul ballad',
    description: 'Slow R&B, intimate, R&B ballad structure',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Neo-Soul',
      subGenreFusion: 'R&B',
      vibe:
          "Intimate neo-soul ballad: silky Rhodes electric piano extensions, smooth fingerstyle Fender Jazz Bass, soft brushed acoustic drum kit, velvet legato tenor saxophone melodies, close-mic'd harmon-muted trumpets, behind-the-beat hand congas.",
      bpm: '78',
      keyRoot: 'E',
      scale: 'Minor',
      vocalSpec: 'Female Lead',
      vocalTone:
          'breathy, soulful, stacked vocal harmonies, warm intimate room tone',
      referenceArtists: 'SZA, Daniel Caesar',
      sonicTags: ['neo-soul intimacy', 'tape-warm saturation'],
      avoid: 'EDM drops, heavy synth sidechain pump, fast triplet trap hats',
      songStructurePresetId: 'rnb_ballad',
    ),
    family: GenreFamily.rnb,
  );

  static const PromptTemplate _cinematicTrailer = PromptTemplate(
    id: 'cinematic_trailer',
    title: 'Cinematic trailer',
    description: 'Orchestral hybrid, epic arcs, flexible structure',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Trailer',
      subGenreFusion: 'Orchestral',
      vibe:
          'Epic cinematic hybrid: thunderous timpani drum rolls, massive low-end symphonic gongs, intense violin and cello ostinatos, piercing lyrical oboes, majestic symphonic French horn swells, powerful fortissimo bass trombone slides, wide deep hall reverb.',
      bpm: '90',
      vocalSpec: 'Instrumental Only',
      referenceArtists: 'Hans Zimmer scale scope',
      sonicTags: ['trailer brass swells', 'hybrid symphonic score'],
      avoid:
          'pop electronic drums, modern vocal hooks, acoustic guitar strumming',
      songStructurePresetId: SongStructureData.flexibleId,
    ),
    family: GenreFamily.cinematic,
  );

  static const PromptTemplate _bracketEdmStructure = PromptTemplate(
    id: 'bracket_edm_structure',
    title: 'Bracketed EDM structure',
    description:
        'Custom outline: v5.5 EDM bracket example (build/drop); paste-friendly for Suno',
    model: UserInputModel(
      sunoVersion: SunoVersion.preferredValue,
      primaryGenre: 'Progressive House',
      subGenreFusion: 'Big Room',
      vibe:
          'Journey from progressive house to peak festival energy: emotional concert grand piano chords, evolving polyphonic sawtooth swells, wide stereo field, shifting into massive electronic kicks and euphoric supersaw leads.',
      bpm: '128',
      keyRoot: 'A#',
      scale: 'Minor',
      vocalSpec: 'Instrumental Only',
      vocalTone:
          'ethereal ghostly background vocal pads in chorus section per outline',
      referenceArtists: 'Swedish House Mafia, Martin Garrix',
      sonicTags: ['festival EDM arc', 'wide master bus width'],
      avoid: 'dry uncompressed mix, thin low end, acoustic folk instruments',
      songStructurePresetId: SongStructureData.customId,
      songStructureCustom: SunoStructureExamples.v55_edm,
    ),
    family: GenreFamily.edm,
  );

  // ────────────────────────── Public registry ──────────────────────────

  /// All available templates in display order.
  static const List<PromptTemplate> all = [
    _bigRoomHardstyleHybrid,
    _hardstyleEuroBootleg,
    _bigRoomProgressive,
    _melodicClub,
    _radioPop,
    _hipHopBoomBap,
    _trapHeavy,
    _afrobeatsGroove,
    _amapianoClub,
    _praiseWorshipEpic,
    _vinahouseViet,
    _reggaetonLatino,
    _modernCountryStory,
    _neoSoulBallad,
    _cinematicTrailer,
    _bracketEdmStructure,
  ];

  /// Templates surfaced in a "featured" or starter row.
  static const List<PromptTemplate> featured = [
    _bigRoomHardstyleHybrid,
    _hardstyleEuroBootleg,
    _bigRoomProgressive,
  ];

  // ────────────────────────── Validation (debug/dev only) ──────────────────────────

  /// Throws if any template id is duplicated.
  static void validateUniqueIds() {
    final ids = <String>{};
    for (final t in all) {
      if (!ids.add(t.id)) {
        throw StateError('Duplicate PromptTemplate id: ${t.id}');
      }
    }
  }

  // ────────────────────────── Lookups ──────────────────────────

  static PromptTemplate? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static List<PromptTemplate> byFamily(String family) {
    return all.where((t) => t.family == family).toList(growable: false);
  }

  static List<PromptTemplate> search(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return List<PromptTemplate>.unmodifiable(all);
    return all
        .where(
          (t) =>
              t.id.toLowerCase().contains(lower) ||
              t.title.toLowerCase().contains(lower) ||
              t.description.toLowerCase().contains(lower) ||
              t.model.primaryGenre.toLowerCase().contains(lower) ||
              t.model.subGenreFusion.toLowerCase().contains(lower),
        )
        .toList(growable: false);
  }

  /// Returns the set of all families present in the registry.
  static Set<String> families() =>
      all.map((t) => t.family).whereType<String>().toSet();
}
