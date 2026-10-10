import 'package:domiday/l10n/app_localizations.dart';
import 'package:domiday/main.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show reveal;

/// Редактор с черновиком (даты уже выбраны) поверх дневника с записью
/// Грузия 1–10 июня: сохранение Турции 8–20 июня задевает 3 дня.
typedef Saved = JournalSnapshot? Function();

Future<Saved> pumpEditor(
  WidgetTester tester, {
  required JournalSnapshot snapshot,
  required Trip draft,
}) async {
  JournalSnapshot? saved;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TripEditor(
        draft: draft,
        today: () => Day(2026, 9, 13),
        snapshot: () => snapshot,
        onSave: (next) async => saved = next,
      ),
    ),
  );
  return () => saved;
}

void main() {
  final georgia = Trip(
    id: 'ge',
    country: 'Грузия',
    countryCode: 'GE',
    arrival: Day(2026, 6, 1),
    departure: Day(2026, 6, 10),
  );
  final turkey = Trip(
    id: 'tr',
    country: 'Турция',
    countryCode: 'TR',
    arrival: Day(2026, 6, 8),
    departure: Day(2026, 6, 20),
  );

  testWidgets('overlap: cancel saves nothing, keep both saves as is', (
    tester,
  ) async {
    final saved = await pumpEditor(
      tester,
      snapshot: JournalSnapshot(trips: [georgia]),
      draft: turkey,
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('overlapDialog')), findsOneWidget);
    expect(find.text('Дни уже заняты'), findsOneWidget);
    expect(
      find.textContaining(
        'Грузия, 01.06.2026 — 10.06.2026: станет 01.06.2026 — 08.06.2026',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(saved(), isNull);
    expect(find.byKey(const Key('saveTrip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overlapKeep')));
    await tester.pumpAndSettle();
    final next = saved()!;
    // Черновик получает id при сохранении; проверяем по стране.
    expect(next.trips.map((t) => t.country), ['Грузия', 'Турция']);
    expect(next.trips.first.departure, Day(2026, 6, 10));
  });

  testWidgets('overlap: replace trims the old record to the junction day', (
    tester,
  ) async {
    final saved = await pumpEditor(
      tester,
      snapshot: JournalSnapshot(trips: [georgia]),
      draft: turkey,
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overlapReplace')));
    await tester.pumpAndSettle();
    final next = saved()!;
    expect(next.trips.map((t) => t.country), ['Грузия', 'Турция']);
    expect(next.trips.first.departure, Day(2026, 6, 8));
    expect(next.trips.last.arrival, Day(2026, 6, 8));
  });

  testWidgets('no overlap: saves without a dialog; junction day allowed', (
    tester,
  ) async {
    final saved = await pumpEditor(
      tester,
      snapshot: JournalSnapshot(trips: [georgia]),
      draft: Trip(
        id: 'tr',
        country: 'Турция',
        countryCode: 'TR',
        arrival: Day(2026, 6, 10),
        departure: Day(2026, 6, 20),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('overlapDialog')), findsNothing);
    expect(saved()!.trips, hasLength(2));
  });
}
