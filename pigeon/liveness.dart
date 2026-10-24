import 'package:pigeon/pigeon.dart';

/// SAJEEV liveness (ticket #52). Frames never cross this bridge: the Java side feeds the engine
/// from the SBI app's frame feed. Flutter only starts a session, reads progress and asks for the capture check.
class LivenessProgressDto {
  /// RUNNING, LIVE, NOT_LIVE or UNAVAILABLE. Only LIVE allows the capture.
  final String phase;
  /// Message key of the challenge to show now (for example challenge.blink), or null.
  final String? challengeKey;
  /// Message key of the guidance or error to show, or null.
  final String? guidanceKey;
  /// Short machine-readable reason, for audit.
  final String reason;
  /// True when the frames come from a mock device.
  final bool mock;
  /// True for the capture-only tier: never show it as full liveness.
  final bool limited;

  LivenessProgressDto({
    required this.phase,
    this.challengeKey,
    this.guidanceKey,
    required this.reason,
    required this.mock,
    required this.limited,
  });
}

@HostApi()
abstract class LivenessApi {
  /// Starts a session for RESIDENT, OPERATOR or SUPERVISOR and returns its id.
  @async
  String start(String workflow);

  LivenessProgressDto progress(String sessionId);

  /// Checks the captured face (JPEG or PNG bytes) against the live face. True only when bound.
  @async
  bool checkCapture(String sessionId, Uint8List capturedImage, int captureTimeoutMs);

  void abort(String sessionId);
}

/// Pushed from Java whenever the phase, the challenge or the guidance changes.
@FlutterApi()
abstract class LivenessEvents {
  void onProgress(String sessionId, LivenessProgressDto progress);
}
