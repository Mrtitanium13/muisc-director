class AudioAnalysisModel {

  static const String fallbackAnalyzerSummary =

      'General Delivery, Smooth Close-Mic, Moderate Energy, Pristine Studio Environment';

  static const String fallbackTitle = 'Original Recording / Stem';

  static const String fallbackArtist = 'User Upload';

  static const String fallbackAlbum = 'Session';

  static const String fallbackReleaseDate = 'Custom';



  const AudioAnalysisModel({

    this.analyzerSummary,

    this.title = fallbackTitle,

    this.artist = fallbackArtist,

    this.album = fallbackAlbum,

    this.releaseDate = fallbackReleaseDate,

    this.trackRecognized = false,

    this.bpm,

    this.keyScale,

    this.energy,

    this.genre,

    this.subGenre,

    this.moodTags = const [],

    this.loudness,

    this.instruments = const [],

    this.vocals,

    this.structure,

    this.lyricsTranscription,

    this.richDescription,

    this.tempoFeel,

    this.chordComplexity,

    this.confidenceOverall = 'Medium',

    this.analysisMode,

    this.success,

    this.isAcapella = false,

    this.productionIntent,

    this.impliedChords,

    this.melodyProfile,

  });



  /// Four-tag comma profile for prompt anchoring (never null after [fromJson]).

  final String? analyzerSummary;

  final String title;

  final String artist;

  final String album;

  final String releaseDate;

  final bool trackRecognized;

  final double? bpm;

  final String? keyScale;

  final String? energy;

  final String? genre;

  final String? subGenre;

  final List<String> moodTags;

  final String? loudness;

  final List<String> instruments;

  final String? vocals;

  final String? structure;

  final String? lyricsTranscription;

  final String? richDescription;

  final String? tempoFeel;

  final String? chordComplexity;

  final String confidenceOverall;

  final String? analysisMode;

  final bool? success;

  final bool isAcapella;

  final String? productionIntent;

  final String? impliedChords;

  final String? melodyProfile;

  bool get hasLyrics =>

      lyricsTranscription != null && lyricsTranscription!.trim().isNotEmpty;



  bool get hasRecognizedTrack => trackRecognized;



  String get compactProfile => sanitizeProfile(analyzerSummary);



  static String sanitizeProfile(String? raw) {

    if (raw == null || raw.trim().isEmpty) return fallbackAnalyzerSummary;

    final text = raw.replaceAll('\n', ' ').trim();

    final parts = text.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);

    final list = parts.toList();

    if (list.length >= 4) return list.take(4).join(', ');

    if (list.length == 3) {

      return '${list.join(', ')}, Pristine Studio Environment';

    }

    return fallbackAnalyzerSummary;

  }



  Map<String, dynamic> toJson() => {

        'analyzerSummary': compactProfile,

        'title': title,

        'artist': artist,

        'album': album,

        'releaseDate': releaseDate,

        'trackRecognized': trackRecognized,

        'success': success,

        'bpm': bpm,

        'keyScale': keyScale,

        'energy': energy,

        'genre': genre,

        'subGenre': subGenre,

        'moodTags': moodTags,

        'loudness': loudness,

        'instruments': instruments,

        'vocals': vocals,

        'structure': structure,

        'lyricsTranscription': lyricsTranscription,

        'richDescription': richDescription,

        'tempoFeel': tempoFeel,

        'chordComplexity': chordComplexity,

        'confidenceOverall': confidenceOverall,

        'analysisMode': analysisMode,

        'isAcapella': isAcapella,

        'productionIntent': productionIntent,

        'impliedChords': impliedChords,

        'melodyProfile': melodyProfile,

      };



  factory AudioAnalysisModel.fromJson(Map<String, dynamic> j) {

    return AudioAnalysisModel(

      analyzerSummary: sanitizeProfile(j['analyzerSummary'] as String?),

      title: j['title'] as String? ?? fallbackTitle,

      artist: j['artist'] as String? ?? fallbackArtist,

      album: j['album'] as String? ?? fallbackAlbum,

      releaseDate: j['releaseDate'] as String? ?? fallbackReleaseDate,

      trackRecognized: j['trackRecognized'] as bool? ?? false,

      success: j['success'] as bool?,

      bpm: (j['bpm'] as num?)?.toDouble(),

      keyScale: j['keyScale'] as String?,

      energy: j['energy'] as String?,

      genre: j['genre'] as String?,

      subGenre: j['subGenre'] as String?,

      moodTags: List<String>.from(j['moodTags'] as List? ?? []),

      loudness: j['loudness'] as String?,

      instruments: List<String>.from(j['instruments'] as List? ?? []),

      vocals: j['vocals'] as String?,

      structure: j['structure'] as String?,

      lyricsTranscription: j['lyricsTranscription'] as String?,

      richDescription: j['richDescription'] as String?,

      tempoFeel: j['tempoFeel'] as String?,

      chordComplexity: j['chordComplexity'] as String?,

      confidenceOverall: j['confidenceOverall'] as String? ?? 'Medium',

      analysisMode: j['analysisMode'] as String?,

      isAcapella: j['isAcapella'] as bool? ?? false,

      productionIntent: j['productionIntent'] as String?,

      impliedChords: j['impliedChords'] as String?,

      melodyProfile: j['melodyProfile'] as String?,

    );

  }



  String toPromptSummary() {

    final buf = StringBuffer();

    buf.writeln(
      'SOURCE AUDIO ANALYSIS (ROLE: Remix Architect. TASK: Deconstruct the following track analysis. '
      'Use its core elements—BPM, key, structure, and lyrics—as the foundational blueprint for the new track. '
      'Re-contextualize this blueprint within the new genre described in the main prompt. '
      'You MUST adhere to the BPM and Key unless explicitly told otherwise.):',
    );

    buf.writeln(compactProfile);

    buf.writeln('Track: $title — $artist');
    if (album.trim().isNotEmpty) {
      buf.writeln('Album: $album');
    }
    if (releaseDate.trim().isNotEmpty &&
        releaseDate != fallbackReleaseDate) {
      buf.writeln('Release: $releaseDate');
    }

    if (isAcapella) {
      buf.writeln(
        'Source type: Isolated vocal / acapella stem — arrange a full backing track.',
      );
    }

    final intent = productionIntent?.trim() ?? '';
    if (intent.isNotEmpty) {
      buf.writeln('Production intent: $intent');
    }

    if (richDescription != null && richDescription!.trim().isNotEmpty) {

      buf.writeln('Summary: ${richDescription!.trim()}');

    }

    if (bpm != null) buf.writeln('BPM: ${bpm!.toStringAsFixed(0)}');

    if (keyScale != null) buf.writeln('Key/scale: $keyScale');

    if (impliedChords != null && impliedChords!.trim().isNotEmpty) {
      buf.writeln(impliedChords!.trim());
    }

    if (melodyProfile != null && melodyProfile!.trim().isNotEmpty) {
      buf.writeln(melodyProfile!.trim());
    }

    if (energy != null) buf.writeln('Energy: $energy');

    if (genre != null) buf.writeln('Genre: $genre');

    if (subGenre != null && subGenre!.trim().isNotEmpty) {

      buf.writeln('Sub-genre: $subGenre');

    }

    if (moodTags.isNotEmpty) buf.writeln('Mood: ${moodTags.join(' · ')}');

    if (vocals != null && vocals!.trim().isNotEmpty) {

      buf.writeln('Vocals: ${vocals!.trim()}');

    }

    if (structure != null && structure!.trim().isNotEmpty) {

      buf.writeln('Structure: ${structure!.trim()}');

    }

    if (loudness != null) buf.writeln('Loudness: $loudness');

    if (instruments.isNotEmpty) {

      buf.writeln('Dominant instruments: ${instruments.join(' · ')}');

    }

    if (tempoFeel != null) buf.writeln('Tempo feel: $tempoFeel');

    if (chordComplexity != null) buf.writeln('Chord complexity: $chordComplexity');

    if (hasLyrics) {

      final lyrics = lyricsTranscription!.trim();

      final preview = lyrics.length > 800 ? '${lyrics.substring(0, 800)}…' : lyrics;

      buf.writeln('Lyrics transcription:\n$preview');

    }

    return buf.toString().trim();

  }

}


