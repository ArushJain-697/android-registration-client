import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'liveness_ui_state.dart';

/// The liveness screen for Android (SAJEEV #53). Same states and wording as the desktop pane.
/// Right-to-left for Arabic, readable at large text sizes, every element has a text label for TalkBack.
class LivenessPane extends StatelessWidget {
  final LivenessUiState state;
  final String lang; // 'en', 'fr' or 'ar'
  final Widget? preview; // the camera picture; a placeholder oval is drawn when null
  final bool mock; // show the MOCK DEVICE label
  final bool limited; // show the LIMITED label: capture-only check, not full liveness
  final void Function(int index)? onButton;

  const LivenessPane({
    super.key,
    required this.state,
    required this.lang,
    this.preview,
    this.mock = false,
    this.limited = false,
    this.onButton,
  });

  Color _badgeColor(BuildContext c) {
    switch (state.badgeStyle) {
      case 'BAD':
        return const Color(0xFFB3261E);
      case 'WARN':
        return const Color(0xFF8A5A00);
      case 'OK':
        return const Color(0xFF1B6E3A);
      default:
        return const Color(0xFF1F4FA3);
    }
  }

  String _t(Map<String, String> m) => m[lang] ?? m['en'] ?? '';

  @override
  Widget build(BuildContext context) {
    final rtl = lang == 'ar';
    final badgeColor = _badgeColor(context);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(_t(state.title),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Semantics(
                  label: _t(state.badge),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: badgeColor, borderRadius: BorderRadius.circular(16)),
                    child: Text(_t(state.badge),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (mock) ...[
                  const SizedBox(width: 8),
                  _tag('MOCK DEVICE'),
                ],
                if (limited) ...[
                  const SizedBox(width: 8),
                  _tag('LIMITED CHECK'),
                ],
              ]),
              const SizedBox(height: 12),
              if (state.showGuide)
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Semantics(
                    label: _t(state.message),
                    child: preview ?? CustomPaint(painter: _OvalPainter(badgeColor), child: Center(child: _icon())),
                  ),
                ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(_t(state.message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Color(0xFF111111))),
              ),
              if (state.progressTotal > 0) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: '${state.progressDone} / ${state.progressTotal}',
                  child: LinearProgressIndicator(
                      value: state.progressDone / state.progressTotal, minHeight: 8, color: badgeColor),
                ),
                Center(child: Text('${state.progressDone} / ${state.progressTotal}', style: const TextStyle(fontSize: 14))),
              ],
              for (final h in state.hints)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• ${_t(h)}', style: const TextStyle(fontSize: 16, color: Color(0xFF333333)))),
              const SizedBox(height: 12),
              for (var i = 0; i < state.buttons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                      onPressed: onButton == null ? null : () => onButton!(i),
                      child: Text(_t(state.buttons[i]))),
                ),
              if (_t(state.footer).isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_t(state.footer),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF444444)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon() => state.icon.isEmpty
      ? const SizedBox.shrink()
      : ExcludeSemantics(child: Text(state.icon, style: const TextStyle(fontSize: 64, color: Color(0xFF1F4FA3))));

  Widget _tag(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF444444)), borderRadius: BorderRadius.circular(4)),
        child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _OvalPainter extends CustomPainter {
  final Color color;
  _OvalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFEFEF));
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.62, height: size.height * 0.72);
    canvas.drawOval(rect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = color);
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) => old.color != color;
}
