import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/openai_key_validation.dart';
import 'api_constants.dart';

/// Which on-device LLM provider to use when [ApiConstants.resolveMdApiBase] is unset.
enum OnDeviceLlmProvider {
  laozhang,
  openrouter,
}

/// SharedPreferences keys and resolution for LaoZhang vs OpenRouter on-device keys.
abstract final class OnDeviceApiKeys {
  OnDeviceApiKeys._();

  static const prefLaozhang = 'md_laozhang_api_key';
  static const prefOpenRouter = 'md_openrouter_api_key';
  static const prefProvider = 'md_on_device_provider';
  static const legacyPref = 'md_openai_key';

  static const envOpenRouterKey = 'OPENROUTER_API_KEY';

  /// Moves [legacyPref] into the correct provider key when the new keys are empty.
  static Future<void> migrateLegacyKey(SharedPreferences prefs) async {
    final legacy = prefs.getString(legacyPref)?.trim() ?? '';
    if (legacy.isEmpty) return;
    if (looksLikeOpenRouterKey(legacy)) {
      if ((prefs.getString(prefOpenRouter) ?? '').trim().isEmpty) {
        await prefs.setString(prefOpenRouter, legacy);
      }
    } else if ((prefs.getString(prefLaozhang) ?? '').trim().isEmpty) {
      await prefs.setString(prefLaozhang, legacy);
    }
  }

  static OnDeviceLlmProvider resolveProvider(SharedPreferences prefs) {
    final raw = prefs.getString(prefProvider)?.trim().toLowerCase();
    if (raw == 'openrouter') return OnDeviceLlmProvider.openrouter;
    return OnDeviceLlmProvider.laozhang;
  }

  static Future<void> setProvider(
    SharedPreferences prefs,
    OnDeviceLlmProvider provider,
  ) =>
      prefs.setString(
        prefProvider,
        provider == OnDeviceLlmProvider.openrouter ? 'openrouter' : 'laozhang',
      );

  static String laozhangKey(SharedPreferences prefs) {
    final fromPrefs = prefs.getString(prefLaozhang)?.trim();
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    final env = dotenv.env[ApiConstants.envOpenAiKey]?.trim() ?? '';
    if (env.isNotEmpty && !looksLikeOpenRouterKey(env)) return env;
    return '';
  }

  static String openRouterKey(SharedPreferences prefs) {
    final fromPrefs = prefs.getString(prefOpenRouter)?.trim();
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    final orEnv = dotenv.env[envOpenRouterKey]?.trim() ?? '';
    if (orEnv.isNotEmpty) return orEnv;
    final legacyEnv = dotenv.env[ApiConstants.envOpenAiKey]?.trim() ?? '';
    if (legacyEnv.isNotEmpty && looksLikeOpenRouterKey(legacyEnv)) {
      return legacyEnv;
    }
    return '';
  }

  /// Whether the selected on-device provider has a non-empty API key saved.
  static bool hasActiveKey(SharedPreferences prefs) {
    final provider = resolveProvider(prefs);
    if (provider == OnDeviceLlmProvider.openrouter) {
      return openRouterKey(prefs).isNotEmpty;
    }
    return laozhangKey(prefs).isNotEmpty;
  }

  /// Active key + provider for on-device chat when no [MD_API_BASE_URL].
  static ({String apiKey, bool useOpenRouter}) resolveActive(
    SharedPreferences prefs,
  ) {
    final provider = resolveProvider(prefs);
    if (provider == OnDeviceLlmProvider.openrouter) {
      return (apiKey: openRouterKey(prefs), useOpenRouter: true);
    }
    return (apiKey: laozhangKey(prefs), useOpenRouter: false);
  }

  /// Optional fields for `POST /generate-prompt` when the server has no env key.
  static Map<String, dynamic> serverRequestFields(SharedPreferences prefs) {
    final provider = resolveProvider(prefs);
    final lz = laozhangKey(prefs);
    final or = openRouterKey(prefs);
    return {
      'llm_provider':
          provider == OnDeviceLlmProvider.openrouter ? 'openrouter' : 'laozhang',
      if (lz.isNotEmpty) 'laozhang_api_key': lz,
      if (or.isNotEmpty) 'openrouter_api_key': or,
    };
  }
}
