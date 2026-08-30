import 'package:flutter/material.dart';

void showUserNotices(BuildContext context, List<String> notices) {
  if (!context.mounted || notices.isEmpty) return;
  for (final notice in notices) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notice), duration: const Duration(seconds: 4)),
    );
  }
}
