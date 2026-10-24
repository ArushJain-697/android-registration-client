// SAJEEV diagnostic panel: nothing unless there is data; banner and rows otherwise; golden image.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registration_client/liveness/diagnostic_panel.dart';

void main() {
  setUpAll(() async {
    const dir = String.fromEnvironment('FLUTTER_FONTS', defaultValue: '');
    final f = File('$dir/Roboto-Regular.ttf');
    if (f.existsSync()) {
      final l = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      await l.load();
    }
  });

  Widget host(Map<String, String> d) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(body: SafeArea(child: DiagnosticPanel(data: d))));

  testWidgets('empty data draws nothing (not enabled, or not the operator)', (t) async {
    await t.pumpWidget(host({}));
    expect(find.text(DiagnosticPanel.banner), findsNothing);
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('data shows the banner and every row', (t) async {
    await t.pumpWidget(host({'state': 'DONE', 'delivered fps': '15.2', 'voter V1_texture_minifasnet': 'ATTACK (LOW) texture_prob=0.016'}));
    expect(find.text(DiagnosticPanel.banner), findsOneWidget);
    expect(find.text('delivered fps'), findsOneWidget);
    expect(find.text('15.2'), findsOneWidget);
  });

  testWidgets('golden diagnostic panel', (t) async {
    t.view.physicalSize = const Size(360, 520);
    t.view.devicePixelRatio = 1.0;
    await t.pumpWidget(RepaintBoundary(child: host({
      'state': 'DONE',
      'verdict': 'ATTACK_SUSPECTED / PAD_FAIL / attack_during_challenge',
      'delivered fps': '15.2',
      'minimum fps (config)': '3.0',
      'queue depth': '0',
      'avg processing ms per frame': '96',
      'last guidance': 'none',
      'voter V1_texture': 'ATTACK (LOW) texture_prob=0.016',
      'voter V2_moire': 'LIVE (HIGH) moire_flagged=0 of 3',
      'voter V3_flatness': 'ABSTAIN (no score) no_motion',
    })));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/diagnostic_panel_en.png'));
  });
}
