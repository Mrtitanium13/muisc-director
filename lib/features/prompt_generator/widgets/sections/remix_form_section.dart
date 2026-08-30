import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/remix_form_widget.dart';

class RemixFormSection extends ConsumerStatefulWidget {
  const RemixFormSection({super.key});

  @override
  ConsumerState<RemixFormSection> createState() => _RemixFormSectionState();
}

class _RemixFormSectionState extends ConsumerState<RemixFormSection> {
  @override
  Widget build(BuildContext context) {
    final form = ref.watch(promptFormProvider);
    final songTitleCtrl = ref.watch(remixSongTitleControllerProvider);
    final artistCtrl = ref.watch(remixArtistControllerProvider);

    return RemixFormWidget(
      songTitleController: songTitleCtrl,
      artistController: artistCtrl,
      generationType: form.songGenerationType,
      targetGenre: form.primaryGenre,
      onGenerationTypeChanged: (mode) {
        ref.read(promptFormProvider.notifier).setSongGenerationType(mode);
      },
      onFieldChanged: () {
        // Rebuild near-activation / ENGINE ON chip; mutual exclusion via setters.
        ref.read(promptFormProvider.notifier)
          ..setRemixOriginalSongTitle(songTitleCtrl.text)
          ..setRemixOriginalArtist(artistCtrl.text);
        setState(() {});
      },
    );
  }
}
