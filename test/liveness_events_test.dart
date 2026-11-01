// SAJEEV #52: the Dart side receives the progress events that the Java side pushes (mocked channel, no device needed).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:registration_client/pigeon/liveness_pigeon.dart';

class _Receiver extends LivenessEvents {
  final List<String> seen = [];
  @override
  void onProgress(String sessionId, LivenessProgressDto progress) {
    seen.add('$sessionId:${progress.phase}:${progress.guidanceKey}:${progress.mock}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('test_state_events_reach_flutter', () async {
    final r = _Receiver();
    LivenessEvents.setup(r);
    final codec = LivenessEvents.codec;
    final msg = codec.encodeMessage(<Object?>[
      's1',
      LivenessProgressDto(phase: 'RUNNING', guidanceKey: 'error.face_not_detected', reason: 'running', mock: true, limited: false),
    ]);
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('dev.flutter.pigeon.registration_client.LivenessEvents.onProgress', msg, (_) {});
    expect(r.seen, ['s1:RUNNING:error.face_not_detected:true']);
  });

  test('host api start returns the session id from the channel', () async {
    const ch = 'dev.flutter.pigeon.registration_client.LivenessApi.start';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(ch, (ByteData? m) async {
      return LivenessApi.codec.encodeMessage(<Object?>['session-42']);
    });
    expect(await LivenessApi().start('RESIDENT'), 'session-42');
  });
}
