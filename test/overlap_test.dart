import 'package:domiday/overlap.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/timeline_import.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

Trip trip(
  String id,
  String code,
  Day from,
  Day to, {
  TripKind kind = TripKind.stay,
}) => Trip(
  id: id,
  country: code,
  countryCode: code,
  arrival: from,
  departure: to,
  kind: kind,
);

Day d(int day, [int month = 6]) => Day(2026, month, day);

void main() {
  final today = d(13, 9);
  var counter = 0;
  String newId() => 'new-${counter++}';

  test('one shared day at the junction is a moving day, not an overlap', () {
    final snapshot = JournalSnapshot(trips: [trip('ge', 'GE', d(1), d(10))]);
    final plan = planOverlap(
      snapshot,
      trip('tr', 'TR', d(10), d(20)),
      today,
      newId: newId,
    );
    expect(plan.isEmpty, isTrue);
    // И запись, целиком лежащая до или после, тоже не пересекается.
    expect(
      planOverlap(
        snapshot,
        trip('x', 'TR', d(11), d(20)),
        today,
        newId: newId,
      ).isEmpty,
      isTrue,
    );
  });

  test('two or more shared days: trim keeps the junction day', () {
    final snapshot = JournalSnapshot(trips: [trip('ge', 'GE', d(1), d(10))]);
    final incoming = trip('tr', 'TR', d(9), d(20));
    final plan = planOverlap(snapshot, incoming, today, newId: newId);
    expect(plan.items, hasLength(1));
    final item = plan.items.single;
    expect(item.outcome, OverlapOutcome.trim);
    expect(item.sameCountry, isFalse);
    expect(item.pieces.single.arrival, d(1));
    expect(item.pieces.single.departure, d(9));
    expect(plan.canReplace, isTrue);
    // «Оставить обе» — обе записи как есть; «Заменить» — обрезка.
    final kept = applyOverlap(snapshot, plan, replace: false);
    expect(kept.trips.map((t) => t.id), ['ge', 'tr']);
    expect(kept.trips.first.departure, d(10));
    final replaced = applyOverlap(snapshot, plan, replace: true);
    expect(replaced.trips.map((t) => t.id), ['ge', 'tr']);
    expect(replaced.trips.first.departure, d(9));
    expect(replaced.trips.first.city, '');
  });

  test('new trip in the middle splits the old one; the tail gets a new id', () {
    final old = Trip(
      id: 'ge',
      country: 'Грузия',
      countryCode: 'GE',
      city: 'Тбилиси',
      note: 'заметка',
      arrival: d(1),
      departure: d(30),
    );
    final snapshot = JournalSnapshot(trips: [old]);
    final plan = planOverlap(
      snapshot,
      trip('tr', 'TR', d(10), d(15)),
      today,
      newId: newId,
    );
    final item = plan.items.single;
    expect(item.outcome, OverlapOutcome.split);
    expect(item.pieces.map((p) => p.id), ['ge', 'new-0']);
    expect(item.pieces.first.departure, d(10));
    expect(item.pieces.last.arrival, d(15));
    expect(item.pieces.last.departure, d(30));
    expect(item.pieces.last.city, 'Тбилиси');
    expect(item.pieces.last.note, 'заметка');
    final next = applyOverlap(snapshot, plan, replace: true);
    expect(next.trips.map((t) => t.id), ['ge', 'new-0', 'tr']);
  });

  test('fully covered record is removed only on replace', () {
    final snapshot = JournalSnapshot(trips: [trip('it', 'IT', d(12), d(14))]);
    final plan = planOverlap(
      snapshot,
      trip('fr', 'FR', d(10), d(20)),
      today,
      newId: newId,
    );
    expect(plan.items.single.outcome, OverlapOutcome.remove);
    expect(
      applyOverlap(snapshot, plan, replace: false).trips.map((t) => t.id),
      ['it', 'fr'],
    );
    expect(applyOverlap(snapshot, plan, replace: true).trips.map((t) => t.id), [
      'fr',
    ]);
  });

  test('same country overlapping warns too and is flagged', () {
    final snapshot = JournalSnapshot(trips: [trip('ge', 'GE', d(1), d(10))]);
    final plan = planOverlap(
      snapshot,
      trip('ge2', 'GE', d(5), d(12)),
      today,
      newId: newId,
    );
    expect(plan.items.single.sameCountry, isTrue);
    expect(plan.items.single.outcome, OverlapOutcome.trim);
  });

  test('transit never conflicts: inside a stay or as the incoming record', () {
    final stay = trip('ge', 'GE', d(1), d(10));
    final transit = trip('tr', 'TR', d(4), d(6), kind: TripKind.transit);
    expect(
      planOverlap(
        JournalSnapshot(trips: [stay]),
        transit,
        today,
        newId: newId,
      ).isEmpty,
      isTrue,
    );
    expect(
      planOverlap(
        JournalSnapshot(trips: [transit]),
        stay,
        today,
        newId: newId,
      ).isEmpty,
      isTrue,
    );
  });

  test('editing a record never conflicts with its own previous version', () {
    final snapshot = JournalSnapshot(trips: [trip('ge', 'GE', d(1), d(10))]);
    final plan = planOverlap(
      snapshot,
      trip('ge', 'GE', d(1), d(12)),
      today,
      newId: newId,
    );
    expect(plan.isEmpty, isTrue);
    final next = applyOverlap(snapshot, plan, replace: false);
    expect(next.trips.single.departure, d(12));
  });

  test('current stay: movable when the trip ends before today', () {
    final snapshot = JournalSnapshot(
      current: CurrentStay(
        id: 'cur',
        country: 'RU',
        countryCode: 'RU',
        arrival: d(1, 9),
        confirmedOn: today,
      ),
    );
    final plan = planOverlap(
      snapshot,
      trip('ge', 'GE', d(25, 8), d(5, 9)),
      today,
      newId: newId,
    );
    final item = plan.items.single;
    expect(item.outcome, OverlapOutcome.moveCurrent);
    expect(item.newArrival, d(5, 9));
    expect(plan.canReplace, isTrue);
    final next = applyOverlap(snapshot, plan, replace: true);
    expect(next.current!.arrival, d(5, 9));
    expect(next.current!.id, 'cur');
    expect(next.trips.single.id, 'ge');
  });

  test('current stay: not resolvable when the trip reaches today or arrival unknown', () {
    final dated = JournalSnapshot(
      current: CurrentStay(
        id: 'cur',
        country: 'RU',
        countryCode: 'RU',
        arrival: d(1, 9),
        confirmedOn: today,
      ),
    );
    final plan = planOverlap(
      dated,
      trip('ge', 'GE', d(5, 9), today),
      today,
      newId: newId,
    );
    expect(plan.items.single.outcome, OverlapOutcome.unresolved);
    expect(plan.canReplace, isFalse);
    // «Заменить» ничего не ломает: неразрешимое остаётся как есть.
    final next = applyOverlap(dated, plan, replace: true);
    expect(next.current!.arrival, d(1, 9));
    expect(next.trips.single.id, 'ge');
    final undated = JournalSnapshot(
      current: CurrentStay(
        id: 'cur',
        country: 'RU',
        countryCode: 'RU',
        arrival: null,
        confirmedOn: d(1, 9),
      ),
    );
    expect(
      planOverlap(
        undated,
        trip('ge', 'GE', d(2, 9), d(5, 9)),
        today,
        newId: newId,
      ).canReplace,
      isFalse,
    );
    // Пересечения нет: поездка закончилась до подтверждённого «сейчас».
    expect(
      planOverlap(
        undated,
        trip('ge', 'GE', d(20, 8), d(1, 9)),
        today,
        newId: newId,
      ).isEmpty,
      isTrue,
    );
  });

  test('import: a selected conflict row trims the record it overlaps', () {
    final snapshot = JournalSnapshot(
      homeCountry: 'RU',
      homeCountryCode: 'RU',
      trips: [trip('ge', 'GE', d(1), d(10))],
    );
    final rows = planImport(
      [
        ImportPeriod(
          code: 'TR',
          start: d(8),
          end: d(20),
          points: 5,
          gapDays: 0,
        ),
      ],
      snapshot,
      today,
    );
    expect(rows.single.status, ImportStatus.conflict);
    expect(rows.single.selected, isFalse);
    rows.single.selected = true;
    final next = applyImport(
      snapshot,
      rows,
      today: today,
      newId: newId,
      nameOf: (code) => code,
    );
    expect(next.trips.map((t) => t.countryCode), ['GE', 'TR']);
    expect(next.trips.first.departure, d(8));
    expect(next.trips.last.arrival, d(8));
    expect(next.trips.last.departure, d(20));
  });
}
