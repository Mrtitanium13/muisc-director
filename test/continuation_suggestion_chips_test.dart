import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/continuation_suggestion_chips.dart';

void main() {
  test('pads with defaults when model has no suggestions', () {
    final chips = buildContinuationChips(null);
    expect(chips.length, greaterThanOrEqualTo(4));
    expect(chips.every((s) => s.startsWith('→')), isTrue);
  });

  test('keeps model lines first and respects maxChips', () {
    final chips = buildContinuationChips(
      '→ First idea\n→ Second idea',
      maxChips: 4,
    );
    expect(chips.length, 4);
    expect(chips[0], contains('First idea'));
  });
}
