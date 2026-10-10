import 'dart:async';

import 'package:domiday/errors.dart';
import 'package:domiday/journal_controller.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trip_test.dart' show trip;
import 'widget_test.dart' show MemoryRepository;

void main() {
  final today = Day(2026, 9, 13);
  JournalSnapshot state({
    Day? arrival,
    List<Trip> trips = const [],
    String country = 'Турция',
  }) => JournalSnapshot(
    trips: trips,
    homeCountry: 'Россия',
    current: CurrentStay(
      id: 'present',
      country: country,
      arrival: arrival,
      confirmedOn: today,
    ),
  );

  test(
    'unknown arrival contributes no days; unknown is full elapsed/past year',
    () {
      final snapshot = state();
      expect(snapshot.knownTrips(today), isEmpty);
      expect(YearSummary(snapshot, 2026, today).unknown, 256);
      expect(YearSummary(snapshot, 2024, today).unknown, 366);
      expect(YearSummary(snapshot, 2025, today).unknown, 365);
      expect(YearSummary(snapshot, 2026, today).home, isEmpty);
      expect(YearSummary(snapshot, 2026, today).away, isEmpty);
      expect(
        () => YearSummary(snapshot, 2027, today),
        throwsA(isA<JournalError>()),
      );
    },
  );

  test('cross-year leap current stays and inclusive same-day counting', () {
    final snapshot = state(arrival: Day(2023, 12, 31));
    expect(YearSummary(snapshot, 2024, today).known.length, 366);
    expect(YearSummary(snapshot, 2023, today).known.length, 1);
    expect(YearSummary(snapshot, 2026, today).known.length, 256);
    expect(state(arrival: today).current!.asTrip(today)!.days, 1);
    expect(
      snapshot.current!.asTrip(today)!.days,
      today.ordinal - Day(2023, 12, 31).ordinal + 1,
    );
  });

  test('same country dedup, cross-country union, home/away overlap honest', () {
    final snapshot = state(
      trips: [
        trip('2024-01-01', '2024-01-05', id: 'a'),
        trip('2024-01-03', '2024-01-05', country: '  РОССИЯ ', id: 'b'),
        trip('2024-01-05', '2024-01-08', country: 'Грузия', id: 'c'),
        trip('2024-01-06', '2024-01-09', country: 'Турция', id: 'd'),
      ],
    );
    final summary = YearSummary(snapshot, 2024, today);
    expect(summary.home.length, 5);
    expect(summary.away.length, 5);
    expect(summary.overlap, 1);
    expect(summary.known.length, 9);
    expect(summary.unknown, 357);
    expect(summary.countries.singleWhere((s) => s.key == 'россия').days, 5);
  });

  test('year stats clip any range to today as well as selected year', () {
    final snapshot = state(
      trips: [trip('2025-12-31', '2026-12-31', id: 'future')],
    );
    expect(YearSummary(snapshot, 2026, today).known.length, 256);
    expect(YearSummary(snapshot, 2025, today).known.length, 1);
  });

  test(
    'changing home changes category only, not records or current identity',
    () {
      final snapshot = state(
        arrival: Day(2026, 9, 1),
        trips: [trip('2026-01-01', '2026-01-05', id: 'a')],
      );
      final next = snapshot.copyWith(homeCountry: 'Турция');
      expect(next.trips.single.toJson(), snapshot.trips.single.toJson());
      expect(identical(next.current, snapshot.current), isTrue);
      expect(YearSummary(next, 2026, today).home.length, 13);
      expect(YearSummary(next, 2026, today).away.length, 5);
    },
  );

  test(
    'current never inferred from latest history and collections immutable',
    () {
      final snapshot = state(
        trips: [trip('2026-09-13', '2026-09-13', country: 'Япония')],
      );
      expect(snapshot.current!.country, 'Турция');
      expect(snapshot.current!.arrival, isNull);
      expect(() => snapshot.trips.clear(), throwsUnsupportedError);
      expect(() => snapshot.undated.clear(), throwsUnsupportedError);
    },
  );

  test(
    'transition closes old and opens new same day, preserves all old fields',
    () {
      final old = trip(
        '2024-01-01',
        '2024-01-03',
        note: ' untouched ',
        id: 'old',
      );
      final snapshot = state(arrival: today, trips: [old]);
      final next = snapshot.transition('Грузия', today, today, 'next');
      expect(snapshot.trips, hasLength(1));
      expect(next.trips.first.toJson(), old.toJson());
      expect(next.trips.last.id, 'present');
      expect(next.trips.last.days, 1);
      expect(next.current!.asTrip(today)!.days, 1);
      expect(next.current!.notBefore, today);
      final summary = YearSummary(next, 2026, today);
      expect(summary.known.length, 1);
      expect(summary.countries.map((s) => s.days).toList(), [1, 1]);
    },
  );

  test(
    'transition rejects same country, before arrival, future and duplicate id',
    () {
      final snapshot = state(arrival: Day(2026, 9, 2));
      expect(
        () => snapshot.transition('  ТУРЦИЯ ', today, today, 'new'),
        throwsA(isA<JournalError>()),
      );
      expect(
        () => snapshot.transition('Грузия', Day(2026, 9, 1), today, 'new'),
        throwsA(isA<JournalError>()),
      );
      expect(
        () => snapshot.transition('Грузия', Day(2026, 9, 14), today, 'new'),
        throwsA(isA<JournalError>()),
      );
      expect(
        () => snapshot.transition('Грузия', today, today, 'present'),
        throwsFormatException,
      );
    },
  );

  test(
    'unknown previous arrival archives without fabricating backdated range',
    () {
      final snapshot = state();
      expect(
        () => snapshot.transition('Грузия', Day(2026, 9, 12), today, 'next'),
        throwsA(isA<JournalError>()),
      );
      final next = snapshot.transition('Грузия', today, today, 'next');
      expect(next.trips, isEmpty);
      expect(next.undated.single.id, 'present');
      expect(next.undated.single.country, 'Турция');
      expect(next.undated.single.departure, today);
      expect(YearSummary(next, 2026, today).known.length, 1);
      expect(
        JournalSnapshot.fromJson(next.toJson(), today).toJson(),
        next.toJson(),
      );
    },
  );

  test('date correction cannot precede a confirmed transition', () {
    final snapshot = state(arrival: today)
        .transition('Грузия', today, today, 'new');
    final bad = snapshot.copyWith(
      current: CurrentStay(
        id: 'new',
        country: 'Грузия',
        arrival: Day(2026, 9, 12),
        confirmedOn: today,
        notBefore: today,
      ),
    );
    expect(() => bad.validate(today), throwsFormatException);
  });

  test('gap preview shows actual bounded missing ranges; cancellation is read-only', () {
    final snapshot = state(
      trips: [
        trip('2024-01-05', '2024-01-08', id: 'a'),
        trip('2024-01-07', '2024-01-10', id: 'b'),
        trip('2024-01-15', '2024-01-16', id: 'c'),
        trip('2024-01-17', '2024-01-20', id: 'd'),
        trip('2024-02-01', '2024-02-02', id: 'e'),
      ],
    );
    final before = snapshot.toJson();
    final preview = HomeFillPreview(snapshot, 2024, today);
    expect(preview.gaps.map((g) => g.label).toList(), [
      '11.01.2024 — 14.01.2024',
      '21.01.2024 — 31.01.2024',
    ]);
    expect(preview.days, 15);
    expect(snapshot.toJson(), before);
    var id = 0;
    final confirmed = preview.confirm(
      snapshot,
      today,
      () => 'fill-${id++}',
      note: 'gap',
    );
    expect(confirmed.trips, hasLength(7));
    expect(confirmed.trips.last.country, 'Россия');
    expect(confirmed.trips.last.note, 'gap');
    expect(missingGaps(confirmed, 2024, today), isEmpty);
    expect(
      confirmed.trips.take(5).map((t) => t.toJson()).toList(),
      snapshot.trips.map((t) => t.toJson()).toList(),
    );
    final addedDays = unionDays(confirmed.trips) - unionDays(snapshot.trips);
    expect(addedDays, preview.days);
  });

  test(
    'cross-year gaps use outside-year bounding stays and include leap day',
    () {
      final snapshot = state(
        trips: [
          trip('2023-12-01', '2023-12-30', id: 'a'),
          trip('2024-03-01', '2024-03-01', id: 'b'),
        ],
      );
      final preview = HomeFillPreview(snapshot, 2024, today);
      expect(preview.gaps.single.label, '01.01.2024 — 29.02.2024');
      expect(preview.days, 60);
      expect(HomeFillPreview(state(), 2024, today).gaps, isEmpty);
      expect(HomeFillPreview(state(arrival: today), 2026, today).gaps, isEmpty);
    },
  );

  test('stale preview rejects changed state/day; repeated confirmation is not a duplicate', () {
    final snapshot = state(
      trips: [
        trip('2024-01-01', '2024-01-01', id: 'a'),
        trip('2024-01-03', '2024-01-03', id: 'b'),
      ],
    );
    final preview = HomeFillPreview(snapshot, 2024, today);
    final next = preview.confirm(snapshot, today, () => 'fill', note: 'gap');
    expect(
      () => preview.confirm(next, today, () => 'duplicate', note: 'gap'),
      throwsA(isA<JournalError>()),
    );
    expect(
      () => preview.confirm(
        snapshot,
        Day(2026, 9, 14),
        () => 'duplicate',
        note: 'gap',
      ),
      throwsA(isA<JournalError>()),
    );
    expect(HomeFillPreview(next, 2024, today).days, 0);
  });

  test('controller awaits disk; save failure preserves exact memory, retry/restart works', () async {
    final repo = MemoryRepository()..failSave = true;
    final controller = JournalController(repo, () => today);
    addTearDown(controller.dispose);
    await controller.load();
    final before = controller.snapshot;
    final next = state(arrival: today);
    await expectLater(controller.commit(next), throwsStateError);
    expect(identical(controller.snapshot, before), isTrue);
    expect(identical(repo.snapshot, before), isTrue);
    repo.failSave = false;
    repo.saveGate = Completer<void>();
    final pending = controller.commit(next);
    expect(identical(controller.snapshot, before), isTrue);
    await expectLater(controller.commit(next), throwsStateError);
    repo.saveGate!.complete();
    await pending;
    expect(identical(controller.snapshot, next), isTrue);
    final restarted = JournalController(repo, () => today);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.snapshot.toJson(), next.toJson());
  });

  test('suggested codes: detected, current, home, recent trips', () {
    Trip t(String start, String end, String code) => Trip(
      id: '$code$start',
      country: code,
      countryCode: code,
      city: '',
      note: '',
      arrival: Day.parse(start),
      departure: Day.parse(end),
    );
    final s = JournalSnapshot(
      homeCountry: 'Кипр',
      homeCountryCode: 'CY',
      current: CurrentStay(
        id: 'present',
        country: 'Грузия',
        countryCode: 'GE',
        arrival: Day(2026, 9, 1),
        confirmedOn: today,
      ),
      trips: [
        t('2026-01-01', '2026-01-10', 'TR'),
        t('2026-06-01', '2026-06-10', 'AM'),
        t('2026-03-01', '2026-03-05', 'GE'),
      ],
    );
    expect(s.suggestedCodes(), ['GE', 'CY', 'AM', 'TR']);
    expect(s.suggestedCodes(detected: 'AM'), ['AM', 'GE', 'CY', 'TR']);
    expect(s.suggestedCodes(limit: 2), ['GE', 'CY']);
    expect(JournalSnapshot().suggestedCodes(), isEmpty);
  });
}
