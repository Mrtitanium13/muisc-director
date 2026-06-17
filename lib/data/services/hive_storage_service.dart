import 'package:hive_flutter/hive_flutter.dart';

import '../models/saved_prompt_model.dart';

class HiveStorageService {
  static const _boxName = 'md_prompts';

  Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(SavedPromptModel model) async {
    await _box.put(model.id, model.toJsonString());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<SavedPromptModel> loadAllSorted() {
    final list = _box.values
        .map((s) => SavedPromptModel.fromJsonString(s))
        .whereType<SavedPromptModel>()
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
