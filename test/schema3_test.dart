import 'dart:convert';
import 'dart:io';

import 'package:domiday/countries.dart';
import 'package:domiday/journal_controller.dart';
import 'package:domiday/repository.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository;

void main() {
  final today = Day(2026, 9, 13);
  late Directory folder;
  late CountryDirectory directory;
  setUpAll(() {
    directory = CountryDirectory.fromJson(
      File('assets/countries.json').readAsStringSync(),
    );
  });
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('domiday_v3_');
  });
  tearDown(() async => folder.delete(recursive: true));

  JsonTripRepository repo() =>
      JsonTripRepository(directory: () async => folder, today: () => today);

  final v2 = {
    'schemaVersion': 2,
    'trips': [
      {
        'id': 'a',
        'country': '  Россия ',
        'city': '',
        'note': 'n',
        'arrival': '2026-01-01',
        'departure': '2026-01-12',
      },
      {
        'id': 'b',
        'country': 'Russia',
        'city': 'Moscow',
        'note': '',
        'arrival': '2026-02-01',
        'departure': '2026-02-03',
      },
      {
        'id': 'c',
        'country': 'Абхазия',
        'city': '',
        'note': '',
        'arrival': '2026-03-01',
        'departure': '2026-03-02',
      },
    ],
    'homeCountry': 'россия',
    'current': {
      'id': 'now',
      'country': 'Грузия',
      'arrival': '2026-08-20',
      'confirmedOn': '2026-09-13',
      'notBefore': null,
    },
    'undated': [
      {'id': 'u', 'country': 'Turkey', 'departure': '2026-05-01'},
    ],
  };

  test('v2 file reads with null codes and is not rewritten', () async {
    final file = File('${folder.path}/trips.json');
    final raw = jsonEncode(v2);
    await file.writeAsString(raw);
    final loaded = await repo().load();
    expect(loaded.trips.map((t) => t.countryCode), [null, null, null]);
    expect(loaded.homeCountryCode, isNull);
    expect(loaded.current!.countryCode, isNull);
    expect(loaded.undated.single.countryCode, isNull);
    expect(await file.readAsString(), raw);
    // Без кодов «Россия» и «Russia» — разные группы, как в 0.4.
    expect(YearSummary(loaded, 2026, today).countries.length, 4);
  });

  test('assignCodes adds codes by exact match only, keeps every text', () {
    final loaded = JournalSnapshot.fromJson(v2, today);
    final coded = loaded.assignCodes(directory.match);
    expect(identical(coded, loaded), isFalse);
    expect(coded.trips.map((t) => t.countryCode), ['RU', 'RU', null]);
    expect(coded.trips.map((t) => t.country), [
      '  Россия ',
      'Russia',
      'Абхазия',
    ]);
    expect(coded.homeCountry, 'россия');
    expect(coded.homeCountryCode, 'RU');
    expect(coded.current!.countryCode, 'GE');
    expect(coded.undated.single.countryCode, 'TR');
    // Группировка по коду: «Россия» и «Russia» — одна страна.
    final summary = YearSummary(coded, 2026, today);
    // Сортировка по дням: текущее пребывание в Грузии (25 дн.) впереди.
    expect(summary.countries.map((c) => c.key), ['ge', 'ru', 'абхазия']);
    final russia = summary.countries.firstWhere((c) => c.key == 'ru');
    expect(russia.code, 'RU');
    expect(russia.trips, 2);
    expect(summary.home.length, 12 + 3);
    expect(summary.countries.last.code, isNull);
    // Повторный вызов без изменений возвращает тот же объект.
    expect(identical(coded.assignCodes(directory.match), coded), isTrue);
  });

  test(
    'first save after v2 writes v3 with codes and untouched texts',
    () async {
      final file = File('${folder.path}/trips.json');
      await file.writeAsString(jsonEncode(v2));
      final r = repo();
      final coded = (await r.load()).assignCodes(directory.match);
      await r.save(coded);
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(json['schemaVersion'], 5);
      expect(json['homeCountry'], 'россия');
      expect(json['homeCountryCode'], 'RU');
      final trips = json['trips'] as List;
      expect(trips[0]['country'], '  Россия ');
      expect(trips[0]['countryCode'], 'RU');
      expect(trips[2]['countryCode'], isNull);
      expect((json['current'] as Map)['countryCode'], 'GE');
      // v3 читается обратно один в один.
      final again = await repo().load();
      expect(again.toJson(), coded.toJson());
    },
  );

  test('v3 rejects malformed codes without replacing the file', () async {
    final bad = Map<String, dynamic>.from(v2)..['schemaVersion'] = 3;
    bad['homeCountryCode'] = 'russia';
    final file = File('${folder.path}/trips.json');
    await file.writeAsString(jsonEncode(bad));
    await expectLater(repo().load(), throwsFormatException);
    expect(jsonDecode(await file.readAsString()), bad);
    final badTrip = jsonDecode(jsonEncode(v2)) as Map<String, dynamic>;
    (badTrip['trips'] as List).first['countryCode'] = 7;
    expect(
      () => JournalSnapshot.fromJson(badTrip, today),
      throwsFormatException,
    );
  });

  test('controller assigns codes on load; commit persists v3', () async {
    final memory = MemoryRepository()
      ..snapshot = JournalSnapshot.fromJson(v2, today);
    final controller = JournalController(
      memory,
      () => today,
      match: directory.match,
    );
    await controller.load();
    expect(controller.snapshot.homeCountryCode, 'RU');
    expect(memory.writes, 0);
    await controller.commit(controller.snapshot);
    expect(memory.snapshot.toJson()['schemaVersion'], 5);
  });

  test('copyWith: new home text resets the code unless given', () {
    final coded = JournalSnapshot.fromJson(
      v2,
      today,
    ).assignCodes(directory.match);
    expect(coded.copyWith(trips: []).homeCountryCode, 'RU');
    expect(coded.copyWith(homeCountry: 'Georgia').homeCountryCode, isNull);
    expect(
      coded.copyWith(homeCountry: 'Georgia', homeCountryCode: 'GE').homeKey,
      'ge',
    );
  });

  test('transition keeps codes and rejects the same country by code', () {
    final coded = JournalSnapshot.fromJson(
      v2,
      today,
    ).assignCodes(directory.match);
    expect(
      () => coded.transition('Georgia', today, today, 'x', countryCode: 'GE'),
      throwsA(isA<Object>()),
    );
    final next = coded.transition(
      'Armenia',
      today,
      today,
      'x',
      countryCode: 'AM',
    );
    expect(next.current!.countryCode, 'AM');
    expect(next.trips.last.countryCode, 'GE');
  });
}
