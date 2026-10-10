import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart'
    show MemoryRepository, fixture, launch, reveal, openCalendar;
import 'dashboard_test.dart' show dashboardFixture, tapVisible;

import 'package:domiday/snapshot.dart';

void main() {
  setUpAll(() async {
    // Bundled test-only Roboto provides readable Russian in deterministic PNGs.
    final font = FontLoader('Roboto');
    for (final weight in ['Regular', 'Bold']) {
      final bytes = await File('test/fonts/Roboto-$weight.ttf').readAsBytes();
      font.addFont(
        Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  // Светлые экраны 390 px рендерятся на английском, тёмные и узкие — на
  // русском: оба языка покрыты без удвоения эталонов.
  testWidgets('empty 390x844', (tester) async {
    await launch(tester, MemoryRepository(), locale: const Locale('en'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/empty-390.png'),
    );
  });

  testWidgets('filled 390x844 and timeline, fixtures only', (tester) async {
    await launch(
      tester,
      MemoryRepository([fixture(), fixture(id: 'second', country: 'Турция')]),
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/filled-390.png'),
    );
    await reveal(tester, find.byKey(const Key('trip-fixture')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -190));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/timeline-390.png'),
    );
  });

  testWidgets('320px large text empty and form', (tester) async {
    await launch(tester, MemoryRepository(), width: 320, scale: 1.8);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/empty-320-large.png'),
    );
    await reveal(tester, find.byKey(const Key('addTrip')));
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/form-320-large.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark filled 390x844', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await launch(tester, MemoryRepository([fixture()]));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dark-390.png'),
    );
  });

  testWidgets('320px large text filled summary', (tester) async {
    await launch(tester, MemoryRepository([fixture()]), width: 320, scale: 1.8);
    await reveal(tester, find.text('Дни в записанных поездках'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/filled-320-large.png'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final variant in [
    (name: 'dashboard-390', width: 390.0, scale: 1.0, dark: false, lang: 'en'),
    (
      name: 'dashboard-dark-390',
      width: 390.0,
      scale: 1.0,
      dark: true,
      lang: 'ru',
    ),
    (
      name: 'dashboard-320-large',
      width: 320.0,
      scale: 1.8,
      dark: false,
      lang: 'ru',
    ),
  ]) {
    testWidgets('v0.2 ${variant.name} and year summary', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = variant.dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        width: variant.width,
        scale: variant.scale,
        locale: Locale(variant.lang),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${variant.name}.png'),
      );
      await reveal(tester, find.byKey(const Key('unknownTotal')));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${variant.name}-summary.png'),
      );
      // Календарь года — отдельная вкладка с 0.15.0.
      await openCalendar(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${variant.name}-calendar.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('v0.2 onboarding 390 and 320 large with real fonts', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(trips: [fixture()]);
    await launch(tester, repo, journal: false, locale: const Locale('en'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding-390.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await launch(tester, repo, journal: false, width: 320, scale: 1.8);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding-320-large.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('v0.2 gap preview uses actual rendered ranges', (tester) async {
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      locale: const Locale('en'),
    );
    await tapVisible(tester, 'previewGaps');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/gap-preview-390.png'),
    );
  });
}
