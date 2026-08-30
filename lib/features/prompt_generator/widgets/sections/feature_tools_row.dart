import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/utils/form_navigation.dart';
import 'package:music_director/presentation/widgets/common/feature_tool_card.dart';

class FeatureToolsRow extends ConsumerWidget {
  const FeatureToolsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gold = Color(0xFFFFCA28);

    Widget card({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return FeatureToolCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        onTap: () {
          hapticLight();
          onTap();
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final tiles = [
          card(
            icon: PhosphorIconsRegular.star,
            iconColor: gold,
            title: 'Templates',
            subtitle: 'Pre-built prompt configurations',
            onTap: () => FormNavigation.openTemplates(context, ref),
          ),
          card(
            icon: PhosphorIconsRegular.chartBar,
            iconColor: const Color(0xFF42A5F5),
            title: 'Batch generate',
            subtitle: 'Create multiple prompts at once',
            onTap: () => FormNavigation.openBatchGenerate(context, ref),
          ),
          card(
            icon: PhosphorIconsRegular.scales,
            iconColor: gold,
            title: 'A / B compare',
            subtitle: 'Compare prompts side-by-side',
            onTap: () => FormNavigation.openAbCompare(context, ref),
          ),
          card(
            icon: PhosphorIconsRegular.textAa,
            iconColor: const Color(0xFF26A69A),
            title: 'Quick describe',
            subtitle: 'One paragraph → full Suno prompt',
            onTap: () => FormNavigation.openQuickDescribe(context, ref),
          ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                SizedBox(width: 168, child: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}
