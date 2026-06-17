import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../providers/session_providers.dart';
import '../../widgets/common/gradient_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.titleGradient.createShader(b),
                child: Text(
                  'Music Director',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suno Prompt Engine — Powered by AI',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              GradientButton(
                label: 'Continue with Google',
                icon: Icons.login,
                onPressed: () {
                  hapticLight();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Wire Firebase Auth in production. Use Guest for now.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  hapticLight();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email/password: add Firebase Auth.'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Email sign-in (configure)'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  hapticLight();
                  await ref.read(sessionPrefsProvider).setGuestMode(true);
                  if (context.mounted) context.go('/generate');
                },
                child: Text(
                  'Continue as Guest',
                  style: GoogleFonts.inter(
                    color: AppColors.accentTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
