// Structural family buckets for deterministic arc assembly.

enum StructuralFamily {

  popStandard,

  popRadio,

  edmProgressiveHouse,

  edmTrance,

  edmTechno,

  edmHardstyle,

  edmDrumAndBass,

  edmBigRoom,

  hiphop,

  worship,

  amapiano,

  cinematic,

  folk,

  jazzStandard,

  mandopop,

  trap,

  // ignore: constant_identifier_names
  boom_bap,

}



/// Resolves structural family from genre / lane strings (ordered priority).

class StructuralFamilyResolver {

  StructuralFamilyResolver._();



  /// All EDM sub-families (DJ mix + club-tier duration).

  static bool isEdmFamily(StructuralFamily family) {

    return switch (family) {

      StructuralFamily.edmProgressiveHouse ||

      StructuralFamily.edmTrance ||

      StructuralFamily.edmTechno ||

      StructuralFamily.edmHardstyle ||

      StructuralFamily.edmDrumAndBass ||

      StructuralFamily.edmBigRoom =>

        true,

      _ => false,

    };

  }



  /// Priority: [commercialLane] > [primaryGenre] > [fusionGenre] > pop fallback.

  static StructuralFamily resolve({

    String? primaryGenre,

    String? fusionGenre,

    String? commercialLane,

  }) {

    if (commercialLane != null && commercialLane.isNotEmpty) {

      return _resolveOne(commercialLane, orElse: StructuralFamily.popStandard);

    }

    if (primaryGenre != null && primaryGenre.isNotEmpty) {

      final fromPair = _resolveEdmFromGenres(primaryGenre, fusionGenre);

      if (fromPair != null) return fromPair;

      return _resolveOne(primaryGenre, orElse: _tryFallback(fusionGenre));

    }

    if (fusionGenre != null && fusionGenre.isNotEmpty) {

      return _tryFallback(fusionGenre);

    }

    return StructuralFamily.popStandard;

  }



  static StructuralFamily? _resolveEdmFromGenres(

    String primary,

    String? fusion,

  ) {

    for (final raw in [primary, fusion ?? '']) {

      if (raw.isEmpty) continue;

      final sub = _resolveEdmSubFamily(raw.toLowerCase());

      if (sub != null) return sub;

    }

    return null;

  }



  static StructuralFamily? _resolveEdmSubFamily(String n) {

    if (n.contains('progressive house') ||

        n.contains('prog house') ||

        n.contains('progressive trance')) {

      return StructuralFamily.edmProgressiveHouse;

    }

    if (n.contains('trance') ||

        n.contains('psytrance') ||

        n.contains('goa') ||

        n.contains('uplifting trance')) {

      return StructuralFamily.edmTrance;

    }

    if (n.contains('techno') ||

        n.contains('tech house') ||

        n.contains('tech-house') ||

        n.contains('minimal house') ||

        n.contains('dj house')) {

      return StructuralFamily.edmTechno;

    }

    if (n.contains('hardstyle') ||

        n.contains('hard dance') ||

        n.contains('hardstyle')) {

      return StructuralFamily.edmHardstyle;

    }

    if (n.contains('drum and bass') ||

        n.contains('drum & bass') ||

        n.contains('dnb') ||

        n.contains('jungle') ||

        n.contains('neurofunk') ||

        n.contains('liquid dnb')) {

      return StructuralFamily.edmDrumAndBass;

    }

    if (n.contains('big room') ||

        n.contains('bigroom') ||

        n.contains('festival house') ||

        n.contains('mainstage')) {

      return StructuralFamily.edmBigRoom;

    }

    return null;

  }



  static StructuralFamily _resolveOne(

    String name, {

    StructuralFamily orElse = StructuralFamily.popStandard,

  }) {

    final n = name.toLowerCase();

    final edmSub = _resolveEdmSubFamily(n);

    if (edmSub != null) return edmSub;

    if (n.contains('worship') || n.contains('gospel')) {

      return StructuralFamily.worship;

    }

    if (n.contains('jazz') ||

        n.contains('bebop') ||

        n.contains('swing') ||

        n.contains('big band') ||

        n.contains('nu-jazz') ||

        n.contains('acid jazz')) {

      return StructuralFamily.jazzStandard;

    }

    if (n.contains('cinematic') ||

        n.contains('ambient') ||

        n.contains('orchestral') ||

        n.contains('film score') ||

        n.contains('trailer') ||

        n.contains('dark ambient') ||

        n.contains('vaporwave') ||

        n.contains('synthwave')) {

      return StructuralFamily.cinematic;

    }

    if (n.contains('amapiano')) return StructuralFamily.amapiano;

    if (n.contains('folk') ||

        n.contains('bluegrass') ||

        n.contains('singer-songwriter') ||

        n.contains('americana') ||

        n.contains('indie folk')) {

      return StructuralFamily.folk;

    }

    if (n.contains('mandopop') || n.contains('c-pop')) {

      return StructuralFamily.mandopop;

    }

    if (n.contains('boom bap') ||

        n.contains('boom-bap') ||

        n.contains('90s hip hop') ||

        n.contains('classic hip hop') ||

        n.contains('east coast') ||

        n.contains('golden era')) {

      return StructuralFamily.boom_bap;

    }

    if (n.contains('trap') ||

        n.contains('melodic trap') ||

        n.contains('drill') ||

        n.contains('phonk')) {

      return StructuralFamily.trap;

    }

    if (n.contains('hip hop') ||

        n.contains('hip-hop') ||

        n.contains('rap') ||

        n.contains('lo-fi hip hop') ||

        n.contains('chillhop') ||

        n.contains('cloud rap') ||

        n.contains('jazz rap')) {

      return StructuralFamily.hiphop;

    }

    if (n.contains('edm') ||

        n.contains('electronic') ||

        n.contains('house') ||

        n.contains('dubstep') ||

        n.contains('bass') ||

        n.contains('bounce') ||

        n.contains('garage') ||

        n.contains('future bass') ||

        n.contains('future house') ||

        n.contains('nu-disco') ||

        n.contains('vinahouse') ||

        n.contains('jersey club') ||

        n.contains('gqom')) {

      return StructuralFamily.edmProgressiveHouse;

    }

    if (n.contains('pop')) return StructuralFamily.popStandard;

    if (n.contains('rock') ||

        n.contains('metal') ||

        n.contains('punk') ||

        n.contains('shoegaze') ||

        n.contains('emo') ||

        n.contains('alt rock') ||

        n.contains('post-rock')) {

      return StructuralFamily.popStandard;

    }

    if (n.contains('r&b') ||

        n.contains('rnb') ||

        n.contains('soul') ||

        n.contains('funk') ||

        n.contains('neo-soul') ||

        n.contains('quiet storm') ||

        n.contains('new jack') ||

        n.contains('trap soul')) {

      return StructuralFamily.popStandard;

    }

    if (n.contains('country')) return StructuralFamily.popStandard;

    if (n.contains('reggae') ||

        n.contains('dub') ||

        n.contains('dancehall') ||

        n.contains('reggaeton') ||

        n.contains('latin') ||

        n.contains('bachata') ||

        n.contains('salsa') ||

        n.contains('cumbia') ||

        n.contains('forró') ||

        n.contains('sertanejo') ||

        n.contains('bossa nova')) {

      return StructuralFamily.popRadio;

    }

    return orElse;

  }



  static StructuralFamily _tryFallback(String? fusion) {

    if (fusion == null || fusion.isEmpty) return StructuralFamily.popStandard;

    return _resolveOne(fusion);

  }



  /// Genre/lane hint for tests and lane-override assembly.

  static String laneHintFor(StructuralFamily family) {

    switch (family) {

      case StructuralFamily.popStandard:

        return 'Pop';

      case StructuralFamily.popRadio:

        return 'Reggaeton';

      case StructuralFamily.edmProgressiveHouse:

        return 'Progressive House';

      case StructuralFamily.edmTrance:

        return 'Trance';

      case StructuralFamily.edmTechno:

        return 'Techno';

      case StructuralFamily.edmHardstyle:

        return 'Hardstyle';

      case StructuralFamily.edmDrumAndBass:

        return 'Drum and Bass';

      case StructuralFamily.edmBigRoom:

        return 'Big Room House';

      case StructuralFamily.hiphop:

        return 'Hip Hop';

      case StructuralFamily.worship:

        return 'Worship';

      case StructuralFamily.amapiano:

        return 'Amapiano';

      case StructuralFamily.cinematic:

        return 'Cinematic';

      case StructuralFamily.folk:

        return 'Folk';

      case StructuralFamily.jazzStandard:

        return 'Jazz';

      case StructuralFamily.mandopop:

        return 'Mandopop';

      case StructuralFamily.trap:

        return 'Trap';

      case StructuralFamily.boom_bap:

        return 'Boom Bap';

    }

  }

}


