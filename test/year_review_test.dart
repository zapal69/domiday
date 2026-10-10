import 'package:domiday/share.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, launch, openCalendar, reveal, testBorders;

void main() {
  testWidgets('year review: countries, new ones, days, map, cities, share', (tester) async {
    Trip t(String id, String country, String code, Day a, Day d, {String city = ''}) =>
        Trip(id: id, country: country, countryCode: code, arrival: a, departure: d, city: city);
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(
        homeCountry: 'Россия',
        homeCountryCode: 'RU',
        current: CurrentStay(id: 'now', country: 'Россия', countryCode: 'RU', arrival: Day(2026, 7, 21), confirmedOn: Day(2026, 9, 13)),
        trips: [
          t('ge25', 'Грузия', 'GE', Day(2025, 5, 1), Day(2025, 5, 10), city: 'Тбилиси'),
          t('ge', 'Грузия', 'GE', Day(2026, 5, 5), Day(2026, 5, 19), city: 'Тбилиси'),
          t('am', 'Армения', 'AM', Day(2026, 6, 1), Day(2026, 6, 9), city: 'Ереван'),
          t('cy', 'Кипр', 'CY', Day(2026, 3, 2), Day(2026, 4, 14), city: 'Лимасол'),
        ],
      );
    await launch(tester, repo, journal: false, borders: testBorders, share: FakeShareService());
    await openCalendar(tester);
    await reveal(tester, find.byKey(const Key('yearReview')));
    await tester.tap(find.byKey(const Key('yearReview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('yearReviewPage')), findsOneWidget);
    // Россия, Грузия, Армения, Кипр — четыре; новых две (Армения и Кипр),
    // Грузия была в 2025, дом был всегда.
    expect(find.text('4 страны'), findsOneWidget);
    expect(find.text('2 новые страны'), findsOneWidget);
    expect(find.byKey(const Key('review-country-cy')), findsOneWidget);
    final pages = find.byKey(const Key('reviewPages'));
    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Самая долгая поездка'), findsOneWidget);
    expect(find.textContaining('Кипр, Лимасол'), findsOneWidget);
    expect(find.textContaining('44 дня'), findsOneWidget);
    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-map')), findsOneWidget);
    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 города'), findsOneWidget);
    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reviewShare')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('yearReviewPage')), findsNothing);
    expect(find.byKey(const Key('yearCard')), findsOneWidget);
  });
}
