import 'dart:io';
import 'dart:typed_data';

import 'package:domiday/borders.dart';
import 'package:domiday/globe.dart';
import 'package:domiday/world_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_test.dart' show journal;
import 'widget_test.dart' show MemoryRepository, launch, testBorders;

void main() {
  late GlobeData data;
  setUpAll(() {
    final borders = CountryBorders.fromJson(
      File('assets/borders.json').readAsStringSync(),
      disputedJson: File('assets/disputed.json').readAsStringSync(),
    );
    data = GlobeData.build(borders, WorldMapData.build(borders));
  });

  test('orthographic: round trip, centre, visibility', () {
    final p = Orthographic(20, 30);
    expect(p.project(20, 30), Offset.zero);
    for (final (lon, lat) in [(44.8, 41.7), (-3.7, 40.4), (33.4, 35.2)]) {
      final q = p.project(lon, lat);
      final back = p.inverse(q.dx, q.dy)!;
      expect(back.$1, closeTo(lon, 1e-6));
      expect(back.$2, closeTo(lat, 1e-6));
      expect(p.cosDistance(lon, lat), greaterThan(0));
    }
    // Антипод скрыт, точка вне шара — null.
    expect(p.cosDistance(-160, -30), lessThan(0));
    expect(p.inverse(1.2, 0), isNull);
    // Восток правее, север выше.
    expect(p.project(40, 30).dx, greaterThan(0));
    expect(p.project(20, 50).dy, greaterThan(0));
  });

  test('simplification keeps the ends and removes detail', () {
    final ring = Float64List.fromList([
      for (var i = 0; i <= 100; i++) ...[i / 10, (i % 2) * 0.01],
    ]);
    final s = simplifyRing(ring, 0.05);
    expect(s.length, lessThan(ring.length ~/ 4));
    expect(s.sublist(0, 2), ring.sublist(0, 2));
    expect(s.sublist(s.length - 2), ring.sublist(ring.length - 2));
    expect(simplifyRing(ring, 0), same(ring));
  });

  test('paths: hidden hemisphere is not drawn, visible countries are', () {
    final g = Globe(const Size(400, 400), const GlobeView(lon: 20, lat: 45));
    // Антарктида из северного полушария скрыта целиком — иначе прижатые
    // к лимбу точки закрасили бы весь диск.
    expect(g.path(data.shape('AQ')!, 0.2), isNull);
    expect(g.path(data.shape('NZ')!, 0.2), isNull);
    final ru = g.path(data.shape('RU')!, 0.2)!;
    final b = ru.getBounds();
    expect(b.left, greaterThanOrEqualTo(g.center.dx - g.radius - 1));
    expect(b.right, lessThanOrEqualTo(g.center.dx + g.radius + 1));
    expect(b.width, greaterThan(g.radius * .4));
    // Грузия видна и невелика; попадание в её центр даёт её код.
    final ge = data.shape('GE')!;
    final c = g.toScreen(ge.centerLon, ge.centerLat);
    final geo = g.toGeo(c)!;
    expect(data.flat.hitTest(WorldMapData.toCanvas(geo.$1, geo.$2)), 'GE');
    // Уровни детализации: чем крупнее, тем точнее.
    expect(GlobeData.levelFor(1.0), 0.6);
    expect(GlobeData.levelFor(0.1), 0.06);
    expect(GlobeData.levelFor(0.01), 0);
  });

  test('fit: Cyprus fills about half of the view', () {
    final cy = data.shape('CY')!;
    final v = GlobeView.fit(cy, const Size(400, 600));
    expect(v.lon, closeTo(33.2, 0.5));
    expect(v.lat, closeTo(35.1, 0.5));
    expect(v.zoom, greaterThan(20));
    expect(v.zoom, lessThanOrEqualTo(GlobeView.maxZoom));
    final ru = GlobeView.fit(data.shape('RU')!, const Size(400, 600));
    expect(ru.zoom, closeTo(GlobeView.minZoom, 0.2));
    // Интерполяция через антимеридиан идёт коротким путём.
    final mid = GlobeView.lerp(
      const GlobeView(lon: 170),
      const GlobeView(lon: -170),
      0.5,
    );
    expect(mid.lon.abs(), closeTo(180, 1e-9));
  });

  testWidgets('map page: globe toggle, tap on the globe, search flies', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false, borders: testBorders);
    await tester.tap(find.byKey(const Key('openMap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('worldMap')), findsOneWidget);
    expect(find.byKey(const Key('globe')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('mapView')),
        matching: find.byIcon(Icons.public_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globe')), findsOneWidget);
    // Нажатие на Грузию на шаре открывает её страницу.
    final rect = tester.getRect(find.byKey(const Key('globe')));
    final g = Globe(rect.size, const GlobeView());
    final ge = data.shape('GE')!;
    await tester.tapAt(rect.topLeft + g.toScreen(ge.centerLon, ge.centerLat));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryTitle')), findsOneWidget);
    expect(find.text('Грузия'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Поиск: выбранная страна оказывается в центре шара.
    await tester.tap(find.byKey(const Key('mapSearch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mapSearchField')), 'Анд');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mapFind-AD')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mapFind-AD')));
    await tester.pumpAndSettle();
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();
    expect(find.text('Андорра'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // На весь экран открывается шар, вид переключается обратно на карту.
    await tester.tap(find.byKey(const Key('mapFullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globeFullscreen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mapFullscreenView')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globeFullscreen')), findsNothing);
    expect(find.byKey(const Key('worldMap')), findsOneWidget);
    expect(find.byKey(const Key('mapFullscreenSearch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mapFullscreenClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globe')), findsOneWidget);
  });

  testWidgets('flat map: search zooms to the country', (tester) async {
    final repo = MemoryRepository()..snapshot = journal();
    await launch(tester, repo, journal: false, borders: testBorders);
    await tester.tap(find.byKey(const Key('openMap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mapSearch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mapSearchField')), 'Груз');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mapFind-GE')));
    await tester.pumpAndSettle();
    // Грузия в центре области просмотра.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('cardMap'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryTitle')), findsOneWidget);
    expect(find.text('Грузия'), findsWidgets);
  });

  Future<void> search(WidgetTester tester, String btn, String q, String code) async {
    await tester.tap(find.byKey(Key(btn)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mapSearchField')), q);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('mapFind-$code')));
    await tester.pumpAndSettle();
  }

  Future<void> expectCentre(WidgetTester tester, Finder area, String name) async {
    await tester.tapAt(tester.getCenter(area));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryTitle')), findsOneWidget, reason: name);
    expect(find.text(name), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('full screen: search positions the globe and the flat map', (
    tester,
  ) async {
    await launch(
      tester,
      MemoryRepository()..snapshot = journal(),
      journal: false,
      borders: testBorders,
    );
    await tester.tap(find.byKey(const Key('openMap')));
    await tester.pumpAndSettle();
    // Шар на вкладке, потом на весь экран: команду поиска выполняет
    // видимый шар, а не тот, что остался под страницей (ошибка 0.15.0:
    // на весь экран ничего не происходило, страна появлялась после
    // возврата на вкладку).
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('mapView')),
        matching: find.byIcon(Icons.public_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await search(tester, 'mapSearch', 'Груз', 'GE');
    await expectCentre(tester, find.byKey(const Key('globe')), 'Грузия');
    await tester.tap(find.byKey(const Key('mapFullscreen')));
    await tester.pumpAndSettle();
    await search(tester, 'mapFullscreenSearch', 'Тур', 'TR');
    await expectCentre(tester, find.byKey(const Key('globeFullscreen')), 'Турция');
    // Плоская карта на весь экран.
    await tester.tap(find.byKey(const Key('mapFullscreenView')));
    await tester.pumpAndSettle();
    await search(tester, 'mapFullscreenSearch', 'Груз', 'GE');
    await expectCentre(tester, find.byType(InteractiveViewer), 'Грузия');
    await tester.tap(find.byKey(const Key('mapFullscreenClose')));
    await tester.pumpAndSettle();
    await search(tester, 'mapSearch', 'Тур', 'TR');
    await expectCentre(tester, find.byKey(const Key('globe')), 'Турция');
  });

  testWidgets('card map and globe take the gesture, the page does not scroll', (
    tester,
  ) async {
    await launch(
      tester,
      MemoryRepository()..snapshot = journal(),
      journal: false,
      borders: testBorders,
    );
    await tester.tap(find.byKey(const Key('openMap')));
    await tester.pumpAndSettle();
    final list = find.byKey(const Key('mapScroll'));
    double offset() => tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    ).position.pixels;
    final card = find.byKey(const Key('cardMap'));
    Matrix4 matrix() => tester
        .widget<Transform>(
          find.descendant(of: card, matching: find.byType(Transform)).first,
        )
        .transform;
    // Один палец вертикально по карте: страница на месте.
    await tester.timedDrag(card, const Offset(0, -120), const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(offset(), 0);
    // Щипок: масштаб растёт, но не больше 12.
    final c = tester.getCenter(card);
    final a = await tester.startGesture(c - const Offset(20, 0));
    final b = await tester.startGesture(c + const Offset(20, 0));
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(c - Offset(20.0 + 8 * i, 0));
      await b.moveTo(c + Offset(20.0 + 8 * i, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(matrix().storage[0], greaterThan(1.5));
    expect(matrix().storage[0], lessThanOrEqualTo(12));
    expect(offset(), 0);
    // Нажатие после масштабирования по-прежнему открывает страну.
    await search(tester, 'mapSearch', 'Груз', 'GE');
    await expectCentre(tester, card, 'Грузия');
    // Шар: вертикальный жест тоже не прокручивает страницу.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('mapView')),
        matching: find.byIcon(Icons.public_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.byKey(const Key('globe')),
      const Offset(0, -120),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(offset(), 0);
    // А вне карты страница прокручивается.
    await tester.drag(find.byKey(const Key('mapRange')), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(0));
  });
}
