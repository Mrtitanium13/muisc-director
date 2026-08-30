import 'package:flutter/material.dart';

class GeneratingDialog extends StatelessWidget {
  const GeneratingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: const Color(0xFF141419),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFFD54F),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Gemini 2.5 Flash (draft + polish)\n'
                  'This usually takes 1–4 minutes.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
