import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

/// Keeps FX arrangement tags in [fxLayoutControllerProvider], never in YOUR LYRICS.
void syncFxLayoutPreview(WidgetRef ref, {bool syncProvider = true}) {
  if (ref.read(promptFormProvider).sunoFieldOutputMode ==
      SunoFieldOutputMode.simple) {
    ref.read(fxLayoutControllerProvider).clear();
    return;
  }

  final form = ref.read(promptFormProvider);
  final lane = GenresConfig.effectiveLaneId(
    genreFxLaneId: ref.read(genreFxLaneIdProvider),
    primaryGenre: form.primaryGenre.isNotEmpty
        ? form.primaryGenre
        : (ref.read(selectedPrimarySubProvider) ?? ''),
    fusionGenre: form.subGenreFusion,
  );

  final lyricsCtrl = ref.read(lyricsControllerProvider);
  final fxCtrl = ref.read(fxLayoutControllerProvider);

  // Migrate any FX head that was previously injected into YOUR LYRICS.
  final mixed = lyricsCtrl.text;
  final core = SunoPromptBuilder.stripFxLayout(mixed);
  if (core != mixed) {
    lyricsCtrl.text = core;
    if (syncProvider) {
      ref.read(promptFormProvider.notifier).setOptionalLyrics(core);
    }
  }

  final preview = SunoPromptBuilder.fxLayoutPreview(
    primaryGenre: lane,
    intensity: ref.read(productionIntensityLevelProvider),
    sunoVersion: form.sunoVersion,
  );
  if (fxCtrl.text != preview) {
    fxCtrl.text = preview;
  }
}

/// @Deprecated — use [syncFxLayoutPreview]. Kept for call-site renames.
void applyFxLayoutToLyricsField(WidgetRef ref, {bool syncProvider = true}) =>
    syncFxLayoutPreview(ref, syncProvider: syncProvider);
