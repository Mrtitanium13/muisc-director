import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/on_device_api_keys.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_connectivity.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../../core/utils/openai_key_validation.dart';
import '../../providers/app_providers.dart';
import '../../providers/session_providers.dart';
import '../../widgets/shell/main_shell.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _laozhangKeyCtrl;
  late final TextEditingController _openRouterKeyCtrl;
  late final TextEditingController _apiBaseCtrl;
  OnDeviceLlmProvider _onDeviceProvider = OnDeviceLlmProvider.laozhang;

  @override
  void initState() {
    super.initState();
    _laozhangKeyCtrl = TextEditingController();
    _openRouterKeyCtrl = TextEditingController();
    _apiBaseCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = ref.read(sharedPrefsProvider);
      await OnDeviceApiKeys.migrateLegacyKey(prefs);
      if (!mounted) return;
      _laozhangKeyCtrl.text = OnDeviceApiKeys.laozhangKey(prefs);
      _openRouterKeyCtrl.text = OnDeviceApiKeys.openRouterKey(prefs);
      final rawApi = prefs.getString(ApiConstants.prefMdApiBaseUrl) ?? '';
      final fixedApi = normalizeApiBaseUrl(rawApi);
      if (fixedApi != rawApi && fixedApi.isNotEmpty) {
        await prefs.setString(ApiConstants.prefMdApiBaseUrl, fixedApi);
        ref.read(mdApiBaseRevisionProvider.notifier).state++;
      }
      _apiBaseCtrl.text = fixedApi;
      setState(() {
        _onDeviceProvider = OnDeviceApiKeys.resolveProvider(prefs);
      });
    });
  }

  @override
  void dispose() {
    _laozhangKeyCtrl.dispose();
    _openRouterKeyCtrl.dispose();
    _apiBaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLaozhangKey() async {
    final prefs = ref.read(sharedPrefsProvider);
    final trimmed = _laozhangKeyCtrl.text.trim();
    await prefs.setString(OnDeviceApiKeys.prefLaozhang, trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(laozhangKeySavedMessage(trimmed)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _saveOpenRouterKey() async {
    final prefs = ref.read(sharedPrefsProvider);
    final trimmed = _openRouterKeyCtrl.text.trim();
    await prefs.setString(OnDeviceApiKeys.prefOpenRouter, trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(openRouterKeySavedMessage(trimmed)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _setOnDeviceProvider(OnDeviceLlmProvider provider) async {
    final prefs = ref.read(sharedPrefsProvider);
    await OnDeviceApiKeys.setProvider(prefs, provider);
    setState(() => _onDeviceProvider = provider);
    if (!mounted) return;
    final label =
        provider == OnDeviceLlmProvider.openrouter ? 'OpenRouter' : 'LaoZhang';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('On-device generation will use $label')),
    );
  }

  Future<void> _saveApiBase() async {
    final normalized = normalizeApiBaseUrl(_apiBaseCtrl.text);
    final err = validateMusicDirectorApiBaseUrl(normalized);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final prefs = ref.read(sharedPrefsProvider);
    final raw = _apiBaseCtrl.text.trim();
    await prefs.setString(ApiConstants.prefMdApiBaseUrl, normalized);
    ref.read(mdApiBaseRevisionProvider.notifier).state++;
    if (mounted) {
      _apiBaseCtrl.text = normalized;
      final msg = raw != normalized
          ? 'Saved as $normalized (local server must use http, not https)'
          : 'API base URL saved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _testApiConnection() async {
    final raw = _apiBaseCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter MD_API_BASE_URL first')),
      );
      return;
    }
    try {
      final result = await runMusicDirectorConnectionTest(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.successMessage),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dioErrorMessage(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(sessionPrefsProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MainShell.contentBottomPadding(context),
        ),
        children: [
          Text(
            'Music Director API (recommended)',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Music Director server only — NOT api.laozhang.ai. '
            'Real phone: PC Wi‑Fi IP with http (e.g. http://192.168.1.10:8080 — not .1, not https). '
            'Emulator: MD_ANDROID_EMULATOR=true + http://127.0.0.1:8080 in .env. '
            'Test http://…/health in a browser.',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiBaseCtrl,
            style: GoogleFonts.jetBrainsMono(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'MD_API_BASE_URL',
              hintText: 'http://192.168.x.x:8080 or https://….railway.app',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saveApiBase,
                  child: const Text('Save API URL'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _testApiConnection,
                child: const Text('Test'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Suno prompt pack: V2 (Path A/B/C + lyric engine) is on by default in the app and '
            'on Railway when unset. Add USE_SUNO_PROMPT_V2=false to `.env` (or server env) for the legacy prompt.',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'LaoZhang & OpenRouter (optional)',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save keys here for on-device generation (direct to api.laozhang.ai / openrouter.ai). '
            'If API base URL is set but the PC server is offline, the app falls back to on-device '
            'when a key is saved. Clear API base URL to skip the server entirely (same as OpenRouter). '
            'Pick which provider runs generation:',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'LLM provider for generation',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OnDeviceLlmProvider>(
            segments: const [
              ButtonSegment(
                value: OnDeviceLlmProvider.laozhang,
                label: Text('LaoZhang'),
              ),
              ButtonSegment(
                value: OnDeviceLlmProvider.openrouter,
                label: Text('OpenRouter'),
              ),
            ],
            selected: {_onDeviceProvider},
            onSelectionChanged: (s) => _setOnDeviceProvider(s.first),
          ),
          const SizedBox(height: 20),
          Text(
            'LaoZhang API',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'api.laozhang.ai/token — GPT-5.5 multilingual prompt + Claude lyrics & expression (Gemini 2.5 Pro fallback); Gemini Pro for style-only.',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _laozhangKeyCtrl,
            obscureText: true,
            style: GoogleFonts.jetBrainsMono(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'LaoZhang API key',
              hintText: 'Paste LaoZhang key',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saveLaozhangKey,
              child: const Text('Save LaoZhang key'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'OpenRouter API',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'openrouter.ai/keys — Qwen / Mistral models (sk-or-v1-…).',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _openRouterKeyCtrl,
            obscureText: true,
            style: GoogleFonts.jetBrainsMono(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'OpenRouter API key',
              hintText: 'sk-or-v1-…',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saveOpenRouterKey,
              child: const Text('Save OpenRouter key'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push('/quick-describe'),
            child: const Text('Quick describe'),
          ),
          const SizedBox(height: 8),
          Text(
            'Free-text → mapped fields → Suno prompt with format QA retry. '
            'Also available from Generate → Quick describe.',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Sign out / leave guest session'),
          ),
        ],
      ),
    );
  }
}
