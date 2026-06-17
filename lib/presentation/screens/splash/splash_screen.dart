import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/session_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final session = ref.read(sessionPrefsProvider);
    if (!session.onboardingDone) {
      context.go('/onboarding');
      return;
    }
    if (session.guestMode) {
      context.go('/generate');
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: 8,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: AppColors.ctaGradient,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleY(
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                      begin: 0.4,
                      end: 1,
                      delay: (i * 120).ms,
                    );
              }),
            ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.titleGradient.createShader(bounds),
              child: Text(
                'Music Director',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Powered Suno Prompt Engine',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
