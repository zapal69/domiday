import 'package:domiday/locator.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show launch, MemoryRepository, reveal;

void main() {
  testWidgets('current card: a long country name is not broken mid-word', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(
        homeCountry: 'Россия',
        homeCountryCode: 'RU',
        current: CurrentStay(
          id: 'current',
          country: 'Великобритания',
          countryCode: 'GB',
          arrival: Day(2026, 8, 20),
          confirmedOn: Day(2026, 9, 13),
        ),
      );
    await launch(tester, repo, journal: false);
    final name = find.byKey(const Key('currentCountry'));
    expect(name, findsOneWidget);
    expect(tester.widget<Text>(name).data, 'Великобритания');
    // Одна строка (две строки были бы выше 40 px), флаг справа в той же строке.
    expect(tester.getSize(name).height, lessThan(40));
    final flag = tester.getTopLeft(
      find.descendant(
        of: find.byKey(const Key('currentStay')),
        matching: find.byKey(const Key('flag-GB')),
      ),
    );
    expect(flag.dy, lessThan(tester.getTopLeft(name).dy + 10));
    expect(flag.dx, greaterThan(tester.getTopRight(name).dx));
  });

  JournalSnapshot byCountry() => JournalSnapshot(
    homeCountry: 'Россия',
    homeCountryCode: 'RU',
    current: CurrentStay(
      id: 'current',
      country: 'Россия',
      countryCode: 'RU',
      arrival: Day(2026, 8, 20),
      confirmedOn: Day(2026, 9, 13),
    ),
    trips: [
      Trip(
        id: 'gb',
        country: 'Великобритания',
        countryCode: 'GB',
        city: '',
        note: '',
        arrival: Day(2026, 6, 1),
        departure: Day(2026, 6, 12),
      ),
      Trip(
        id: 'cy',
        country: 'Кипр',
        countryCode: 'CY',
        city: '',
        note: '',
        arrival: Day(2026, 6, 19),
        departure: Day(2026, 6, 19),
      ),
    ],
  );

  testWidgets('by country: days at the right edge, name whole at 400', (
    tester,
  ) async {
    // Тестовый шрифт даёт каждой букве ширину 1em: на 390 px
    // «Великобритания» (14 · 17 = 238 px) ровно упирается в ширину
    // колонки, поэтому проверяем на 400 px.
    final repo = MemoryRepository()..snapshot = byCountry();
    await launch(tester, repo, journal: false, width: 400);
    await reveal(tester, find.byKey(const Key('country-stat-gb')));
    final name = find.byKey(const Key('country-name-gb'));
    final days = find.byKey(const Key('country-days-gb'));
    expect(tester.widget<Text>(name).data, 'Великобритания');
    // Одна строка полного размера: шрифт не мельчает, слово не рвётся.
    expect(tester.widget<Text>(name).style?.fontSize, 17);
    expect(tester.getSize(name).height, lessThan(30));
    // Длинное название не умещается рядом с днями — дни во второй строке,
    // у правого края карточки: 400 − 20 (поле) − 16 (отступ строки) = 364.
    expect(
      tester.getTopLeft(days).dy,
      greaterThan(tester.getBottomLeft(name).dy - 1),
    );
    expect(tester.getTopRight(days).dx, closeTo(364, 1));
    // Короткое название — дни в той же строке, прижаты к шеврону:
    // 364 − 22 (шеврон) − 4 = 338.
    final short = find.byKey(const Key('country-name-cy'));
    final shortDays = find.byKey(const Key('country-days-cy'));
    expect(tester.getTopRight(shortDays).dx, closeTo(338, 1));
    expect(
      tester.getTopLeft(shortDays).dy,
      lessThan(tester.getBottomLeft(short).dy),
    );
  });

  testWidgets('by country at 320/180%: name whole, days on the second line', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = byCountry();
    await launch(tester, repo, journal: false, width: 320, scale: 1.8);
    await reveal(tester, find.byKey(const Key('country-stat-gb')));
    final name = find.byKey(const Key('country-name-gb'));
    final days = find.byKey(const Key('country-days-gb'));
    expect(tester.widget<Text>(name).data, 'Великобритания');
    // Название не рвётся: одна строка (14 px · 1,8 · 1,25 ≈ 32 px).
    expect(tester.getSize(name).height, lessThan(40));
    // Дни — ниже названия и у правого края: 320 − 20 (поле) − 16 = 284.
    expect(
      tester.getTopLeft(days).dy,
      greaterThan(tester.getBottomLeft(name).dy - 1),
    );
    expect(tester.getTopRight(days).dx, closeTo(284, 1));
  });

  testWidgets('current card: multi-word names wrap by words at 320/180%', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(
        homeCountry: 'Россия',
        homeCountryCode: 'RU',
        current: CurrentStay(
          id: 'current',
          country: 'Босния и Герцеговина',
          countryCode: 'BA',
          arrival: Day(2026, 8, 20),
          confirmedOn: Day(2026, 9, 13),
        ),
      );
    await launch(tester, repo, journal: false, width: 320, scale: 1.8);
    final name = find.byKey(const Key('currentCountry'));
    expect(tester.widget<Text>(name).data, 'Босния и Герцеговина');
    // Две строки целыми словами, без переноса внутри слова.
    expect(tester.getSize(name).height, greaterThan(40));
    expect(tester.getSize(name).height, lessThan(130));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detect row: candidate → «Нет» dismisses without writing', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final settings = MemorySettingsRepository(
      AppSettings(
        autoDetect: false,
        candidate: Candidate(
          code: 'CY',
          detectedOn: Day(2026, 9, 13),
          accuracyM: 1500,
          uncertain: false,
        ),
      ),
    );
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: FakeLocationSource(const Unavailable()),
    );
    expect(find.byKey(const Key('candidateBanner')), findsOneWidget);
    expect(find.text('Похоже, вы здесь: Кипр'), findsOneWidget);
    expect(find.byKey(const Key('detectNow')), findsNothing);
    await tester.tap(find.byKey(const Key('candidateDismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('candidateBanner')), findsNothing);
    expect(settings.settings.candidate!.dismissed, isTrue);
    // Тихое состояние: подсказка и кнопка «Проверить».
    expect(find.byKey(const Key('detectNow')), findsOneWidget);
    expect(find.text('Проверить'), findsOneWidget);
    expect(repo.writes, 0);
  });
}
