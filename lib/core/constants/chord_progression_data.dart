/// Quick-insert labels for common progressions (Roman numerals or chord symbols).
class ChordProgressionQuickPick {
  const ChordProgressionQuickPick({
    required this.label,
    required this.insert,
  });

  final String label;
  final String insert;
}

class ChordProgressionData {
  ChordProgressionData._();

  static const List<ChordProgressionQuickPick> quickPicks = [
    ChordProgressionQuickPick(
      label: 'I–V–vi–IV',
      insert: 'I–V–vi–IV',
    ),
    ChordProgressionQuickPick(
      label: 'vi–IV–I–V',
      insert: 'vi–IV–I–V',
    ),
    ChordProgressionQuickPick(
      label: 'ii–V–I',
      insert: 'ii–V–I',
    ),
    ChordProgressionQuickPick(
      label: 'I–IV–V–I',
      insert: 'I–IV–V–I',
    ),
    ChordProgressionQuickPick(
      label: 'I–vi–IV–V',
      insert: 'I–vi–IV–V',
    ),
    ChordProgressionQuickPick(
      label: '12-bar blues',
      insert:
          'I I I I · IV IV I I · V IV I V (12-bar blues form; adapt voicings to genre)',
    ),
  ];
}
