import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/features/prompt_generator/utils/form_commit.dart';
import 'package:music_director/features/prompt_generator/utils/form_hydration.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

/// Commits form state then navigates to feature routes.
class FormNavigation {
  const FormNavigation._();

  static Future<void> openTemplates(BuildContext context, WidgetRef ref) async {
    FormCommit.commitAll(ref);
    final selectedModel = await context.push<UserInputModel>('/templates');
    if (!context.mounted) return;
    if (selectedModel != null) {
      ref.read(promptFormProvider.notifier).replace(selectedModel);
      FormHydration.reloadAll(ref);
    }
  }

  static void openBatchGenerate(BuildContext context, WidgetRef ref) {
    FormCommit.commitAll(ref);
    context.push('/batch-generate');
  }

  static void openAbCompare(BuildContext context, WidgetRef ref) {
    FormCommit.commitAll(ref);
    context.push('/ab-compare');
  }

  static void openQuickDescribe(BuildContext context, WidgetRef ref) {
    FormCommit.commitAll(ref);
    context.push('/quick-describe');
  }
}
