import 'structural_family_resolver.dart';

/// Per-genre default mutation for the Final Chorus (spec §3).
enum FinalChorusMutation {
  keyChangeAndOctaveDouble,
  adLibCounterMelody,
  halfTimeFeel,
  gospelVampCallAndResponse,
  spontaneousFlowLift,
  beatSwitchVariation,
  hookExtensionWithAdLibFlood,
  logDrumBassVariation,
  truncationWithPianoCoda,
  instrumentalFadeReentry,
  truncationWithLyricalTwist,
}

/// Version-dispatched routing and staging notes for final chorus / drop mutations.
abstract final class FinalChorusMutationRule {
  FinalChorusMutationRule._();

  /// Authoritative per-family Final Chorus / Final Drop mutation routing.
  ///
  /// Extend this table when new [StructuralFamily] values are added.
  static const Map<StructuralFamily, FinalChorusMutation> mutationTable = {
    StructuralFamily.popStandard: FinalChorusMutation.keyChangeAndOctaveDouble,
    StructuralFamily.popRadio: FinalChorusMutation.keyChangeAndOctaveDouble,
    StructuralFamily.mandopop: FinalChorusMutation.keyChangeAndOctaveDouble,
    StructuralFamily.edmProgressiveHouse:
        FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.edmTrance: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.edmTechno: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.edmHardstyle: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.edmDrumAndBass: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.edmBigRoom: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.trap: FinalChorusMutation.beatSwitchVariation,
    StructuralFamily.worship: FinalChorusMutation.gospelVampCallAndResponse,
    StructuralFamily.amapiano: FinalChorusMutation.logDrumBassVariation,
    StructuralFamily.hiphop: FinalChorusMutation.hookExtensionWithAdLibFlood,
    StructuralFamily.boom_bap: FinalChorusMutation.hookExtensionWithAdLibFlood,
    StructuralFamily.cinematic: FinalChorusMutation.truncationWithPianoCoda,
    StructuralFamily.folk: FinalChorusMutation.truncationWithLyricalTwist,
    StructuralFamily.jazzStandard: FinalChorusMutation.truncationWithLyricalTwist,
  };

  /// Falls back to [FinalChorusMutation.keyChangeAndOctaveDouble] if [family]
  /// is missing from [mutationTable].
  static FinalChorusMutation mutationFor(StructuralFamily family) =>
      mutationTable[family] ?? FinalChorusMutation.keyChangeAndOctaveDouble;

  static String stagingNoteFor(FinalChorusMutation m) {
    return switch (m) {
      FinalChorusMutation.keyChangeAndOctaveDouble =>
        'key-change lift, octave-double vocal, max belt dynamic',
      FinalChorusMutation.adLibCounterMelody =>
        'ad-lib counter-melody, wider harmonies, extended vocal tail',
      FinalChorusMutation.halfTimeFeel =>
        'half-time feel, belted chest voice, stripped percussion, trailing plate decay',
      FinalChorusMutation.gospelVampCallAndResponse =>
        'gospel call-and-response vamp, spontaneous lift, full choir belt',
      FinalChorusMutation.spontaneousFlowLift =>
        'spontaneous flow lift, leader ad-libs, congregation response',
      FinalChorusMutation.beatSwitchVariation =>
        'beat-switch to half-time final drop variation',
      FinalChorusMutation.hookExtensionWithAdLibFlood =>
        'hook extends over fading drum break, ad-lib flood, DJ scratch tag',
      FinalChorusMutation.logDrumBassVariation =>
        'log drum bass variation with chant accent, full groove climax',
      FinalChorusMutation.truncationWithPianoCoda =>
        'truncation into piano coda, lingering last phrase',
      FinalChorusMutation.instrumentalFadeReentry =>
        'instrumental fade then full-band re-entry, final hit',
      FinalChorusMutation.truncationWithLyricalTwist =>
        'truncation, final lyrical twist, closing single line',
    };
  }

  /// Version-dispatched mutation hint for directives or inline bracket staging.
  static String directiveFor({
    required FinalChorusMutation mutation,
    required String sunoVersion,
    bool inline = false,
  }) {
    final staging = stagingNoteFor(mutation);
    final v = sunoVersion.trim().toLowerCase();

    if (inline) {
      if (v == 'v4.5') return '';
      if (v.startsWith('v5.5')) return staging;
      return staging.split(',').first.trim();
    }

    if (v == 'v4.5') {
      return 'Final Chorus mutation: apply lyrical/dynamic mutation only — '
          'staging belongs in Block 1 prose for v4.5.';
    }

    return 'Final Chorus mutation ($staging): mandatory — never copy-paste Chorus 1.';
  }

  /// Short inline staging string for a final chorus / final drop bracket header.
  static String inlineStagingFor({
    required StructuralFamily family,
    required String sunoVersion,
  }) {
    return directiveFor(
      mutation: mutationFor(family),
      sunoVersion: sunoVersion,
      inline: true,
    );
  }
}
