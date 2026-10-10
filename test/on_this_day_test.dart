import 'package:domiday/on_this_day.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, launch, reveal;

Trip t(String id, String country, String code, Day a, Day d, {TripKind kind = TripKind.stay, String city = ''}) =>
    Trip(id: id, country: country, countryCode: code, arrival: a, departure: d, kind: kind, city: city);

JournalSnapshot snap(List<Trip> trips) => JournalSnapshot(
  homeCountry: 'Россия',
  homeCountryCode: 'RU',
  current: CurrentStay(id: 'now', country: 'Россия', countryCode: 'RU', arrival: Day(2020, 1, 1), confirmedOn: Day(2026, 9, 13)),
  trips: trips,
);

void main() {
  test('exact day, window, home excluded, years descending', () {
    final s = snap([
      t('it', 'Италия', 'IT', Day(2025, 9, 10), Day(2025, 9, 20), city: 'Рим'),
      t('es', 'Испания', 'ES', Day(2024, 9, 15), Day(2024, 9, 18)),
      t('fr', 'Франция', 'FR', Day(2023, 3, 1), Day(2023, 3, 5)),
      t('tr', 'Турция', 'TR', Day(2025, 9, 13), Day(2025, 9, 13), kind: TripKind.transit),
    ]);
    final r = onThisDay(s, Day(2026, 9, 13));
    expect(r.map((e) => '${e.year}-${e.trip.id}-${e.exact}').toList(), ['2025-it-true', '2025-tr-true', '2024-es-false']);
    expect(r.first.dayIndex, 4);
    // Ничего в прошлых годах — пусто; дома не показывается.
    expect(onThisDay(s, Day(2026, 6, 1)), isEmpty);
    expect(onThisDay(snap(const []), Day(2026, 9, 13)), isEmpty);
  });

  test('29 February in a common year counts as the 28th', () {
    final s = snap([t('cy', 'Кипр', 'CY', Day(2023, 2, 26), Day(2023, 2, 28))]);
    final r = onThisDay(s, Day(2024, 2, 29));
    expect(r.single.exact, isTrue);
    expect(r.single.dayIndex, 3);
  });

  testWidgets('Today tab: card with entries, opens the trip; hidden when empty', (tester) async {
    final repo = MemoryRepository()
      ..snapshot = snap([
        t('it', 'Италия', 'IT', Day(2025, 9, 10), Day(2025, 9, 20), city: 'Рим'),
        t('es', 'Испания', 'ES', Day(2024, 9, 15), Day(2024, 9, 18)),
      ]);
    await launch(tester, repo, journal: false);
    await reveal(tester, find.byKey(const Key('onThisDay')));
    expect(find.text('Италия, Рим'), findsOneWidget);
    expect(find.text('День 4 из 11'), findsOneWidget);
    expect(find.text('В эти дни'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onThisDay-2025-it')));
    await tester.pumpAndSettle();
    expect(find.text('Рим'), findsWidgets);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    // Без совпадений карточки нет.
    await tester.pumpWidget(const SizedBox());
    final empty = MemoryRepository()..snapshot = snap([t('fr', 'Франция', 'FR', Day(2023, 3, 1), Day(2023, 3, 5))]);
    await launch(tester, empty, journal: false);
    expect(find.byKey(const Key('onThisDay')), findsNothing);
    expect(find.byKey(const Key('reviewNudge')), findsNothing);
  });

  testWidgets('December: the review nudge opens the year review', (tester) async {
    final repo = MemoryRepository()..snapshot = snap([t('it', 'Италия', 'IT', Day(2026, 5, 1), Day(2026, 5, 9))]);
    await launch(tester, repo, journal: false, today: () => Day(2026, 12, 24));
    await reveal(tester, find.byKey(const Key('reviewNudge')));
    await tester.tap(find.byKey(const Key('reviewNudge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('yearReviewPage')), findsOneWidget);
    expect(find.text('Ваш 2026'), findsOneWidget);
  });
}
