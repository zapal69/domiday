import 'package:flutter_test/flutter_test.dart';
import 'package:domiday/trip.dart';

Trip trip(
  String start,
  String end, {
  String country = 'Россия',
  String id = '1',
  String city = '',
  String note = '',
}) => Trip(
  id: id,
  country: country,
  city: city,
  note: note,
  arrival: Day.parse(start),
  departure: Day.parse(end),
);

void main() {
  test('strict dates, leap years, and ISO calendar roundtrip', () {
    expect(Day.parse('2024-02-29').iso, '2024-02-29');
    expect(() => Day.parse('2023-02-29'), throwsFormatException);
    expect(() => Day.parse('2024-04-31'), throwsFormatException);
    expect(() => Day.parse('2024-13-01'), throwsFormatException);
    expect(() => Day.parse('2024-1-01'), throwsFormatException);
    expect(() => Day.parse('1899-12-31'), throwsFormatException);
    expect(() => Day.parse('2024-01-01T00:00:00Z'), throwsFormatException);
  });

  test('inclusive day, leap day and both DST boundaries', () {
    expect(unionDays([trip('2024-02-29', '2024-02-29')]), 1);
    expect(unionDays([trip('2024-02-28', '2024-03-01')]), 3);
    expect(unionDays([trip('2024-03-30', '2024-04-01')]), 3);
    expect(unionDays([trip('2024-10-26', '2024-10-28')]), 3);
    expect(unionDays([]), 0);
    expect(unionDays([trip('1900-01-01', '1900-01-02')]), 2);
  });

  test('overlap, nesting, adjacency, disjoint and cross-country union', () {
    final trips = [
      trip('2024-01-01', '2024-01-05'),
      trip('2024-01-03', '2024-01-04', id: '2'),
      trip('2024-01-05', '2024-01-08', id: '3', country: 'Грузия'),
      trip('2024-01-09', '2024-01-09', id: '4'),
      trip('2024-01-12', '2024-01-12', id: '5'),
    ];
    expect(unionDays(trips), 10);
    expect(countryStats(trips).first.days, 7);
    expect(countryStats(trips).last.days, 4);
  });

  test('country normalization retains original display', () {
    final trips = [
      trip('2024-01-01', '2024-01-03', country: '  Южная   Корея '),
      trip('2024-01-02', '2024-01-04', country: 'южная корея', id: '2'),
    ];
    expect(countryStats(trips), hasLength(1));
    expect(countryStats(trips).single.days, 4);
    expect(trips.first.country, '  Южная   Корея ');
    expect(normalize('  Орёл  '), 'орел');
  });

  test('year selects touching trips and clips only calculated days', () {
    final trips = [
      trip('2023-12-30', '2024-01-02'),
      trip('2024-12-31', '2025-01-02', id: '2'),
    ];
    expect(selectTrips(trips, year: 2024), hasLength(2));
    expect(unionDays(trips, year: 2024), 3);
    expect(countryStats(trips, year: 2024).single.days, 3);
    expect(unionDays(trips, year: 2022), 0);
    expect(trips.first.days, 4);
  });

  test('search country city note year, combining terms and filters', () {
    final trips = [
      trip(
        '2023-12-30',
        '2025-01-02',
        country: 'Турция',
        city: 'Стамбул',
        note: 'Тёплый вечер',
      ),
      trip('2024-06-01', '2024-06-02', id: '2', country: 'Грузия'),
    ];
    expect(selectTrips(trips, query: 'ТУРЦИЯ теплый'), hasLength(1));
    expect(selectTrips(trips, query: '  стамбул '), hasLength(1));
    expect(selectTrips(trips, query: '2024'), hasLength(2));
    expect(selectTrips(trips, query: 'вечер', country: 'грузия'), isEmpty);
    expect(selectTrips(trips, query: 'Париж'), isEmpty);
    expect(selectTrips(trips).first.id, '2');
  });

  test('invalid ranges, missing country and future dates fail validation', () {
    final today = Day(2026, 9, 13);
    expect(trip('2026-09-13', '2026-09-13').validate(today), isNull);
    expect(trip('2026-09-14', '2026-09-14').validate(today), isNotNull);
    expect(trip('2026-09-12', '2026-09-14').validate(today), isNotNull);
    expect(trip('2024-01-02', '2024-01-01').validate(today), isNotNull);
    expect(
      trip('2024-01-01', '2024-01-02', country: ' ').validate(today),
      isNotNull,
    );
  });
}
