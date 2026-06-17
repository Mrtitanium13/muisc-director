import 'dart:convert';

class SavedPromptModel {
  SavedPromptModel({
    required this.id,
    required this.createdAt,
    required this.genreTag,
    required this.promptText,
    required this.sunoVersion,
  });

  final String id;
  final DateTime createdAt;
  final String genreTag;
  final String promptText;
  final String sunoVersion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'genreTag': genreTag,
        'promptText': promptText,
        'sunoVersion': sunoVersion,
      };

  factory SavedPromptModel.fromJson(Map<String, dynamic> j) {
    return SavedPromptModel(
      id: j['id'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      genreTag: j['genreTag'] as String,
      promptText: j['promptText'] as String,
      sunoVersion: j['sunoVersion'] as String? ?? 'v5.0',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static SavedPromptModel? fromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    return SavedPromptModel.fromJson(
      jsonDecode(s) as Map<String, dynamic>,
    );
  }
}
