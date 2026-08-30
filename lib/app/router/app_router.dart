import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/audio/audio_analyzer_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/output/output_screen.dart';
import '../../features/prompt_generator/screens/prompt_generator_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/tools/ab_compare_screen.dart';
import '../../presentation/screens/tools/batch_generate_screen.dart';
import '../../presentation/screens/tools/batch_output_screen.dart';
import '../../presentation/screens/tools/quick_describe_screen.dart';
import '../../presentation/screens/tools/templates_screen.dart';
import '../../features/anti_artifact/screens/create_screen.dart';
import '../../features/anti_artifact/screens/fix_it_screen.dart';
import '../../features/anti_artifact/screens/verified_screen.dart';
import '../../features/anti_artifact/shell/artifact_shell.dart';
import '../../presentation/widgets/shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/generate',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PromptGeneratorScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analyzer',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AudioAnalyzerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return ArtifactShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artifact/create',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CreateScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artifact/fix-it',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FixItScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artifact/verified',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: VerifiedScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/artifact',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/artifact/create',
      ),
      GoRoute(
        path: '/templates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/batch-generate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BatchGenerateScreen(),
      ),
      GoRoute(
        path: '/batch-output',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final items = <BatchOutputItem>[];
          if (extra is Map) {
            final raw = extra['items'];
            if (raw is List) {
              for (final e in raw) {
                if (e is Map) {
                  items.add(
                    BatchOutputItem(
                      label: e['label']?.toString() ?? '',
                      prompt: e['prompt']?.toString() ?? '',
                      sunoVersion: e['version']?.toString() ?? 'v5.0',
                    ),
                  );
                }
              }
            }
          }
          return BatchOutputScreen(items: items);
        },
      ),
      GoRoute(
        path: '/ab-compare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AbCompareScreen(),
      ),
      GoRoute(
        path: '/quick-describe',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuickDescribeScreen(),
      ),
      GoRoute(
        path: '/quick-describe-test',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/quick-describe',
      ),
      GoRoute(
        path: '/output',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          String prompt = '';
          String version = 'v5.0';
          var fieldModeName = 'custom';
          var trustedGenerationInput = false;
          if (extra is Map) {
            final rawPrompt = extra['prompt'];
            if (rawPrompt != null) {
              prompt = rawPrompt is String ? rawPrompt : rawPrompt.toString();
            }
            final rawVer = extra['version'];
            if (rawVer != null) {
              version = rawVer is String ? rawVer : rawVer.toString();
            }
            final rawMode = extra['field_mode'];
            if (rawMode != null) {
              fieldModeName =
                  rawMode is String ? rawMode : rawMode.toString();
            }
            final rawTrusted = extra['trusted_generation_input'];
            trustedGenerationInput =
                rawTrusted == true || rawTrusted == 'true';
          } else if (extra is String) {
            prompt = extra;
          }
          return OutputScreen(
            prompt: prompt,
            sunoVersion: version,
            fieldMode: fieldModeName,
            trustedGenerationInput: trustedGenerationInput,
          );
        },
      ),
    ],
  );
});
