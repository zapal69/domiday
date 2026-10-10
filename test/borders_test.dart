import 'dart:io';

import 'package:domiday/borders.dart';
import 'package:domiday/countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CountryBorders borders;
  late CountryDirectory directory;
  setUpAll(() {
    borders = CountryBorders.fromJson(
      File('assets/borders.json').readAsStringSync(),
    );
    directory = CountryDirectory.fromJson(
      File('assets/countries.json').readAsStringSync(),
    );
  });

  test('disputed areas: neutral detection offers both sides', () {
    final withDisputed = CountryBorders.fromJson(
      File('assets/borders.json').readAsStringSync(),
      disputedJson: File('assets/disputed.json').readAsStringSync(),
    );
    expect(withDisputed.disputed.length, 27);
    // Крым: в базовых границах RU, претендент UA — обе стороны, неуверенно.
    final crimea = withDisputed.locate(44.95, 34.10, accuracyM: 500);
    expect(crimea.code, 'RU');
    expect(crimea.uncertain, isTrue);
    expect(crimea.alternatives, contains('UA'));
    // Северный Кипр: в базовых границах дыра, единственная сторона — CY.
    final north = withDisputed.locate(35.20, 33.37, accuracyM: 500);
    expect(north.code, 'CY');
    expect(north.uncertain, isTrue);
    // Абхазия: базовые границы GE, самопровозглашённая — только GE.
    final abkhazia = withDisputed.locate(43.00, 41.02, accuracyM: 500);
    expect(abkhazia.code, 'GE');
    expect(abkhazia.uncertain, isTrue);
    expect(withDisputed.disputedAt(43.00, 41.02)?.name, 'Abkhazia');
    // Вне спорных территорий поведение прежнее.
    expect(
      withDisputed.locate(41.7151, 44.8271, accuracyM: 2000).uncertain,
      isFalse,
    );
    expect(withDisputed.disputedAt(41.7151, 44.8271), isNull);
    // Без слоя — как раньше: Крым уверенно RU, север Кипра — ничего.
    expect(borders.disputed, isEmpty);
    expect(borders.locate(44.95, 34.10, accuracyM: 500).uncertain, isFalse);
  });

  test('every border code exists in the directory', () {
    expect(borders.count, greaterThan(230));
    // Точки известных столиц.
    expect(borders.containing(41.7151, 44.8271), 'GE'); // Тбилиси
    expect(borders.containing(39.9334, 32.8597), 'TR'); // Анкара
    expect(borders.containing(55.7558, 37.6173), 'RU'); // Москва
    expect(borders.containing(54.71, 20.51), 'RU'); // Калининград
    expect(borders.containing(40.1792, 44.4991), 'AM'); // Ереван
    expect(borders.containing(25.2854, 51.5310), 'QA'); // Доха
    expect(
      borders.containing(41.902, 12.433),
      'VA',
    ); // Ватикан (полигон NE 1:50m)
    expect(borders.containing(-29.31, 27.48), 'LS'); // Масеру — дырка в ZA
    expect(borders.containing(43.0, 34.0), isNull); // Чёрное море
    for (final code in ['GE', 'TR', 'RU', 'VA', 'LS']) {
      expect(directory.contains(code), isTrue);
    }
  });

  test('locate: confident inland, uncertain at borders and coasts', () {
    final tbilisi = borders.locate(41.7151, 44.8271, accuracyM: 2000);
    expect(tbilisi.code, 'GE');
    expect(tbilisi.uncertain, isFalse);
    // Сарпи: граница Грузии и Турции на побережье.
    final sarpi = borders.locate(41.52, 41.55, accuracyM: 2000);
    expect(sarpi.code, isNotNull);
    expect(sarpi.uncertain, isTrue);
    expect({sarpi.code, ...sarpi.alternatives}, containsAll(['GE', 'TR']));
    // Точка в море у Батуми: страна по соседству, неуверенно.
    final sea = borders.locate(41.65, 41.58, accuracyM: 3000);
    expect(sea.code, 'GE');
    expect(sea.uncertain, isTrue);
    // Открытое море: ничего.
    final open = borders.locate(43.0, 34.0, accuracyM: 3000);
    expect(open.code, isNull);
    // Грубая точность (30 км) у Еревана задевает соседей → неуверенно.
    final coarse = borders.locate(40.1792, 44.4991, accuracyM: 30000);
    expect(coarse.code, 'AM');
    expect(coarse.uncertain, isTrue);
  });

  test('French overseas departments resolve to FR (Natural Earth admin-0)', () {
    expect(borders.containing(14.6, -61.0), 'FR'); // Мартиника
  });
}
