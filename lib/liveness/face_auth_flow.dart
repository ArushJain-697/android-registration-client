import 'package:flutter/material.dart';
import 'package:registration_client/pigeon/biometrics_pigeon.dart';
import 'package:registration_client/pigeon/process_spec_pigeon.dart';

import 'liveness_gate.dart';

/// SAJEEV #55/#56: face authentication of one onboarded user. Order: liveness (dialog) -> capture through the SBI intent ->
/// the Java side checks live AND bound, then matches 1:1 against that user's onboarded face. True only for a match, and
/// then the Java side holds a single-use ticket that the login or approval call spends. Password stays available.
class FaceAuthFlow {
  static const faceAuthKey = 'mosip.registration.liveness.faceAuth.enabled';
  static const livenessKey = 'mosip.registration.liveness.enabled';

  /// Off unless the server (or the local config) switches it on, so the password path is unchanged by default.
  static Future<bool> enabled() async {
    try {
      final f = await ProcessSpecApi().getStringValueGlobalParam(faceAuthKey);
      final l = await ProcessSpecApi().getStringValueGlobalParam(livenessKey);
      return f.trim().toLowerCase() == 'true' && l.trim().toLowerCase() != 'false';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verify(BuildContext context, String username, String workflow) async {
    if (username.trim().isEmpty) return false;
    if (!await LivenessGate.passIfFace(context, 'Face', workflow: workflow)) return false;
    try {
      final r = await BiometricsApi().invokeDiscoverSbi('faceAuth:$username', 'Face');
      return r == 'MATCH';
    } catch (_) {
      return false; // LIVENESS_REFUSED, no SBI, no onboarded face: all refuse
    }
  }
}
