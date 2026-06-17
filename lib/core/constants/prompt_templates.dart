import '../../data/models/user_input_model.dart';
import 'song_structure_data.dart';
import 'suno_structure_bracket_example.dart';

/// Saved starting points for the prompt generator.
class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.model,
  });

  final String id;
  final String title;
  final String description;
  final UserInputModel model;
}

/// Pre-built [UserInputModel] configurations (genre, vibe, structure, etc.).
class PromptTemplates {
  PromptTemplates._();

  static const List<PromptTemplate> all = [
    PromptTemplate(
      id: 'melodic_club',
      title: 'Melodic club',
      description: 'Melodic techno, peak-time energy, EDM drop layout',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Melodic Techno',
        subGenreFusion: 'Progressive House',
        vibe:
            'Peak-time melodic techno: driving kick, rolling sub groove, emotional analog lead hooks, wide stereo pads, hypnotic minor-scale staccato flutes, massive sidechain pumping, deep trailing delays.',
        bpm: '128',
        keyRoot: 'A',
        scale: 'Minor',
        vocalSpec: 'Female Lead',
        vocalTone: 'ethereal, distant, wet room decay',
        referenceArtists:
            'melodic techno peak-time, warehouse space; optional artist-style: Tale Of Us, Stephan Bodzin',
        avoid: 'four-on-the-floor acoustic only, generic big room pop, dry mix',
        songStructurePresetId: 'edm_drop',
      ),
    ),
    PromptTemplate(
      id: 'radio_pop',
      title: 'Radio pop',
      description: 'Synth pop, clean mix, standard verse–chorus',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Synth Pop',
        subGenreFusion: 'Dance Pop',
        vibe:
            'Modern radio pop: tight punchy compressed drum kit, glossy Juno synths, lush pop string pads, anthemic brass chord fanfares, aggressive high-frequency brilliance, maximum loudness optimization.',
        bpm: '115',
        keyRoot: 'C',
        scale: 'Major',
        vocalSpec: 'Male Lead',
        vocalTone: 'clear, charismatic, polished double-tracked stacks',
        referenceArtists:
            'chart pop gloss, hook-forward chorus, percussive verse; optional: The Weeknd, Dua Lipa',
        avoid: 'lo-fi, distorted vocals, acoustic folk guitars, uncompressed drums',
        songStructurePresetId: 'standard_pop',
      ),
    ),
    PromptTemplate(
      id: 'hip_hop_boom_bap',
      title: 'Hip hop',
      description: 'Boom bap pocket, warm samples, space for rap vocals',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Boom Bap',
        subGenreFusion: 'Jazz Rap',
        vibe:
            'Classic boom bap: dusty vintage vinyl-sampled acoustic drum breaks, swung MPC pocket, deep warm Fender P-bass mono groove, filtering Rhodes piano stabs, filtered lo-fi violins and close-mic\'d muted jazz trumpets, tape hiss, muted congas.',
        bpm: '88',
        keyRoot: 'D',
        scale: 'Minor',
        vocalSpec: 'Rap Vocal Space',
        vocalTone: 'confident, conversational, upfront center dry booth presence',
        referenceArtists:
            '90s East Coast sample chop, SP-1200 grit, behind-the-beat pocket; optional: DJ Premier, Pete Rock',
        avoid: 'modern trap hi-hats only, sliding 808s, supersaw EDM, autotune',
        songStructurePresetId: 'standard_pop',
      ),
    ),
    PromptTemplate(
      id: 'trap_heavy',
      title: 'Heavy Trap',
      description: 'Sliding 808s, dark piano loops, rapid hi-hat rolls',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Trap',
        subGenreFusion: 'Drill',
        vibe:
            'Dark heavy trap: massive sliding 808 sub-bass glides, minor-key concert grand piano loops, machinegun rolling triplet hi-hats, staccato orchestral string hits, dark synthesized woodwind accents, mid-range frequency dip at 300Hz.',
        bpm: '140',
        keyRoot: 'G',
        scale: 'Minor',
        vocalSpec: 'Rap Vocal Space',
        vocalTone: 'aggressive, intense, sharp autotuned transients',
        referenceArtists:
            'dark plugg mood, heavy 808 sub pocket; optional: Metro Boomin, Future, 21 Savage',
        avoid: 'acoustic double bass, jazzy sax solos, cheerful major scales',
        songStructurePresetId: 'standard_pop',
      ),
    ),
    PromptTemplate(
      id: 'afrobeats_groove',
      title: 'Afrobeats groove',
      description: 'Afrobeats bounce, warm and percussive',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Afrobeats',
        subGenreFusion: 'Highlife',
        vibe:
            'Sunlit Afrobeats groove: interlocking syncopated traditional talking drums, earthy open-tone conga syncopation, crisp highlife electric guitar rhythmic picking, blazing tenor saxophone modal lines, wide panned staccato trumpet accent stabs.',
        bpm: '108',
        vocalSpec: 'Male Lead',
        vocalTone: 'smooth, melodic, pidgin inflection, rhythmic cadence',
        referenceArtists:
            'Afrobeats swing, center-panned perc pocket; optional: Burna Boy, Wizkid, Davido',
        avoid: 'heavy trap sub-bass only, distorted guitars, dark ambient techno pads',
        songStructurePresetId: 'radio_edit',
      ),
    ),
    PromptTemplate(
      id: 'amapiano_club',
      title: 'Amapiano Bounce',
      description: 'Log drum club bass, continuous shakers, vocal chants',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Amapiano',
        subGenreFusion: 'Soulful House',
        vibe:
            'Authentic Amapiano: FM synthesized log-drum club bass, continuous hypnotic seed shakers, syncopated woodblock accents, smooth improvisational alto saxophone lounge lines, clean jazz piano comping, slow rhythmic pocket build.',
        bpm: '112',
        keyRoot: 'F',
        scale: 'Minor',
        vocalSpec: 'Vocal Chants Only',
        vocalTone: 'hypnotic spoken chant hooks, rhythmic short loops, low-density',
        referenceArtists:
            'log drum bounce, sub-heavy groove pocket; optional: Kabza De Small, DJ Maphorisa',
        avoid: 'live acoustic log drums, rock drums, heavy distorted vocal screaming',
        songStructurePresetId: 'edm_drop',
      ),
    ),
    PromptTemplate(
      id: 'praise_worship_epic',
      title: 'Praise & Worship',
      description: 'Contemporary Christian worship, pristine dynamic build',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Praise/Worship',
        subGenreFusion: 'Contemporary Gospel',
        vibe:
            'Epic modern worship: contemporary acoustic grand piano chords, soaring ambient electric guitar volume swells, stereo delay loops, lush legato orchestral string pads, majestic sustained French horn swells, pristine studio isolation.',
        bpm: '76',
        keyRoot: 'G',
        scale: 'Major',
        vocalSpec: 'Unison Stacks',
        vocalTone: 'prayerful, clear, thick multi-tracked vocal doubles, zero room bleed',
        referenceArtists:
            'worship acoustic dynamic build, analog VCA compression; optional: Hillsong, Elevation',
        avoid: 'club filter sweeps, sidechain pumping, DJ outro, synthetic loop triggers',
        songStructurePresetId: 'rnb_ballad',
      ),
    ),
    PromptTemplate(
      id: 'vinahouse_viet',
      title: 'Vinahouse Bounce',
      description: 'High-energy offbeat bounce, traditional strings',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Vinahouse',
        subGenreFusion: 'Hard Bounce',
        vibe:
            'High-energy Vinahouse: relentless offbeat bounce grooves, hard aggressive electronic kick, traditional pentatonic đàn tranh string motifs, cutting high-register trumpet stabs, heavy sub-bass pulses, high-tension festival fills.',
        bpm: '138',
        keyRoot: 'C',
        scale: 'Minor',
        vocalSpec: 'Female Lead',
        vocalTone: 'breathy, upfront, tight short phrase iterations',
        referenceArtists:
            'offbeat bounce groove, pentatonic hooks; optional: Hoaprox, Masew, DJ Trang Moon',
        avoid: 'slow acoustic guitars, dusty boom bap loops, relaxed behind-the-beat swing',
        songStructurePresetId: 'edm_drop',
      ),
    ),
    PromptTemplate(
      id: 'reggaeton_latino',
      title: 'Reggaeton Latino',
      description: 'Dem bow drum grid, classical nylon guitar, staccato horns',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Reggaeton',
        subGenreFusion: 'Latin Pop',
        vibe:
            'Urban Latin Pop: iconic crisp syncopated Dem Bow drum grid, heavy 808 sub-bass pulses, intimate bright classical nylon-string acoustic guitar picking, piercing staccato trumpet lines, fast-paced conga rolls, metal guiro scrapes.',
        bpm: '94',
        keyRoot: 'A',
        scale: 'Minor',
        vocalSpec: 'Male Lead',
        vocalTone: 'melodic swagger, fast-paced syncopated rhythmic delivery',
        referenceArtists:
            'dembow 808 pattern, bright synth plucks; optional: Bad Bunny, Rauw Alejandro',
        avoid: 'heavy rock guitars, distorted industrial techno saws, classic swing jazz',
        songStructurePresetId: 'radio_edit',
      ),
    ),
    PromptTemplate(
      id: 'modern_country_story',
      title: 'Modern Country',
      description: 'Acoustic strum pocket, pedal steel guitar, dry room',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Modern Country',
        subGenreFusion: 'Americana',
        vibe:
            'Polished modern country: crisp steel-string acoustic guitar strumming pocket, weeping pedal steel guitar slides, organic acoustic violin/fiddle layers, clean punchy studio rock drums, rustic tambourines, upright bass.',
        bpm: '102',
        keyRoot: 'D',
        scale: 'Major',
        vocalSpec: 'Male Lead',
        vocalTone: 'twang-forward, conversational, authentic story-first delivery',
        referenceArtists:
            'country acoustic strum, crisp radio polish; optional: Morgan Wallen, Luke Combs',
        avoid: 'synthetic sub bass, 808 glides, digital vocal chops, techno sidechain',
        songStructurePresetId: 'standard_pop',
      ),
    ),
    PromptTemplate(
      id: 'neo_soul_ballad',
      title: 'Neo-soul ballad',
      description: 'Slow R&B, intimate, R&B ballad structure',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Neo-Soul',
        subGenreFusion: 'R&B',
        vibe:
            'Intimate neo-soul ballad: silky Rhodes electric piano extensions, smooth fingerstyle Fender Jazz Bass, soft brushed acoustic drum kit, velvet legato tenor saxophone melodies, close-mic\'d harmon-muted trumpets, behind-the-beat hand congas.',
        bpm: '78',
        keyRoot: 'E',
        scale: 'Minor',
        vocalSpec: 'Female Lead',
        vocalTone: 'breathy, soulful, stacked vocal harmonies, warm intimate room tone',
        referenceArtists:
            'neo-soul intimacy, tape-warm saturation; optional: SZA, Daniel Caesar',
        avoid: 'EDM drops, heavy synth sidechain pump, fast triplet trap hats',
        songStructurePresetId: 'rnb_ballad',
      ),
    ),
    PromptTemplate(
      id: 'cinematic_trailer',
      title: 'Cinematic trailer',
      description: 'Orchestral hybrid, epic arcs, flexible structure',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Trailer',
        subGenreFusion: 'Orchestral',
        vibe:
            'Epic cinematic hybrid: thunderous timpani drum rolls, massive low-end symphonic gongs, intense violin and cello ostinatos, piercing lyrical oboes, majestic symphonic French horn swells, powerful fortissimo bass trombone slides, wide deep hall reverb.',
        bpm: '90',
        vocalSpec: 'Instrumental Only',
        referenceArtists:
            'trailer brass swells, hybrid symphonic score; optional: Hans Zimmer scale scope',
        avoid: 'pop electronic drums, modern vocal hooks, acoustic guitar strumming',
        songStructurePresetId: SongStructureData.flexibleId,
      ),
    ),
    PromptTemplate(
      id: 'bracket_edm_structure',
      title: 'Bracketed EDM structure',
      description:
          'Custom outline: full [Intro]…[Outro] example (Progressive → hard dance); paste-friendly for Suno',
      model: UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room',
        vibe:
            'Journey from progressive house to peak festival energy: emotional concert grand piano chords, evolving polyphonic sawtooth swells, wide stereo field, shifting into massive electronic kicks and euphoric supersaw leads.',
        bpm: '128',
        keyRoot: 'A#',
        scale: 'Minor',
        vocalSpec: 'Instrumental Only',
        vocalTone: 'ethereal ghostly background vocal pads in chorus section per outline',
        referenceArtists:
            'festival EDM arc, wide master bus width; optional: Swedish House Mafia, Martin Garrix',
        avoid: 'dry uncompressed mix, thin low end, acoustic folk instruments',
        songStructurePresetId: SongStructureData.customId,
        songStructureCustom: kSunoBracketStructureExampleFull,
      ),
    ),
  ];

  static PromptTemplate? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
