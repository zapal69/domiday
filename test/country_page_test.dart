import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:domiday/year_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show tapVisible;
import 'widget_test.dart' show MemoryRepository, launch, reveal;

void main() {
  JournalSnapshot journal() => JournalSnapshot(
    homeCountry: 'Россия',
    homeCountryCode: 'RU',
    current: CurrentStay(
      id: 'now',
      country: 'Россия',
      countryCode: 'RU',
      arrival: Day(2026, 8, 20),
      confirmedOn: Day(2026, 9, 13),
    ),
    trips: [
      Trip(
        id: 'cy1',
        country: 'Кипр',
        countryCode: 'CY',
        arrival: Day(2026, 5, 1),
        departure: Day(2026, 5, 20),
      ),
      Trip(
        id: 'cy2',
        country: 'Кипр',
        countryCode: 'CY',
        arrival: Day(2025, 12, 28),
        departure: Day(2026, 1, 3),
      ),
      Trip(
        id: 'ge',
        country: 'Грузия',
        countryCode: 'GE',
        arrival: Day(2026, 6, 1),
        departure: Day(2026, 6, 12),
      ),
      Trip(
        id: 'tr',
        country: 'Турция',
        countryCode: 'TR',
        arrival: Day(2026, 5, 18),
        departure: Day(2026, 5, 19),
        kind: TripKind.transit,
      ),
    ],
  );

  testWidgets('country page: days, calendar paints only this country', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false);
    await tapVisible(tester, 'country-stat-cy');
    expect(find.byKey(const Key('countryTitle')), findsOneWidget);
    expect(find.text('Кипр'), findsWidgets);
    // 20 дней в мае + 3 дня января в 2026; за всё время ещё 4 дня декабря.
    expect(find.text('23 дн. в 2026 · 27 дн. за всё время'), findsOneWidget);
    final calendar = tester.widget<YearCalendar>(find.byType(YearCalendar));
    final data = YearCalendarData(
      calendar.summary,
      calendar.today,
      snapshot: calendar.snapshot,
      slots: calendar.slots,
    );
    expect(data.paintedCount, 23);
    // Дни Грузии и транзит Турции в календаре страны не закрашены.
    expect(data.kindOf(6, 5), DayKind.unknown);
    expect(data.countriesOf(5, 18).map((m) => m.code), ['CY']);
    // Записи страны ниже; журнал по кнопке.
    await reveal(tester, find.byKey(const Key('trip-cy2')));
    expect(find.byKey(const Key('trip-cy1')), findsOneWidget);
    expect(find.byKey(const Key('trip-ge')), findsNothing);
    await reveal(tester, find.byKey(const Key('countryJournal')));
    await tester.tap(find.byKey(const Key('countryJournal')));
    await tester.pumpAndSettle();
    expect(find.text('Найдено поездок: 2'), findsOneWidget);
  });

  testWidgets('calendar: full month names when they fit, else short', (
    tester,
  ) async {
    // Тестовый шрифт даёт букве 1em: «Сентябрь» = 96 px при 12 px, а
    // колонка месяца на 390 px — 91 px, поэтому «широкий» экран — 430.
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false, width: 430);
    await reveal(tester, find.byKey(const Key('monthName-1')));
    expect(find.text('Январь'), findsOneWidget);
    expect(find.text('Сентябрь'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // 320 px при 180 %: два месяца в ряд, но «Сентябрь» (173 px) шире.
    await launch(tester, repo, journal: false, width: 320, scale: 1.8);
    await reveal(tester, find.byKey(const Key('monthName-1')));
    expect(find.text('янв'), findsOneWidget);
    expect(find.text('Январь'), findsNothing);
  });

  testWidgets('expanded month shows country codes, not flags', (tester) async {
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false);
    await tapVisible(tester, 'month-5');
    await reveal(tester, find.byKey(const Key('day-2026-5-18')));
    final cell = find.byKey(const Key('day-2026-5-18'));
    // Пребывание Кипр + транзит Турция: коды буквами, флагов нет.
    expect(
      find.descendant(of: cell, matching: find.text('CY')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cell, matching: find.text('TR')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cell, matching: find.byKey(const Key('flag-CY'))),
      findsNothing,
    );
  });
}
