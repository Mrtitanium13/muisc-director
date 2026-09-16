import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/ai/modules/genre_lyrics_emission.dart';
import 'package:music_director/core/ai/modules/humanized_lyrics_qa.dart';
import 'package:music_director/core/ai/modules/k_genre_cliche_blacklist.dart';
import 'package:music_director/core/ai/modules/k_human_voice_directive.dart';
import 'package:music_director/core/constants/api_constants.dart';
import 'package:music_director/core/constants/dialect_style_data.dart';
import 'package:music_director/core/ai/modules/meaningfulness_check.dart';
import 'package:music_director/core/routing/music_prompt_routing.dart';
import 'package:music_director/core/constants/suno_polish_system_prompt.dart';
import 'package:music_director/core/routing/music_prompt_routing_monitor.dart';
import 'package:music_director/core/routing/genre_scaffold_map.dart';
import 'package:music_director/core/routing/prompt_engine_qa.dart';
import 'package:music_director/core/routing/stage1_classifier.dart';
import 'package:music_director/core/routing/stage2_model_router.dart';
import 'package:music_director/data/models/user_input_model.dart';

UserInputModel _input({
  String primaryGenre = '',
  String subGenreFusion = '',
  String vibe = '',
  String language = 'English',
  String? vocalAccent,
  String dialectStyleId = DialectStyleData.standardEnglishId,
  String dialectVariantId = DialectStyleData.generalVariantId,
}) =>
    UserInputModel(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      language: language,
      vocalAccent: vocalAccent,
      dialectStyleId: dialectStyleId,
      dialectVariantId: dialectVariantId,
    );

Stage1Classification _classify(UserInputModel input, {String? textHint}) =>
    Stage1Classifier.classify(input, textHint: textHint ?? input.vibe);

void main() {
  group('Stage1Classifier routing matrix', () {
    test('Amapiano → GEN_AFRICAN_MAINSTREAM', () {
      final c = _classify(_input(vibe: 'Amapiano groove, log drum'));
      expect(c.routingKey, RoutingKeys.genAfricanMainstream);
      expect(c.eastAsianSubVariant, isNull);
    });

    test('Nigerian Pidgin gospel + ibibio accent → GEN_AFRICAN_PIDGIN / ibibio', () {
      final c = _classify(
        _input(
          vibe: 'Nigerian Pidgin gospel',
          vocalAccent: 'nigerian_ibibio',
          dialectStyleId: DialectStyleData.nigerianPidginId,
          dialectVariantId: 'ibibio',
        ),
      );
      expect(c.routingKey, RoutingKeys.genAfricanPidgin);
      expect(c.pidginSubVariant, 'ibibio');
    });

    test('Mandopop → GEN_EAST_ASIAN / mandopop', () {
      final c = _classify(_input(vibe: 'Mandopop ballad in Chinese'));
      expect(c.routingKey, RoutingKeys.genEastAsian);
      expect(c.eastAsianSubVariant, 'mandopop');
    });

    test('K-pop → GEN_EAST_ASIAN / kpop', () {
      final c = _classify(_input(vibe: 'K-pop dance track'));
      expect(c.routingKey, RoutingKeys.genEastAsian);
      expect(c.eastAsianSubVariant, 'kpop');
    });

    test('Vinahouse → GEN_EAST_ASIAN / vpop_vinahouse', () {
      final c = _classify(_input(vibe: 'Vinahouse Vietnamese'));
      expect(c.routingKey, RoutingKeys.genEastAsian);
      expect(c.eastAsianSubVariant, 'vpop_vinahouse');
    });

    test('French chanson → GEN_EUROPEAN_LINGUAL', () {
      final c = _classify(_input(vibe: 'French chanson'));
      expect(c.routingKey, RoutingKeys.genEuropeanLingual);
    });

    test('Reggaeton → GEN_LATIN', () {
      final c = _classify(_input(vibe: 'Reggaeton'));
      expect(c.routingKey, RoutingKeys.genLatin);
    });

    test('Indie rock US → GEN_WESTERN_POP', () {
      final c = _classify(_input(vibe: 'Indie rock US'));
      expect(c.routingKey, RoutingKeys.genWesternPop);
    });

    test('Arabic pop → GEN_MIDDLE_EASTERN', () {
      final c = _classify(_input(vibe: 'Arabic pop'));
      expect(c.routingKey, RoutingKeys.genMiddleEastern);
    });

    test('Amapiano + Vinahouse hybrid → HYBRID_MULTI_GENRE', () {
      final c = _classify(_input(vibe: 'Amapiano + Vinahouse hybrid'));
      expect(c.routingKey, RoutingKeys.hybridMultiGenre);
      expect(c.isHybrid, isTrue);
    });

    test('Afrobeat + EDM crossover → HYBRID_MULTI_GENRE', () {
      final c = _classify(
        _input(
          primaryGenre: 'Afrobeat',
          subGenreFusion: 'EDM',
          vibe: 'Afrobeat + EDM crossover',
        ),
      );
      expect(c.routingKey, RoutingKeys.hybridMultiGenre);
      expect(c.isHybrid, isTrue);
    });

    test('Three-genre fusion → HYBRID_MULTI_GENRE', () {
      final c = _classify(
        _input(
          primaryGenre: 'Amapiano',
          subGenreFusion: 'Vinahouse',
          vibe: 'Afrobeat blend',
        ),
      );
      expect(c.routingKey, RoutingKeys.hybridMultiGenre);
      expect(c.isHybrid, isTrue);
    });

    test('K-pop bilingual → HYBRID_CULTURAL', () {
      final c = _classify(
        _input(vibe: 'K-pop with English verse and Korean chorus'),
      );
      expect(c.routingKey, RoutingKeys.hybridCultural);
      expect(c.isHybrid, isTrue);
    });

    test('Latin bilingual → HYBRID_CULTURAL', () {
      final c = _classify(
        _input(vibe: 'Bilingual Latin track Spanish + English'),
      );
      expect(c.routingKey, RoutingKeys.hybridCultural);
      expect(c.isHybrid, isTrue);
    });
  });

  group('Stage2ModelRouter', () {
    test('African Pidgin routes to Claude', () {
      final c = _classify(
        _input(
          vibe: 'Pidgin worship',
          dialectStyleId: DialectStyleData.nigerianPidginId,
        ),
      );
      expect(Stage2ModelRouter.pickModelKey(c), ModelKeys.claudeSonnet);
    });

    test('East Asian routes to GLM', () {
      final c = _classify(_input(vibe: 'Mandopop'));
      expect(Stage2ModelRouter.pickModelKey(c), ModelKeys.glm);
    });

    test('Hybrid with Vinahouse picks GLM', () {
      final c = _classify(
        _input(
          primaryGenre: 'Amapiano',
          subGenreFusion: 'Vinahouse',
        ),
      );
      expect(c.routingKey, RoutingKeys.hybridMultiGenre);
      expect(Stage2ModelRouter.pickModelKey(c), ModelKeys.glm);
    });

    test('Western pop English draft uses Gemini 3.1 Pro on LaoZhang', () {
      final c = _classify(_input(vibe: 'Indie rock US'));
      expect(Stage2ModelRouter.pickModelKey(c), ModelKeys.gpt5);
      expect(
        Stage2ModelRouter.resolveDraftModelSlug(
          classification: c,
          useOpenRouter: false,
          lightweight: false,
        ),
        ApiConstants.laozhangGemini31ProModel,
      );
    });

    test('routing user block append includes routing_key', () {
      final c = _classify(_input(vibe: 'Amapiano'));
      final block = Stage2ModelRouter.buildRegionalUserBlockAppend(c);
      expect(block, contains('routing_key=GEN_AFRICAN_MAINSTREAM'));
    });
  });

  group('Item 1 — hybrid tempo_strategy', () {
    test('Amapiano + Vinahouse triggers dual_section tempo strategy', () {
      final c = _classify(
        _input(
          primaryGenre: 'Amapiano',
          subGenreFusion: 'Vinahouse',
        ),
      );
      expect(c.hybridResolution?.tempoStrategy, equals('dual_section'));
    });

    test('dual_section appears in user-block for Amapiano + Vinahouse', () {
      final c = _classify(
        _input(
          primaryGenre: 'Amapiano',
          subGenreFusion: 'Vinahouse',
        ),
      );
      final block = Stage2ModelRouter.buildRegionalUserBlockAppend(c);
      expect(block, contains('tempo_strategy=dual_section'));
      expect(block, contains('TEMPO_STRATEGY=dual_section'));
    });

    test('≤8 BPM gap → dominant_lock', () {
      final c = _classify(
        _input(
          primaryGenre: 'Afrobeats',
          subGenreFusion: 'Amapiano',
        ),
      );
      expect(c.hybridResolution?.tempoStrategy, equals('dominant_lock'));
    });

    test('≤20 BPM gap → midpoint', () {
      final c = _classify(
        _input(
          primaryGenre: 'Amapiano',
          subGenreFusion: 'House',
        ),
      );
      expect(c.hybridResolution?.tempoStrategy, equals('midpoint'));
    });
  });

  group('Item 2 — Ibibio polish persistence', () {
    test('draft user-block includes full Ibibio vocabulary', () {
      final c = _classify(
        _input(
          vibe: 'Nigerian Pidgin gospel',
          vocalAccent: 'nigerian_ibibio',
          dialectStyleId: DialectStyleData.nigerianPidginId,
          dialectVariantId: 'ibibio',
        ),
      );
      final block = Stage2ModelRouter.buildRegionalUserBlockAppend(c);
      expect(block, contains('Abasi'));
      expect(block, contains('esie'));
      expect(block, contains('kpa'));
    });

    test('polish user-block carries Ibibio vocabulary guard', () {
      final c = _classify(
        _input(
          vibe: 'gospel worship',
          vocalAccent: 'nigerian_ibibio',
          dialectStyleId: DialectStyleData.nigerianPidginId,
          dialectVariantId: 'ibibio',
        ),
      );
      final userBlock =
          'Primary genre: Gospel\n\n${Stage2ModelRouter.buildRegionalUserBlockAppend(c)}';
      final polishUser = buildSunoPolishUserMessage(
        draft: '[Verse 1]\nAbasi mi kpa emi edinen',
        originalUserBlock: userBlock,
        pidginSubVariant: 'ibibio',
      );
      expect(polishUser, contains('Abasi'));
      expect(polishUser, contains('esie'));
      expect(polishUser, contains('kpa'));
    });

    test('five Ibibio gospel fixtures pass post-polish marker QA', () {
      const fixtures = [
        '[Chorus]\nAbasi mi kpa emi edinen\nEsie dey watch idaha fo mi',
        '[Verse 1]\nMmo dey sing, kpa emi nno\nEdinen word fo mi heart',
        '[Bridge]\nAbasi esie kpa — idaha fo mi\nMi dey nno fo Cross River',
        '[Chorus]\nKpa edinen, Abasi mmo\nEsie mi idaha nno',
        '[Outro]\nAbasi mi, esie kpa emi\nFo mi edinen idaha',
      ];
      for (final lyrics in fixtures) {
        expect(
          IbibioLyricQa.passesPostPolishQa(lyrics),
          isTrue,
          reason: lyrics,
        );
        expect(IbibioLyricQa.lagosHits(lyrics), isEmpty);
      }
    });

    test('Ibibio output rejects Lagos vocabulary', () {
      const lagosLyrics = '[Chorus]\nWahala dey, abeg na wa o sef oya';
      expect(IbibioLyricQa.lagosHits(lagosLyrics), isNotEmpty);
      expect(IbibioLyricQa.passesPostPolishQa(lagosLyrics), isFalse);
    });
  });

  group('Item 3 — Ibibio V1 fallback logging', () {
    test('metrics track ibibio v1 fallback rate', () {
      MusicPromptRoutingMonitor.resetMetrics();
      for (var i = 0; i < 20; i++) {
        MusicPromptRoutingMonitor.recordRoutingGateCheck();
      }
      MusicPromptRoutingMonitor.warnIbibioV1Fallback();
      expect(MusicPromptRoutingMonitor.ibibioV1FallbackCount, 1);
      expect(
        MusicPromptRoutingMonitor.ibibioV1FallbackRateExceeds(0.05),
        isFalse,
      );
      for (var i = 0; i < 5; i++) {
        MusicPromptRoutingMonitor.warnIbibioV1Fallback();
      }
      expect(
        MusicPromptRoutingMonitor.ibibioV1FallbackRateExceeds(0.05),
        isTrue,
      );
    });
  });

  group('Item 4 — style_prompt QA contract', () {
    test('blacklistViolation catches Section D words', () {
      const bad =
          'immersive log-drum groove with ethereal haunting tapestry feel';
      expect(
        PromptEngineQa.blacklistViolation(bad),
        containsAll(['immersive', 'ethereal', 'haunting', 'tapestry']),
      );
    });

    test('valid natural-language style passes contract', () {
      const style =
          'log-drum Amapiano groove dusty shaker pocket breathy close-mic lead deep sub warm Rhodes vocal-forward mix township swing';
      expect(PromptEngineQa.qaCheckStylePromptContract(style), isEmpty);
    });

    test('240-char hard limit flagged', () {
      final long = 'a' * 241;
      expect(
        PromptEngineQa.qaCheckStylePromptContract(long),
        contains(contains('240-char hard limit')),
      );
    });

    test('legacy comma-tag list flagged', () {
      const legacy = 'amapiano,log-drum,shaker,vocal-forward,deep-sub';
      expect(
        PromptEngineQa.qaCheckStylePromptContract(legacy),
        isNotEmpty,
      );
    });
  });

  group('Rule A6 — Genre scaffold map (157 unique genres)', () {
    test('covers app genres with stable normalize keys', () {
      expect(GenreScaffoldMap.normalizeGenre('Amapiano'), 'amapiano');
      final genres = GenreScaffoldMap.specFor('Amapiano');
      expect(genres.type, ScaffoldType.clubExtended);
      expect(genres.introBars, 32);
    });

    group('ScaffoldType coverage', () {
      test('clubExtended: Amapiano intro contains 32 bars', () {
        final inst = GenreScaffoldMap.buildIntroOutroInstruction('Amapiano');
        expect(inst, contains('32 bars'));
      });

      test('clubExtended: Techno intro + outro 32 bars', () {
        final inst = GenreScaffoldMap.buildIntroOutroInstruction('Techno');
        expect(inst, contains('32 bars'));
      });

      test('clubExtended: Vinahouse uses 32-bar intro', () {
        final inst = GenreScaffoldMap.buildIntroOutroInstruction('Vinahouse');
        expect(inst, contains('32 bars'));
      });

      test('clubStandard: Drum & Bass uses 32-bar intro, 24-bar outro', () {
        final spec = GenreScaffoldMap.specFor('Drum & Bass');
        expect(spec.introBars, 32);
        expect(spec.outroBars, 24);
      });

      test('clubTight: Future Bass uses 16-bar intro', () {
        final spec = GenreScaffoldMap.specFor('Future Bass');
        expect(spec.introBars, 16);
      });

      test('radioShort: K-Pop intro ≤8 bars, instruction says radioShort', () {
        final spec = GenreScaffoldMap.specFor('K-Pop');
        expect(spec.introBars, lessThanOrEqualTo(8));
        final inst = GenreScaffoldMap.buildIntroOutroInstruction('K-Pop');
        expect(inst, contains('radioShort'));
        expect(inst, contains('INTRO: 4 bars'));
      });

      test('radioShort: Trap intro ≤4 bars', () {
        expect(GenreScaffoldMap.specFor('Trap').introBars, lessThanOrEqualTo(4));
      });

      test('radioWide: R&B intro 8-12 bars', () {
        final spec = GenreScaffoldMap.specFor('R&B');
        expect(spec.introBars, greaterThanOrEqualTo(8));
        expect(spec.introBars, lessThanOrEqualTo(12));
      });

      test('narrativeWide: Classic Rock intro 8-16 bars', () {
        final spec = GenreScaffoldMap.specFor('Classic Rock');
        expect(spec.introBars, greaterThanOrEqualTo(8));
        expect(spec.introBars, lessThanOrEqualTo(16));
      });

      test('narrativeWide: Funk outro 16-20 bars', () {
        final spec = GenreScaffoldMap.specFor('Funk');
        expect(spec.outroBars, greaterThanOrEqualTo(16));
        expect(spec.outroBars, lessThanOrEqualTo(20));
      });

      test('ambientLong: Lo-fi hip hop intro 16+ bars', () {
        expect(
          GenreScaffoldMap.specFor('Lo-Fi Hip Hop').introBars,
          greaterThanOrEqualTo(16),
        );
      });

      test('ambientLong: Post-rock intro 16+ bars, outro 24+ bars', () {
        final spec = GenreScaffoldMap.specFor('Post-Rock');
        expect(spec.introBars, greaterThanOrEqualTo(16));
        expect(spec.outroBars, greaterThanOrEqualTo(24));
      });
    });

    group('Dual-path sub-routing', () {
      test('Afrobeats with club hint → clubStandard 16/24', () {
        final spec = GenreScaffoldMap.specFor(
          'Afrobeats',
          vibeHint: 'club extended mix log drum',
        );
        expect(spec.type, ScaffoldType.clubStandard);
        expect(spec.introBars, 16);
        expect(spec.outroBars, 24);
      });

      test('Afrobeats with no hint → radioWide 8/16', () {
        final spec = GenreScaffoldMap.specFor('Afrobeats');
        expect(spec.type, ScaffoldType.radioWide);
        expect(spec.introBars, 8);
        expect(spec.outroBars, 16);
      });

      test('Reggaeton with remix hint → clubTight', () {
        final spec = GenreScaffoldMap.specFor(
          'Reggaeton',
          vibeHint: 'club remix DJ set',
        );
        expect(spec.type, ScaffoldType.clubTight);
      });

      test('Reggaeton with no hint → radioShort', () {
        expect(
          GenreScaffoldMap.specFor('Reggaeton').type,
          ScaffoldType.radioShort,
        );
      });
    });

    group('Negative scaffold coverage', () {
      test('Gospel Praise/Worship instruction rejects 32-bar club scaffold', () {
        final inst =
            GenreScaffoldMap.buildIntroOutroInstruction('Praise/Worship');
        expect(inst, contains('No 32-bar scaffolding'));
      });

      test('Mandopop instruction rejects 32-bar club scaffold', () {
        final inst = GenreScaffoldMap.buildIntroOutroInstruction('Mandopop');
        expect(inst, isNot(contains('mix-in ready')));
      });

      test('Bossa Nova is narrativeWide not clubExtended', () {
        expect(
          GenreScaffoldMap.specFor('Bossa Nova').type,
          ScaffoldType.narrativeWide,
        );
      });

      test('Death Metal intro ≤4 bars', () {
        expect(
          GenreScaffoldMap.specFor('Death Metal').introBars,
          lessThanOrEqualTo(4),
        );
      });

      test('Hyperpop intro ≤2 bars tightest', () {
        expect(GenreScaffoldMap.specFor('Hyperpop').introBars, lessThanOrEqualTo(2));
      });
    });

    group('Hybrid scaffold interaction', () {
      test('Amapiano + Vinahouse hybrid → dominant 32-bar intro', () {
        final c = _classify(
          _input(primaryGenre: 'Amapiano', subGenreFusion: 'Vinahouse'),
        );
        final inst = GenreScaffoldMap.buildIntroOutroInstructionForClassification(c);
        expect(inst, contains('32 bars'));
        expect(inst, contains('HYBRID SCAFFOLD'));
      });

      test('Pop + Amapiano hybrid → Pop radioShort wins when Pop dominant', () {
        final c = _classify(
          _input(primaryGenre: 'Pop', subGenreFusion: 'Amapiano'),
        );
        final inst = GenreScaffoldMap.buildIntroOutroInstructionForClassification(c);
        expect(inst, contains('radioShort'));
      });

      test('Dance Pop + House hybrid → dominant scaffold applies', () {
        final c = _classify(
          _input(primaryGenre: 'Dance Pop', subGenreFusion: 'House'),
        );
        final spec = GenreScaffoldMap.specForClassification(c);
        expect(spec.type, ScaffoldType.clubTight);
      });
    });

    group('Intro/outro QA consistency', () {
      test('club-extended lyrics missing bars triggers warning issue', () {
        const lyrics = '[Intro]\nShaker pocket opens\n[Verse 1]\nLine';
        final issues = IntroOutroScaffoldQa.checkIntroOutroConsistency(
          lyrics,
          dominantGenre: 'Amapiano',
        );
        expect(issues, isNotEmpty);
      });

      test('radio-short with 32 bars flagged as contamination', () {
        const lyrics = '[Intro]\n32 bars filtered kick build\n[Chorus]\nHook';
        final issues = IntroOutroScaffoldQa.checkIntroOutroConsistency(
          lyrics,
          dominantGenre: 'K-Pop',
        );
        expect(issues.any((i) => i.contains('contamination')), isTrue);
      });
    });

    test('routing user block includes Rule A6 scaffold line', () {
      final c = _classify(_input(primaryGenre: 'Techno'));
      final block = Stage2ModelRouter.buildRegionalUserBlockAppend(c);
      expect(block, contains('RULE A6 SCAFFOLD'));
    });
  });

  group('Humanized lyric quality layer', () {
    setUp(HumanizedLyricsSession.reset);

    test('kHumanVoiceDirective is non-empty and > 500 chars', () {
      expect(kHumanVoiceDirective.trim().isNotEmpty, isTrue);
      expect(kHumanVoiceDirective.length, greaterThan(500));
    });

    test('kHumanVoiceDirective contains all 8 rule numbers', () {
      for (var i = 1; i <= 8; i++) {
        expect(kHumanVoiceDirective, contains('$i.'));
      }
    });

    test('kHumanVoiceDirective bans stock 3 AM / Lagos / receipt kits', () {
      expect(kHumanVoiceDirective, contains('ANTI-PARROT'));
      expect(kHumanVoiceDirective, contains('v2.0'));
      expect(kHumanVoiceDirective, contains('checklist bingo'));
      expect(kHumanVoiceDirective, contains('song in my heart'));
      // Ban lists live in the detector — not re-enumerated in the prompt.
      expect(kHumanVoiceDirective.toLowerCase(), isNot(contains('cold tile')));
      expect(kHumanVoiceDirective.toLowerCase(), isNot(contains('bent receipt')));
    });

    test('GenreLyricsEmission keeps melodic techno as lyrical', () {
      expect(GenreLyricsEmission.emitsLyrics('Techno'), isFalse);
      expect(GenreLyricsEmission.emitsLyrics('melodic techno'), isTrue);
      expect(GenreLyricsEmission.emitsLyrics('Orchestral'), isFalse);
      expect(GenreLyricsEmission.emitsLyrics('Country'), isTrue);
    });

    test('MeaningfulnessCheck sensory dimension requires >= 3 sense categories', () {
      final check = MeaningfulnessCheck();
      expect(check.sensoryCount('salt on my lips, warm grit'), lessThan(3));
      expect(
        check.sensoryCount(
          'salt sweet hum echo whisper warm cold shadow glow',
        ),
        greaterThanOrEqualTo(3),
      );
      const strong = '''
James said, "Meet me at Oak Cliff by 3 AM."
Salt on your lips, whiskey smoke in the air.
Seventeen dollars in my pocket, gravel rough under boots.
''';
      expect(check.score(strong), 1.0);
    });

    test('MeaningfulnessCheck zeros score for stock Lagos tile kit', () {
      final check = MeaningfulnessCheck();
      const stock = '''
At 3 AM on cold tile in Lagos
Bleach on my hands from scrubbing the floor
A bent receipt lay curled by the kettle
Mama said baby count grace before receipts
''';
      expect(check.hasStockPhrases(stock), isTrue);
      expect(check.score(stock), 0.0);
      final qa = HumanizedLyricsQa.enforceHumanizedLyrics(stock, 'Afrobeats');
      expect(qa.shouldRegenerate, isTrue);
      expect(qa.issues.join(' '), contains('stock'));
    });

    test('MeaningfulnessCheck flags AI body-poetry as stock', () {
      final check = MeaningfulnessCheck();
      const aiPoetic = '''
So when I serve now, I will not boast loud
I know whose breath fills my lungs
The song in my chest is borrowed and holy
Still You let me carry one
''';
      expect(check.hasStockPhrases(aiPoetic), isTrue);
      expect(check.stockPhraseHits(aiPoetic), contains('song in my chest'));
      expect(check.score(aiPoetic), 0.0);
    });

    test('MeaningfulnessCheck uses word boundaries for senses and numbers', () {
      final check = MeaningfulnessCheck();
      expect(check.sensoryCount('my sweater is warm'), 1);
      expect(check.sensoryCount('salt, sweat, shadow'), 3);
      expect(check.hasSpecificNumber('someone said no'), isFalse);
      expect(check.hasSpecificNumber('three am'), isTrue);
    });

    test('MeaningfulnessCheck dialogue ignores contractions', () {
      final check = MeaningfulnessCheck();
      expect(check.hasDialogue("don't you know"), isFalse);
      expect(check.hasDialogue('she said "hello"'), isTrue);
    });

    test('MeaningfulnessCheck weak sample scores below threshold', () {
      final check = MeaningfulnessCheck();
      const weak = '''
the hum echo whisper in the dark shadow glow
warm and cold grit under my skin
somewhere lost inside
''';
      // 1 of 4 measured dimensions (sensory only; through-line is a
      // generation-side rule and no longer earns a free point).
      expect(check.score(weak), 0.25);
      expect(check.score(weak), lessThan(MeaningfulnessCheck().score('''
James said, "Meet me at Oak Cliff by 3 AM."
Salt on your lips, whiskey smoke in the air.
Seventeen dollars in my pocket, gravel rough under boots.
''')));
      expect(check.isMeaningful(weak), isFalse);
    });

    test('clichePackFor resolves genre families', () {
      // Amapiano maps to the EDM-vocal pack (festival-cliché coverage).
      expect(clichePackKeyFor('Amapiano'), 'edm_vocal');
      expect(clichePackFor('Contemporary Gospel'), isNotNull);
      expect(clichePackKeyFor('Contemporary Gospel'), 'worship_gospel');
      expect(clichePackKeyFor('Alt Rock'), 'rock_alt');
      expect(clichePackKeyFor('Afrobeats'), 'afrobeats_pidgin');
      expect(clichePackFor('Mandopop'), contains('下着雨又想起你'));
      expect(clichePackFor('K-Pop'), isNotNull);
      expect(clichePackKeyFor('Hip Hop'), 'hip_hop');
      expect(clichePackKeyFor('R&B'), 'rnb_contemp');
      expect(clichePackKeyFor('K-Pop'), 'kpop');
      expect(resolveClichePack('Country')?.tier, ClichePackTier.tier1);
    });

    test('cliche genre matching avoids word-interior false positives', () {
      expect(clichePackKeyFor('Soulful House'), isNot('rnb_contemp'));
      expect(clichePackKeyFor('Soulful House'), 'edm_vocal');
      expect(clichePackKeyFor('Kpop'), 'kpop');
      expect(clichePackKeyFor('Kpop'), isNot('pop_mainstream'));
    });

    test('preserves big-room fusion guard vs plain progressive house', () {
      expect(clichePackKeyFor('Progressive House'), 'edm_vocal');
      expect(
        clichePackKeyFor('Progressive House Festival Anthem'),
        'big_room_fusion_vocal',
      );
    });

    test('tier sets match pack tiers', () {
      for (final entry in kClichePacks.entries) {
        final expected = entry.value.tier == ClichePackTier.tier1
            ? kTier1ClichePacks
            : kTier2ClichePacks;
        expect(expected, contains(entry.key));
      }
    });

    test('T1 cliché scans fail on first hit', () {
      const countryLyrics = '[Verse]\nDriving down the road in my pickup truck';
      final country = HumanizedLyricsQa.scanClicheHits(countryLyrics, 'Country');
      expect(country.hits, contains('pickup truck'));
      expect(country.isFailure, isTrue);
      expect(country.severity, ClicheSeverity.tier1);

      const hipHop = '[Verse]\nStarted from the bottom now we here';
      final hh = HumanizedLyricsQa.scanClicheHits(hipHop, 'Trap');
      expect(hh.hits, isNotEmpty);
      expect(hh.isFailure, isTrue);

      const rnb = '[Verse]\nIt is 2 AM and I still think of you';
      final rb = HumanizedLyricsQa.scanClicheHits(rnb, 'R&B');
      expect(rb.hits, isNotEmpty);
      expect(rb.isFailure, isTrue);
    });

    test('worship stock phrases fail cliché scan', () {
      const worship = '''
[Verse]
I acknowledge You in all my ways
Guide my steps when I can't see
Trust the path You make for me
''';
      final hits = HumanizedLyricsQa.scanClicheHits(
        worship,
        'Contemporary Gospel',
      );
      expect(hits.hits, isNotEmpty);
      expect(hits.isFailure, isTrue);
    });

    test('instrumental genres skip meaningfulness and cliché QA', () {
      const lyrics = 'pickup truck at 2 AM oh na na';
      for (final genre in ['Orchestral', 'Ambient', 'Techno']) {
        expect(GenreLyricsEmission.emitsLyrics(genre), isFalse);
        final result = HumanizedLyricsQa.enforceHumanizedLyrics(lyrics, genre);
        expect(result.issues, isEmpty);
        expect(result.shouldRegenerate, isFalse);
      }
    });

    test('T2 pop cliché warns on first session hit, fails on repeat', () {
      const popLyrics = '[Chorus]\nPut your hands up in the air tonight';
      final first = HumanizedLyricsQa.scanClicheHits(popLyrics, 'Pop');
      expect(first.hits, isNotEmpty);
      expect(first.isFailure, isFalse);

      HumanizedLyricsSession.recordGeneration('Pop');
      final second = HumanizedLyricsQa.scanClicheHits(popLyrics, 'Pop');
      expect(second.isFailure, isTrue);
    });

    test('regenerateOnClicheHits triggers shouldRegenerate on first T2 hit', () {
      HumanizedLyricsSession.reset();
      const popLyrics = '[Chorus]\nPut your hands up in the air tonight';
      final strict = HumanizedLyricsQa.enforceHumanizedLyrics(
        popLyrics,
        'Pop',
        regenerateOnClicheHits: true,
      );
      expect(strict.clicheHits, isNotEmpty);
      expect(strict.shouldRegenerate, isTrue);
    });

    test('buildRegenerateSuffix lists QA issues for retry prompt', () {
      const weak = 'I feel sad\nmany nights alone\nsomewhere lost';
      final qa = HumanizedLyricsQa.enforceHumanizedLyrics(weak, 'Country');
      final suffix = HumanizedLyricsQa.buildRegenerateSuffix(qa);
      expect(suffix, contains('LYRIC QUALITY RETRY'));
      expect(suffix, contains('meaningfulness'));
      expect(suffix, contains('[End]'));
    });

    test('isBetterResult prefers passing QA over failing', () {
      const weak = 'I feel sad\nmany nights alone\nsomewhere lost';
      const strong = '''
[Verse]
Mama's kettle whistling at 5 AM
Coffee stains on the Formica counter
[Chorus]
I'm still here
Still breathing
Still me
''';
      final bad = HumanizedLyricsQa.enforceHumanizedLyrics(weak, 'Country');
      final good = HumanizedLyricsQa.enforceHumanizedLyrics(strong, 'Country');
      expect(
        HumanizedLyricsQa.isBetterResult(good, bad),
        isTrue,
      );
    });

    test('lyrical routing user block injects HUMAN VOICE DIRECTIVE', () {
      final country = Stage2ModelRouter.buildRegionalUserBlockAppend(
        _classify(_input(primaryGenre: 'Country')),
      );
      expect(country, contains('HUMAN VOICE DIRECTIVE'));

      final orchestral = Stage2ModelRouter.buildRegionalUserBlockAppend(
        _classify(_input(primaryGenre: 'Orchestral')),
      );
      expect(orchestral, isNot(contains('HUMAN VOICE DIRECTIVE')));
    });

    test('PromptEngineQa.qaCheckHumanizedLyrics surfaces low meaningfulness', () {
      const weak = 'I feel sad\nmany nights alone\nsomewhere lost';
      final issues = PromptEngineQa.qaCheckHumanizedLyrics(weak, 'Country');
      expect(issues.any((i) => i.contains('meaningfulness')), isTrue);
    });
  });
}
