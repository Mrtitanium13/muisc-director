// Reroll Coach — progressive simplification + verified prompt library.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/engine_config.dart';
import 'prompt_assembler.dart';

class CoachResult {
  final AssemblerOutput output;
  final String coachMessage;
  const CoachResult(this.output, this.coachMessage);
}

class VerifiedPrompt {
  final String stylePrompt;
  final String excludeStyles;
  final AssemblerInput input;
  final String savedAt;
  final String? note;

  const VerifiedPrompt({
    required this.stylePrompt,
    required this.excludeStyles,
    required this.input,
    required this.savedAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'stylePrompt': stylePrompt,
        'excludeStyles': excludeStyles,
        'input': input.toJson(),
        'savedAt': savedAt,
        'note': note,
      };

  factory VerifiedPrompt.fromJson(Map<String, dynamic> j) => VerifiedPrompt(
        stylePrompt: j['stylePrompt'] as String,
        excludeStyles: j['excludeStyles'] as String,
        input: AssemblerInput.fromJson(j['input'] as Map<String, dynamic>),
        savedAt: j['savedAt'] as String,
        note: j['note'] as String?,
      );
}

class RerollCoach {
  static const _storageKey = 'verified_clean_prompts_v1';
  static const _maxSaved = 100;

  static CoachResult getSimplifiedRetry(AssemblerInput input, int failCount) {
    final ladder = EngineConfig.simplificationLadder;
    final step = ladder[(failCount - 1).clamp(0, ladder.length - 1)];

    AssemblerInput modified;
    switch (step.action) {
      case 'drop_mood':
        modified = input.copyWith(mood: () => null);
        break;
      case 'drop_one_texture':
        final trimmed = input.customTokens.isEmpty
            ? <String>[]
            : input.customTokens.sublist(0, input.customTokens.length - 1);
        modified = input.copyWith(mood: () => null, customTokens: trimmed);
        break;
      case 'minimal_core':
      default:
        modified = input.copyWith(
          mood: () => null,
          customTokens: [],
          genres: input.genres.take(1).toList(),
        );
    }

    final output = PromptAssembler.assemble(modified);
    return CoachResult(
        output, '${step.message} ${EngineConfig.listenGuidance}');
  }

  static Future<void> saveVerifiedPrompt(VerifiedPrompt entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadVerifiedPrompts();
    list.insert(0, entry);
    final capped = list.take(_maxSaved).toList();
    await prefs.setString(
      _storageKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<VerifiedPrompt>> loadVerifiedPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => VerifiedPrompt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteVerifiedPrompt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadVerifiedPrompts();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await prefs.setString(
      _storageKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
