// SAJEEV #54, A1/A2/A8
import 'package:flutter_test/flutter_test.dart';
import 'package:registration_client/liveness/liveness_gate.dart';

void main() {
  setUp(() {
    LivenessGate.setMaxRetries(3);
    LivenessGate.startFlow();
  });

  test('test_android_retry_limit_enforced', () {
    final r = LivenessRetries(3);
    expect(r.exhausted, false);
    r.failed();
    r.failed();
    expect(r.exhausted, false);
    r.failed();
    expect(r.exhausted, true);
    r.reset();
    expect(r.exhausted, false);
    expect(LivenessGate.retries.max, 3);
  });

  test('test_retry_counters_are_per_workflow', () {
    for (var i = 0; i < 3; i++) {
      LivenessGate.retriesFor('OPERATOR').failed(); // three failed face logins
    }
    expect(LivenessGate.retriesFor('OPERATOR').exhausted, true);
    expect(LivenessGate.retriesFor('RESIDENT').exhausted, false, reason: 'login failures never block registration');
    expect(LivenessGate.retriesFor('SUPERVISOR').exhausted, false);
    expect(LivenessGate.retriesFor('ONBOARD').exhausted, false);
  });

  test('test_new_flow_resets_every_counter', () {
    for (var i = 0; i < 3; i++) {
      LivenessGate.retriesFor('RESIDENT').failed();
      LivenessGate.retriesFor('OPERATOR').failed();
    }
    LivenessGate.startFlow();
    expect(LivenessGate.retriesFor('RESIDENT').exhausted, false);
    expect(LivenessGate.retriesFor('OPERATOR').exhausted, false);
    expect(LivenessGate.retriesFor('RESIDENT').failures, 0);
  });

  test('test_resetAttempts_resets_only_its_scope', () {
    LivenessGate.retriesFor('RESIDENT').failed();
    LivenessGate.retriesFor('OPERATOR').failed();
    LivenessGate.resetAttempts();
    expect(LivenessGate.retriesFor('RESIDENT').failures, 0);
    expect(LivenessGate.retriesFor('OPERATOR').failures, 1);
  });

  test('test_max_retries_comes_from_the_setting_and_keeps_failures', () {
    LivenessGate.retriesFor('RESIDENT').failed();
    LivenessGate.setMaxRetries(5);
    expect(LivenessGate.retriesFor('RESIDENT').max, 5);
    expect(LivenessGate.retriesFor('RESIDENT').failures, 1);
    LivenessGate.setMaxRetries(0); // invalid: back to 3
    expect(LivenessGate.retriesFor('RESIDENT').max, 3);
    LivenessGate.setMaxRetries(null);
    expect(LivenessGate.retriesFor('NEW').max, 3);
  });

  test('test_exception_photo_and_face_are_gated_other_modalities_pass', () {
    expect(LivenessGate.isFaceCapture('Face'), true);
    expect(LivenessGate.isFaceCapture('Exception'), true, reason: 'A2: the SBI is asked for FACE');
    expect(LivenessGate.isFaceCapture('Exception '), true);
    for (final m in ['Iris', 'LeftHand', 'RightHand', 'Thumbs', 'Fingerprint', '']) {
      expect(LivenessGate.isFaceCapture(m), false, reason: m);
    }
  });
}
