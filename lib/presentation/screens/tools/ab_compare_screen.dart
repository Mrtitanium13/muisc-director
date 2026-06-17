import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/user_input_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/md_text_field.dart';

class AbCompareScreen extends ConsumerStatefulWidget {
  const AbCompareScreen({super.key});

  @override
  ConsumerState<AbCompareScreen> createState() => _AbCompareScreenState();
}

class _AbCompareScreenState extends ConsumerState<AbCompareScreen> {
  final _vibeA = TextEditingController();
  final _vibeB = TextEditingController();
  String? _outA;
  String? _outB;
  bool _busyA = false;
  bool _busyB = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final f = ref.read(promptFormProvider);
      _vibeA.text = f.vibe;
      _vibeB.text = f.vibe.isEmpty ? '' : '${f.vibe.trim()} (alt mix)';
    });
  }

  @override
  void dispose() {
    _vibeA.dispose();
    _vibeB.dispose();
    super.dispose();
  }

  UserInputModel _withVibe(String vibe) {
    final base = ref.read(promptFormProvider);
    return base.copyWith(vibe: vibe.trim());
  }

  Future<void> _genA() async {
    if (_vibeA.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vibe for A.')),
      );
      return;
    }
    setState(() {
      _busyA = true;
      _outA = null;
    });
    try {
      final t = await ref
          .read(aiRepositoryProvider)
          .generatePrompt(_withVibe(_vibeA.text));
      if (mounted) setState(() => _outA = t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A failed: ${dioErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyA = false);
    }
  }

  Future<void> _genB() async {
    if (_vibeB.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vibe for B.')),
      );
      return;
    }
    setState(() {
      _busyB = true;
      _outB = null;
    });
    try {
      final t = await ref
          .read(aiRepositoryProvider)
          .generatePrompt(_withVibe(_vibeB.text));
      if (mounted) setState(() => _outB = t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('B failed: ${dioErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyB = false);
    }
  }

  void _reloadVibesFromForm() {
    final f = ref.read(promptFormProvider);
    setState(() {
      _vibeA.text = f.vibe;
      _vibeB.text =
          f.vibe.isEmpty ? '' : '${f.vibe.trim()} (alt arrangement)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(promptFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('A / B compare'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              hapticLight();
              _reloadVibesFromForm();
            },
            child: const Text('Sync vibes from form'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const pad = 16.0;
          final wide = constraints.maxWidth >= 720;
          final hint =
              '${form.primaryGenre.isEmpty ? '—' : form.primaryGenre} · Suno ${form.sunoVersion}';
          final sideA = _side(
            context,
            label: 'A',
            color: AppColors.accentPrimary,
            vibeController: _vibeA,
            busy: _busyA,
            output: _outA,
            onGenerate: _genA,
            formHint: hint,
          );
          final sideB = _side(
            context,
            label: 'B',
            color: AppColors.accentTertiary,
            vibeController: _vibeB,
            busy: _busyB,
            output: _outB,
            onGenerate: _genB,
            formHint: hint,
          );

          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(pad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sideA),
                  const SizedBox(width: 16),
                  Expanded(child: sideB),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(pad),
            children: [
              sideA,
              const SizedBox(height: 20),
              sideB,
            ],
          );
        },
      ),
    );
  }

  Widget _side(
    BuildContext context, {
    required String label,
    required Color color,
    required TextEditingController vibeController,
    required bool busy,
    required String? output,
    required VoidCallback onGenerate,
    required String formHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prompt $label',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formHint,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Uses the rest of your generator settings; only the vibe line differs.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          MdTextField(
            controller: vibeController,
            label: 'VIBE (this side)',
            hint: 'Steer energy, arrangement feel, references…',
            maxLines: 4,
            maxLength: 800,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: busy ? null : onGenerate,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsRegular.magicWand, size: 20),
            label: Text(busy ? 'Generating…' : 'Generate $label'),
          ),
          const SizedBox(height: 14),
          Text(
            'OUTPUT',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 1.1,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 420),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                output ??
                    'Generate to compare two full Suno prompts side by side.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  height: 1.45,
                  color: output == null
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
