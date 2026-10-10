import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapVisible, yearHeader;
import 'widget_test.dart'
    show MemoryRepository, launch, reveal, openCalendar;

void main() {
  testWidgets('editor: quick chips set both dates; range picker opens', (
    tester,
  ) async {
    final repo = MemoryRepository();
    await launch(tester, repo);
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country')), 'Грузия');
    expect(find.textContaining('Выбрать дату'), findsOneWidget);
    // «Вчера» — обе даты вчерашние, поле показывает одну дату.
    await tapVisible(tester, 'quickYesterday');
    expect(find.textContaining('Даты *  12.09.2026'), findsOneWidget);
    expect(find.textContaining('12.09.2026 —'), findsNothing);
    // «Сегодня» — 13.09.2026 один день.
    await tapVisible(tester, 'quickToday');
    expect(find.textContaining('Даты *  13.09.2026'), findsOneWidget);
    // Диапазон: открывается системный выбор диапазона, отмена ничего не
    // меняет.
    await tapVisible(tester, 'dates');
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.textContaining('Даты *  13.09.2026'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(repo.records.single.arrival, Day(2026, 9, 13));
    expect(repo.records.single.departure, Day(2026, 9, 13));
    // «Один день» у существующей записи: отъезд = приезд.
    final id = repo.records.single.id;
    await reveal(tester, find.byKey(Key('trip-$id')));
    await tester.tap(find.byKey(Key('trip-$id')));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'quickOneDay');
    expect(find.textContaining('Даты *  13.09.2026'), findsOneWidget);
  });

  testWidgets('settings: helpers are one line until “More”', (tester) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('more-autoDetectHelper')));
    expect(find.byKey(const Key('helper-autoDetectHelper')), findsNothing);
    expect(find.textContaining('не чаще раза в час'), findsOneWidget);
    await tester.tap(find.byKey(const Key('more-autoDetectHelper')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('helper-autoDetectHelper')), findsOneWidget);
    expect(find.text('Скрыть'), findsOneWidget);
    await tester.tap(find.byKey(const Key('more-autoDetectHelper')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('helper-autoDetectHelper')), findsNothing);
  });

  testWidgets('dashboard: year arrows page years, next is off at today', (
    tester,
  ) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    await openCalendar(tester);
    expect(yearHeader('2026'), findsOneWidget);
    final next = tester.widget<IconButton>(find.byKey(const Key('yearNext')));
    expect(next.onPressed, isNull);
    await tapVisible(tester, 'yearPrev');
    expect(yearHeader('2025'), findsOneWidget);
    await tapVisible(tester, 'yearNext');
    expect(yearHeader('2026'), findsOneWidget);
    // Год по нажатию — прежний список лет.
    await tapVisible(tester, 'dashboardYear');
    expect(find.text('2024'), findsWidgets);
  });

  test('journal snapshot unchanged by ui polish', () {
    expect(JournalSnapshot().needsOnboarding, isTrue);
  });
}
