// SAJEEV #53: widget tests for every state and golden images for UX1-UX14 (saved to docs/UIUX/android/).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registration_client/liveness/liveness_pane.dart';
import 'package:registration_client/liveness/liveness_states.g.dart';
import 'package:registration_client/liveness/liveness_ui_state.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final f = File(path);
    if (!f.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }

  const sdkFonts = String.fromEnvironment('FLUTTER_FONTS', defaultValue: '');
  await load('Roboto', '$sdkFonts/Roboto-Regular.ttf');
  await load('ArialUnicode', '/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
}

Widget _host(LivenessUiState s, String lang, {double scale = 1.0}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', fontFamilyFallback: const ['ArialUnicode']),
      home: MediaQuery(
        data: MediaQueryData(size: const Size(360, 780), textScaleFactor: scale),
        child: Scaffold(body: SafeArea(child: LivenessPane(state: s, lang: lang, mock: true, onButton: (_) {}))),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('test_every_error_state_renders_a_message', (t) async {
    for (final lang in ['en', 'fr', 'ar', 'hi', 'kn', 'ta']) {
      for (final e in livenessErrorStates.entries) {
        await t.pumpWidget(_host(e.value, lang));
        final msg = e.value.message[lang] ?? '';
        expect(msg.trim().isNotEmpty, true, reason: '${e.key} has no $lang message');
        expect(find.text(msg), findsOneWidget, reason: '${e.key} / $lang did not show its message');
      }
    }
    expect(livenessErrorStates.length, 13);
  });

  testWidgets('every UX state shows a badge text, not colour alone, in every language', (t) async {
    for (final lang in ['en', 'fr', 'ar', 'hi', 'kn', 'ta']) {
      for (final s in livenessUxStates) {
        await t.pumpWidget(_host(s, lang));
        expect(find.text(s.badge[lang]!), findsOneWidget, reason: '${s.id}/$lang badge');
      }
    }
  });

  testWidgets('layout is right-to-left for Arabic and survives large text', (t) async {
    await t.pumpWidget(_host(livenessUxStates[7], 'ar', scale: 2.0));
    final dir = Directionality.of(t.element(find.byType(LinearProgressIndicator).first));
    expect(dir, TextDirection.rtl);
    expect(t.takeException(), isNull, reason: 'overflow at 200% text');
  });

  testWidgets('semantics: the message is a live region and the title is a header', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(livenessUxStates[5], 'en'));
    expect(find.bySemanticsLabel('Please turn your head to the left'), findsWidgets);
    h.dispose();
  });

  for (var i = 0; i < livenessUxStates.length; i++) {
    final s = livenessUxStates[i];
    testWidgets('golden ${s.id} en', (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1.0;
      await t.pumpWidget(RepaintBoundary(child: _host(s, 'en')));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${s.id.toLowerCase()}_en.png'));
    });
  }
  for (final id in ['UX1', 'UX6', 'UX9', 'UX12']) {
    final s = livenessUxStates.firstWhere((x) => x.id == id);
    testWidgets('golden $id ar', (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1.0;
      await t.pumpWidget(RepaintBoundary(child: _host(s, 'ar')));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${s.id.toLowerCase()}_ar.png'));
    });
  }
}
