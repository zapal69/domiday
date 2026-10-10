import 'package:domiday/share.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:domiday/world_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart'
    show MemoryRepository, launch, testBorders, testDirectory;

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
      id: 'ge',
      country: 'Грузия',
      countryCode: 'GE',
      arrival: Day(2026, 6, 1),
      departure: Day(2026, 6, 12),
    ),
    Trip(
      id: 'ad',
      country: 'Андорра',
      countryCode: 'AD',
      arrival: Day(2025, 3, 1),
      departure: Day(2025, 3, 3),
    ),
    Trip(
      id: 'tr',
      country: 'Турция',
      countryCode: 'TR',
      arrival: Day(2026, 6, 12),
      departure: Day(2026, 6, 13),
      kind: TripKind.transit,
    ),
  ],
);

/// Точка карты (lon, lat) → координата экрана внутри виджета карты.
Offset at(WidgetTester tester, double lon, double lat) {
  final box = tester.getRect(find.byKey(const Key('worldMap')));
  final p = WorldMapData.toCanvas(lon, lat) * (box.width / WorldMapData.width);
  return box.topLeft + p;
}

void main() {
  testWidgets(
    'map tab counts stays, transit is not a visit; page opens countries',
    (tester) async {
      final repo = MemoryRepository()..snapshot = journal();
      final share = FakeShareService();
      await launch(
        tester,
        repo,
        journal: false,
        borders: testBorders,
        share: share,
      );
      await tester.tap(find.byKey(const Key('openMap')));
      await tester.pumpAndSettle();
      final total = testDirectory.all.length;
      // Дом, Грузия и Андорра — три; Турция только транзитом — не считается.
      expect(find.text('3 из $total'), findsWidgets);
      expect(find.byKey(const Key('mapScroll')), findsOneWidget);
      // Одна фраза сверху объясняет экран.
      expect(
        find.text(
          'Закрашены страны, где вы были. Нажмите на страну — увидите её дни.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mapChip-GE')), findsOneWidget);
      expect(find.byKey(const Key('mapChip-TR')), findsOneWidget);
      // Год 2026: Андорры (2025) нет.
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.textContaining('где вы были в 2026 году'), findsOneWidget);
      expect(find.text('2 из $total'), findsWidgets);
      expect(find.byKey(const Key('mapChip-AD')), findsNothing);
      await tester.tap(find.text('За всё время'));
      await tester.pumpAndSettle();
      // Нажатие на Грузию открывает её страницу.
      await tester.tapAt(at(tester, 44.8271, 41.7151));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('countryTitle')), findsOneWidget);
      expect(find.text('Грузия'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // Андорра: под пальцем несколько мелких стран — список на выбор.
      await tester.tapAt(at(tester, 1.70, 42.35));
      await tester.pumpAndSettle();
      expect(find.text('Какая страна?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mapPick-AD')));
      await tester.pumpAndSettle();
      expect(find.text('Андорра'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // Море — ничего не происходит.
      await tester.tapAt(at(tester, 0, -60));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mapScroll')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('countryTitle')), findsNothing);
      // Поделиться — PNG в системное меню (рендер вне тестового цикла).
      await tester.tap(find.byKey(const Key('mapShare')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      expect(share.fileName, 'domiday-map.png');
      expect(share.shared!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    },
  );

  testWidgets('app bar icon opens the map; full screen opens and closes', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false, borders: testBorders);
    await tester.tap(find.byKey(const Key('openMap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mapScroll')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mapFullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mapFullscreenPage')), findsOneWidget);
    expect(find.textContaining('из '), findsWidgets);
    // Нажатие на Грузию работает и на весь экран.
    await tester.tapAt(at(tester, 44.8271, 41.7151));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryTitle')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mapFullscreenClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mapFullscreenPage')), findsNothing);
    expect(find.byKey(const Key('mapScroll')), findsOneWidget);
  });

  testWidgets('no borders — no map tab', (tester) async {
    await launch(
      tester,
      MemoryRepository()..snapshot = journal(),
      journal: false,
    );
    expect(find.byKey(const Key('openMap')), findsNothing);
    expect(find.byKey(const Key('navCalendar')), findsOneWidget);
  });
}
