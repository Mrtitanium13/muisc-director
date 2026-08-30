import '../constants/song_structure_data.dart';
import 'structural_family_resolver.dart';

/// Positional context for genre-aware default staging lookup.
class StagingContext {
  const StagingContext({
    required this.kind,
    required this.label,
    this.verseOrdinal = 1,
    this.hookOrdinal = 1,
    this.chorusOrdinal = 1,
    this.dropOrdinal = 1,
    this.buildUpOrdinal = 1,
  });

  final SectionKind kind;
  final String label;
  final int verseOrdinal;
  final int hookOrdinal;
  final int chorusOrdinal;
  final int dropOrdinal;
  final int buildUpOrdinal;
}

/// Per-family structural DNA: label overrides + sonic staging vocabulary.
///
/// Data lives here — [SunoSyntaxRenderer] delegates label/staging resolution
/// to this module so genre conventions stay deterministic and testable.
class GenreStructuralProfile {
  GenreStructuralProfile._();

  /// Display label for bracket rendering (routing [SectionKind] stays unchanged).
  static String displayLabel(SongSection s, StructuralFamily? family) {
    if (family == null) return s.label;

    switch (family) {
      case StructuralFamily.boom_bap:
        if (s.kind == SectionKind.hook) return 'Chorus';
      case StructuralFamily.worship:
        if (s.kind == SectionKind.spontaneousFlow) {
          return 'Spontaneous Worship / Flow';
        }
      case StructuralFamily.edmProgressiveHouse:
      case StructuralFamily.edmTrance:
      case StructuralFamily.edmTechno:
      case StructuralFamily.edmHardstyle:
      case StructuralFamily.edmDrumAndBass:
      case StructuralFamily.edmBigRoom:
      case StructuralFamily.cinematic:
      case StructuralFamily.jazzStandard:
      case StructuralFamily.popStandard:
      case StructuralFamily.popRadio:
      case StructuralFamily.hiphop:
      case StructuralFamily.amapiano:
      case StructuralFamily.folk:
      case StructuralFamily.mandopop:
      case StructuralFamily.trap:
        break;
    }
    return s.label;
  }

  /// Genre- and position-aware default staging (sonic character only).
  static String defaultStaging(
    StructuralFamily? family,
    StagingContext ctx,
  ) {
    if (family == null) return _genericStaging(ctx);
    return switch (family) {
      StructuralFamily.popStandard => _popStandardStaging(ctx),
      StructuralFamily.popRadio => _popRadioStaging(ctx),
      StructuralFamily.edmProgressiveHouse => _edmProgressiveHouseStaging(ctx),
      StructuralFamily.edmTrance => _edmTranceStaging(ctx),
      StructuralFamily.edmTechno => _edmTechnoStaging(ctx),
      StructuralFamily.edmHardstyle => _edmHardstyleStaging(ctx),
      StructuralFamily.edmDrumAndBass => _edmDrumAndBassStaging(ctx),
      StructuralFamily.edmBigRoom => _edmBigRoomStaging(ctx),
      StructuralFamily.hiphop => _hiphopStaging(ctx),
      StructuralFamily.boom_bap => _boomBapStaging(ctx),
      StructuralFamily.worship => _worshipStaging(ctx),
      StructuralFamily.amapiano => _amapianoStaging(ctx),
      StructuralFamily.cinematic => _cinematicStaging(ctx),
      StructuralFamily.folk => _folkStaging(ctx),
      StructuralFamily.jazzStandard => _jazzStaging(ctx),
      StructuralFamily.mandopop => _mandopopStaging(ctx),
      StructuralFamily.trap => _trapStaging(ctx),
    };
  }

  static String _genericStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'ambient establishing pad texture',
        SectionKind.verse => ctx.verseOrdinal >= 3
            ? 'full band weight, wider stereo field, vocal intensity peaks'
            : ctx.verseOrdinal == 2
                ? 'denser drum groove, wider stereo field'
                : 'sparse arrangement, intimate lead vocal',
        SectionKind.preChorus => 'rising tension, harmonic anticipation',
        SectionKind.chorus => ctx.chorusOrdinal >= 2
            ? 'stacked vocal doubles, wide stereo lift'
            : 'tight mono pocket, lead vocal centered',
        SectionKind.hook => ctx.hookOrdinal >= 2
            ? 'stacked vocal doubles, wide stereo lift, full dynamic peak'
            : 'tight mono pocket, lead vocal centered',
        SectionKind.bridge =>
          'stripped-back dynamic shift, vulnerable vocal pocket',
        SectionKind.breakdown => 'stripped atmospheric space',
        SectionKind.buildUp =>
          'rising white-noise sweep, snare roll tension',
        SectionKind.drop => ctx.dropOrdinal >= 2
            ? 'second half-time variation, wider stereo, ad-lib flood over drop'
            : 'signature instrument hook land, full energy, sub-bass weight',
        SectionKind.dropA => ctx.dropOrdinal >= 2
            ? 'second drop variation, wider stereo, evolved lead hook'
            : 'driving bassline, supersaw chords, signature lead hook',
        SectionKind.dropB =>
          'second drop variation, wider stereo, evolved lead hook',
        SectionKind.mainDrop => ctx.dropOrdinal >= 2
            ? 'peak drop impact, full arrangement, sub-bass weight'
            : 'primary drop impact, signature hook land, full energy',
        SectionKind.riser =>
          'rising tension, snare roll, filter sweep, white-noise lift',
        SectionKind.fill => 'short percussive transition, tom fill, energy step',
        SectionKind.atmosphericBreak =>
          'ethereal pads, vocal chop reverb wash, ambient space',
        SectionKind.antiClimax =>
          'fake drop tension, energy dip, stripped percussion tease',
        SectionKind.finalDrop =>
          'second half-time variation, wider stereo, ad-lib flood over drop',
        SectionKind.finalChorus => 'key-change lift, max dynamics',
        SectionKind.vamp => 'congregational call-and-response',
        SectionKind.spontaneousFlow => 'leader ad-libs over sustained chord',
        SectionKind.interlude => 'instrumental interlude',
        SectionKind.solo => 'instrumental solo',
        SectionKind.outro => 'gradual decay fade-out',
        SectionKind.end || SectionKind.unknown || SectionKind.postChorus => '',
      };

  static String _popStandardStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'warm pad swell establishing the tonal center',
        SectionKind.verse => ctx.verseOrdinal >= 3
            ? 'full band weight, wider stereo field, vocal intensity peaks'
            : ctx.verseOrdinal == 2
                ? 'denser drum groove, wider stereo field'
                : 'stripped arrangement, intimate lead vocal',
        SectionKind.preChorus => 'rising tension, harmonic anticipation',
        SectionKind.chorus => ctx.chorusOrdinal >= 2
            ? 'stacked vocal doubles, wide stereo lift'
            : 'tight mono pocket, lead vocal centered',
        SectionKind.bridge =>
          'stripped back, vulnerable pocket, dynamic dip',
        SectionKind.finalChorus =>
          'key-change lift, octave-double vocal, max belt dynamic',
        SectionKind.outro => 'gradual reverb fade, lingering last phrase',
        _ => _genericStaging(ctx),
      };

  static String _popRadioStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'warm pad swell, radio-ready tonal center',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'denser drum groove, wider stereo field'
            : 'stripped arrangement, intimate lead vocal',
        SectionKind.chorus => ctx.chorusOrdinal >= 2
            ? 'stacked vocal doubles, wide stereo lift'
            : 'tight mono pocket, lead vocal centered',
        SectionKind.outro => 'hard-hitting tag ending, short fade',
        _ => _popStandardStaging(ctx),
      };

  static String _edmProgressiveHouseStaging(StagingContext ctx) =>
      _edmSharedStaging(ctx);

  static String _edmTranceStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'atmospheric pads, light percussion',
        SectionKind.buildUp =>
          'arpeggiated synth lead, snare roll, filter sweep',
        SectionKind.dropA =>
          'driving bassline, supersaw chords, plucky lead',
        SectionKind.atmosphericBreak =>
          'ethereal pads, vocal chop reverb wash',
        SectionKind.finalDrop =>
          'euphoric lead melody, layered synths, pounding kick',
        SectionKind.outro => 'filter decay, reverb tail',
        _ => _edmSharedStaging(ctx),
      };

  static String _edmTechnoStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'filtered kick, rumble bass, subtle hi-hats',
        SectionKind.buildUp => 'tense synth stabs, increasing clap pattern',
        SectionKind.mainDrop =>
          'heavy 909 kick, dark percussion loop, hypnotic acid line',
        SectionKind.breakdown => 'droning pads, industrial fx',
        _ => _edmSharedStaging(ctx),
      };

  static String _edmHardstyleStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.antiClimax => 'fake drop tension, kick tease, energy dip',
        SectionKind.mainDrop => 'distorted hardstyle kick, reverse bass punch',
        SectionKind.breakdown => 'melodic synth lead, emotional lift',
        SectionKind.finalDrop => 'peak hardstyle kick, full reverse bass drive',
        _ => _edmSharedStaging(ctx),
      };

  static String _edmDrumAndBassStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'amen break tease, sub rumble, atmospheric pad',
        SectionKind.buildUp => 'snare roll, rising bass wobble, tension lift',
        SectionKind.dropA => 'rolling breakbeat, reese bass, sharp lead stab',
        SectionKind.finalDrop => 'peak break pressure, full sub weight, lead hook',
        _ => _edmSharedStaging(ctx),
      };

  static String _edmBigRoomStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.mainDrop => 'supersaw lead, sidechain pump, festival kick',
        SectionKind.riser => 'white-noise sweep, snare roll, pitch riser',
        SectionKind.finalDrop => 'mainstage supersaw climax, wide stereo lift',
        _ => _edmSharedStaging(ctx),
      };

  static String _edmSharedStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro =>
          '16-bar DJ-friendly drum loop, tonal world establish',
        SectionKind.buildUp =>
          'rising white-noise sweep, snare roll tension, filter open-up',
        SectionKind.drop => ctx.dropOrdinal >= 2
            ? 'second half-time variation, wider stereo, ad-lib flood over drop'
            : 'signature instrument hook land, full energy, sub-bass weight',
        SectionKind.dropA => ctx.dropOrdinal >= 2
            ? 'second drop variation, wider stereo, evolved lead hook'
            : 'driving bassline, supersaw chords, signature lead hook',
        SectionKind.dropB =>
          'second drop variation, wider stereo, evolved lead hook',
        SectionKind.mainDrop => ctx.dropOrdinal >= 2
            ? 'peak drop impact, full arrangement, sub-bass weight'
            : 'primary drop impact, signature hook land, full energy',
        SectionKind.breakdown =>
          'stripped atmospheric pads, distant vocal texture, ambient space',
        SectionKind.finalDrop =>
          'second half-time variation, wider stereo, ad-lib flood over drop',
        SectionKind.outro => 'DJ mix-out loop, 16-bar drum-only exit',
        _ => _genericStaging(ctx),
      };

  static String _hiphopStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro =>
          'distant vocal sample, vinyl crackle, pocket drum tease',
        SectionKind.verse => ctx.verseOrdinal >= 3
            ? 'full break pressure, vocal intensity peaks, ad-lib flood'
            : ctx.verseOrdinal == 2
                ? 'denser break pressure, vocal urgency up, ad-lib accents'
                : 'boom bap pocket, dry vocal, swung 16th feel',
        SectionKind.hook => ctx.hookOrdinal >= 2
            ? 'wider vocal doubles, delayed horn flash, lift in dynamics'
            : 'mono low groove, lead vocal centered, tight pocket',
        SectionKind.bridge =>
          'beat-switch moment, filtered Rhodes bed, dynamic dip',
        SectionKind.outro =>
          'ad-lib fade, DJ scratching tail, distant vocal echo',
        _ => _genericStaging(ctx),
      };

  static String _boomBapStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro =>
          'close-mic vocal sample, dusted vinyl crackle, warm bass tease',
        SectionKind.verse => ctx.verseOrdinal >= 3
            ? 'full band weight, wider stereo field, vocal intensity peaks'
            : ctx.verseOrdinal == 2
                ? 'denser drum break, vocal urgency escalates, filtered mid loop'
                : 'stripped 90s boom bap pocket, dry intimate vocal, swung 16ths',
        SectionKind.hook => ctx.hookOrdinal >= 2
            ? 'crisp horn flash, wider vocal doubles, lifted dynamics'
            : 'tight pocket, low mono groove, lead vocal grounded',
        SectionKind.interlude =>
          'DJ scratch cut, isolated drum break, beat-breakdown moment',
        SectionKind.outro =>
          'fading ad-lib tail, scratch tag, lo-fi tape roll-off',
        _ => _genericStaging(ctx),
      };

  static String _worshipStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro =>
          'warm pad swell, congregation settle, soft worshipful tone',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'drums lift in, wider arrangement, vocal delivery builds'
            : 'acoustic intimacy, close-mic tender vocal, sparse arrangement',
        SectionKind.chorus => ctx.chorusOrdinal >= 2
            ? 'stacked worship choir, wider stereo, rising intensity'
            : 'full worship lift, layered vocal harmonies, open dynamic',
        SectionKind.bridge =>
          'stripped-back vulnerable pocket, leader vocal exposed',
        SectionKind.vamp =>
          'congregational call-and-response, 4-bar repeating motif',
        SectionKind.spontaneousFlow =>
          'leader ad-libs over sustained chord, congregation hums',
        SectionKind.finalChorus =>
          'gospel vamp lift, full choir belt, hands-up energy',
        SectionKind.outro =>
          'gentle decay, congregation amen resolve, soft piano fade',
        _ => _genericStaging(ctx),
      };

  static String _amapianoStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'shaker pulse, log drum tease, atmospheric pad',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'log drum pattern variation, denser hi-hats, vocal urgency'
            : 'minimal pocket, intimate chant vocal, log drum light',
        SectionKind.chorus => ctx.chorusOrdinal >= 2
            ? 'full groove peak, log drum punch, group chant accents'
            : 'full groove land, log drum punch, group chant accents',
        SectionKind.bridge =>
          'filtered pad moment, vocal chant layering, build toward breakdown',
        SectionKind.breakdown =>
          'log drum isolated, atmospheric space, rising percussion texture',
        SectionKind.finalChorus =>
          'log drum bass variation, full groove peak, group chant accents',
        SectionKind.outro =>
          'gentle groove fade, log drum tail, percussion trail-off',
        _ => _genericStaging(ctx),
      };

  static String _cinematicStaging(StagingContext ctx) {
    if (ctx.label.contains('Theme')) {
      return 'main melodic theme introduced, full orchestral warmth';
    }
    return switch (ctx.kind) {
      SectionKind.intro =>
        'distant orchestral pad, atmospheric world establish',
      SectionKind.interlude =>
        'motif expansion, counter-melody, harmonic complexity builds',
      SectionKind.drop =>
        'full orchestral peak, brass statement, timpani punctuate, max dynamic',
      SectionKind.outro =>
        'theme resolve, gentle decay, lingering final orchestral chord',
      _ => _genericStaging(ctx),
    };
  }

  static String _folkStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => 'warm acoustic guitar fingerpick, ambient room tone',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'second instrument joins, fiddle or mandolin enters, vocal lifts'
            : 'stripped folk pocket, intimate close-mic vocal, single acoustic',
        SectionKind.chorus =>
          'full folk lift, acoustic strum, vocal harmonies enter',
        SectionKind.interlude =>
          'fingerpicked acoustic passage, breathing space, room ambience',
        SectionKind.bridge =>
          'vulnerable pocket, lead vocal exposed, single instrument carry',
        SectionKind.finalChorus =>
          'truncation lyrical twist, closing stanza reframe, final line',
        SectionKind.outro =>
          'gentle decay fade, acoustic tail, room ambience lingering',
        _ => _genericStaging(ctx),
      };

  static String _jazzStaging(StagingContext ctx) {
    final label = ctx.label.toLowerCase();
    if (label.contains('head return')) {
      return 'head returns full, post-solo recommitment, warm room ambience';
    }
    if (label.contains('head out')) {
      return 'final head statement, gentle close, last cymbal tap';
    }
    if (label.contains('middle eight')) {
      return 'harmonic turn, modulating bridge, walking bass carries';
    }
    if (label.contains('solo')) {
      return 'instrumental solo over changes, trading-eights feel, dynamic peak';
    }
    if (ctx.kind == SectionKind.verse) {
      return label.contains('(head)')
          ? 'melodic head stated cleanly, walking bass, brushed drums'
          : 'head re-state with subtle embellishment';
    }
    return switch (ctx.kind) {
      SectionKind.intro => 'ambient room establish, walking bass tease',
      SectionKind.outro => 'gentle tail-out, final chord sustain, room decay',
      _ => _genericStaging(ctx),
    };
  }

  static String _mandopopStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro =>
          'erhu establishing line, guzheng shimmer, cinematic tonal center',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'fuller arrangement enters, strings pad layer, vocal delivery builds'
            : 'intimate vocal, spare piano, subtle erhu undertone',
        SectionKind.preChorus =>
          'rising tension, harmonic anticipation, vocal lift into chorus',
        SectionKind.chorus =>
          'full pop lift, key-change lift preparation, layered harmonies, string swell',
        SectionKind.bridge =>
          'vulnerable pocket, erhu statement alone, dynamic dip',
        SectionKind.finalChorus =>
          'key-change lift with full string swell and octave-double vocal',
        SectionKind.outro =>
          'piano coda resolve, erhu farewell line, gentle decay',
        _ => _genericStaging(ctx),
      };

  static String _trapStaging(StagingContext ctx) => switch (ctx.kind) {
        SectionKind.intro => '808 tease, atmospheric pad, vocal ad-lib tease',
        SectionKind.hook => ctx.hookOrdinal >= 2
            ? 'beat-switch half-time feel, ad-lib flood, max energy'
            : 'triple-time hi-hats, lead vocal centered, hard-hitting 808',
        SectionKind.verse => ctx.verseOrdinal == 2
            ? 'denser 808 variation, vocal urgency escalates, ad-lib accents'
            : 'sparse pocket, vocal cadence focus, minimal hi-hats',
        SectionKind.bridge =>
          'beat-switch to half-time feel, 808 pattern change, new bass texture',
        SectionKind.outro => 'ad-lib flood fade, 808 tail, reverb wash close',
        _ => _genericStaging(ctx),
      };
}
