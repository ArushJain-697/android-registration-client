/// SAJEEV liveness screens (ticket #53): one screen state as data. All text is already in en, fr and ar.
class LivenessUiState {
  final String id;
  final Map<String, String> title;
  final Map<String, String> badge;
  /// PRIMARY, WARN, BAD or OK. Colour is never the only signal: the badge always has a text label.
  final String badgeStyle;
  final bool showGuide;
  final String icon;
  final int progressDone;
  final int progressTotal;
  final Map<String, String> message;
  final List<Map<String, String>> hints;
  final List<Map<String, String>> buttons;
  final Map<String, String> footer;

  const LivenessUiState({
    required this.id,
    required this.title,
    required this.badge,
    required this.badgeStyle,
    required this.showGuide,
    required this.icon,
    required this.progressDone,
    required this.progressTotal,
    required this.message,
    required this.hints,
    required this.buttons,
    required this.footer,
  });
}
