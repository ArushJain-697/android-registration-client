import 'package:flutter/material.dart';

/// SAJEEV diagnostic panel (PDF good-to-have). Draws what the engine returns for the operator when an administrator enabled
/// diagnostic mode. An empty map draws nothing at all: no banner, no rows. Never shows an image or a template.
class DiagnosticPanel extends StatelessWidget {
  final Map<String, String> data;
  const DiagnosticPanel({super.key, required this.data});

  static const String banner = 'DIAGNOSTIC MODE';

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$banner: technical information for troubleshooting',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFFB3261E),
              child: const Text(banner, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          for (final e in data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Semantics(
                label: '${e.key}: ${e.value}',
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 130, child: Text(e.key, style: const TextStyle(fontSize: 12, color: Color(0xFF4A5560)))),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12, color: Color(0xFF111111)))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
