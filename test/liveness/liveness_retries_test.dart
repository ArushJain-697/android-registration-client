// SAJEEV #54
import 'package:flutter_test/flutter_test.dart';
import 'package:registration_client/liveness/liveness_gate.dart';

void main() {
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
}
