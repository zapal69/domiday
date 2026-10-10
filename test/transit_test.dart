import 'dart:convert';
import 'dart:io';

import 'package:domiday/repository.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = Day(2026, 9, 13);
  Trip stay(String id, String c, Day a, Day d, {String? code}) =>
      Trip(id: id, country: c, countryCode: code, arrival: a, departure: d);
  Trip transit(
    String id,
    String c,
    Day a,
    Day d, {
    String? code,
    String city = '',
  }) => Trip(
    id: id,
    country: c,
    countryCode: code,
    city: city,
    arrival: a,
    departure: d,
    kind: TripKind.transit,
  );

  final snapshot = JournalSnapshot(
    trips: [
      stay('h', 'Россия', Day(2026, 1, 1), Day(2026, 3, 10), code: 'RU'),
      // 10 марта: выезд из России, пересадка в Турции, прилёт в Грузию.
      transit(
        't1',
        'Турция',
        Day(2026, 3, 10),
        Day(2026, 3, 10),
        code: 'TR',
        city: 'Стамбул',
      ),
      stay('g', 'Грузия', Day(2026, 3, 10), Day(2026, 4, 2), code: 'GE'),
      // Транзит через полночь: две даты.
      transit('t2', 'Катар', Day(2026, 4, 2), Day(2026, 4, 3), code: 'QA'),
    ],
    homeCountry: 'Россия',
    homeCountryCode: 'RU',
    current: CurrentStay(
      id: 'now',
      country: 'Россия',
      countryCode: 'RU',
      arrival: Day(2026, 4, 3),
      confirmedOn: today,
    ),
  );

  test('kind defaults to stay for schemas 1–3 and round-trips in schema 4', () {
    final json = snapshot.toJson();
    expect(json['schemaVersion'], 5);
    final trips = json['trips'] as List;
    expect(trips[0]['kind'], 'stay');
    expect(trips[1]['kind'], 'transit');
    final back = JournalSnapshot.fromJson(json, today);
    expect(back.trips[1].kind, TripKind.transit);
    expect(back.toJson(), json);
    // Схема 3 без kind: всё — пребывание, транзитом ничего не становится.
    final v3 = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    v3['schemaVersion'] = 3;
    for (final t in v3['trips'] as List) {
      (t as Map).remove('kind');
    }
    final old = JournalSnapshot.fromJson(v3, today);
    expect(old.trips.every((t) => t.kind == TripKind.stay), isTrue);
    // Неизвестный тип отвергается.
    (v3['trips'] as List).first['kind'] = 'flight';
    expect(() => JournalSnapshot.fromJson(v3, today), throwsFormatException);
  });

  test(
    'schema 4 is written only on save; v3 file stays intact on read',
    () async {
      final folder = await Directory.systemTemp.createTemp('domiday_v4_');
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/trips.json');
      final v3 =
          jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>;
      v3['schemaVersion'] = 3;
      for (final t in v3['trips'] as List) {
        (t as Map).remove('kind');
      }
      final raw = jsonEncode(v3);
      await file.writeAsString(raw);
      final repo = JsonTripRepository(
        directory: () async => folder,
        today: () => today,
      );
      final loaded = await repo.load();
      expect(await file.readAsString(), raw);
      await repo.save(loaded);
      final written =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(written['schemaVersion'], 5);
      expect(
        (written['trips'] as List).every((t) => t['kind'] == 'stay'),
        isTrue,
      );
    },
  );

  test('transit days count once in known and in their country', () {
    final s = YearSummary(snapshot, 2026, today);
    // Известные дни: 1 янв → 13 сен без пропусков = 256.
    expect(s.known.length, 256);
    expect(s.unknown, 0);
    expect(s.transit, {
      Day(2026, 3, 10).ordinal,
      Day(2026, 4, 2).ordinal,
      Day(2026, 4, 3).ordinal,
    });
    final turkey = s.countries.firstWhere((c) => c.key == 'tr');
    expect(turkey.days, 1);
    expect(turkey.trips, 1);
    expect(turkey.transits, 1);
    final georgia = s.countries.firstWhere((c) => c.key == 'ge');
    expect(georgia.transits, 0);
    // 10 марта принадлежит трём странам, но в известных днях один раз.
    expect(s.overlap, 2); // 10 марта и 3 апреля: дома и вне дома
    // Транзит вне дома входит в «вне дома»; дом не удваивается.
    expect(s.away.contains(Day(2026, 3, 10).ordinal), isTrue);
    expect(s.home.contains(Day(2026, 3, 10).ordinal), isTrue);
  });

  test('eventsOn lists every record of the day, transits after stays', () {
    final e = eventsOn(snapshot, Day(2026, 3, 10), today);
    expect(e.map((x) => x.id), ['h', 'g', 't1']);
    expect(e[2].kind, TripKind.transit);
    expect(e[2].city, 'Стамбул');
    final midnight = eventsOn(snapshot, Day(2026, 4, 3), today);
    expect(midnight.map((x) => x.id), ['t2', 'now']);
    expect(midnight.last.isCurrent, isTrue);
    expect(midnight.last.end, isNull);
    // Пустой день, будущий день, день до приезда текущего пребывания.
    expect(eventsOn(snapshot, Day(2025, 12, 31), today), isEmpty);
    expect(eventsOn(snapshot, Day(2026, 9, 14), today), isEmpty);
    final unknownArrival = snapshot.copyWith(
      trips: [],
      current: CurrentStay(
        id: 'now',
        country: 'Россия',
        arrival: null,
        confirmedOn: today,
      ),
    );
    expect(eventsOn(unknownArrival, today, today), isEmpty);
  });
}
