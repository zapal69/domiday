import 'dart:io';

import 'package:domiday/borders.dart';
import 'package:domiday/world_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CountryBorders borders;
  late WorldMapData data;
  setUpAll(() {
    borders = CountryBorders.fromJson(
      File('assets/borders.json').readAsStringSync(),
      disputedJson: File('assets/disputed.json').readAsStringSync(),
    );
    data = WorldMapData.build(borders);
  });

  test('Equal Earth: extents, equator and poles', () {
    expect(EqualEarth.project(0, 0), Offset.zero);
    final east = EqualEarth.project(180, 0);
    expect(east.dx, closeTo(EqualEarth.halfWidth, 0.001));
    expect(east.dy, closeTo(0, 1e-9));
    final north = EqualEarth.project(0, 90);
    expect(north.dx, closeTo(0, 1e-9));
    expect(north.dy, closeTo(-EqualEarth.halfHeight, 0.001));
    // Симметрия и монотонность: восток правее, север выше.
    expect(EqualEarth.project(-90, 45).dx, lessThan(0));
    expect(
      EqualEarth.project(30, 60).dy,
      lessThan(EqualEarth.project(30, 30).dy),
    );
  });

  test(
    'map data: every country and disputed area has a path inside the canvas',
    () {
      expect(data.countries.length, borders.count);
      expect(data.disputed.length, 27);
      final canvas = Rect.fromLTWH(
        0,
        0,
        WorldMapData.width,
        WorldMapData.height,
      );
      for (final s in [...data.countries, ...data.disputed]) {
        expect(s.bounds.isEmpty, isFalse, reason: s.key);
        expect(
          canvas.inflate(1).contains(s.bounds.topLeft),
          isTrue,
          reason: s.key,
        );
        expect(
          canvas.inflate(1).contains(s.bounds.bottomRight),
          isTrue,
          reason: s.key,
        );
      }
      // Россия разрезана по 180°: её рамка не шире карты (нет линии через всю карту).
      final ru = data.countries.firstWhere((s) => s.key == 'RU');
      expect(ru.bounds.width, lessThan(WorldMapData.width * 0.9));
    },
  );

  test('political colours: Russia reddish, neighbours differ', () {
    expect(data.colorIndex['RU'], 0);
    expect(data.politicalColor('RU'), politicalPalette[0]);
    for (final (a, b) in [
      ('RU', 'CN'),
      ('RU', 'KZ'),
      ('RU', 'UA'),
      ('CN', 'KZ'),
      ('CN', 'IN'),
      ('FR', 'ES'),
      ('FR', 'DE'),
      ('GE', 'AM'),
      ('GE', 'AZ'),
      ('GE', 'TR'),
      ('AM', 'AZ'),
    ]) {
      expect(data.colorIndex[a], isNot(data.colorIndex[b]), reason: '$a vs $b');
    }
    // У каждой страны есть цвет, и это не чёрный.
    for (final s in data.countries) {
      final c = data.politicalColor(s.key);
      expect(politicalPalette, contains(c), reason: s.key);
    }
  });

  test('hit test: capitals resolve to their countries, enclaves win', () {
    String? at(double lat, double lon) =>
        data.hitTest(WorldMapData.toCanvas(lon, lat));
    expect(at(41.7151, 44.8271), 'GE');
    expect(at(55.7558, 37.6173), 'RU');
    expect(at(-29.31, 27.48), 'LS');
    expect(at(43.0, 34.0), isNull);
    // Рядом с Андоррой в круге 14 px есть несколько мелких стран.
    final near = data.near(WorldMapData.toCanvas(1.52, 42.51), 14);
    expect(near, contains('AD'));
    expect(near.length, greaterThan(1));
  });

  test('labels: mainland anchor, not the bounding box centre', () {
    final fr = data.shape('FR')!;
    // Заморские территории раздвигают общую рамку; «материк» — Европа.
    expect(fr.main.width, lessThan(fr.bounds.width / 2));
    final paris = WorldMapData.toCanvas(2.35, 48.86);
    expect(fr.main.contains(paris), isTrue);
    final ru = data.shape('RU')!;
    expect(ru.main.contains(WorldMapData.toCanvas(37.6, 55.75)), isTrue);
  });

  testWidgets('painter draws fills, transit hatching and disputed outlines', (
    tester,
  ) async {
    final style = WorldMapStyle(
      fills: const {'GE': Colors.orange, 'RU': Colors.black},
      transit: const {'TR'},
      land: const Color(0xFFDDDDDD),
      line: const Color(0xFF999999),
      disputedLine: const Color(0xFF333333),
      background: Colors.white,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 390,
            child: WorldMap(data: data, style: style, onTap: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('worldMap')), findsOneWidget);
    final size = tester.getSize(find.byKey(const Key('worldMap')));
    expect(size.width, 390);
    expect(
      size.height,
      closeTo(390 * WorldMapData.height / WorldMapData.width, 1),
    );
  });
}
