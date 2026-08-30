import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_director/core/constants/lyric_temperament_data.dart';
import 'package:music_director/core/constants/power_code_data.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

void toggleTemperament(WidgetRef ref, String code) {
  hapticLight();
  final picks = {...ref.read(temperamentPickProvider)};
  if (picks.contains(code)) {
    picks.remove(code);
  } else {
    picks.add(code);
  }
  ref.read(temperamentPickProvider.notifier).state = picks;
  ref.read(promptFormProvider.notifier).setActiveModifierCodes(
        _temperamentLine(picks),
      );
}

String _temperamentLine(Set<String> picks) {
  final ordered = [
    for (final c in PowerCodeData.codes)
      if (picks.contains(c)) c,
    for (final c in LyricTemperamentData.codes)
      if (picks.contains(c)) c,
  ];
  return ordered.join(' ');
}
