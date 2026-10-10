import 'dart:convert';

import 'package:domiday/snapshot.dart';
import 'package:domiday/timeline_import.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show testBorders, testDirectory;

// Точки внутри стран (вдали от границ).
const tbilisi = '41.7151°, 44.8271°';
const yerevan = '40.1792°, 44.4991°';
const ankara = '39.9334°, 32.8597°';
const moscow = '55.7558°, 37.6173°';

Map<String, Object?> visit(String place, String start, String end) => {
  'startTime': start,
  'endTime': end,
  'visit': {
    'topCandidate': {
      'placeLocation': {'latLng': place},
    },
  },
};

Map<String, Object?> move(String from, String to, String start, String end) => {
  'startTime': start,
  'endTime': end,
  'activity': {
    'start': {'latLng': from},
    'end': {'latLng': to},
  },
};

String export(List<Map<String, Object?>> segments, {List<Object?>? raw}) =>
    jsonEncode({'semanticSegments': segments, 'rawSignals': raw ?? []});

void main() {
  test('parse: phone export — visits span days, moves give both ends', () {
    final text = export(
      [
        visit(
          moscow,
          '2026-05-01T09:00:00.000+03:00',
          '2026-05-03T18:30:00.000+03:00',
        ),
        move(
          moscow,
          tbilisi,
          '2026-05-03T19:00:00.000+03:00',
          '2026-05-04T01:10:00.000+04:00',
        ),
        {
          'startTime': '2026-05-04T10:00:00.000+04:00',
          'endTime': '2026-05-04T12:00:00.000+04:00',
          'timelinePath': [
            {'point': tbilisi, 'time': '2026-05-04T10:30:00.000+04:00'},
            {'point': tbilisi, 'durationMinutesOffsetFromStartTime': '90'},
          ],
        },
      ],
      raw: [
        {
          'position': {
            'LatLng': tbilisi,
            'timestamp': '2026-05-04T20:00:00.000Z',
          },
        },
      ],
    );
    final samples = parseTimeline(text);
    final byDay = countriesByDay(samples, testBorders);
    expect(byDay.keys.toList()..sort(), [
      Day(2026, 5, 1),
      Day(2026, 5, 2),
      Day(2026, 5, 3),
      Day(2026, 5, 4),
    ]);
    expect(byDay[Day(2026, 5, 2)]!.codes, {'RU'});
    expect(byDay[Day(2026, 5, 3)]!.first, 'RU');
    expect(byDay[Day(2026, 5, 3)]!.last, 'RU');
    // Ночной переезд: прибытие 4-го по местному времени Тбилиси (UTC+4).
    expect(byDay[Day(2026, 5, 4)]!.codes, {'GE'});
    // «Z» в rawSignals → местная дата по долготе (44.8° → +3 ч): 4 мая 23:00.
    expect(byDay[Day(2026, 5, 4)]!.points, 4);
  });

  test('parse: Takeout formats (Records.json, Semantic Location History)', () {
    final records = jsonEncode({
      'locations': [
        {
          'latitudeE7': 557558000,
          'longitudeE7': 376173000,
          'timestamp': '2024-01-10T08:00:00Z',
        },
        {
          'latitudeE7': 557558000,
          'longitudeE7': 376173000,
          'timestampMs': '1704960000000',
        },
      ],
    });
    final byDay = countriesByDay(parseTimeline(records), testBorders);
    expect(byDay.keys, contains(Day(2024, 1, 10)));
    expect(byDay[Day(2024, 1, 10)]!.codes, {'RU'});
    final semantic = jsonEncode({
      'timelineObjects': [
        {
          'placeVisit': {
            'location': {'latitudeE7': 399334000, 'longitudeE7': 328597000},
            'duration': {
              'startTimestamp': '2024-02-01T10:00:00Z',
              'endTimestamp': '2024-02-02T10:00:00Z',
            },
          },
        },
        {
          'activitySegment': {
            'startLocation': {
              'latitudeE7': 399334000,
              'longitudeE7': 328597000,
            },
            'endLocation': {'latitudeE7': 417151000, 'longitudeE7': 448271000},
            'duration': {
              'startTimestamp': '2024-02-02T11:00:00Z',
              'endTimestamp': '2024-02-02T15:00:00Z',
            },
          },
        },
      ],
    });
    final days = countriesByDay(parseTimeline(semantic), testBorders);
    expect(days[Day(2024, 2, 1)]!.codes, {'TR'});
    expect(days[Day(2024, 2, 2)]!.first, 'TR');
    expect(days[Day(2024, 2, 2)]!.last, 'GE');
  });

  test('parse: garbage is skipped, non-JSON throws', () {
    expect(
      parseTimeline(
        '{"semanticSegments": [{"visit": 5}, 7, {"activity": {}}]}',
      ),
      isEmpty,
    );
    expect(parseTimeline('[]'), isEmpty);
    expect(() => parseTimeline('not json'), throwsFormatException);
    // Нулевые координаты и даты вне диапазона отбрасываются.
    expect(
      parseTimeline(
        jsonEncode({
          'locations': [
            {
              'latitudeE7': 0,
              'longitudeE7': 0,
              'timestamp': '2024-01-10T08:00:00Z',
            },
            {
              'latitudeE7': 557558000,
              'longitudeE7': 376173000,
              'timestamp': '1850-01-10T08:00:00Z',
            },
          ],
        }),
      ),
      isEmpty,
    );
  });

  test(
    'periods: border day belongs to both, short gaps bridge, long split',
    () {
      final text = export([
        visit(moscow, '2026-01-01T00:00:00+03:00', '2026-01-05T10:00:00+03:00'),
        move(
          moscow,
          tbilisi,
          '2026-01-05T11:00:00+03:00',
          '2026-01-05T16:00:00+04:00',
        ),
        visit(
          tbilisi,
          '2026-01-05T16:00:00+04:00',
          '2026-01-08T09:00:00+04:00',
        ),
        // Пробел 9–11 января (3 дня) — та же Грузия: мост.
        visit(
          tbilisi,
          '2026-01-12T09:00:00+04:00',
          '2026-01-14T09:00:00+04:00',
        ),
        // Пробел 15 января — 1 февраля (17 дней): разрыв.
        visit(
          tbilisi,
          '2026-02-02T09:00:00+04:00',
          '2026-02-03T09:00:00+04:00',
        ),
      ]);
      final periods = analyzeTimeline(text, testBorders).periods;
      expect(
        periods.map(
          (p) => '${p.code} ${p.start.iso}..${p.end.iso} gap=${p.gapDays}',
        ),
        [
          'RU 2026-01-01..2026-01-05 gap=0',
          'GE 2026-01-05..2026-01-14 gap=3',
          'GE 2026-02-02..2026-02-03 gap=0',
        ],
      );
      expect(periods.every((p) => !p.transit), isTrue);
    },
  );

  test(
    'periods: a one-day stop between two countries is transit; day trip merges',
    () {
      final text = export([
        visit(moscow, '2026-03-01T00:00:00+03:00', '2026-03-02T06:00:00+03:00'),
        visit(ankara, '2026-03-02T09:00:00+03:00', '2026-03-02T20:00:00+03:00'),
        visit(
          tbilisi,
          '2026-03-03T02:00:00+04:00',
          '2026-03-10T09:00:00+04:00',
        ),
        // Однодневная вылазка в Армению и обратно в тот же день.
        visit(
          yerevan,
          '2026-03-06T10:00:00+04:00',
          '2026-03-06T18:00:00+04:00',
        ),
      ]);
      final periods = analyzeTimeline(text, testBorders).periods;
      expect(
        periods.map(
          (p) =>
              '${p.code} ${p.start.iso}..${p.end.iso}${p.transit ? ' T' : ''}',
        ),
        [
          'RU 2026-03-01..2026-03-02',
          'TR 2026-03-02..2026-03-02 T',
          'GE 2026-03-03..2026-03-10',
          'AM 2026-03-06..2026-03-06 T',
        ],
      );
      final analysis = analyzeTimeline(text, testBorders);
      expect(analysis.frequentCode, 'GE');
      expect(analysis.daysWithData, 10);
    },
  );

  test(
    'plan: existing, conflicting, open and new periods against the journal',
    () async {
      final snapshot = await dashboardFixture().load();
      final today = Day(2026, 9, 13);
      ImportPeriod p(String code, Day a, Day b) =>
          ImportPeriod(code: code, start: a, end: b, points: 3, gapDays: 0);
      final rows = planImport(
        [
          p('RU', Day(2026, 1, 1), Day(2026, 1, 12)), // уже есть
          p('AM', Day(2026, 3, 1), Day(2026, 3, 10)), // новое
          p('AM', Day(2026, 7, 5), Day(2026, 7, 9)), // пересекается с Турцией
          p(
            'GE',
            Day(2026, 8, 20),
            Day(2026, 9, 20),
          ), // текущее пребывание, будущее отрезано
          p('QA', Day(2026, 10, 1), Day(2026, 10, 5)), // будущее — пропуск
        ],
        snapshot,
        today,
        match: testDirectory.match,
      );
      expect(rows.map((r) => r.status), [
        ImportStatus.exists,
        ImportStatus.add,
        ImportStatus.conflict,
        ImportStatus.exists,
      ]);
      expect(rows[2].overlaps, 'TR');
      expect(rows[3].period.end, today);
      expect(rows.map((r) => r.selected), [false, true, false, false]);
      // Без текущего пребывания открытый период становится «сейчас».
      final empty = JournalSnapshot(
        trips: snapshot.trips,
        homeCountry: snapshot.homeCountry,
        homeCountryCode: snapshot.homeCountryCode,
        current: null,
      );
      final open = planImport(
        [p('AM', Day(2026, 9, 1), Day(2026, 9, 13))],
        empty,
        today,
        match: testDirectory.match,
      );
      expect(open.single.status, ImportStatus.current);
    },
  );

  test('apply: selected rows become records, current stay and home', () async {
    final today = Day(2026, 9, 13);
    var n = 0;
    final rows = planImport(
      [
        ImportPeriod(
          code: 'RU',
          start: Day(2026, 2, 1),
          end: Day(2026, 2, 10),
          points: 9,
          gapDays: 0,
        ),
        ImportPeriod(
          code: 'TR',
          start: Day(2026, 2, 10),
          end: Day(2026, 2, 10),
          points: 2,
          gapDays: 0,
          transit: true,
        ),
        ImportPeriod(
          code: 'GE',
          start: Day(2026, 2, 11),
          end: Day(2026, 9, 13),
          points: 40,
          gapDays: 2,
        ),
      ],
      JournalSnapshot(),
      today,
    );
    final next = applyImport(
      JournalSnapshot(),
      rows,
      today: today,
      newId: () => 'id${n++}',
      nameOf: (code) => 'name-$code',
      homeCountry: 'Россия',
      homeCountryCode: 'RU',
    );
    expect(next.trips.map((t) => '${t.country} ${t.kind.name}'), [
      'name-RU stay',
      'name-TR transit',
    ]);
    expect(next.current!.countryCode, 'GE');
    expect(next.current!.arrival, Day(2026, 2, 11));
    expect(next.homeCountry, 'Россия');
    next.validate(today);
    // Снятая галочка — записи нет.
    rows[0].selected = false;
    final fewer = applyImport(
      JournalSnapshot(),
      rows,
      today: today,
      newId: () => 'x${n++}',
      nameOf: (c) => c,
      homeCountry: 'Россия',
      homeCountryCode: 'RU',
    );
    expect(fewer.trips.length, 1);
  });
}
