/// DJ mix request parameters for the user-message block.
class DjMixRequest {
  const DjMixRequest({
    required this.trackTitle,
    required this.genre,
    required this.bpm,
    this.djTag,
    this.mood,
    this.keySignature,
    this.vocalStyle,
    this.additionalNotes,
  });

  final String trackTitle;
  final String genre;
  final int bpm;
  final String? djTag;
  final String? mood;
  final String? keySignature;
  final String? vocalStyle;
  final String? additionalNotes;
}

/// Builds the user-message block that accompanies the system prompt for DJ mix
/// generation requests. Uses positive, content-first instructions so Suno reliably
/// produces DJ Mix-In intro and DJ Mix-Out outro sections.
String buildDjMixUserBlock(DjMixRequest request) {
  final lines = <String>[
    'Generate a DJ-ready Suno track package for:',
    '',
    'Track: ${request.trackTitle}',
    'Genre: ${request.genre}',
    'BPM: ${request.bpm}',
  ];

  if (request.mood != null && request.mood!.isNotEmpty) {
    lines.add('Mood: ${request.mood}');
  }
  if (request.keySignature != null && request.keySignature!.isNotEmpty) {
    lines.add('Key: ${request.keySignature}');
  }
  if (request.vocalStyle != null && request.vocalStyle!.isNotEmpty) {
    lines.add('Vocal style: ${request.vocalStyle}');
  }
  if (request.djTag != null && request.djTag!.isNotEmpty) {
    lines.add('DJ tag (spoken during mix-in only): "${request.djTag}"');
  }
  if (request.additionalNotes != null && request.additionalNotes!.isNotEmpty) {
    lines.add('Notes: ${request.additionalNotes}');
  }

  lines.addAll([
    '',
    'STRUCTURE REQUIREMENTS (mandatory):',
    '',
    '1. Open the lyrics field with [Intro: DJ Mix-In] as the very first tag.',
    '   • 8–16 bars of filtered, beat-driven intro material at ${request.bpm} BPM',
    '   • Progressive element entry: drums → bass → melody',
    '   • Snare build in the final 4 bars before the first body section',
  ]);

  if (request.djTag != null && request.djTag!.isNotEmpty) {
    lines.add('   • Include the DJ tag as spoken word within the mix-in section');
  } else {
    lines.add('   • Keep the mix-in instrumental (no vocals)');
  }

  lines.addAll([
    '',
    '2. Build the main body with at least one verse and one chorus (or drop).',
    '',
    '3. Close the lyrics field with [Outro: DJ Mix-Out] as the final body section.',
    '   • 16–32 bars of sustained rhythm at full ${request.bpm} BPM',
    '   • Strip vocals and melodic leads first; keep kick + hi-hat + bass',
    '   • Beat stays steady — no slowdown, no fade-to-silence',
    '',
    '4. End with [End] on its own line after the mix-out completes.',
    '',
    'Return the JSON package (title, style, lyrics, notes) per Section 1B.',
  ]);

  return lines.join('\n');
}
