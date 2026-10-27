import 'dart:async';

import 'package:flutter/material.dart';

import 'package:registration_client/pigeon/liveness_pigeon.dart';
import 'package:registration_client/pigeon/process_spec_pigeon.dart';

import 'liveness_pane.dart';
import 'liveness_texts.g.dart';
import 'liveness_ui_state.dart';

/// SAJEEV #54: liveness before the face capture. The Java side refuses to store a face that was not live and bound
/// even if this gate is skipped; this gate is what the person sees (guidance, challenges, retries).
/// Counts failed liveness attempts and says when the limit is reached (default 3, the PDF retry limit).
class LivenessRetries {
  final int max;
  int _failures = 0;
  LivenessRetries(this.max);
  bool get exhausted => _failures >= max;
  int get failures => _failures;
  void failed() => _failures++;
  void reset() => _failures = 0;
}

class LivenessGate {
  /// Failed-attempt counters, one per scope (workflow, or an explicit scope such as 'ONBOARD'). They are not shared, so
  /// failures at the login screen never block registration capture and the other way round.
  static final Map<String, LivenessRetries> _counters = {};
  static int _max = 3;

  /// The counter of one scope (created on first use with the current limit).
  static LivenessRetries retriesFor(String scope) => _counters.putIfAbsent(scope, () => LivenessRetries(_max));

  /// Test and diagnostics access to the default (resident registration) counter.
  static LivenessRetries get retries => retriesFor('RESIDENT');

  /// The retry limit (maxRetries global parameter, default 3, never below 1). Existing counters keep their failures.
  static void setMaxRetries(int? value) {
    final max = (value == null || value < 1) ? 3 : value;
    if (max == _max) return;
    _max = max;
    final old = Map<String, LivenessRetries>.from(_counters);
    _counters.clear();
    old.forEach((k, v) {
      final n = LivenessRetries(max);
      for (var i = 0; i < v.failures && i < max; i++) {
        n.failed();
      }
      _counters[k] = n;
    });
  }

  /// A new registration or login flow starts: every counter begins at zero.
  static void startFlow() => _counters.forEach((_, v) => v.reset());

  /// True for the captures that are a real face capture: the face and the exception photo (the SBI is asked for FACE).
  static bool isFaceCapture(String modality) {
    final m = modality.replaceAll(' ', '');
    return m == 'Face' || m == 'Exception';
  }
  static const _enabledKey = 'mosip.registration.liveness.enabled';
  static const _maxRetriesKey = 'mosip.registration.liveness.maxRetries';

  /// The client's own settings (global parameters): liveness on unless exactly "false"; retries default 3, never below 1.
  static Future<void> _loadSettings() async {
    try {
      setMaxRetries(int.tryParse((await ProcessSpecApi().getStringValueGlobalParam(_maxRetriesKey)).trim()));
    } catch (_) {
      // keep the current limit
    }
  }

  static Future<bool> _enabled() async {
    try {
      return (await ProcessSpecApi().getStringValueGlobalParam(_enabledKey)).trim().toLowerCase() != 'false';
    } catch (_) {
      return true; // a missing or unreadable setting never switches liveness off
    }
  }

  /// True when the capture may start. Non-face modalities pass through untouched. [scope] names the retry counter
  /// (default: the workflow); operator onboarding uses its own scope so it never shares a counter with login.
  static Future<bool> passIfFace(BuildContext context, String modality,
      {String workflow = 'RESIDENT', String? scope}) async {
    if (!isFaceCapture(modality)) return true;
    if (!await _enabled()) return true; // an administrator switched liveness off
    await _loadSettings();
    if (!context.mounted) return false;
    final lang = _lang(context);
    final retries = retriesFor(scope ?? workflow);
    if (retries.exhausted) {
      await _info(context, livenessTexts['failure.max_retries']![lang]!);
      return false;
    }
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LivenessDialog(lang: lang, workflow: workflow),
    );
    if (result == 'LIVE') {
      retries.reset();
      return true;
    }
    if (result == 'NOT_LIVE') retries.failed();
    return false;
  }

  static void resetAttempts([String scope = 'RESIDENT']) => retriesFor(scope).reset();

  static String _lang(BuildContext c) {
    final l = Localizations.localeOf(c).languageCode;
    return const ['fr', 'ar', 'hi', 'kn', 'ta'].contains(l) ? l : 'en';
  }

  static Future<void> _info(BuildContext c, String text) =>
      showDialog<void>(context: c, builder: (_) => AlertDialog(content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));
}

class LivenessDialog extends StatefulWidget {
  final String lang;
  final String workflow;
  const LivenessDialog({super.key, required this.lang, required this.workflow});

  @override
  State<LivenessDialog> createState() => _LivenessDialogState();
}

class _Events extends LivenessEvents {
  final void Function(String, LivenessProgressDto) cb;
  _Events(this.cb);
  @override
  void onProgress(String sessionId, LivenessProgressDto progress) => cb(sessionId, progress);
}

class _LivenessDialogState extends State<LivenessDialog> {
  String? _id;
  LivenessProgressDto? _p;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    LivenessEvents.setup(_Events((id, p) {
      if (id != _id && _id != null) return;
      _update(p);
    }));
    LivenessApi().start(widget.workflow).then((id) {
      _id = id;
      LivenessApi().progress(id).then(_update);
    }).catchError((_) {
      _update(LivenessProgressDto(phase: 'UNAVAILABLE', guidanceKey: 'error.engine', reason: 'start_failed', mock: false, limited: false));
    });
  }

  void _update(LivenessProgressDto p) {
    if (!mounted || _closed) return;
    setState(() => _p = p);
    if (p.phase == 'LIVE') {
      _closed = true;
      Navigator.of(context).pop('LIVE');
    }
  }

  @override
  void dispose() {
    LivenessEvents.setup(null);
    if (_id != null && !_closed) LivenessApi().abort(_id!);
    super.dispose();
  }

  Map<String, String> _t(String key) => livenessTexts[key] ?? {'en': key};

  LivenessUiState _state() {
    final p = _p;
    final title = _t(widget.workflow == 'OPERATOR' ? 'ui.title.operator' : widget.workflow == 'SUPERVISOR' ? 'ui.title.supervisor' : 'ui.title.resident');
    if (p == null || p.phase == 'RUNNING') {
      final key = p?.challengeKey ?? p?.guidanceKey ?? 'passive.checking';
      return LivenessUiState(id: 'RUN', title: title, badge: _t(p?.challengeKey != null ? 'ui.badge.challenge' : 'ui.badge.checking'),
          badgeStyle: p?.challengeKey != null ? 'WARN' : 'PRIMARY', showGuide: true, icon: '', progressDone: 0, progressTotal: 0,
          message: _t(key), hints: const [], buttons: const [], footer: const {});
    }
    final failed = p.phase == 'NOT_LIVE' || p.phase == 'LIMITED';
    return LivenessUiState(id: p.phase, title: title, badge: _t(failed ? 'ui.badge.not_verified' : 'ui.badge.device_error'),
        badgeStyle: 'BAD', showGuide: false, icon: '', progressDone: 0, progressTotal: 0,
        message: _t(p.guidanceKey ?? 'failure.liveness'), hints: const [], buttons: [_t('ui.try_again')], footer: const {});
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: LivenessPane(
        state: _state(),
        lang: widget.lang,
        mock: p?.mock ?? false,
        limited: p?.limited ?? false,
        onButton: (_) {
          _closed = true;
          Navigator.of(context).pop(p?.phase ?? 'UNAVAILABLE');
        },
      ),
    );
  }
}
