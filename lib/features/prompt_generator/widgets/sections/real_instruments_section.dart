import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:music_director/core/constants/real_instruments_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class RealInstrumentsSection extends ConsumerStatefulWidget {
  const RealInstrumentsSection({super.key});

  @override
  ConsumerState<RealInstrumentsSection> createState() =>
      _RealInstrumentsSectionState();
}

class _RealInstrumentsSectionState extends ConsumerState<RealInstrumentsSection> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primarySub = ref.watch(selectedPrimarySubProvider);
    final fusionSub = ref.watch(selectedFusionSubProvider);
    final genreFilter = ref.watch(realInstrumentGenreFilterProvider);
    final realInstrumentsCtrl = ref.watch(realInstrumentsControllerProvider);
    final searchQuery = _searchCtrl.text;
    final useAll = genreFilter == '__all__';
    final picks = _instrumentPicks(
      searchQuery: searchQuery,
      useAll: useAll,
      primarySub: primarySub,
      fusionSub: fusionSub,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REAL / ACOUSTIC INSTRUMENTS (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap common instruments below, or search the full catalog. '
          'Genre match prioritizes useful picks for your selection.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          // ignore: deprecated_member_use
          value: genreFilter,
          decoration: const InputDecoration(
            labelText: 'Instrument filter',
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                primarySub == null || primarySub.isEmpty
                    ? 'Essentials — piano, guitar, drums…'
                    : 'Genre match — $primarySub',
              ),
            ),
            const DropdownMenuItem<String?>(
              value: '__all__',
              child: Text('Essentials — piano, guitar, drums…'),
            ),
          ],
          onChanged: (v) {
            hapticLight();
            ref.read(realInstrumentGenreFilterProvider.notifier).state = v;
          },
        ),
        const SizedBox(height: 10),
        MdTextField(
          controller: _searchCtrl,
          label: 'SEARCH INSTRUMENTS',
          hint: 'Search full catalog — e.g. violin, sax, kalimba, 808…',
          onChanged: (_) => setState(() {}),
        ),
        if (searchQuery.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  picks.isEmpty
                      ? 'No instruments match your search.'
                      : '${picks.length} match${picks.length == 1 ? '' : 'es'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  hapticLight();
                  _searchCtrl.clear();
                  setState(() {});
                },
                child: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.creodomeCyan,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        _InstrumentChipList(
          picks: picks,
          onPick: (pick) => _appendRealInstrument(ref, pick),
        ),
        const SizedBox(height: 10),
        MdTextField(
          controller: realInstrumentsCtrl,
          label: 'INSTRUMENTS LIST',
          hint:
              'e.g. Wurlitzer Electric Piano, Fender Jazz Bass — articulation injected per Suno version',
          maxLines: 3,
          maxLength: 400,
          onChanged: (t) =>
              ref.read(promptFormProvider.notifier).setRealInstrumentals(t),
        ),
      ],
    );
  }

  List<String> _instrumentPicks({
    required String searchQuery,
    required bool useAll,
    required String? primarySub,
    required String? fusionSub,
  }) {
    final q = searchQuery.trim().toLowerCase();
    // Search always scans the full catalog so orchestral winds/strings/brass
    // are findable even when a genre filter is active.
    if (q.isNotEmpty) {
      return RealInstrumentsData.search(searchQuery)
          .map((i) => i.name)
          .toList(growable: false);
    }
    if (useAll || primarySub == null || primarySub.trim().isEmpty) {
      return RealInstrumentsData.quickPicks;
    }
    return RealInstrumentsData.decongestGenrePicks(
      RealInstrumentsData.instrumentsForGenre(primarySub, fusionSub ?? ''),
    );
  }

  void _appendRealInstrument(WidgetRef ref, String label) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final nLabel = norm(label);
    final ctrl = ref.read(realInstrumentsControllerProvider);
    final cur = ctrl.text.trim();
    final existing = cur
        .split(',')
        .map(norm)
        .where((e) => e.isNotEmpty)
        .toList();
    if (existing.any(
      (e) =>
          e == nLabel ||
          (e.contains(nLabel) && nLabel.length > 4) ||
          (nLabel.contains(e) && e.length > 4),
    )) {
      return;
    }
    final next = cur.isEmpty ? label : '$cur, $label';
    ctrl.text = next;
    ctrl.selection = TextSelection.collapsed(offset: next.length);
    ref.read(promptFormProvider.notifier).setRealInstrumentals(next);
  }
}

class _InstrumentChipList extends StatelessWidget {
  const _InstrumentChipList({
    required this.picks,
    required this.onPick,
  });

  final List<String> picks;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const SizedBox.shrink();
    }

    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final pick in picks)
          ActionChip(
            label: Text(
              pick,
              style: GoogleFonts.inter(fontSize: 11),
            ),
            avatar: Icon(
              PhosphorIconsRegular.plus,
              size: 14,
              color: AppColors.creodomeCyan,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              hapticLight();
              onPick(pick);
            },
          ),
      ],
    );

    if (picks.length <= 16) return chips;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: SingleChildScrollView(child: chips),
    );
  }
}
