import 'package:domiday/main.dart' show appVersion, appVersionShort;
import 'package:domiday/share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, fixture, launch, reveal;

void main() {
  testWidgets('about: current version, contacts open mail and site, credits', (
    tester,
  ) async {
    final share = FakeShareService();
    await launch(tester, MemoryRepository([fixture()]), share: share);
    await tester.tap(find.byTooltip('О дневнике'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aboutPage')), findsOneWidget);
    // Версия берётся из той же константы, что и подпись внизу экранов.
    expect(appVersion, startsWith(appVersionShort));
    expect(find.textContaining(appVersionShort), findsWidgets);
    await reveal(tester, find.text('Что умеет'));
    expect(find.text('Что умеет'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('aboutEmail')));
    await tester.tap(find.byKey(const Key('aboutEmail')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('aboutSite')));
    await tester.tap(find.byKey(const Key('aboutSite')));
    await tester.pumpAndSettle();
    // Письмо с версией в теме, форма на сайте по языку с версией в адресе.
    expect(share.opened, [
      'mailto:info@domiday.com?subject=Domiday%20$appVersionShort%3A%20%D0%B7%D0%B0%D0%BC%D0%B5%D1%87%D0%B0%D0%BD%D0%B8%D0%B5',
      'https://domiday.com/ru/?v=$appVersionShort#feedback',
    ]);
    await reveal(tester, find.byKey(const Key('aboutHome')));
    await tester.tap(find.byKey(const Key('aboutHome')));
    await tester.pumpAndSettle();
    expect(share.opened.last, 'https://domiday.com');
    await reveal(tester, find.text('© 2026 Domiday. Все права защищены.'));
    expect(find.textContaining('Natural Earth'), findsWidgets);
    expect(find.textContaining('flag-icons'), findsOneWidget);
  });

  testWidgets('about: without an opener the tap reports, nothing crashes', (
    tester,
  ) async {
    await launch(tester, MemoryRepository([fixture()]));
    await tester.tap(find.byTooltip('О дневнике'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('aboutEmail')));
    await tester.tap(find.byKey(const Key('aboutEmail')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось открыть'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings: feedback card opens the site form and mail', (
    tester,
  ) async {
    final share = FakeShareService();
    await launch(
      tester,
      MemoryRepository([fixture()]),
      journal: false,
      share: share,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('settingsFeedbackSite')));
    await tester.tap(find.byKey(const Key('settingsFeedbackSite')));
    await tester.pumpAndSettle();
    expect(share.opened, [
      'https://domiday.com/ru/?v=$appVersionShort#feedback',
    ]);
  });
}
