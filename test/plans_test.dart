import 'dart:convert';

import 'package:domiday/errors.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:domiday/year_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, launch, openCalendar, reveal;

final today = Day(2026, 9, 13);

Trip t(String id, String country, String code, Day a, Day d, {String city = ''}) =>
    Trip(id: id, country: country, countryCode: code, arrival: a, departure: d, city: city);

JournalSnapshot snap({List<Trip> trips = const [], List<Trip> plans = const []}) => JournalSnapshot(
  homeCountry: 'Россия',
  homeCountryCode: 'RU',
  current: CurrentStay(id: 'now', country: 'Россия', countryCode: 'RU', arrival: Day(2026, 7, 21), confirmedOn: today),
  trips: trips,
  plans: plans,
);

void main() {
  group('schema 5', () {
    test('writes plans, reads 4 without plans and 5 with them, rejects 6', () {
      final s = snap(plans: [t('p1', 'Кипр', 'CY', Day(2026, 10, 1), Day(2026, 10, 14), city: 'Лимасол')]);
      final json = s.toJson();
      expect(json['schemaVersion'], 5);
      expect((json['plans'] as List).length, 1);
      final back = JournalSnapshot.fromJson(jsonDecode(jsonEncode(json)), today);
      expect(back.plans.single.city, 'Лимасол');
      expect(back.plans.single.arrival, Day(2026, 10, 1));
      // Планы не факты: в известных поездках их нет.
      expect(back.knownTrips(today).map((x) => x.id), isNot(contains('p1')));
      final v4 = Map<String, Object?>.of(json)..['schemaVersion'] = 4..remove('plans');
      expect(JournalSnapshot.fromJson(v4, today).plans, isEmpty);
      final v6 = Map<String, Object?>.of(json)..['schemaVersion'] = 6;
      expect(() => JournalSnapshot.fromJson(v6, today), throwsFormatException);
      final noPlans = Map<String, Object?>.of(json)..remove('plans');
      expect(() => JournalSnapshot.fromJson(noPlans, today), throwsFormatException);
    });

    test('plan validation: future allowed, departure before arrival and duplicate ids rejected', () {
      expect(t('p', 'Кипр', 'CY', Day(2027, 1, 1), Day(2027, 1, 5)).validate(today, plan: true), isNull);
      expect(t('p', 'Кипр', 'CY', Day(2027, 1, 1), Day(2027, 1, 5)).validate(today), JournalErrorCode.futureTrip);
      expect(t('p', 'Кипр', 'CY', Day(2027, 1, 5), Day(2027, 1, 1)).validate(today, plan: true), JournalErrorCode.departureBeforeArrival);
      final dup = snap(
        trips: [t('x', 'Грузия', 'GE', Day(2026, 5, 1), Day(2026, 5, 3))],
        plans: [t('x', 'Кипр', 'CY', Day(2027, 1, 1), Day(2027, 1, 5))],
      );
      expect(() => dup.validate(today), throwsFormatException);
    });

    test('calendar: planned future days carry the plan mark, past days do not', () {
      final s = snap(plans: [t('p', 'Кипр', 'CY', Day(2026, 9, 10), Day(2026, 9, 20))]);
      final data = YearCalendarData(YearSummary(s, 2026, today), today, snapshot: s);
      expect(data.planOf(9, 15)?.code, 'CY');
      expect(data.planOf(9, 12), isNull);
      expect(data.kindOf(9, 15), DayKind.future);
      expect(data.hasPlans, isTrue);
    });
  });

  testWidgets('journal: plans section, editing a plan, deleting it', (tester) async {
    final repo = MemoryRepository()
      ..snapshot = snap(
        trips: [t('ge', 'Грузия', 'GE', Day(2026, 5, 5), Day(2026, 5, 19))],
        plans: [t('p1', 'Кипр', 'CY', Day(2026, 10, 1), Day(2026, 10, 14), city: 'Лимасол')],
      );
    await launch(tester, repo);
    await reveal(tester, find.byKey(const Key('plansSection')));
    expect(find.byKey(const Key('plan-p1')), findsOneWidget);
    expect(find.text('через 18 дней'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan-p1')));
    await tester.pumpAndSettle();
    expect(find.text('План поездки'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('city')), 'Пафос');
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(repo.snapshot.plans.single.city, 'Пафос');
    expect(repo.snapshot.trips.length, 1);
    await reveal(tester, find.byKey(const Key('plan-p1')));
    await tester.tap(find.byKey(const Key('plan-p1')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('deleteTrip')));
    await tester.tap(find.byKey(const Key('deleteTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(repo.snapshot.plans, isEmpty);
    expect(repo.snapshot.trips.length, 1);
  });

  testWidgets('journal: new record with the plan toggle is saved as a plan', (tester) async {
    final repo = MemoryRepository()..snapshot = snap(trips: [t('ge', 'Грузия', 'GE', Day(2026, 5, 5), Day(2026, 5, 19))]);
    await launch(tester, repo);
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modePlan')));
    await tester.pumpAndSettle();
    expect(find.text('Новый план'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('country')), 'Кипр');
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('quickToday')));
    await tester.tap(find.byKey(const Key('quickToday')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(repo.snapshot.plans.single.countryCode, 'CY');
    expect(repo.snapshot.trips.length, 1);
  });

  testWidgets('Today: next trip card, arrived plan in the same country is just cleared', (tester) async {
    final repo = MemoryRepository()
      ..snapshot = snap(plans: [
        t('next', 'Кипр', 'CY', Day(2026, 10, 1), Day(2026, 10, 14)),
        t('here', 'Россия', 'RU', Day(2026, 9, 10), Day(2026, 9, 20)),
      ]);
    await launch(tester, repo, journal: false);
    await reveal(tester, find.byKey(const Key('nextTrip')));
    expect(find.text('через 18 дней'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('planArrived')));
    await tester.tap(find.byKey(const Key('planYes')));
    await tester.pumpAndSettle();
    expect(repo.snapshot.plans.map((p) => p.id), ['next']);
    expect(find.byKey(const Key('planArrived')), findsNothing);
  });

  testWidgets('Today: arrived plan in another country opens the status editor prefilled', (tester) async {
    final repo = MemoryRepository()..snapshot = snap(plans: [t('cy', 'Кипр', 'CY', Day(2026, 9, 10), Day(2026, 9, 20), city: 'Лимасол')]);
    await launch(tester, repo, journal: false);
    await reveal(tester, find.byKey(const Key('planArrived')));
    expect(find.text('По плану сегодня: Кипр, Лимасол. Вы там?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planYes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saveStatus')), findsOneWidget);
    expect(find.text('Кипр'), findsWidgets);
    // Ничего не записано, пока владелец не сохранил.
    expect(repo.snapshot.plans.length, 1);
    expect(repo.snapshot.current!.countryCode, 'RU');
  });

  testWidgets('Today: overdue plan can be added as a trip, the plan is removed', (tester) async {
    final repo = MemoryRepository()..snapshot = snap(plans: [t('old', 'Грузия', 'GE', Day(2026, 6, 1), Day(2026, 6, 9), city: 'Тбилиси')]);
    await launch(tester, repo, journal: false);
    await reveal(tester, find.byKey(const Key('planOverdue')));
    expect(find.text('Грузия, Тбилиси: даты прошли'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planAddAsTrip')));
    await tester.pumpAndSettle();
    expect(find.text('Новая поездка'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(repo.snapshot.plans, isEmpty);
    expect(repo.snapshot.trips.single.city, 'Тбилиси');
    expect(repo.snapshot.trips.single.arrival, Day(2026, 6, 1));
  });

  testWidgets('expanded month: planned future days show the country code', (tester) async {
    final repo = MemoryRepository()..snapshot = snap(plans: [t('cy', 'Кипр', 'CY', Day(2026, 9, 20), Day(2026, 9, 25))]);
    await launch(tester, repo, journal: false);
    await openCalendar(tester);
    await reveal(tester, find.byKey(const Key('month-9')));
    await tester.tap(find.byKey(const Key('month-9')));
    await tester.pumpAndSettle();
    final cell = find.byKey(const Key('day-2026-9-22'));
    await reveal(tester, cell);
    expect(find.descendant(of: cell, matching: find.text('CY')), findsOneWidget);
    // Прошедший день без записей кода не получает.
    expect(find.descendant(of: find.byKey(const Key('day-2026-9-10')), matching: find.text('CY')), findsNothing);
  });
}
