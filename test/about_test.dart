import 'package:domiday/main.dart' show appVersion, appVersionShort;
import 'package:domiday/share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, fixture, launch, reveal;

void main() {
  testWidgets('about: current version, contacts open mail and site, credits', (tester) async {
    final share = FakeShareService();
    await launch(tester, MemoryRepository([fixture()]), share: share);
    await tester.tap(find.byTooltip('О дневнике'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aboutPage')), findsOneWidget);
    // Версия берётся из той же константы, что и подпись внизу экранов.
    expect(appVersion, startsWith(appVersionShort));
    expect(find.textContaining(appVersionShort), findsWidgets);
    expect(find.text('Что умеет'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('aboutEmail')));
    await tester.tap(find.byKey(const Key('aboutEmail')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('aboutSite')));
    await tester.tap(find.byKey(const Key('aboutSite')));
    await tester.pumpAndSettle();
    expect(share.opened, ['mailto:info@domiday.com', 'https://www.domiday.com']);
    await reveal(tester, find.text('© 2026 Domiday. Все права защищены.'));
    expect(find.textContaining('Natural Earth'), findsWidgets);
    expect(find.textContaining('flag-icons'), findsOneWidget);
  });

  testWidgets('about: without an opener the tap reports, nothing crashes', (tester) async {
    await launch(tester, MemoryRepository([fixture()]));
    await tester.tap(find.byTooltip('О дневнике'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('aboutEmail')));
    await tester.tap(find.byKey(const Key('aboutEmail')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось открыть'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
