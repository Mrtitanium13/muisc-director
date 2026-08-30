import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';

class ArtifactShell extends StatelessWidget {
  const ArtifactShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem('Create', PhosphorIconsRegular.plusCircle, '/artifact/create'),
    _NavItem('Fix It', PhosphorIconsRegular.wrench, '/artifact/fix-it'),
    _NavItem('Verified', PhosphorIconsRegular.sealCheck, '/artifact/verified'),
  ];

  void _goBranch(BuildContext context, int index) {
    hapticSelection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.22),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                selectedIndex: idx,
                onDestinationSelected: (i) => _goBranch(context, i),
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  for (var i = 0; i < _items.length; i++)
                    NavigationDestination(
                      icon: Icon(
                        _items[i].icon,
                        color: i == idx ? AppColors.accentPrimary : AppColors.textTertiary,
                      ),
                      selectedIcon: Icon(
                        _items[i].icon,
                        color: AppColors.accentPrimary,
                      ),
                      label: _items[i].label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}
