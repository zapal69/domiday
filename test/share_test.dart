import 'package:domiday/share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapVisible;
import 'widget_test.dart' show launch;

void main() {
  testWidgets('share: card preview and PNG handed to the system sheet', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final share = FakeShareService();
    await launch(tester, repo, journal: false, share: share);
    await tapVisible(tester, 'shareYear');
    expect(find.byKey(const Key('yearCard')), findsOneWidget);
    expect(find.text('Итоги 2026'), findsOneWidget);
    // Карточка: год, три итога, страны с флагами.
    expect(
      find.descendant(
        of: find.byKey(const Key('yearCard')),
        matching: find.text('2026'),
      ),
      findsOneWidget,
    );
    expect(find.text('Дома'), findsOneWidget);
    expect(find.text('Вне дома'), findsOneWidget);
    expect(find.text('Неизвестно'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('yearCard')),
        matching: find.text('Грузия'),
      ),
      findsOneWidget,
    );
    // Рендер в PNG идёт вне тестового цикла кадров.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('shareSend')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(share.fileName, 'domiday-2026.png');
    expect(share.title, 'Итоги 2026');
    final png = share.shared!;
    expect(png.length, greaterThan(1000));
    expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('share: button hidden without the service; failure is shown', (
    tester,
  ) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    expect(find.byKey(const Key('shareYear')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    final share = FakeShareService()..fail = true;
    await launch(tester, repo, journal: false, share: share);
    await tapVisible(tester, 'shareYear');
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('shareSend')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось поделиться'), findsOneWidget);
  });
}
